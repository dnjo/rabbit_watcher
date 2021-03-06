require 'spec_helper'
require 'rabbit_watcher/watcher'
require 'rabbit_watcher/queue'
require 'rabbit_watcher/host'
require 'rabbit_watcher/client'
require 'rabbit_watcher/trigger'

describe RabbitWatcher::Watcher do
  let(:uri) { 'http://rabbituri:15672' }
  let(:username) { 'testuser' }
  let(:password) { 'testpass' }
  let(:vhost) { 'vhost' }
  let(:queue_name) { '-suffix$' }
  let(:status_name) { 'name-suffix' }
  let(:message_threshold) { 100 }
  let(:consumer_threshold) { 0 }
  let(:trigger) { RabbitWatcher::Trigger.new }

  before :each do
    threshold_options = {
      messages: {
        count: message_threshold,
        time: 300
      },
      consumers: {
        count: consumer_threshold,
        time: 300
      }
    }
    @queue = configure_queue threshold_options
    @host = configure_host @queue
  end

  describe '.watch' do
    it 'watches queues for status changes' do
      status = client_status message_threshold, consumer_threshold
      status_opts = {
        uri: uri,
        username: username,
        password: password,
        vhost: vhost,
        queues: [queue_name],
        columns: %w(name messages_ready consumers)
      }
      expect(RabbitWatcher::Client)
        .to(receive(:status))
        .with(status_opts)
        .and_return status
      RabbitWatcher::Watcher.watch @host
    end

    it 'updates queue timestamps when within threshold limits' do
      stub_client message_threshold - 1, consumer_threshold + 1
      expect(@queue)
        .to(receive(:update_timestamp))
        .with status_name, :messages
      expect(@queue)
        .to(receive(:update_timestamp))
        .with status_name, :consumers
      RabbitWatcher::Watcher.watch @host
    end

    it 'does not update queue timestamps when outside threshold limits' do
      stub_client message_threshold, consumer_threshold
      expect(@queue).not_to receive :update_timestamp
      RabbitWatcher::Watcher.watch @host
    end

    it 'supports consumer less than operator condition' do
      less_than_threshold = 2
      threshold_options = {
        consumers: {
          time: 300,
          less_than_count: less_than_threshold
        }
      }
      queue = configure_queue threshold_options
      host = configure_host queue
      initial_timestamp = queue.timestamp status_name, :consumers
      stub_client message_threshold, less_than_threshold
      RabbitWatcher::Watcher.watch host
      updated_timestamp = queue.timestamp status_name, :consumers
      expect(updated_timestamp).to eq initial_timestamp
    end

    it 'calls queue triggers when outside time threshold' do
      expect(trigger)
        .to(receive(:trigger))
        .with trigger_args(:messages, message_threshold, :less_than)
      expect(trigger)
        .to(receive(:trigger))
        .with trigger_args(:consumers, consumer_threshold, :more_than)
      now = Time.now
      one_hour_ago = Time.now - 3600
      stub_now one_hour_ago
      stub_client message_threshold - 1, consumer_threshold + 1
      RabbitWatcher::Watcher.watch @host
      stub_now now
      stub_client message_threshold, consumer_threshold
      RabbitWatcher::Watcher.watch @host
    end

    it 'resets queue triggers when within threshold limits' do
      stub_client message_threshold - 1, consumer_threshold + 1
      expect(trigger)
        .to(receive(:reset))
        .with trigger_args(:messages, message_threshold - 1, :less_than)
      expect(trigger)
        .to(receive(:reset))
        .with trigger_args(:consumers, consumer_threshold + 1, :more_than)
      RabbitWatcher::Watcher.watch @host
    end

    it 'does nothing if queue status is missing' do
      status = []
      expect(RabbitWatcher::Client)
        .to(receive(:status))
        .and_return status
      expect(@queue).not_to receive :update_timestamp
      expect(trigger).not_to receive :trigger
      expect(trigger).not_to receive :reset
      RabbitWatcher::Watcher.watch @host
    end
  end

  def trigger_args(value, count, operator)
    {
      host: @host,
      queue: @queue,
      name: status_name,
      value: value,
      count: count,
      operator: operator
    }
  end

  def client_status(message_threshold, consumer_threshold)
    [
      {
        name: status_name,
        messages: message_threshold,
        consumers: consumer_threshold
      }
    ]
  end

  def stub_client(message_threshold, consumer_threshold)
    status = client_status message_threshold, consumer_threshold
    expect(RabbitWatcher::Client)
      .to(receive(:status))
      .and_return status
  end

  def stub_now(time)
    allow(Time)
      .to(receive(:now))
      .and_return time
  end

  def configure_queue(threshold_options)
      RabbitWatcher::Queue.new name: queue_name,
          threshold_options: threshold_options,
          triggers: [trigger]
  end

  def configure_host(queue)
      RabbitWatcher::Host.new uri: uri,
          username: username,
          password: password,
          vhost: vhost,
          queues: [queue]
  end
end
