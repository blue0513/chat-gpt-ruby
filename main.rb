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

def take_last(array, number)
  systems = array.filter { |msg| msg[:role] == 'system' }
  systems + array.drop(systems.size).reverse.take(number - systems.size).reverse
end

def undo(msgs)
  msgs.reverse.drop(1).reverse
end

def start_progress(bar)
  Thread.new do
    bar.reset
    600.times do
      sleep(0.1)
      bar.advance
    end
  end
end

def stop_progress(bar)
  bar.finish
end

def request_ai(client:, bar:, messages:, temperature:)
  start_progress(bar)
  response = client.chat(
    parameters: {
      model: 'gpt-3.5-turbo',            # Required.
      messages: take_last(messages, 20), # Required.
      temperature:
    }
  )
  stop_progress(bar)

  response
end

def say_ai(response:)
  total_token = response.dig('usage', 'total_tokens')
  ai_content = response.dig('choices', 0, 'message', 'content')

  Prompt.prompt.warn("---- AI（#{total_token}） ----")
  Prompt.prompt.say("\n")
  Prompt.prompt.say(ai_content&.to_s)

  ai_content&.to_s
end

############
# Init
############

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
end

client = OpenAI::Client.new
cmd = Command.new
cmd.parse
bar = TTY::ProgressBar.new(
  'waiting [:bar]',
  { total: nil, width: 20, clear: true, frequency: 10 }
)

############
# Settings
############

# Model
chat_config = ChatConfig.new(quick: cmd.params[:quick])
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
    response = request_ai(
      client:, bar:, messages:, temperature:
    )
    ai_content = say_ai(response:)
    messages.push({ role: 'assistant', content: ai_content })
    play_sound
  rescue StandardError => e
    Prompt.prompt.error(e)
    dump_message(messages)
    exit
  end
end

# rubocop:enable Metrics/BlockLength
