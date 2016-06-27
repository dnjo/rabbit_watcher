require 'spec_helper'
require 'webmock/rspec'
require 'rabbit_watcher/client'

describe RabbitWatcher::Client do
  let(:uri) { 'http://rabbituri:15672' }
  let(:vhost) { 'vhost' }
  let(:queue) { 'queue' }
  let(:username) { 'testuser' }
  let(:password) { 'testpass' }
  let(:client) { init_client }

  describe '#status' do
    it 'returns the queue status' do
      body = {
        'messages_ready' => 100,
        'consumers' => 4
      }.to_json
      stub_rabbit_request 200, body
      status = client.status queue
      expect(status[:message_count]).to eq 100
      expect(status[:consumer_count]).to eq 4
    end

    it 'throws an error on invalid response' do
      stub_rabbit_request 404, nil
      expect { client.status queue }
        .to raise_error RabbitWatcher::Client::InvalidResponse
    end
  end

  def init_client
    RabbitWatcher::Client.new uri: uri,
                              vhost: vhost,
                              username: username,
                              password: password
  end

  def stub_rabbit_request(status, body)
    request_headers = {
      'Accept' => 'application/json',
      'Authorization' => 'Basic dGVzdHVzZXI6dGVzdHBhc3M='
    }
    stub_request(:get, "#{uri}/api/queues/#{vhost}/#{queue}")
      .with(headers: request_headers)
      .to_return status: status,
                 body: body,
                 headers: { 'Content-Type' => 'application/json' }
  end
end
