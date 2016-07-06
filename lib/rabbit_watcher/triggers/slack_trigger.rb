require 'httparty'
require 'rabbit_watcher/message_helper'

module RabbitWatcher
  module Triggers
    class SlackTrigger < Trigger
      def initialize(url)
        @url = url
      end

      def handle_trigger(queue, value, count)
        title = MessageHelper.trigger_title queue, value
        text = MessageHelper.trigger_text queue, value, count
        message = build_message title, text, :trigger
        post message
      end

      def handle_reset(queue, value, count)
        title = MessageHelper.reset_title queue, value
        text = MessageHelper.reset_text count
        message = build_message title, text, :reset
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

      def build_message(title, text, message_type)
        {
          attachments: [
            {
              fallback: title,
              color: message_colors[message_type],
              title: title,
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
    end
  end
end
