require 'spec_helper'
require 'webmock/rspec'
require 'rabbit_watcher/client'

describe RabbitWatcher::Client do
  let(:uri) { 'http://rabbituri:15672' }
  let(:vhost) { 'vhost' }
  let(:queues) { %w(queue1 queue2) }
  let(:username) { 'testuser' }
  let(:password) { 'testpass' }
  let(:client) { init_client }

  describe '#status' do
    it 'returns the status of queues' do
      body = {
        'messages_ready' => 100,
        'consumers' => 4
      }.to_json
      stub_rabbit_request 200, body
      status = client.status queues
      expect(status['queue1'][:message_count]).to eq 100
      expect(status['queue1'][:consumer_count]).to eq 4
      expect(status['queue2'][:message_count]).to eq 100
      expect(status['queue2'][:consumer_count]).to eq 4
    end

    it 'throws an error on invalid response' do
      stub_rabbit_request 404, nil
      expect { client.status queues }
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
    stub_request(:get, %r{#{uri}/api/queues/#{vhost}/queue})
      .with(headers: request_headers)
      .to_return status: status,
                 body: body,
                 headers: { 'Content-Type' => 'application/json' }
  end
end
