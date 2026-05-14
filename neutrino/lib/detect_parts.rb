# frozen_string_literal: true

require_relative "configuration_loader"
require_relative "path_converter"
require "json"

song = ARGV[0]
config = ConfigurationLoader.load
apps_dir = config[:apps_dir]

wsl_path = PathConverter.to_wsl(apps_dir)
musicxml_dir = File.join(wsl_path, "score", "musicxml", song)

# パート名の候補（大文字小文字・略称も含む）
PART_PATTERNS = {
  "Soprano"  => [/sop/i, /soprano/i],
  "Alto"     => [/alto/i, /alt/i],
  "Tenor"    => [/tenor/i, /ten/i],
  "Baritone" => [/baritone/i, /bari/i, /bar/i]
}

parts = []

if Dir.exist?(musicxml_dir)
  Dir.glob(File.join(musicxml_dir, "**", "*.musicxml")).each do |file|
    filename = File.basename(file)

    PART_PATTERNS.each do |part, patterns|
      if patterns.any? { |pat| filename =~ pat }
        parts << part
      end
    end
  end
end

puts parts.uniq.to_json