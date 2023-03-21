# frozen_string_literal: true

class Sound
  def self.play_sound
    if RbConfig::CONFIG['host_os'] =~ /darwin/
      file = '/System/Library/Sounds/Ping.aiff'
      system("afplay \"#{file}\" &")
    else
      puts('Sorry, play_sound.rb is currently not compatible with your operating system.')
    end
  end
end
