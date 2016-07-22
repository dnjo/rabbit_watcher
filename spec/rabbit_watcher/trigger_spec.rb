require 'spec_helper'
require 'rabbit_watcher/trigger'

describe RabbitWatcher::Trigger do
  class InheritedTrigger < RabbitWatcher::Trigger
    def handle_trigger(status); end

    def handle_reset(status); end
  end

  before(:each) { @trigger = InheritedTrigger.new }
  let(:queue) { instance_double RabbitWatcher::Queue, name: 'queue' }

  describe '#trigger' do
    it 'calls handle_trigger if not previously triggered' do
      expect(@trigger)
        .to(receive(:handle_trigger))
        .with hash_including(trigger_args)
      @trigger.trigger trigger_args
    end

    it 'does not call handle_trigger if previusly triggered' do
      @trigger.trigger trigger_args
      expect(@trigger).not_to receive :handle_trigger
      @trigger.trigger trigger_args
    end

    it 'increments and appends a trigger ID to the status' do
      trigger_id = { trigger_id: 1 }
      counter = mock_trigger_counter
      expect(counter)
        .to(receive(:increment))
        .and_return 1
      expect(@trigger)
        .to(receive(:handle_trigger))
        .with hash_including(trigger_id)
      @trigger.trigger trigger_args
    end
  end

  describe '#reset' do
    it 'calls handle_reset if not previously reset' do
      @trigger.trigger trigger_args
      expect(@trigger)
        .to(receive(:handle_reset))
        .with hash_including(trigger_args)
      @trigger.reset trigger_args
    end

    it 'does not call handle_reset if previusly reset' do
      @trigger.trigger trigger_args
      @trigger.reset trigger_args
      expect(@trigger).not_to receive :handle_reset
      @trigger.reset trigger_args
    end

    it 'appends a trigger ID to the reset status' do
      trigger_id = { trigger_id: 1 }
      counter = mock_trigger_counter
      expect(counter)
        .to(receive(:increment))
        .and_return 1
      expect(@trigger)
        .to(receive(:handle_reset))
        .with hash_including(trigger_id)
      @trigger.trigger trigger_args
      @trigger.reset trigger_args
    end
  end

  def trigger_args
    {
      host: 'host',
      queue: queue,
      value: :value,
      count: 1
    }
  end

  def mock_trigger_counter
    counter = instance_double RabbitWatcher::Counter
    expect(RabbitWatcher)
      .to(receive(:trigger_counter))
      .and_return counter
    counter
  end
end
