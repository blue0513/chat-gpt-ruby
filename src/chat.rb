# frozen_string_literal: true

require 'fileutils'
require 'json'

class Chat
  HISTORY_DIR = 'history'
  FILE_NAME_BASE = 'history.json'

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

  def self.read_user_input(histories:)
    Prompt.prompt.ok('---- User ----')
    user_content = Prompt.prompt.multiline('', echo: false).join.chomp
    Prompt.prompt.say(user_content)

    command_executed = false
    case user_content.chomp
    when 'dump'
      Prompt.prompt.ok('Dump history')
      dump_message(histories)
      command_executed = true
    when 'quit'
      Prompt.prompt.ok('Bye')
      exit
    when 'undo'
      Prompt.prompt.ok('Undo')
      undo!(histories)
      puts histories
      command_executed = true
    when 'clear'
      Prompt.prompt.ok('Clear all history')
      clear_messages!(histories)
      command_executed = true
    end

    { user_content:, command_executed: }
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def self.dump_message(messages)
    date = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    filename = "#{HISTORY_DIR}/#{date}_#{FILE_NAME_BASE}"
    FileUtils.touch(filename)

    File.open(filename, 'w') do |f|
      json = JSON.pretty_generate(messages)
      f.puts(json)
    end

    Prompt.prompt.ok("Dumped: #{filename}")
  end

  def self.undo!(messages)
    messages.pop(2)
  end

  def self.clear_messages!(messages)
    messages.clear
  end
end
