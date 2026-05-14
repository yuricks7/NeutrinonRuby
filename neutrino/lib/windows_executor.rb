# frozen_string_literal: true

require_relative "path_converter"

##
# WindowsExecutor
#
# WSL 上から Windows の exe を安全に実行する責務を持つ。
#
module WindowsExecutor
  ##
  # Windows のコマンドを cmd.exe 経由で実行する
  #
  # @param command [String] Windows パスを含むコマンド
  # @param working_directory [String] Windows パス
  # @param logger [Proc] ログ出力用の Proc
  #
  # @return [void]
  #
  def self.execute(command, working_directory, logger)
    cmd_exe = "/mnt/c/Windows/System32/cmd.exe"

    full_command =
      "\"#{cmd_exe}\" /d /c \"cd /d #{working_directory} && #{command}\""

    logger.call("→ #{command}")
    system(full_command) or abort("❌ Failed: #{command}")
  end
end
