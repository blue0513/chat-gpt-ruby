# frozen_string_literal: true

require 'openai'
require 'tty-prompt'
require 'tty-progressbar'
require 'json'
require 'fileutils'
require 'tty-option'

# Load other libraries
require './play_sound'

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

MODEL_DIR = 'model_profiles'
HISTORY_DIR = 'history'
FILE_NAME_BASE = 'history.json'
MODEL_OPTION = {
  cycle: true,
  marker: true,
  filter: true,
  echo: true,
  active_color: :magenta
}.freeze
TEMPATURE_OPTION = {
  min: 0.0,
  max: 2.0,
  step: 0.1,
  default: 0.7,
  active_color: :magenta,
  format: '|:slider| %.1f'
}.freeze

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

def list_files(base_dir, ext)
  Dir.glob("./#{base_dir}/*").select { |f| File.file?(f) && File.extname(f) == ext }
end

def take_last(array, number)
  systems = array.filter { |msg| msg[:role] == 'system' }
  systems + array.drop(systems.size).reverse.take(number - systems.size).reverse
end

def system_content(profile_files)
  model_name = @prompt.select('Model', profile_files.map { |f| File.basename(f, '.*') }, MODEL_OPTION)
  profile_file = profile_files.find { |f| f.include?(model_name) }
  File.open(profile_file, 'r', &:read)
end

def history_content(history_files)
  history = @prompt.select(
    'History',
    history_files.map { |f| File.basename(f, '.*') },
    MODEL_OPTION
  )
  history_file = history_files.find { |f| f.include?(history) }
  content = File.open(history_file, 'r', &:read)
  JSON.parse(content)
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

  @prompt.warn("---- AI（#{total_token}） ----")
  @prompt.say("\n")
  @prompt.say(ai_content&.to_s)

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
@prompt = TTY::Prompt.new(
  interrupt: proc { |_|
    @prompt.ok('Bye')
    exit
  }
)
bar = TTY::ProgressBar.new(
  'waiting [:bar]',
  { total: nil, width: 20, clear: true, frequency: 10 }
)

############
# Settings
############

# Model
model_profiles = list_files(MODEL_DIR, '.txt')
system_message = cmd.params[:quick] ? '' : system_content(model_profiles)
@prompt.ok('---- system message is ----', color: :magenta)
@prompt.say(system_message)

# Temperature
temperature = if cmd.params[:quick]
                1.0
              else
                @prompt.slider('Temperature', active_color: :magenta) do |range|
                  range.min 0.0
                  range.max 2.0
                  range.step 0.1
                  range.default 1.0
                  range.format '|:slider| %.1f'
                end
              end

# History Log
history_files = list_files(HISTORY_DIR, '.json')
history_messages = cmd.params[:quick] ? [] : history_content(history_files)
@prompt.ok('---- history is ----', color: :magenta)
history_messages.each do |msg|
  actor = msg['role']
  content = msg['content']
  @prompt.say("#{actor}: #{content}")
end

messages = [
  { role: 'system', content: system_message.to_s },
  *history_messages
]

############
# Main Chat
############

# rubocop:disable Metrics/BlockLength

100.times do |_|
  @prompt.ok('---- User ----')
  user_content = @prompt.multiline('', echo: false).join.chomp
  @prompt.say(user_content)

  case user_content.chomp
  when 'dump'
    @prompt.ok('Dump history')
    dump_message(messages)
    next
  when 'quit'
    @prompt.ok('Bye')
    exit
  when 'undo'
    @prompt.ok('Undo')
    messages = undo(messages)
    puts messages
    next
  when 'clear'
    @prompt.ok('Clear all history')
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
    @prompt.error(e)
    dump_message(messages)
    exit
  end
end

# rubocop:enable Metrics/BlockLength
