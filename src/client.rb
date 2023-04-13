# frozen_string_literal: true

class Client
  MODEL = 'gpt-3.5-turbo'
  MESSAGE_LENGTH = 20

  def initialize
    OpenAI.configure do |config|
      config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
      config.request_timeout = 240 # default is 120
    end

    @client = OpenAI::Client.new
  end

  def request(messages:, temperature:)
    @client.chat(
      parameters: {
        model: MODEL,
        messages: take_last(messages, MESSAGE_LENGTH),
        temperature:
      }
    )
  end

  private

  def take_last(messages, history_length)
    systems = messages.filter { |msg| msg[:role] == 'system' }
    histories = messages.drop(systems.size).reverse.take(history_length - systems.size).reverse
    systems + histories
  end
end
