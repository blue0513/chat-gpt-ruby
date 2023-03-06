require 'openai'

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
end

client = OpenAI::Client.new
message = [
  { role: 'system', content: 'あなたは語尾に「ですニャ」をつけます' }
]

5.times { |i|
  print 'User: '
  user_content = gets
  message.push({ role: 'user', content: user_content })

  response = client.chat(
    parameters: {
      model: 'gpt-3.5-turbo', # Required.
      messages: message,      # Required.
      temperature: 0.7
    }
  )

  gpt_content = response.dig('choices', 0, 'message', 'content')
  puts 'ChatGPT: ' + gpt_content

  message.push({ role: 'assistant', content: gpt_content })
}
