require 'rufus-scheduler'
require 'rabbit_watcher'
require 'rabbit_watcher/watcher'

module RabbitWatcher
  module Scheduler
    def self.start(opts)
      RabbitWatcher.logger.info { "Starting scheduler with watch interval #{opts[:watch_interval]}" }
      scheduler = Rufus::Scheduler.new
      opts[:hosts].each do |host|
        scheduler.every opts[:watch_interval] do
          watch host
        end
      end
      scheduler.join
    end

    def self.watch(host)
      Watcher.watch host
    rescue => e
      RabbitWatcher.logger.error do
        backtrace = e.backtrace.join "\n\t"
        "An error occurred while watching host #{host}: #{e}" \
        "\n\t#{backtrace}"
      end
    end
    private_class_method :watch
  end
end
