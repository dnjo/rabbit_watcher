module RabbitWatcher
  class Trigger
    def initialize
      @queues = {}
    end

    def trigger(status)
      handle_action status, :trigger
    end

    def reset(status)
      handle_action status, :reset
    end

    private

    def handle_action(status, action)
      queue_key = build_queue_key status
      value = status[:value]
      triggered = triggered? queue_key, value
      call_actions queue_key, status, action, triggered
      set_trigger_value queue_key, value, action
    end

    def call_actions(queue_key, status, action, triggered)
      case action
      when :trigger
        call_trigger queue_key, status unless triggered
      when :reset
        call_reset queue_key, status if triggered
      end
    end

    def call_trigger(queue_key, status)
      RabbitWatcher.logger.info { "Triggering queue #{status[:name]}" }
      RabbitWatcher.logger.debug { "Status: #{status}" }
      trigger_id = set_value_trigger_id queue_key, status[:value]
      status[:trigger_id] = trigger_id
      handle_trigger status
    end

    def call_reset(queue_key, status)
      RabbitWatcher.logger.info { "Resetting queue #{status[:name]}" }
      RabbitWatcher.logger.debug { "Status: #{status}" }
      status[:trigger_id] = value_trigger_id queue_key, status[:value]
      handle_reset status
    end

    def set_trigger_value(queue_key, value, action)
      value_hash = get_value_hash queue_key, value
      case action
      when :trigger
        value_hash[:triggered] = true
      when :reset
        value_hash[:triggered] = false
      end
    end

    def value_trigger_id(queue_key, value)
      value_hash = get_value_hash queue_key, value
      value_hash[:trigger_id]
    end

    def set_value_trigger_id(queue_key, value)
      trigger_id = RabbitWatcher.trigger_counter.increment
      value_hash = get_value_hash queue_key, value
      value_hash[:trigger_id] = trigger_id
    end

    def triggered?(queue_key, value)
      value_hash = get_value_hash queue_key, value
      value_hash[:triggered]
    end

    def get_value_hash(queue_key, value)
      values = values queue_key
      values[value] ||= {}
    end

    def values(queue_key)
      @queues[queue_key] ||= {}
    end

    def build_queue_key(status)
      {
        host: status[:host],
        queue: status[:queue],
        name: status[:name]
      }
    end
  end
end
