require 'httparty'
require 'rabbit_watcher/message_helper'

module RabbitWatcher
  module Triggers
    class SlackTrigger < Trigger
      def initialize(url)
        @url = url
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
        text = MessageHelper.text trigger_type, status
        build_slack_message title, text, trigger_type, host, queue
      end

      def build_slack_message(title, text, trigger_type, host, queue)
        title_link = queue_url host, queue
        {
          attachments: [
            {
              fallback: title,
              color: message_colors[trigger_type],
              title: title,
              title_link: title_link,
              text: text
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
