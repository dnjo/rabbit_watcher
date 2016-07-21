module RabbitWatcher
  class Trigger
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
      handle_trigger status
    end

    def call_reset(status)
      RabbitWatcher.logger.info { "Resetting queue #{status[:queue].name}" }
      RabbitWatcher.logger.debug { "Status: #{status}" }
      handle_reset status
    end

    def set_trigger_value(queue, value, action)
      values = values queue
      case action
      when :trigger
        values[value] = true
      when :reset
        values[value] = false
      end
    end

    def triggered?(queue, value)
      values = values queue
      values[value]
    end

    def values(queue)
      queues[queue] ||= {}
    end

    def queues
      @queues ||= {}
    end
  end
end
