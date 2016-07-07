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
  let(:queue_name) { 'queue1' }
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
    @queue = RabbitWatcher::Queue.new name: queue_name,
                                      threshold_options: threshold_options,
                                      triggers: [trigger]
    @host = RabbitWatcher::Host.new uri: uri,
                                    username: username,
                                    password: password,
                                    vhost: vhost,
                                    queues: [@queue]
  end

  describe '.watch' do
    it 'watches queues for status changes' do
      status = client_status message_threshold, consumer_threshold
      status_opts = {
        uri: uri,
        username: username,
        password: password,
        vhost: vhost,
        queues: [queue_name]
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
        .with :messages
      expect(@queue)
        .to(receive(:update_timestamp))
        .with :consumers
      RabbitWatcher::Watcher.watch @host
    end

    it 'does not update queue timestamps when outside threshold limits' do
      stub_client message_threshold, consumer_threshold
      expect(@queue).not_to receive :update_timestamp
      RabbitWatcher::Watcher.watch @host
    end

    it 'calls queue triggers when outside time threshold' do
      expect(trigger)
        .to(receive(:trigger))
        .with trigger_args(:messages, message_threshold)
      expect(trigger)
        .to(receive(:trigger))
        .with trigger_args(:consumers, consumer_threshold)
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
        .with trigger_args(:messages, message_threshold - 1)
      expect(trigger)
        .to(receive(:reset))
        .with trigger_args(:consumers, consumer_threshold + 1)
      RabbitWatcher::Watcher.watch @host
    end
  end

  def trigger_args(value, count)
    {
      host: @host,
      queue: @queue,
      value: value,
      count: count
    }
  end

  def client_status(message_threshold, consumer_threshold)
    {
      queue_name => {
        messages: message_threshold,
        consumers: consumer_threshold
      }
    }
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
end
