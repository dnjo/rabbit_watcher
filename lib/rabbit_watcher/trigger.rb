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
      queue = status[:queue]
      value = status[:value]
      triggered = triggered? queue, value
      call_actions status, action, triggered
      set_trigger_value queue, value, action
    end

    def call_actions(status, action, triggered)
      case action
      when :trigger
        call_trigger status unless triggered
      when :reset
        call_reset status if triggered
      end
    end

    def call_trigger(status)
      RabbitWatcher.logger.info { "Triggering queue #{status[:queue].name}" }
      RabbitWatcher.logger.debug { "Status: #{status}" }
      trigger_id = set_value_trigger_id status[:queue], status[:value]
      status[:trigger_id] = trigger_id
      handle_trigger status
    end

    def call_reset(status)
      RabbitWatcher.logger.info { "Resetting queue #{status[:queue].name}" }
      RabbitWatcher.logger.debug { "Status: #{status}" }
      status[:trigger_id] = value_trigger_id status[:queue], status[:value]
      handle_reset status
    end

    def set_trigger_value(queue, value, action)
      value_hash = get_value_hash queue, value
      case action
      when :trigger
        value_hash[:triggered] = true
      when :reset
        value_hash[:triggered] = false
      end
    end

    def value_trigger_id(queue, value)
      value_hash = get_value_hash queue, value
      value_hash[:trigger_id]
    end

    def set_value_trigger_id(queue, value)
      trigger_id = RabbitWatcher.trigger_counter.increment
      value_hash = get_value_hash queue, value
      value_hash[:trigger_id] = trigger_id
    end

    def triggered?(queue, value)
      value_hash = get_value_hash queue, value
      value_hash[:triggered]
    end

    def get_value_hash(queue, value)
      values = values queue
      values[value] ||= {}
    end

    def values(queue)
      @queues[queue] ||= {}
    end
  end
end
