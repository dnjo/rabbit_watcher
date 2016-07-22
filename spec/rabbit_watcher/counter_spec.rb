require 'spec_helper'
require 'rabbit_watcher/counter'

describe RabbitWatcher::Counter do
  before :each do
    @counter = RabbitWatcher::Counter.new
  end

  describe '#increment' do
    it 'increments and returns the count' do
      count = @counter.increment
      expect(count).to eq 1
    end
  end
end
