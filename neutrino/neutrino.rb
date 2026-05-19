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

# 曲名
song_name = ARGV[0] or abort("Usage: ruby neutrino.rb SONG_NAME")
# song = ARGV[0]

# partsの受け取り
parts = JSON.parse(ARGV[1]) rescue []
# parts = model_map.keys
abort("No parts selected") if parts.empty?

# model_mapの受け取り
model_map = JSON.parse(ARGV[2]) rescue {}
config[:model_map] = model_map unless model_map.empty?

# 進捗バー用
total_parts = parts.size
current_part_index = 0

# ログ取り用
log_file_path = ApplicationLogger.create_log_file

# 歌詞のチェック
def validate_lyrics(lyrics)
  # NEUTRINO が許可する文字（ひらがな・カタカナ・長音符の組み合わせ）
  allowed = /\A[ぁ-んァ-ヶー]+\z/

  invalid = []

  lyrics.each_with_index do |lyric, idx|
    next if lyric.match?(allowed)
    invalid << { measure: idx + 1, text: lyric }
  end

  invalid
end

# スペルチェック
SpellChecker.check_song_folder(apps_directory, song_name)
SpellChecker.check_musicxml_files(apps_directory, song_name, model_map.keys)

# フォルダ作成
FolderInitializer.ensure_song_folders(apps_directory, song_name)

# 各パート処理
parts.each do |part_name|
  model_name = model_map[part_name]

  current_part_index += 1
  base_name = "#{song_name}-#{part_name}"

  puts "\n" if parts.length > 1
  ApplicationLogger.write("=== #{base_name} ===", log_file_path)
  puts "\n[#{current_part_index}/#{total_parts}] #{part_name}"

  # MusicXMLtoLabel
  print "  - MusicXMLtoLabel   "
  ProgressBar.render(0, 1)

lyrics = SpellChecker.extract_lyrics(song_name)  # 既存の SpellChecker を利用
invalid = validate_lyrics(lyrics)

if invalid.any?
  puts "=== Invalid Lyrics Detected ==="
  invalid.each do |err|
    puts "Measure #{err[:measure]}: #{err[:text]}"
  end
  abort("Invalid lyrics found")
end

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
