require 'httparty'
require 'rabbit_watcher/message_helper'

module RabbitWatcher
  module Triggers
    class SlackTrigger < Trigger
      def initialize(url)
        @url = url
      end

      def handle_trigger(status)
        queue = status[:queue]
        host = status[:host]
        value = status[:value]
        count = status[:count]
        title = MessageHelper.trigger_title queue, value
        text = MessageHelper.trigger_text queue, value, count
        message = build_message title, text, :trigger, host, queue
        post message
      end

      def handle_reset(status)
        queue = status[:queue]
        host = status[:host]
        value = status[:value]
        count = status[:count]
        title = MessageHelper.reset_title queue, value
        text = MessageHelper.reset_text count
        message = build_message title, text, :reset, host, queue
        post message
      end

      private

      def post(message)
        post_options = {
          body: message.to_json,
          headers: { 'Content-Type' => 'application/json' }
        }
        HTTParty.post @url, post_options
      end

      def build_message(title, text, message_type, host, queue)
        title_link = queue_url host, queue
        {
          attachments: [
            {
              fallback: title,
              color: message_colors[message_type],
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
