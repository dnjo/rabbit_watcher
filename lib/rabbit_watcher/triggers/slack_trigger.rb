require 'httparty'
require 'rabbit_watcher/trigger'
require 'rabbit_watcher/message_helper'
require 'rabbit_watcher/markdown_helper'

module RabbitWatcher
  module Triggers
    class SlackTrigger < Trigger
      def initialize(opts)
        @url = opts[:url]
        @username = opts[:username] || 'Rabbit Watcher'
        @icon_emoji = opts[:icon_emoji] || ':rabbit2:'
        super()
      end

      def handle_trigger(status)
        build_and_post :trigger, status
      end

      def handle_reset(status)
        build_and_post :reset, status
      end

      private

      def build_and_post(trigger_type, status)
        message = build_post_message trigger_type, status
        post message
      end

      def post(message)
        post_options = {
          body: message.to_json,
          headers: { 'Content-Type' => 'application/json' }
        }
        HTTParty.post @url, post_options
      end

      def build_post_message(trigger_type, status)
        queue_name = status[:name]
        host = status[:host]
        title = MessageHelper.title trigger_type, status
        text = build_slack_text trigger_type, status
        build_slack_message title, text, trigger_type, host, queue_name
      end

      def build_slack_text(trigger_type, status)
        queue_name = status[:name]
        count = status[:count]
        trigger_id = status[:trigger_id]
        trigger_text = MessageHelper.text trigger_type, status
        prefixes = %w(Queue: Trigger: Trigger\ ID: Count:)
        texts = [queue_name, trigger_text, trigger_id, count]
        MarkdownHelper.bold_prefixes prefixes, texts
      end

      def build_slack_message(title, text, trigger_type, host, queue_name)
        title_link = queue_url host, queue_name
        {
          username: @username,
          icon_emoji: @icon_emoji,
          attachments: [
            {
              fallback: title,
              color: message_colors[trigger_type],
              title: title,
              title_link: title_link,
              text: text,
              mrkdwn_in: ['text']
            }
          ]
        }
      end

      def message_colors
        {
          trigger: '#ce0814',
          reset: '#36a64f'
        }
      end

      def queue_url(host, queue_name)
        uri = host.uri
        vhost = host.vhost
        "#{uri}/#/queues/#{vhost}/#{queue_name}"
      end
    end
  end
end
