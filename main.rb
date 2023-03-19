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

class Command
  include TTY::Option

  flag :quick do
    short "-q"
    long "--quick"
  end
end

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
}
TEMPATURE_OPTION = {
  min: 0.0,
  max: 2.0,
  step: 0.1,
  default: 0.7,
  active_color: :magenta,
  format: '|:slider| %.1f'
}

############
# Methods
############

def dump_message(msg)
  date = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
  filename = "#{HISTORY_DIR}/#{date}_#{FILE_NAME_BASE}"
  FileUtils.touch(filename)

  File.open(filename, 'w') do |f|
    f.puts(msg.to_json)
  end
end

def list_files(base_dir, ext)
  Dir.glob("./#{base_dir}/*").select { |f| File.file?(f) && File.extname(f) == ext }
end

def take_last(array, n)
  systems = array.filter { |msg| msg.dig(:role) == 'system' }
  systems + array.drop(systems.size).reverse.take(n - systems.size).reverse
end

def system_content(profile_files)
  model_name = @prompt.select('Model', profile_files.map {|f| File.basename(f, '.*') }, MODEL_OPTION)
  profile_file = profile_files.find { |f| f.include?(model_name) }
  File.open(profile_file, 'r') do |file|
    file.read
  end
end

def history_content(history_files)
  history = @prompt.select(
    'History',
    history_files.map {|f| File.basename(f, '.*') },
    MODEL_OPTION
  )
  history_file = history_files.find { |f| f.include?(history) }
  content = File.open(history_file, 'r') do |file|
    file.read
  end
  JSON.parse(content)
end

def undo(msgs)
  msgs.reverse.drop(2).reverse
end

def start_progress(bar)
  Thread.new {
    bar.reset
    600.times { sleep(0.1); bar.advance }
  }
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
      temperature: temperature
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
@prompt = TTY::Prompt.new
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
temperature = cmd.params[:quick] ? 1.0 : @prompt.slider('Temperature', active_color: :magenta) do |range|
  range.min 0.0
  range.max 2.0
  range.step 0.1
  range.default 1.0
  range.format '|:slider| %.1f'
end

# History Log
history_files = list_files(HISTORY_DIR, '.json')
history_messages = cmd.params[:quick] ? [] : history_content(history_files)
@prompt.ok('---- history is ----', color: :magenta)
history_messages.each { |msg|
  actor = msg.dig("role")
  content = msg.dig("content")
  @prompt.say("#{actor}: #{content}")
}

messages = [
  { role: 'system', content: "#{system_message}" },
  *history_messages
]

############
# Main Chat
############

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

  response = request_ai(
    client: client, bar: bar, messages: messages, temperature: temperature
  )

  begin
    ai_content = say_ai(response: response)
    messages.push({ role: 'assistant', content: ai_content })
    play_sound
  rescue => e
    @prompt.error(e)
    dump_message(messages)
    exit
  end
end
