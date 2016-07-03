require 'spec_helper'
require 'rabbit_watcher/trigger'

describe RabbitWatcher::Trigger do
  class InheritedTrigger < RabbitWatcher::Trigger
    def handle_trigger(queue, value, count); end

    def handle_reset(queue, value, count); end
  end

  before(:each) { @trigger = InheritedTrigger.new }

  describe '#trigger' do
    it 'calls handle_trigger if not previously triggered' do
      queue = 'queue'
      value = :value
      count = 1
      expect(@trigger)
        .to(receive(:handle_trigger))
        .with queue, value, count
      @trigger.trigger queue, value, count
    end

    it 'does not call handle_trigger if previusly triggered' do
      @trigger.trigger 'queue', :value, 1
      expect(@trigger).not_to receive :handle_trigger
      @trigger.trigger 'queue', :value, 1
    end
  end

  describe '#reset' do
    it 'calls handle_reset if not previously reset' do
      queue = 'queue'
      value = :value
      count = 1
      @trigger.trigger queue, value, count
      expect(@trigger)
        .to(receive(:handle_reset))
        .with queue, value, count
      @trigger.reset queue, value, count
    end

    it 'does not call handle_reset if previusly reset' do
      @trigger.trigger 'queue', :value, 1
      @trigger.reset 'queue', :value, 1
      expect(@trigger).not_to receive :handle_reset
      @trigger.reset 'queue', :value, 1
    end
  end
end
