require 'httparty'

module RabbitWatcher
  class Client
    class InvalidResponse < StandardError; end

    def initialize(opts)
      @uri = opts[:uri] || 'http://localhost:15672'
      @username = opts[:username] || 'guest'
      @password = opts[:password] || 'guest'
      @vhost = opts[:vhost]
    end

    def status(queues)
      queues = [queues] unless queues.is_a? Array
      queues.each_with_object({}) do |queue, status_hash|
        response = get queue
        validate_response response
        queue_status = parse_status response.parsed_response
        status_hash[queue] = queue_status
      end
    end

    private

    def get(path)
      HTTParty.get "#{@uri}/api/queues/#{@vhost}/#{path}",
                   basic_auth: auth_hash,
                   headers: { 'Accept' => 'application/json' }
    end

    def auth_hash
      {
        username: @username,
        password: @password
      }
    end

    def validate_response(response)
      return if response.code == 200
      raise InvalidResponse, response
    end

    def parse_status(body)
      {
        message_count: body['messages_ready'],
        consumer_count: body['consumers']
      }
    end
  end
end
