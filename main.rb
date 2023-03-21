# frozen_string_literal: true

require 'openai'
require 'tty-prompt'
require 'tty-progressbar'
require 'json'
require 'fileutils'
require 'tty-option'

# Load other libraries
require './chat'
require './chat_config'
require './play_sound'
require './prompt'
require './client'
require './option'

############
# Constant
############

HISTORY_DIR = 'history'
FILE_NAME_BASE = 'history.json'

############
# Methods
############

def say_ai(response:)
  total_token = response.dig('usage', 'total_tokens')
  ai_content = response.dig('choices', 0, 'message', 'content')

  { ai_content:, total_token: }
end

############
# Init
############

# Command line options
option = Option.new

# Model
chat_config = ChatConfig.new(quick: option.cmd.params[:quick])
model_profile = chat_config.load_model_profile

Prompt.prompt.ok('---- system message is ----', color: :magenta)
Prompt.prompt.say(model_profile)

# Temperature
temperature = chat_config.load_temperature

# History Log
history_messages = chat_config.load_history

Prompt.prompt.ok('---- history is ----', color: :magenta)
history_messages.each do |msg|
  Prompt.prompt.say("#{msg['role']}: #{msg['content']}")
end

messages = [
  { role: 'system', content: model_profile.to_s },
  *history_messages
]

# Client

client = Client.new

############
# Main Chat
############

100.times do |_|
  user_input_result = Chat.read_user_input(histories: messages)
  next if user_input_result[:command_executed]

  messages = user_input_result[:histories]
  messages.push({ role: 'user', content: user_input_result[:user_content] })

  begin
    progress_bar = Prompt.start_progress
    response = client.request(messages:, temperature:)
    Prompt.stop_progress(progress_bar)

    content = say_ai(response:)

    Prompt.prompt.warn("---- AI（#{content[:total_token]}） ----")
    Prompt.prompt.say("\n")
    Prompt.prompt.say(content[:ai_content]&.to_s)

    messages.push({ role: 'assistant', content: content[:ai_content] })
    play_sound
  rescue StandardError => e
    Prompt.prompt.error(e)
    Chat.dump_message(messages)
    exit
  end
end
