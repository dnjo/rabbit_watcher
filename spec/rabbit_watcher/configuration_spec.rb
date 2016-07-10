require 'spec_helper'
require 'rabbit_watcher/configuration'

describe RabbitWatcher::Configuration do
  describe '.triggers' do
    it 'creates and returns triggers' do
      config = {
        'trigger_id' => {
          'type' => 'slack_trigger',
          'url' => 'trigger_url'
        }
      }
      expect(RabbitWatcher::Triggers::SlackTrigger)
        .to(receive(:new))
        .with(hash_including(url: 'trigger_url'))
        .and_return 'trigger'
      triggers = RabbitWatcher::Configuration.triggers config
      expect(triggers['trigger_id']).to eq 'trigger'
    end
  end

  describe '.thresholds' do
    it 'creates and returns threshold options' do
      config = {
        'threshold_id' => {
          'messages' => {
            'count' => 0
          },
          'consumers' => {
            'count' => 0
          }
        }
      }
      thresholds = RabbitWatcher::Configuration.thresholds config
      expect(thresholds['threshold_id'][:messages]).to eq count: 0
      expect(thresholds['threshold_id'][:consumers]).to eq count: 0
    end
  end

  describe '.queue_sets' do
    it 'creates and returns queues' do
      thresholds = { 'threshold_id' => 'queue_threshold' }
      triggers = { 'trigger_id' => 'queue_trigger' }
      queue_args = {
        name: 'queue_name',
        threshold_options: 'queue_threshold',
        triggers: ['queue_trigger']
      }
      config = {
        'queue_set_id' => {
          'thresholds' => 'threshold_id',
          'triggers' => ['trigger_id'],
          'queues' => ['queue_name']
        }
      }
      expect(RabbitWatcher::Queue)
        .to(receive(:new))
        .with(queue_args)
        .and_return 'queue'
      queues = RabbitWatcher::Configuration.queue_sets config,
                                                       triggers,
                                                       thresholds
      expect(queues['queue_set_id'][0]).to eq 'queue'
    end
  end

  describe '.hosts' do
    it 'creates and returns hosts' do
      queue_sets = { 'queue_set_id' => ['host_queue'] }
      config = [
        {
          'uri' => 'host_uri',
          'username' => 'host_username',
          'password' => 'host_password',
          'vhost' => 'host_vhost',
          'queue_sets' => ['queue_set_id']
        }
      ]
      host_args = {
        uri: 'host_uri',
        username: 'host_username',
        password: 'host_password',
        vhost: 'host_vhost',
        queues: ['host_queue']
      }
      expect(RabbitWatcher::Host)
        .to(receive(:new))
        .with(host_args)
        .and_return 'host'
      hosts = RabbitWatcher::Configuration.hosts config, queue_sets
      expect(hosts[0]).to eq 'host'
    end
  end
end
