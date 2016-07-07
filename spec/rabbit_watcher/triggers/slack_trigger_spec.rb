require 'spec_helper'
require 'rabbit_watcher/triggers/slack_trigger'

describe RabbitWatcher::Triggers::SlackTrigger do
  let(:url) { 'http://testurl.com' }
  let(:threshold_options) do
    {
      messages: {
        count: 1,
        time: 300
      }
    }
  end
  let(:trigger) { RabbitWatcher::Triggers::SlackTrigger.new url }
  let(:queue) do
    RabbitWatcher::Queue.new name: 'queue1',
                             threshold_options: threshold_options,
                             triggers: [trigger]
  end
  let(:host) do
    RabbitWatcher::Host.new uri: 'http://testurl.com',
                            vhost: '%2F',
                            queues: [queue]
  end
  let(:trigger_args) do
    {
      queue: queue,
      host: host,
      value: :messages,
      count: 2
    }
  end

  describe '#handle_trigger' do
    it 'should send a JSON message to Slack' do
      mock_httparty
      trigger.handle_trigger trigger_args
    end
  end

  describe '#handle_reset' do
    it 'should send a JSON message to Slack' do
      mock_httparty
      trigger.handle_reset trigger_args
    end
  end

  def mock_httparty
    post_content = {
      headers: { 'Content-Type' => 'application/json' }
    }
    expect(HTTParty)
      .to(receive(:post))
      .with url, hash_including(post_content)
  end
end
