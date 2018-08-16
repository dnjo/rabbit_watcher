require 'rabbit_watcher/client'

module RabbitWatcher
  module Watcher
    def self.watch(host)
      RabbitWatcher.logger.info { "Watching host #{host}" }
      status = get_status host
      check_queues host, status
    end

    def self.check_queues(host, status)
      queues = find_matching_queues host.queues, status
      queues.each do |queue|
        handle_matching_statuses queue[:queue], queue[:matching_statuses]
        queue[:matching_statuses].each do |matching_status|
          check_values matching_status, host, queue[:queue]
        end
      end
    end
    private_class_method :check_queues

    def self.handle_matching_statuses(queue, statuses)
      if statuses.empty?
        RabbitWatcher.logger.warn { "Found no queues matching #{queue} in status response" }
      else
        names = statuses.map { |s| s[:name] }.join ', '
        RabbitWatcher.logger.info { "Checking queue status for #{names}" }
      end
    end
    private_class_method :handle_matching_statuses

    def self.check_values(status, host, queue)
      [:messages, :consumers].each do |value|
        count = status[value]
        name = status[:name]
        queue_status = build_queue_status queue,
                                          name,
                                          host,
                                          value,
                                          count
        check_queue_value queue_status
      end
    end
    private_class_method :check_values

    def self.check_queue_value(status)
      queue = status[:queue]
      value = status[:value]
      count = status[:count]
      name = status[:name]
      count_result = check_count queue, value, count
      status[:operator] = count_result[:operator]
      if count_result[:count_ok]
        queue.update_timestamp name, value
        reset status
      elsif !timestamp_ok? queue, name, value
        trigger status
      end
    end
    private_class_method :check_queue_value

    def self.check_count(queue, value, count)
      unless queue.threshold_options[value]
        return build_count_result true, value, :less_than
      end
      threshold = queue.threshold_options[value][:count]
      case value
      when :messages
        build_count_result count < threshold, value, :less_than
      when :consumers
        check_consumer_count queue, count
      end
    end
    private_class_method :check_count

    def self.check_consumer_count(queue, count)
      value = :consumers
      threshold = queue.threshold_options[value][:count]
      less_than_threshold = queue.threshold_options[value][:less_than_count]
      more_than_ok = count > threshold
      if less_than_threshold.nil? || !more_than_ok
        build_count_result more_than_ok, value, :more_than
      else
        build_count_result count < less_than_threshold, value, :less_than
      end
    end
    private_class_method :check_consumer_count

    def self.build_count_result(count_ok, value, operator)
      {
        count_ok: count_ok,
        operator: operator
      }
    end
    private_class_method :build_count_result

    def self.timestamp_ok?(queue, name, value)
      timestamp = queue.timestamp name, value
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

    def self.build_queue_status(queue, name, host, value, count)
      {
        queue: queue,
        name: name,
        host: host,
        value: value,
        count: count
      }
    end
    private_class_method :build_queue_status

    def self.find_matching_queues(queues, status)
      queues.map do |queue|
        matching_statuses = status.select do |queue_status|
          matches? queue.name, queue_status[:name]
        end
        {
          queue: queue,
          matching_statuses: matching_statuses
        }
      end
    end
    private_class_method :find_matching_queues

    def self.matches?(pattern, name)
      pattern = Regexp.new pattern
      pattern.match name
    end
    private_class_method :matches?

    def self.get_status(host)
      queue_names = host.queues.map(&:name)
      Client.status uri: host.uri,
                    username: host.username,
                    password: host.password,
                    vhost: host.vhost,
                    queues: queue_names,
                    columns: %w(name messages_ready consumers)
    end
    private_class_method :get_status
  end
end
