require 'httparty'

module RabbitWatcher
  module Client
    class InvalidResponse < StandardError; end

    def self.status(opts)
      queues = get_queues opts[:queues]
      queues.each_with_object({}) do |queue, status_hash|
        response = request_status queue, opts
        validate_response response
        queue_status = parse_status response.parsed_response
        status_hash[queue] = queue_status
      end
    end

    def self.request_status(queue, opts)
      path = build_path queue, opts
      credentials = build_credentials opts
      get_opts = {}
      get_opts[:headers] = { 'Accept' => 'application/json' }
      get_opts[:basic_auth] = credentials if credentials
      HTTParty.get path, get_opts
    end
    private_class_method :request_status

    def self.build_path(queue, opts)
      "#{opts[:uri]}/api/queues/#{opts[:vhost]}/#{queue}"
    end
    private_class_method :build_path

    def self.build_credentials(opts)
      return nil unless opts[:username]
      {
        username: opts[:username],
        password: opts[:password]
      }
    end
    private_class_method :build_credentials

    def self.validate_response(response)
      return if response.code == 200
      raise InvalidResponse, response
    end
    private_class_method :validate_response

    def self.parse_status(body)
      {
        message_count: body['messages_ready'],
        consumer_count: body['consumers']
      }
    end
    private_class_method :parse_status

    def self.get_queues(queues)
      return queues if queues.is_a? Array
      [queues]
    end
    private_class_method :get_queues
  end
end
