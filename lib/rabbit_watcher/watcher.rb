require 'rabbit_watcher/client'

module RabbitWatcher
  module Watcher
    def self.watch(host)
      RabbitWatcher.logger.info { "Watching host #{host.uri}" }
      status = get_status host
      check_queues host, status
    end

    def self.check_queues(host, status)
      host.queues.each do |queue|
        [:messages, :consumers].each do |value|
          count = status[queue.name][value]
          queue_status = build_queue_status queue, host, value, count
          check_queue_value queue_status
        end
      end
    end
    private_class_method :check_queues

    def self.check_queue_value(status)
      queue = status[:queue]
      value = status[:value]
      count = status[:count]
      if count_ok? queue, value, count
        queue.update_timestamp value
        reset status
      elsif !timestamp_ok? queue, value, queue.timestamps[value]
        trigger status
      end
    end
    private_class_method :check_queue_value

    def self.count_ok?(queue, value, count)
      return true unless queue.threshold_options[value]
      threshold = queue.threshold_options[value][:count]
      case value
      when :messages
        count < threshold
      when :consumers
        count > threshold
      end
    end
    private_class_method :count_ok?

    def self.timestamp_ok?(queue, value, timestamp)
      time_threshold = queue.threshold_options[value][:time]
      Time.now - timestamp < time_threshold
    end
    private_class_method :timestamp_ok?

    def self.trigger(status)
      status[:queue].triggers.each { |t| t.trigger status }
    end
    private_class_method :trigger

    def self.reset(status)
      status[:queue].triggers.each { |t| t.reset status }
    end
    private_class_method :reset

    def self.build_queue_status(queue, host, value, count)
      {
        queue: queue,
        host: host,
        value: value,
        count: count
      }
    end
    private_class_method :build_queue_status

    def self.get_status(host)
      queue_names = host.queues.map(&:name)
      Client.status uri: host.uri,
                    username: host.username,
                    password: host.password,
                    vhost: host.vhost,
                    queues: queue_names
    end
    private_class_method :get_status
  end
end
