module RabbitWatcher
  module MessageHelper
    def self.title(trigger_type, status)
      case trigger_type
      when :trigger
        trigger_title status
      when :reset
        reset_title status
      end
    end

    def self.text(trigger_type, status)
      case trigger_type
      when :trigger
        trigger_text status
      when :reset
        reset_text status
      end
    end

    def self.trigger_title(status)
      queue = status[:queue]
      value = status[:value]
      case value
      when :messages
        "[#{queue.name}] Too many messages"
      when :consumers
        "[#{queue.name}] Not enough consumers"
      end
    end
    private_class_method :trigger_title

    def self.trigger_text(status)
      queue = status[:queue]
      value = status[:value]
      count = status[:count]
      count_threshold = count_threshold value,
                                        queue.threshold_options[value][:count]
      time_threshold = queue.threshold_options[value][:time]
      time = format_time time_threshold
      case value
      when :messages
        "Message count > #{count_threshold} for #{time}. Current count: #{count}"
      when :consumers
        "Consumer count < #{count_threshold} for #{time}. Current count: #{count}"
      end
    end
    private_class_method :trigger_text

    def self.reset_title(status)
      queue = status[:queue]
      value = status[:value]
      case value
      when :messages
        "[#{queue.name}] Message count is below threshold"
      when :consumers
        "[#{queue.name}] Consumer count is above threshold"
      end
    end
    private_class_method :reset_title

    def self.reset_text(status)
      count = status[:count]
      "Current count: #{count}"
    end
    private_class_method :reset_text

    def self.count_threshold(value, count)
      case value
      when :messages
        count - 1
      when :consumers
        count + 1
      end
    end
    private_class_method :count_threshold

    def self.format_time(seconds)
      if seconds >= 60
        format_minutes seconds
      else
        format_seconds seconds
      end
    end
    private_class_method :format_time

    def self.format_minutes(seconds)
      minutes = seconds / 60
      seconds = seconds % 60
      minute_suffix = minutes == 1 ? 'minute' : 'minutes'
      if seconds > 0
        second_format = format_seconds seconds
        "#{minutes} #{minute_suffix} and #{second_format}"
      else
        "#{minutes} #{minute_suffix}"
      end
    end
    private_class_method :format_minutes

    def self.format_seconds(seconds)
      suffix = seconds == 1 ? 'second' : 'seconds'
      "#{seconds} #{suffix}"
    end
    private_class_method :format_seconds
  end
end
