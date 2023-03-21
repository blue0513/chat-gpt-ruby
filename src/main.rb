# frozen_string_literal: true

require './src/chat'
require './src/chat_config'
require './src/play_sound'
require './src/prompt'
require './src/client'
require './src/option'

############
# Methods
############

def show_config(config:)
  Prompt.prompt.ok('---- system message is ----', color: :magenta)
  Prompt.prompt.say(config.model_profile)
  Prompt.prompt.ok('---- history is ----', color: :magenta)
  config.history_messages.each do |msg|
    Prompt.prompt.say("#{msg['role']}: #{msg['content']}")
  end
end

def client_request(client:, messages:, temperature:)
  progress_bar = Prompt.start_progress
  response = client.request(messages:, temperature:)
  Prompt.stop_progress(progress_bar)

  total_token = response.dig('usage', 'total_tokens')
  content = response.dig('choices', 0, 'message', 'content')

  Prompt.prompt.warn("---- AI（#{total_token}） ----")
  Prompt.prompt.say("\n")
  Prompt.prompt.say(content&.to_s)

  content
end

############
# Init
############

option = Option.new
client = Client.new
chat_config = ChatConfig.new(quick: option.cmd.params[:quick])
messages = [
  { role: 'system', content: chat_config.model_profile.to_s },
  *chat_config.history_messages
]

############
# Main Chat
############

show_config(config: chat_config)

loop do
  user_input_result = Chat.read_user_input(histories: messages)
  next if user_input_result[:command_executed]

  messages = user_input_result[:histories]
  messages.push({ role: 'user', content: user_input_result[:user_content] })
  response = client_request(client:, messages:, temperature: chat_config.temperature)
  messages.push({ role: 'assistant', content: response })
  Sound.play_sound
rescue StandardError => e
  Prompt.prompt.error(e)
  Chat.dump_message(messages)
  exit
end
