# frozen_string_literal: true

require_relative "lib/configuration_loader"
require_relative "lib/application_logger"
require_relative "lib/path_converter"
require_relative "lib/folder_initializer"
require_relative "lib/spell_checker"
require_relative "lib/command_builder"
require_relative "lib/slack_notifier"
require_relative "lib/windows_executor"
require_relative "lib/progress_bar"

## ==============================
# NEUTRINO 自動生成メインスクリプト
# ===============================

# 基本設定
config = ConfigurationLoader.load
apps_directory = config[:apps_dir]
thread_count   = config[:threads]
transpose_value = config[:transpose]
webhook_url    = config[:webhook]
model_map      = config[:model_map]

# 曲名
song_name = ARGV[0] or abort("Usage: ruby neutrino.rb SONG_NAME")

# ログ取り用
log_file_path = ApplicationLogger.create_log_file

# 進捗バー用
total_parts = model_map.keys.size
current_part_index = 0

# スペルチェック
SpellChecker.check_song_folder(apps_directory, song_name)
SpellChecker.check_musicxml_files(apps_directory, song_name, model_map.keys)

# フォルダ作成
FolderInitializer.ensure_song_folders(apps_directory, song_name)

# 各パート処理
model_map.each do |part_name, model_name|
  current_part_index += 1
  base_name = "#{song_name}-#{part_name}"

  ApplicationLogger.write("=== #{base_name} ===", log_file_path)
  puts "\n[#{current_part_index}/#{total_parts}] #{part_name}"

  # MusicXMLtoLabel
  print "  - MusicXMLtoLabel   "
  ProgressBar.render(0, 1)
  WindowsExecutor.execute(
    CommandBuilder.build_musicxml_to_label_command(apps_directory, song_name, base_name),
    apps_directory,
    ->(msg) { ApplicationLogger.write(msg, log_file_path) }
  )
  ProgressBar.render(1, 1)
  ProgressBar.finish

  # NEUTRINO
  print "  - NEUTRINO          "
  ProgressBar.render(0, 1)
  WindowsExecutor.execute(
    CommandBuilder.build_neutrino_command(apps_directory, song_name, base_name, model_name, thread_count, transpose_value),
    apps_directory,
    ->(msg) { ApplicationLogger.write(msg, log_file_path) }
  )
  ProgressBar.render(1, 1)
  ProgressBar.finish
end

SlackNotifier.notify(webhook_url, "NEUTRINO 完了: #{song_name}")
ApplicationLogger.write("=== Slack 投稿完了 ===", log_file_path)
