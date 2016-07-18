require 'httparty'

module RabbitWatcher
  module Client
    def self.status(opts)
      queues = get_queues opts[:queues]
      queues.each_with_object({}) do |queue, status_hash|
        status = queue_status queue, opts
        status_hash[queue] = status
      end
    end

    def self.queue_status(queue, opts)
      response = request_status queue, opts
      parse_status response.parsed_response if response
    end
    private_class_method :queue_status

    def self.request_status(queue, opts)
      url = build_url queue, opts
      credentials = build_credentials opts
      get_opts = {
        headers: { 'Accept' => 'application/json' }
      }
      get_opts[:basic_auth] = credentials if credentials
      get url, get_opts
    end
    private_class_method :request_status

    def self.get(url, opts)
      RabbitWatcher.logger.debug { "Requesting queue status at URL #{url}" }
      response = HTTParty.get url, opts
      RabbitWatcher.logger.debug { "Queue status response: #{response.parsed_response}"}
      return response if response.code == 200
      RabbitWatcher.logger.error { "Got code #{response.code} while requesting URL #{url}: #{response.parsed_response}" }
      false
    end
    private_class_method :get

    def self.build_url(queue, opts)
      "#{opts[:uri]}/api/queues/#{opts[:vhost]}/#{queue}"
    end
    private_class_method :build_url

    def self.build_credentials(opts)
      return nil unless opts[:username]
      {
        username: opts[:username],
        password: opts[:password]
      }
    end
    private_class_method :build_credentials

    def self.parse_status(body)
      {
        messages: body['messages_ready'],
        consumers: body['consumers']
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
