module RabbitWatcher
  module MessageHelper
    def self.title(_trigger_type, status)
      host = status[:host]
      queue_name = status[:name]
      "#{host.uri} (#{queue_name})"
    end

    def self.text(trigger_type, status)
      case trigger_type
      when :trigger
        trigger_text status
      when :reset
        reset_text status
      end
    end

    def self.trigger_text(status)
      queue = status[:queue]
      value = status[:value]
      count_threshold = count_threshold value,
                                        queue.threshold_options[value][:count]
      time_threshold = queue.threshold_options[value][:time]
      time_text = format_time_text time_threshold
      value_text = format_value_text value, count_threshold
      [value_text, time_text].reject(&:empty?).join ' '
    end
    private_class_method :trigger_text

    def self.reset_text(status)
      value = status[:value]
      case value
      when :messages
        'Message count is below threshold'
      when :consumers
        'Consumer count is above threshold'
      end
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

    def self.format_time_text(time_threshold)
      return '' unless time_threshold > 0
      time = format_time time_threshold
      "for #{time}"
    end
    private_class_method :format_time_text

    def self.format_value_text(value, count_threshold)
      case value
      when :messages
        "Message count > #{count_threshold}"
      when :consumers
        "Consumer count < #{count_threshold}"
      end
    end
    private_class_method :format_value_text

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
