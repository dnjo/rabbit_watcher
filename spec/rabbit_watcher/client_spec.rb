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
      queue1 = {
        'name' => queues[0],
        'messages_ready' => 100,
        'consumers' => 4
      }
      queue2 = {
        'name' => queues[1],
        'messages_ready' => 50,
        'consumers' => 1
      }
      body = [queue1, queue2].to_json
      stub_rabbit_request 200, body
      status = request_status
      expect(status[0][:name]).to eq queues[0]
      expect(status[0][:messages]).to eq 100
      expect(status[0][:consumers]).to eq 4
      expect(status[1][:name]).to eq queues[1]
      expect(status[1][:messages]).to eq 50
      expect(status[1][:consumers]).to eq 1
    end

    it 'returns empty array on invalid response' do
      stub_rabbit_request 404, { error: 'error message' }.to_json
      status = request_status
      expect(status).to eq []
    end
  end

  def stub_rabbit_request(status, body)
    request_headers = {
      'Accept' => 'application/json',
      'Authorization' => 'Basic dGVzdHVzZXI6dGVzdHBhc3M='
    }
    stub_request(:get, %r{#{uri}/api/queues/#{vhost}})
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
