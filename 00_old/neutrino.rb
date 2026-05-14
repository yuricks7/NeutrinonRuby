# neutrino.rb
require "net/http"
require "json"
require "fileutils"
require "time"

# ================================
# Load Config
# ================================
config_path = File.join(__dir__, "config.json")
Config = JSON.parse(File.read(config_path), symbolize_names: true)

# apps_dir   = Config[:apps_dir]   # Windows パス (例: C:\neutrino\Apps)
apps_dir = Config[:apps_dir].gsub("/", "\\") # 念のため変換

threads    = Config[:threads]
transpose  = Config[:transpose]
webhook    = Config[:webhook]
model_map  = Config[:model_map]

# ================================
# Logging
# ================================
timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
log_dir   = File.join(__dir__, "logs")
FileUtils.mkdir_p(log_dir)
log_path  = File.join(log_dir, "#{timestamp}.log")

def log(msg, log_path)
  puts msg
  File.open(log_path, "a") { |f| f.puts(msg) }
end

# ================================
# Windows パス → WSL パス変換
# ================================
def to_wsl_path(win_path)
  drive = win_path[0].downcase
  rest  = win_path[2..].gsub("\\", "/")
  "/mnt/#{drive}/#{rest}"
end

# ================================
# Helpers
# ================================
def run_in_windows(cmd, workdir, log_path)
  Dir.chdir("/mnt/c/Windows/System32")
  cmd_exe = "/mnt/c/Windows/System32/cmd.exe"
  full = "\"#{cmd_exe}\" /d /c \"cd /d #{workdir} && #{cmd}\""

  log("→ #{cmd}", log_path)
  system(full) or abort("❌ Failed: #{cmd}")
end

def wp(*parts)
  parts.join("\\")
end

puts apps_dir
puts wp(apps_dir, "score", "musicxml")

def build_musicxml_cmd(base, song, basename)
  [
    wp(base, "bin", "musicXMLtoLabel.exe"),
    wp(base, "score", "musicxml", song, "#{basename}.musicxml"),
    wp(base, "score", "label", "full",   song, "#{basename}.lab"),
    wp(base, "score", "label", "mono",   song, "#{basename}.lab")
  ].join(" ")
end

def build_neutrino_cmd(base, song, basename, model, threads, transpose)
  [
    wp(base, "bin", "neutrino.exe"),
    wp(base, "score", "label", "full",   song, "#{basename}.lab"),
    wp(base, "score", "label", "timing", song, "#{basename}.lab"),

    # 出力フォルダ分割
    wp(base, "output", song, "f0",      "#{basename}.f0"),
    wp(base, "output", song, "melspec", "#{basename}.melspec"),
    wp(base, "output", song, "wav",     "#{basename}.wav"),

    wp(base, "model", model) + "\\",
    "-n #{threads}",
    "-f #{transpose}",
    "-m -t"
  ].join(" ")
end

def notify_slack(webhook, text)
  uri = URI(webhook)
  Net::HTTP.post(uri, { text: text }.to_json, "Content-Type" => "application/json")
end

# ================================
# Folder auto-generation (WSL)
# ================================
def ensure_song_folders(apps_dir, song)
  wsl_apps = to_wsl_path(apps_dir)

  folders = [
    File.join(wsl_apps, "score", "musicxml", song),
    File.join(wsl_apps, "score", "label", "full",   song),
    File.join(wsl_apps, "score", "label", "mono",   song),
    File.join(wsl_apps, "score", "label", "timing", song),

    # 出力フォルダ分割
    File.join(wsl_apps, "output", song, "f0"),
    File.join(wsl_apps, "output", song, "melspec"),
    File.join(wsl_apps, "output", song, "wav")
  ]

  folders.each do |path|
    FileUtils.mkdir_p(path) unless Dir.exist?(path)
  end
end

# ================================
# Levenshtein Distance（簡易版）
# ================================
def levenshtein(a, b)
  a_len = a.length
  b_len = b.length
  dp = Array.new(a_len + 1) { Array.new(b_len + 1, 0) }

  (0..a_len).each { |i| dp[i][0] = i }
  (0..b_len).each { |j| dp[0][j] = j }

  (1..a_len).each do |i|
    (1..b_len).each do |j|
      cost = a[i - 1] == b[j - 1] ? 0 : 1
      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost
      ].min
    end
  end

  dp[a_len][b_len]
end

# ================================
# （WSLパス版）song フォルダ存在チェック + 候補表示
# ================================
def check_song_folder(apps_dir, song)
  wsl_base = to_wsl_path(apps_dir)
  base = File.join(wsl_base, "score", "musicxml")

  FileUtils.mkdir_p(base) unless Dir.exist?(base)

  song_path = File.join(base, song)
  return if Dir.exist?(song_path)

  candidates = Dir.children(base)
                  .select { |name| levenshtein(name.downcase, song.downcase) <= 3 }

  msg = ""
  msg += "❌ エラー: フォルダ \"#{song}\" は存在しません。\n"
  msg += "base: #{base}"

  unless candidates.empty?
    msg << "\nもしかして:\n"
    candidates.each { |c| msg << "  - #{c}\n" }
  end

  abort(msg)
end

# ================================
# （WSLパス版）MusicXML ファイル存在チェック + 候補表示
# ================================
def check_musicxml_files(apps_dir, song, parts)
  wsl_base = to_wsl_path(apps_dir)
  folder = File.join(wsl_base, "score", "musicxml", song)

  FileUtils.mkdir_p(folder) unless Dir.exist?(folder)

  existing = Dir.children(folder)

  parts.each do |part|
    expected = "#{song}-#{part}.musicxml"

    next if existing.include?(expected)

    candidates = existing.select do |f|
      levenshtein(f.downcase, expected.downcase) <= 4
    end

    msg = ""
    msg += "❌ エラー: #{expected} が見つかりません。\n"
    msg += "folder: #{folder}"

    unless candidates.empty?
      msg << "\n似ているファイル:\n"
      candidates.each { |c| msg << "  - #{c}\n" }
    end

    abort(msg)
  end
end

# ================================
# Main
# ================================
song = ARGV[0] or abort("Usage: ruby neutrino.rb SONG_NAME")

# Folder & File Spell Check
check_song_folder(apps_dir, song)
check_musicxml_files(apps_dir, song, model_map.keys)

# ================================
# 日本語（全角文字）禁止チェック
# ================================
if song =~ /[^\x00-\x7F]/
  abort("❌ エラー: 曲名に日本語（全角文字）が含まれています。\n" \
        "NEUTRINO は日本語パスに対応していないため、半角英数字のみ使用してください。\n" \
        "例: Mikakunin, test-song, mySong01")
end

# ================================
# Ensure folders exist (WSL)
# ================================
ensure_song_folders(apps_dir, song)

# ================================
# Process each part
# ================================
model_map.each do |part, model|
  # ★★★ ここをアンダースコア → ハイフンに変更 ★★★
  basename = "#{song}-#{part}"

  log("\n=== #{basename} : MusicXMLtoLabel ===", log_path)
  run_in_windows(
    build_musicxml_cmd(apps_dir, song, basename),
    apps_dir,
    log_path
  )

  log("=== #{basename} : NEUTRINO (model=#{model}) ===", log_path)
  run_in_windows(
    build_neutrino_cmd(apps_dir, song, basename, model, threads, transpose),
    apps_dir,
    log_path
  )
end

notify_slack(webhook, "NEUTRINO 完了: #{song} の4声部を生成しました")
log("\n=== Slack 投稿完了 ===", log_path)
log("ログファイル: #{log_path}", log_path)