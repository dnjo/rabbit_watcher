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

  describe '#handle_trigger' do
    it 'should send a JSON message to Slack' do
      mock_httparty
      trigger.handle_trigger queue, :messages, 2
    end
  end

  describe '#handle_reset' do
    it 'should send a JSON message to Slack' do
      mock_httparty
      trigger.handle_reset queue, :messages, 1
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
