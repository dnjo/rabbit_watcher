require 'spec_helper'

describe RabbitWatcher do
  it 'has a version number' do
    expect(RabbitWatcher::VERSION).not_to be nil
  end

  describe '.configure_hosts' do
    let(:config) do
      {
        'triggers' => 'triggers_config',
        'thresholds' => 'thresholds_config',
        'queue_sets' => 'queues_config',
        'hosts' => 'hosts_config'
      }
    end

    it 'parses host configuration file' do
      expect(RabbitWatcher::Configuration)
        .to(receive(:parse_config_file))
        .with('config/path.yml')
        .and_return config
      expect(RabbitWatcher::Configuration)
        .to(receive(:triggers))
        .with('triggers_config')
        .and_return 'triggers'
      expect(RabbitWatcher::Configuration)
        .to(receive(:thresholds))
        .with('thresholds_config')
        .and_return 'thresholds'
      expect(RabbitWatcher::Configuration)
        .to(receive(:queue_sets))
        .with('queues_config', 'triggers', 'thresholds')
        .and_return 'queues'
      expect(RabbitWatcher::Configuration)
        .to(receive(:hosts))
        .with('hosts_config', 'queues')
        .and_return 'hosts'
      hosts = RabbitWatcher.configure_hosts 'config/path.yml'
      expect(hosts).to eq 'hosts'
    end
  end
end
