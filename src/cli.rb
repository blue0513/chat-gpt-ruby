# frozen_string_literal: true

require './src/main'

main = Main.new

loop do
  main.chat!
end
