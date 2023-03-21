# frozen_string_literal: true

require 'tty-option'

class Option
  attr_accessor :cmd

  def initialize
    @cmd = Command.new
    @cmd.parse
  end

  class Command
    include TTY::Option

    flag :quick do
      short '-q'
      long '--quick'
    end
  end
end
