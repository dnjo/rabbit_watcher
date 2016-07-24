module RabbitWatcher
  class Queue
    attr_reader :name,
                :threshold_options,
                :triggers

    def initialize(opts)
      @name = opts[:name]
      @threshold_options = opts[:threshold_options]
      @triggers = opts[:triggers]
      @timestamps = {}
    end

    def update_timestamp(name, value)
      key = timestamp_key name, value
      @timestamps[key] = Time.now
    end

    def timestamp(name, value)
      key = timestamp_key name, value
      @timestamps[key] ||= Time.now
    end

    def to_s
      @name
    end

    private

    def timestamp_key(name, value)
      {
        name: name,
        value: value
      }
    end
  end
end
