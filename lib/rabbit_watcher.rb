require 'logger'
require 'rabbit_watcher/version'
require 'rabbit_watcher/configuration'

module RabbitWatcher
  def self.configure_hosts(path)
    config = Configuration.parse_config_file path
    triggers = parse_triggers config
    thresholds = parse_thresholds config
    queues = parse_queue_sets config,
                              triggers,
                              thresholds
    parse_hosts config, queues
  end

  def self.configure(opts)
    @logger = opts[:logger]
  end

  def self.logger
    return @logger if @logger
    @logger = Logger.new STDOUT
    @logger.level = Logger::INFO
    @logger
  end

  def self.parse_triggers(config)
    Configuration.triggers config['triggers']
  end
  private_class_method :parse_triggers

  def self.parse_thresholds(config)
    Configuration.thresholds config['thresholds']
  end
  private_class_method :parse_thresholds

  def self.parse_queue_sets(config, triggers, thresholds)
    Configuration.queue_sets config['queue_sets'],
                             triggers,
                             thresholds
  end
  private_class_method :parse_queue_sets

  def self.parse_hosts(config, queues)
    Configuration.hosts config['hosts'], queues
  end
  private_class_method :parse_hosts
end
