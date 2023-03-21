# frozen_string_literal: true

class Prompt

  attr_accessor :prompt, :bar

  def initialize
    @prompt = TTY::Prompt.new(
      interrupt: proc { |_|
        @prmpt.ok('Bye')
        exit
      }
    )
    @bar = TTY::ProgressBar.new(
      'waiting [:bar]',
      { total: nil, width: 20, clear: true, frequency: 10 }
    )
  end

  def start_progress
    Thread.new do
      @bar.reset
      600.times do
        sleep(0.1)
        bar.advance
      end
    end
  end

  def stop_progress
    @bar.finish
  end
end
