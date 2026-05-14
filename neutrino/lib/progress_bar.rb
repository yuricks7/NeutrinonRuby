# frozen_string_literal: true

##
# ProgressBar
#
# ターミナルに進捗バーを表示するためのユーティリティ。
#
module ProgressBar
  ##
  # 進捗バーを描画する
  #
  # @param current [Integer] 現在の進捗
  # @param total [Integer] 全体の進捗
  # @param width [Integer] バーの幅
  #
  # @return [void]
  #
  def self.render(current, total, width = 30)
    ratio = current.to_f / total
    filled = (ratio * width).round
    empty = width - filled

    bar = "[" + "#" * filled + "-" * empty + "]"
    percent = (ratio * 100).round

    print "\r#{bar} #{percent}%"
    $stdout.flush
  end

  ##
  # 完了時に改行する
  #
  def self.finish
    print "\n"
  end
end
