# frozen_string_literal: true

require 'tty-prompt'

class Prompt
  def self.prompt
    TTY::Prompt.new(
      interrupt: proc { |_|
        prmpt.ok('Bye')
        exit
      }
    )
  end
end
