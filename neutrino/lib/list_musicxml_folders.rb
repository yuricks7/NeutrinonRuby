# frozen_string_literal: true

require_relative "configuration_loader"
require_relative "path_converter"

config = ConfigurationLoader.load
apps_dir = config[:apps_dir]

wsl_path = PathConverter.to_wsl(apps_dir)
musicxml_dir = File.join(wsl_path, "score", "musicxml")

folders = Dir.exist?(musicxml_dir) ? Dir.children(musicxml_dir) : []

puts folders.to_json
