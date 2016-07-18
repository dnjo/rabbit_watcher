require 'spec_helper'
require 'rabbit_watcher/trigger'

describe RabbitWatcher::Trigger do
  class InheritedTrigger < RabbitWatcher::Trigger
    def handle_trigger(status); end

    def handle_reset(status); end
  end

  before(:each) { @trigger = InheritedTrigger.new }

  let(:queue) { instance_double RabbitWatcher::Queue, name: 'queue' }
  let(:trigger_args) do
    {
      host: 'host',
      queue: queue,
      value: :value,
      count: 1
    }
  end

  describe '#trigger' do
    it 'calls handle_trigger if not previously triggered' do
      expect(@trigger)
        .to(receive(:handle_trigger))
        .with trigger_args
      @trigger.trigger trigger_args
    end

    it 'does not call handle_trigger if previusly triggered' do
      @trigger.trigger trigger_args
      expect(@trigger).not_to receive :handle_trigger
      @trigger.trigger trigger_args
    end
  end

  describe '#reset' do
    it 'calls handle_reset if not previously reset' do
      @trigger.trigger trigger_args
      expect(@trigger)
        .to(receive(:handle_reset))
        .with trigger_args
      @trigger.reset trigger_args
    end

    it 'does not call handle_reset if previusly reset' do
      @trigger.trigger trigger_args
      @trigger.reset trigger_args
      expect(@trigger).not_to receive :handle_reset
      @trigger.reset trigger_args
    end
  end
end
