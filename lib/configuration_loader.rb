# frozen_string_literal: true

require "json"

##
# ConfigurationLoader
#
# config.json を読み込み、Ruby の Hash として返す責務を持つ。
#
# @example
#   config = ConfigurationLoader.load
#
module ConfigurationLoader
  ##
  # config.json を読み込む
  #
  # @return [Hash] 設定値
  #
  def self.load
    configuration_path = File.join(__dir__, "..", "config.json")
    JSON.parse(File.read(configuration_path), symbolize_names: true)
  end
end