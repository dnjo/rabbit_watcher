require 'httparty'
require 'rabbit_watcher/message_helper'
require 'rabbit_watcher/markdown_helper'

module RabbitWatcher
  module Triggers
    class SlackTrigger < Trigger
      def initialize(opts)
        @url = opts[:url]
        @username = opts[:username] || 'Rabbit Watcher'
        @icon_emoji = opts[:icon_emoji] || ':rabbit2:'
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
        queue = status[:queue]
        host = status[:host]
        title = MessageHelper.title trigger_type, status
        text = build_slack_text trigger_type, status
        build_slack_message title, text, trigger_type, host, queue
      end

      def build_slack_text(trigger_type, status)
        queue = status[:queue]
        count = status[:count]
        trigger_text = MessageHelper.text trigger_type, status
        prefixes = ['Queue:', 'Trigger:', 'Current count:']
        texts = [queue.name, trigger_text, count]
        MarkdownHelper.bold_prefixes prefixes, texts
      end

      def build_slack_message(title, text, trigger_type, host, queue)
        title_link = queue_url host, queue
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

      def queue_url(host, queue)
        uri = host.uri
        vhost = host.vhost
        "#{uri}/#/queues/#{vhost}/#{queue.name}"
      end
    end
  end
end
