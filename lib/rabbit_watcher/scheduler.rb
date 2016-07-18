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
          Watcher.watch host
        end
      end
      scheduler.join
    end
  end
end
