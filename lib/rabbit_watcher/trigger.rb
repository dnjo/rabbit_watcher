module RabbitWatcher
  class Trigger
    def trigger(queue, value, count)
      handle_trigger queue, value, count unless triggered? queue, value
      set_trigger_value queue, value, true
    end

    def reset(queue, value, count)
      handle_reset queue, value, count if triggered? queue, value
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
