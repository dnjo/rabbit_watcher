require 'rabbit_watcher/host'
require 'rabbit_watcher/queue'
require 'rabbit_watcher/triggers/slack_trigger'

module RabbitWatcher
  module Configuration
    class InvalidConfiguration < StandardError; end

    def self.parse_config_file(path)
      YAML.load(ERB.new(File.read(path)).result)
    end

    def self.triggers(config)
      config.map do |trigger_id, trigger_config|
        type = trigger_config['type']
        trigger_opts = parse_trigger_opts trigger_config
        trigger = init_trigger type.to_sym, trigger_opts
        [trigger_id, trigger]
      end.to_h
    end

    def self.thresholds(config)
      config.map do |threshold_id, threshold_config|
        threshold_opts = parse_threshold_opts threshold_config
        [threshold_id, threshold_opts]
      end.to_h
    end

    def self.queue_sets(config, triggers, thresholds)
      config.map do |queue_set_id, queue_set_config|
        queue_opts = parse_queue_opts queue_set_config, triggers, thresholds
        queues = queue_set_config['queues'].map do |queue_name|
          opts = queue_opts.merge name: queue_name
          RabbitWatcher::Queue.new opts
        end
        [queue_set_id, queues]
      end.to_h
    end

    def self.hosts(config, queue_sets)
      config.map do |host_config|
        opts = parse_host_opts host_config, queue_sets
        RabbitWatcher::Host.new opts
      end
    end

    def self.init_trigger(type, opts)
      case type
      when :slack_trigger
        RabbitWatcher::Triggers::SlackTrigger.new opts
      end
    end
    private_class_method :init_trigger

    def self.parse_trigger_opts(config)
      {
        url: config['url'],
        username: config['username'],
        icon_emoji: config['icon_emoji']
      }
    end
    private_class_method :parse_trigger_opts

    def self.parse_threshold_opts(config)
      {
        messages: symbolize_keys(config['messages']),
        consumers: symbolize_keys(config['consumers'])
      }
    end
    private_class_method :parse_threshold_opts

    def self.parse_queue_opts(config, triggers, thresholds)
      {
        threshold_options: find_threshold(config, thresholds),
        triggers: find_triggers(config, triggers)
      }
    end
    private_class_method :parse_queue_opts

    def self.parse_host_opts(config, queue_sets)
      {
        uri: config['uri'],
        username: config['username'],
        password: config['password'],
        vhost: config['vhost'],
        queues: find_queues(config, queue_sets)
      }
    end
    private_class_method :parse_host_opts

    def self.find_threshold(config, thresholds)
      id = config['thresholds']
      threshold = thresholds[id]
      object_not_found id unless threshold
      threshold
    end
    private_class_method :find_threshold

    def self.find_triggers(config, triggers)
      config['triggers'].map do |id|
        trigger = triggers[id]
        object_not_found id unless trigger
        trigger
      end
    end
    private_class_method :find_triggers

    def self.find_queues(config, queue_sets)
      config['queue_sets'].each_with_object([]) do |id, queues|
        queue_set = queue_sets[id]
        object_not_found id unless queue_set
        queues.concat queue_set
      end
    end
    private_class_method :find_queues

    def self.symbolize_keys(hash)
      return nil unless hash
      Hash[hash.map { |k, v| [k.to_sym, v] }]
    end
    private_class_method :symbolize_keys

    def self.object_not_found(id)
      raise InvalidConfiguration, "No object with ID #{id}"
    end
    private_class_method :object_not_found
  end
end
