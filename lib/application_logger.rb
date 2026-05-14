# frozen_string_literal: true

require "fileutils"
require "time"

##
# ApplicationLogger
#
# ログファイルの生成とログ書き込みを担当する。
#
module ApplicationLogger
  ##
  # ログファイルを作成し、そのパスを返す
  #
  # @return [String] ログファイルパス
  #
  def self.create_log_file
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    log_directory = File.join(__dir__, "..", "logs")
    FileUtils.mkdir_p(log_directory)
    File.join(log_directory, "#{timestamp}.log")
  end

  ##
  # ログを書き込む
  #
  # @param message [String] ログ内容
  # @param log_file_path [String] ログファイルパス
  #
  # @return [void]
  #
  def self.write(message, log_file_path)
    puts message
    File.open(log_file_path, "a") { |file| file.puts(message) }
  end
end
