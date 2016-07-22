require 'httparty'

module RabbitWatcher
  module Client
    def self.status(opts)
      queue_status opts
    end

    def self.queue_status(opts)
      response = request_status opts
      return {} unless response
      parse_status response.parsed_response
    end
    private_class_method :queue_status

    def self.request_status(opts)
      url = build_url opts
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

    def self.build_url(opts)
      "#{opts[:uri]}/api/queues/#{opts[:vhost]}"
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
      body.each_with_object({}) do |queue_status, status|
        name = queue_status['name']
        status[name] = {
          messages: queue_status['messages_ready'],
          consumers: queue_status['consumers']
        }
      end
    end
    private_class_method :parse_status
  end
end
