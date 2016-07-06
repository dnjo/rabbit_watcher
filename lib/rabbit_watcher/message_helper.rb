module RabbitWatcher
  module MessageHelper
    def self.trigger_title(queue, value)
      case value
      when :messages
        "[#{queue.name}] Too many messages"
      when :consumers
        "[#{queue.name}] Not enough consumers"
      end
    end

    def self.trigger_text(queue, value, count)
      value_threshold = value_threshold value,
                                        queue.threshold_options[value][:count]
      time_threshold = queue.threshold_options[value][:time]
      time = format_time time_threshold
      case value
      when :messages
        "Message count > #{value_threshold} for #{time}. Current count: #{count}"
      when :consumers
        "Consumer count < #{value_threshold} for #{time}. Current count: #{count}"
      end
    end

    def self.reset_title(queue, value)
      case value
      when :messages
        "[#{queue.name}] Message count is below threshold"
      when :consumers
        "[#{queue.name}] Consumer count is above threshold"
      end
    end

    def self.reset_text(count)
      "Current count: #{count}"
    end

    def self.value_threshold(value, count)
      case value
      when :messages
        count - 1
      when :consumers
        count + 1
      end
    end

    def self.format_time(seconds)
      if seconds >= 60
        format_minutes seconds
      else
        format_seconds seconds
      end
    end

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

    def self.format_seconds(seconds)
      suffix = seconds == 1 ? 'second' : 'seconds'
      "#{seconds} #{suffix}"
    end
  end
end
