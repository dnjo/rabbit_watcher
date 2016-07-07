module RabbitWatcher
  class Trigger
    def trigger(status)
      queue = status[:queue]
      value = status[:value]
      handle_trigger status unless triggered? queue, value
      set_trigger_value queue, value, true
    end

    def reset(status)
      queue = status[:queue]
      value = status[:value]
      handle_reset status if triggered? queue, value
      set_trigger_value queue, value, false
    end

    private

    def set_trigger_value(queue, value, triggered)
      values = values queue
      values[value] = triggered
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
