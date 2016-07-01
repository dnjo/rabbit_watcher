module RabbitWatcher
  class Queue
    attr_reader :name,
                :threshold_options,
                :triggers,
                :timestamps

    def initialize(opts)
      @name = opts[:name]
      @threshold_options = opts[:threshold_options]
      @triggers = opts[:triggers]
      @timestamps = init_timestamps
    end

    def update_timestamp(value)
      timestamps[value] = Time.now
    end

    private

    def init_timestamps
      {
        messages: Time.now,
        consumers: Time.now
      }
    end
  end
end
