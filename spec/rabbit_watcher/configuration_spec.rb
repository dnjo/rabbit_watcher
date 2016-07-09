require 'spec_helper'
require 'rabbit_watcher/configuration'

describe RabbitWatcher::Configuration do
  describe '.triggers' do
    it 'creates and returns triggers' do
      config = [
        {
          'id' => 'trigger_id',
          'type' => 'slack_trigger',
          'url' => 'trigger_url'
        }
      ]
      expect(RabbitWatcher::Triggers::SlackTrigger)
        .to(receive(:new))
        .with(hash_including(url: 'trigger_url'))
        .and_return 'trigger'
      triggers = RabbitWatcher::Configuration.triggers config
      expect(triggers[0][:id]).to eq 'trigger_id'
      expect(triggers[0][:trigger]).to eq 'trigger'
    end
  end

  describe '.thresholds' do
    it 'creates and returns threshold options' do
      config = [
        {
          'id' => 'options_id',
          'messages' => {
            'count' => 0
          },
          'consumers' => {
            'count' => 0
          }
        }
      ]
      thresholds = RabbitWatcher::Configuration.thresholds config
      expect(thresholds[0][:id]).to eq 'options_id'
      expect(thresholds[0][:threshold][:messages]).to eq count: 0
      expect(thresholds[0][:threshold][:consumers]).to eq count: 0
    end
  end

  describe '.queues' do
    it 'creates and returns queues' do
      thresholds = [{ id: 'threshold_id', threshold: 'queue_threshold' }]
      triggers = [{ id: 'trigger_id', trigger: 'queue_trigger' }]
      queue_args = {
        name: 'queue_name',
        threshold_options: 'queue_threshold',
        triggers: ['queue_trigger']
      }
      config = [
        {
          'id' => 'queue_set_id',
          'threshold_options' => 'threshold_id',
          'triggers' => ['trigger_id'],
          'queues' => ['queue_name']
        }
      ]
      expect(RabbitWatcher::Queue)
        .to(receive(:new))
        .with(queue_args)
        .and_return 'queue'
      queues = RabbitWatcher::Configuration.queues config, triggers, thresholds
      expect(queues[0][:id]).to eq 'queue_set_id'
      expect(queues[0][:queues][0]).to eq 'queue'
    end
  end

  describe '.hosts' do
    it 'creates and returns hosts' do
      queue_sets = [{ id: 'queue_set_id', queues: ['host_queue'] }]
      config = [
        {
          'id' => 'host_id',
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
