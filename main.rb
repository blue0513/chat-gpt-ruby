require 'openai'
require 'tty-prompt'

FILE_NAME = 'history.log'
MODEL_OPTION = {
  cycle: true,
  marker: true,
  filter: true,
  echo: true
}
TEMPATURE_OPTION = {
  min: 0.0,
  max: 2.0,
  step: 0.1,
  default: 0.7,
  format: '|:slider| %.1f'
}
MODELS = %w(
  デフォルト
  アーニャ
)

def dump_message(msg)
  File.open(FILE_NAME, 'w') do |f|
    f.puts(msg)
  end
end

def take_last(array, n)
  systems = array.filter { |msg| msg.dig(:role) == 'system' }
  systems + array.drop(systems.size).reverse.take(n-systems.size).reverse
end

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
end

client = OpenAI::Client.new
prompt = TTY::Prompt.new

selected_ai = prompt.select('Model', MODELS, MODEL_OPTION)
temperature = prompt.slider('Temperature') do |range|
  range.min 0.0
  range.max 2.0
  range.step 0.1
  range.default 1.0
  range.format '|:slider| %.1f'
end

system_message = selected_ai == 'アーニャ' ? 'あなたは語尾に「ます」をつけます' : ''

messages = [
  { role: 'system', content: "#{system_message}" }
]

100.times { |i|
  user_content = prompt.multiline('User:', echo: true).join.chomp

  if user_content.chomp == 'dump'
    dump_message(messages)
    next
  end

  messages.push({ role: 'user', content: user_content })

  response = client.chat(
    parameters: {
      model: 'gpt-3.5-turbo',            # Required.
      messages: take_last(messages, 10), # Required.
      temperature: temperature
    }
  )

  gpt_content = response.dig('choices', 0, 'message', 'content')
  puts "#{selected_ai}: " + gpt_content

  messages.push({ role: 'assistant', content: gpt_content })
}
