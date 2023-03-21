class Client

  MODEL = 'gpt-3.5-turbo'

  def initialize
    OpenAI.configure do |config|
      config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
    end

    @client = OpenAI::Client.new
  end

  def request(messages:, temperature:)
    @client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: take_last(messages, 20),
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
