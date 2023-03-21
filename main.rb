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

############
# Command
############

# rubocop:disable Style/Documentation

class Command
  include TTY::Option

  flag :quick do
    short '-q'
    long '--quick'
  end
end

# rubocop:enable Style/Documentation

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
  ai_content&.to_s
end

############
# Init
############

cmd = Command.new
prompter = Prompt.new

cmd.parse

############
# Settings
############

# Model
chat_config = ChatConfig.new(quick: cmd.params[:quick])
model_profile = chat_config.load_model_profile

prompter.prompt.ok('---- system message is ----', color: :magenta)
prompter.prompt.say(model_profile)

# Temperature
temperature = chat_config.load_temperature

# History Log
history_messages = chat_config.load_history

prompter.prompt.ok('---- history is ----', color: :magenta)
history_messages.each do |msg|
  prompter.prompt.say("#{msg['role']}: #{msg['content']}")
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
  prompter.prompt.ok('---- User ----')
  user_content = prompter.prompt.multiline('', echo: false).join.chomp
  prompter.prompt.say(user_content)

  case user_content.chomp
  when 'dump'
    prompter.prompt.ok('Dump history')
    dump_message(messages)
    next
  when 'quit'
    prompter.prompt.ok('Bye')
    exit
  when 'undo'
    prompter.prompt.ok('Undo')
    messages = undo(messages)
    puts messages
    next
  when 'clear'
    prompter.prompt.ok('Clear all history')
    messages = []
    next
  end

  messages.push({ role: 'user', content: user_content })

  begin
    prompter.start_progress
    response = client.request(messages:, temperature:)
    prompter.stop_progress

    ai_content = say_ai(response:)

    prompter.prompt.warn("---- AI（#{total_token}） ----")
    prompter.prompt.say("\n")
    prompter.prompt.say(ai_content&.to_s)

    messages.push({ role: 'assistant', content: ai_content })
    play_sound
  rescue StandardError => e
    prompter.prompt.error(e)
    dump_message(messages)
    exit
  end
end

# rubocop:enable Metrics/BlockLength
