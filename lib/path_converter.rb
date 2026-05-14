# frozen_string_literal: true

##
# PathConverter
#
# Windows パスと WSL パスの相互変換を担当する。
#
module PathConverter
  ##
  # Windows パスを WSL パスに変換する
  #
  # @param windows_path [String]
  # @return [String] WSL パス
  #
  # @example
  #   PathConverter.to_wsl("C:\\neutrino\\Apps")
  #   # => "/mnt/c/neutrino/Apps"
  #
  def self.to_wsl(windows_path)
    drive_letter = windows_path[0].downcase
    rest = windows_path[2..].gsub("\\", "/")
    "/mnt/#{drive_letter}/#{rest}"
  end
end
