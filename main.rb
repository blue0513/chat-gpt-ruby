# frozen_string_literal: true

require 'openai'
require 'tty-prompt'
require 'tty-progressbar'
require 'json'
require 'fileutils'
require 'tty-option'

# Load other libraries
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

def dump_message(msg)
  date = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
  filename = "#{HISTORY_DIR}/#{date}_#{FILE_NAME_BASE}"
  FileUtils.touch(filename)

  File.open(filename, 'w') do |f|
    f.puts(msg.to_json)
  end
end

def undo(msgs)
  msgs.reverse.drop(1).reverse
end

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

# rubocop:disable Metrics/BlockLength

100.times do |_|
  Prompt.prompt.ok('---- User ----')
  user_content = Prompt.prompt.multiline('', echo: false).join.chomp
  Prompt.prompt.say(user_content)

  case user_content.chomp
  when 'dump'
    Prompt.prompt.ok('Dump history')
    dump_message(messages)
    next
  when 'quit'
    Prompt.prompt.ok('Bye')
    exit
  when 'undo'
    Prompt.prompt.ok('Undo')
    messages = undo(messages)
    puts messages
    next
  when 'clear'
    Prompt.prompt.ok('Clear all history')
    messages = []
    next
  end

  messages.push({ role: 'user', content: user_content })

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
    dump_message(messages)
    exit
  end
end

# rubocop:enable Metrics/BlockLength
