require 'spec_helper'
require 'webmock/rspec'
require 'rabbit_watcher/client'

describe RabbitWatcher::Client do
  let(:uri) { 'http://rabbituri:15672' }
  let(:username) { 'testuser' }
  let(:password) { 'testpass' }
  let(:vhost) { 'vhost' }
  let(:queues) { %w(queue1 queue2) }

  describe '.status' do
    it 'returns the status of queues' do
      body = {
        'messages_ready' => 100,
        'consumers' => 4
      }.to_json
      stub_rabbit_request 200, body
      status = request_status
      expect(status['queue1'][:message_count]).to eq 100
      expect(status['queue1'][:consumer_count]).to eq 4
      expect(status['queue2'][:message_count]).to eq 100
      expect(status['queue2'][:consumer_count]).to eq 4
    end

    it 'throws an error on invalid response' do
      stub_rabbit_request 404, nil
      expect { request_status }
        .to raise_error RabbitWatcher::Client::InvalidResponse
    end
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

  def request_status
    RabbitWatcher::Client.status uri: uri,
                                 username: username,
                                 password: password,
                                 vhost: vhost,
                                 queues: queues
  end
end
