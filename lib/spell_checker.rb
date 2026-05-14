# frozen_string_literal: true

require "fileutils"
require_relative "path_converter"

##
# SpellChecker
#
# 曲名フォルダおよび MusicXML ファイルの存在確認と、
# スペルミスに対する候補提示を行う責務を持つ。
#
module SpellChecker
  ##
  # Levenshtein 距離を計算する
  #
  # @param string_a [String]
  # @param string_b [String]
  # @return [Integer] 距離（小さいほど類似）
  #
  def self.levenshtein_distance(string_a, string_b)
    length_a = string_a.length
    length_b = string_b.length
    matrix = Array.new(length_a + 1) { Array.new(length_b + 1, 0) }

    (0..length_a).each { |i| matrix[i][0] = i }
    (0..length_b).each { |j| matrix[0][j] = j }

    (1..length_a).each do |i|
      (1..length_b).each do |j|
        cost = string_a[i - 1] == string_b[j - 1] ? 0 : 1
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        ].min
      end
    end

    matrix[length_a][length_b]
  end

  ##
  # 曲名フォルダの存在を確認し、存在しない場合は候補を提示する
  #
  # @param apps_directory [String] Windows の Apps ディレクトリ
  # @param song_name [String] 曲名
  #
  # @return [void]
  #
  def self.check_song_folder(apps_directory, song_name)
    wsl_base = PathConverter.to_wsl(apps_directory)
    musicxml_base = File.join(wsl_base, "score", "musicxml")

    FileUtils.mkdir_p(musicxml_base)

    song_folder = File.join(musicxml_base, song_name)
    return if Dir.exist?(song_folder)

    candidates = Dir.children(musicxml_base)
                    .select { |name| levenshtein_distance(name.downcase, song_name.downcase) <= 3 }

    message = "❌ フォルダ \"#{song_name}\" が見つかりません。\n"
    message << "検索対象: #{musicxml_base}\n"

    unless candidates.empty?
      message << "\nもしかして:\n"
      candidates.each { |c| message << "  - #{c}\n" }
    end

    abort(message)
  end

  ##
  # MusicXML ファイルの存在を確認し、存在しない場合は候補を提示する
  #
  # @param apps_directory [String] Windows の Apps ディレクトリ
  # @param song_name [String] 曲名
  # @param parts [Array<String>] パート名（Soprano, Alto, Tenor, Bass など）
  #
  # @return [void]
  #
  def self.check_musicxml_files(apps_directory, song_name, parts)
    wsl_base = PathConverter.to_wsl(apps_directory)
    folder = File.join(wsl_base, "score", "musicxml", song_name)

    FileUtils.mkdir_p(folder)
    existing_files = Dir.children(folder)

    parts.each do |part|
      expected = "#{song_name}-#{part}.musicxml"
      next if existing_files.include?(expected)

      candidates = existing_files.select do |file|
        levenshtein_distance(file.downcase, expected.downcase) <= 4
      end

      message = "❌ #{expected} が見つかりません。\n"
      message << "検索対象: #{folder}\n"

      unless candidates.empty?
        message << "\n似ているファイル:\n"
        candidates.each { |c| message << "  - #{c}\n" }
      end

      abort(message)
    end
  end
end
