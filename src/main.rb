# frozen_string_literal: true

require 'tiktoken_ruby'

require './src/chat'
require './src/chat_config'
require './src/play_sound'
require './src/prompt'
require './src/client'
require './src/option'

class Main
  attr_accessor :option, :client, :chat_config, :messages

  def initialize
    @option = Option.new
    @client = Client.new
    @chat_config = ChatConfig.new(quick: option.cmd.params[:quick])
    @chat_config.configure!
    @messages = [
      { role: 'system', content: @chat_config.model_profile.to_s },
      *@chat_config.history_messages
    ]

    show_config(config: @chat_config)
  end

  def chat!
    user_input_result = Chat.read_user_input(histories: @messages)
    return if user_input_result[:command_executed]

    @messages.push({ role: 'user', content: user_input_result[:user_content] })
    response = client_request(client: @client, messages: @messages, temperature: @chat_config.temperature)
    @messages.push({ role: 'assistant', content: response })

    print_token(model: @client.model, content: @messages.map { |msg| msg[:content] }.join)
  rescue Interrupt => _e
    interrupt(@messages)
  rescue StandardError => e
    catch_error(error: e, messages: @messages)
  end

  private

  def show_config(config:)
    Prompt.prompt.ok('---- system message is ----', color: :magenta)
    Prompt.prompt.say(config.model_profile)
    Prompt.prompt.ok('---- history is ----', color: :magenta)
    config.history_messages.each do |msg|
      Prompt.prompt.say("#{msg['role']}: #{msg['content']}")
    end
  end

  def client_request(client:, messages:, temperature:)
    Prompt.prompt.warn('---- AI ----')
    Prompt.prompt.say("\n")
    # Processed by Stream and output to stdout
    content = client.request(messages:, temperature:)
    Prompt.prompt.say("\n")
    Sound.play_sound

    content
  end

  def interrupt(messages)
    exit 0 unless messages.last[:role] == 'user' # while waiting for user input, interrupting will exit
    Prompt.prompt.warn('interrupted')
  end

  def catch_error(error:, messages:)
    Prompt.prompt.error(error)
    Chat.dump_message(messages)
    exit
  end

  def print_token(model:, content:)
    Prompt.prompt.say("\n")
    enc = Tiktoken.encoding_for_model(model)
    length = enc.encode(content).length
    Prompt.prompt.ok("token length: #{length}", color: :cyan)
  end
end
