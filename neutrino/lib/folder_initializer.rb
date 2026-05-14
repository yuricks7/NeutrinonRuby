# frozen_string_literal: true

require "fileutils"
require_relative "path_converter"

##
# FolderInitializer
#
# NEUTRINO が必要とするフォルダ構造を WSL 側に作成する。
#
module FolderInitializer
  ##
  # 曲ごとのフォルダを作成する
  #
  # @param apps_directory [String] Windows の Apps ディレクトリ
  # @param song_name [String] 曲名
  #
  # @return [void]
  #
  def self.ensure_song_folders(apps_directory, song_name)
    wsl_apps = PathConverter.to_wsl(apps_directory)

    folders = [
      File.join(wsl_apps, "score", "musicxml", song_name),
      File.join(wsl_apps, "score", "label", "full",   song_name),
      File.join(wsl_apps, "score", "label", "mono",   song_name),
      File.join(wsl_apps, "score", "label", "timing", song_name),
      File.join(wsl_apps, "output", song_name, "f0"),
      File.join(wsl_apps, "output", song_name, "melspec"),
      File.join(wsl_apps, "output", song_name, "wav")
    ]

    folders.each { |folder| FileUtils.mkdir_p(folder) }
  end
end
