require 'openai'
require 'tty-prompt'

FILE_NAME = 'history.log'

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

messages = [
  { role: 'system', content: 'あなたは語尾に「ですニャ」をつけます' }
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
      temperature: 0.7
    }
  )

  gpt_content = response.dig('choices', 0, 'message', 'content')
  puts 'ChatGPT: ' + gpt_content

  messages.push({ role: 'assistant', content: gpt_content })
}
