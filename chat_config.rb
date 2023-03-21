# frozen_string_literal: true

require 'json'
require './prompt'

class ChatConfig
  attr_accessor :quick

  MODEL_DIR = 'model_profiles'
  HISTORY_DIR = 'history'

  MODEL_OPTION = {
    cycle: true,
    marker: true,
    filter: true,
    echo: true,
    active_color: :magenta
  }.freeze

  def initialize(quick:)
    @quick = quick
  end

  def load_model_profile
    model_profiles = list_files(MODEL_DIR, '.txt')
    @quick ? '' : system_content(model_profiles)
  end

  def load_history
    history_files = list_files(HISTORY_DIR, '.json')
    @quick ? [] : history_content(history_files)
  end

  def load_temperature
    return 1.0 if @quick

    Prompt.prompt.slider('Temperature', active_color: :magenta) do |range|
      range.min 0.0
      range.max 2.0
      range.step 0.1
      range.default 1.0
      range.format '|:slider| %.1f'
    end
  end

  private

  def list_files(base_dir, ext)
    Dir.glob("./#{base_dir}/*").select { |f| File.file?(f) && File.extname(f) == ext }
  end

  def system_content(profile_files)
    model_name = Prompt.prompt.select('Model', profile_files.map { |f| File.basename(f, '.*') }, MODEL_OPTION)
    profile_file = profile_files.find { |f| f.include?(model_name) }
    File.open(profile_file, 'r', &:read)
  end

  def history_content(history_files)
    history = Prompt.prompt.select(
      'History',
      history_files.map { |f| File.basename(f, '.*') },
      MODEL_OPTION
    )
    history_file = history_files.find { |f| f.include?(history) }
    content = File.open(history_file, 'r', &:read)
    JSON.parse(content)
  end
end
