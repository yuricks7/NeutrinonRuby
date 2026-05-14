# frozen_string_literal: true

##
# WindowsPathBuilder
#
# Windows パスを安全に結合する。
#
module WindowsPathBuilder
  ##
  # Windows パスを "\" で結合する
  #
  # @param parts [Array<String>]
  # @return [String]
  #
  # @example
  #   WindowsPathBuilder.join("C:\\neutrino", "Apps", "bin")
  #
  def self.join(*parts)
    parts.join("\\")
  end
end
