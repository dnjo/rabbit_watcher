$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'logger'
require 'rabbit_watcher'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

logger = Logger.new File::NULL
RabbitWatcher.configure logger: logger
