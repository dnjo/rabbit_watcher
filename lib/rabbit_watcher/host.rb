module RabbitWatcher
  class Host
    attr_reader :uri,
                :username,
                :password,
                :vhost,
                :queues

    def initialize(opts)
      @uri = opts[:uri] || 'http://localhost:15672'
      @username = opts[:username] || 'guest'
      @password = opts[:password] || 'guest'
      @vhost = opts[:vhost]
      @queues = opts[:queues]
    end
  end
end
