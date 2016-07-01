require 'rabbit_watcher/client'

module RabbitWatcher
  module Watcher
    def self.watch(host)
      status = get_status host
      check_queues host.queues, status
    end

    def self.check_queues(queues, status)
      queues.each do |queue|
        [:messages, :consumers].each do |value|
          count = status[queue.name][value]
          check_queue_value queue, value, count
        end
      end
    end
    private_class_method :check_queues

    def self.check_queue_value(queue, value, count)
      if count_ok? queue, value, count
        queue.update_timestamp value
        reset queue, value, count
      elsif !timestamp_ok? queue, value, queue.timestamps[value]
        trigger queue, value, count
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

    def self.trigger(queue, value, count)
      queue.triggers.each { |t| t.trigger queue, value, count }
    end
    private_class_method :trigger

    def self.reset(queue, value, count)
      queue.triggers.each { |t| t.reset queue, value, count }
    end
    private_class_method :reset

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
