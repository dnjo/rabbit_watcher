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
      config.each_with_object([]) do |trigger_config, triggers|
        id = trigger_config['id']
        type = trigger_config['type']
        trigger_opts = parse_trigger_opts trigger_config
        trigger = init_trigger type.to_sym, trigger_opts
        triggers.push id: id, trigger: trigger
      end
    end

    def self.thresholds(config)
      config.each_with_object([]) do |threshold_config, thresholds|
        id = threshold_config['id']
        threshold_opts = parse_threshold_opts threshold_config
        thresholds.push id: id, threshold: threshold_opts
      end
    end

    def self.queues(config, triggers, thresholds)
      config.each_with_object([]) do |queue_config, queue_sets|
        queue_opts = parse_queue_opts queue_config, triggers, thresholds
        queues = []
        queue_config['queues'].each do |queue_name|
          opts = queue_opts.merge name: queue_name
          queue = RabbitWatcher::Queue.new opts
          queues.push queue
        end
        queue_sets.push id: queue_config['id'], queues: queues
      end
    end

    def self.hosts(config, queue_sets)
      config.each_with_object([]) do |host_config, hosts|
        opts = parse_host_opts host_config, queue_sets
        host = RabbitWatcher::Host.new opts
        hosts.push host
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
        threshold_options: find_thresholds(config, thresholds),
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

    def self.find_thresholds(config, thresholds)
      id = config['threshold_options']
      threshold = find_object id, thresholds
      object_not_found id unless threshold
      threshold[:threshold]
    end
    private_class_method :find_thresholds

    def self.find_triggers(config, triggers)
      config['triggers'].map do |id|
        trigger = find_object id, triggers
        object_not_found id unless trigger
        trigger[:trigger]
      end
    end
    private_class_method :find_triggers

    def self.find_queues(config, queue_sets)
      config['queue_sets'].each_with_object([]) do |id, queues|
        queue_set = find_object id, queue_sets
        object_not_found id unless queue_set
        queues.concat queue_set[:queues]
      end
    end
    private_class_method :find_queues

    def self.find_object(id, objects)
      objects.find { |object| object[:id] == id }
    end
    private_class_method :find_object

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
