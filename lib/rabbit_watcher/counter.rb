require 'thread'

module RabbitWatcher
  class Counter
    def initialize
      @count = 0
      @semaphore = Mutex.new
    end

    def increment
      @semaphore.synchronize { @count += 1 }
    end
  end
end
