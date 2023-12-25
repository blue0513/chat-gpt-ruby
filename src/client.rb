# frozen_string_literal: true

class Client
  DEFAULT_MODEL = 'gpt-4-1106-preview'
  MESSAGE_LENGTH = 20

  attr_accessor :model

  def initialize(model:)
    OpenAI.configure do |config|
      config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
      config.request_timeout = 240 # default is 120
    end

    @model = model || DEFAULT_MODEL
    @client = OpenAI::Client.new
  end

  def request(messages:, temperature:)
    response_content = []
    @client.chat(
      parameters: {
        model: @model,
        messages: take_last(messages, MESSAGE_LENGTH),
        temperature:,
        stream: proc do |chunk, _bytesize| handle_stream!(response_content, chunk) end
      }
    )
    response_content.join
  end

  private

  def take_last(messages, history_length)
    systems = messages.filter { |msg| msg[:role] == 'system' }
    histories = messages.drop(systems.size).reverse.take(history_length - systems.size).reverse
    systems + histories
  end

  def handle_stream!(response_content, chunk)
    stream_str = chunk.dig('choices', 0, 'delta', 'content')
    response_content << stream_str
    print stream_str
  end
end
