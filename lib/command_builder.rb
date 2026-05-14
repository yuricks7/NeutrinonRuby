# frozen_string_literal: true

require_relative "windows_path_builder"

##
# CommandBuilder
#
# NEUTRINO の各種コマンドを生成する責務を持つ。
#
module CommandBuilder
  include WindowsPathBuilder

  ##
  # MusicXMLtoLabel.exe のコマンドを生成する
  #
  # @param apps_directory [String]
  # @param song_name [String]
  # @param base_name [String] "Song-Part" の形式
  #
  # @return [String] Windows コマンド文字列
  #
  def self.build_musicxml_to_label_command(apps_directory, song_name, base_name)
    [
      WindowsPathBuilder.join(apps_directory, "bin", "musicXMLtoLabel.exe"),
      WindowsPathBuilder.join(apps_directory, "score", "musicxml", song_name, "#{base_name}.musicxml"),
      WindowsPathBuilder.join(apps_directory, "score", "label", "full",   song_name, "#{base_name}.lab"),
      WindowsPathBuilder.join(apps_directory, "score", "label", "mono",   song_name, "#{base_name}.lab")
    ].join(" ")
  end

  ##
  # neutrino.exe のコマンドを生成する
  #
  # @param apps_directory [String]
  # @param song_name [String]
  # @param base_name [String]
  # @param model_name [String]
  # @param thread_count [Integer]
  # @param transpose_value [Integer]
  #
  # @return [String] Windows コマンド文字列
  #
  def self.build_neutrino_command(apps_directory, song_name, base_name, model_name, thread_count, transpose_value)
    [
      WindowsPathBuilder.join(apps_directory, "bin", "neutrino.exe"),
      WindowsPathBuilder.join(apps_directory, "score", "label", "full",   song_name, "#{base_name}.lab"),
      WindowsPathBuilder.join(apps_directory, "score", "label", "timing", song_name, "#{base_name}.lab"),
      WindowsPathBuilder.join(apps_directory, "output", song_name, "f0",      "#{base_name}.f0"),
      WindowsPathBuilder.join(apps_directory, "output", song_name, "melspec", "#{base_name}.melspec"),
      WindowsPathBuilder.join(apps_directory, "output", song_name, "wav",     "#{base_name}.wav"),
      WindowsPathBuilder.join(apps_directory, "model", model_name) + "\\",
      "-n #{thread_count}",
      "-f #{transpose_value}",
      "-m -t"
    ].join(" ")
  end
end
