# frozen_string_literal: true

require 'tty-prompt'
require 'tty-progressbar'

class Prompt
  def self.prompt
    TTY::Prompt.new(
      interrupt: proc { |_|
        prmpt.ok('Bye')
        exit
      }
    )
  end

  def self.start_progress
    bar_instance = build_bar
    Thread.new do
      600.times do
        sleep(0.1)
        bar_instance.advance
      end
    end
    bar_instance
  end

  def self.stop_progress(bar)
    bar.finish
  end

  def self.build_bar
    TTY::ProgressBar.new(
      'waiting [:bar]',
      { total: nil, width: 20, clear: true, frequency: 10 }
    )
  end

  private_class_method :build_bar
end
