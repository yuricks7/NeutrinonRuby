# frozen_string_literal: true

require "net/http"
require "json"

##
# SlackNotifier
#
# Slack Webhook を使って通知を送信する責務を持つ。
#
module SlackNotifier
  ##
  # Slack にメッセージを送信する
  #
  # @param webhook_url [String]
  # @param text [String]
  #
  # @return [void]
  #
  def self.notify(webhook_url, text)
    uri = URI(webhook_url)
    Net::HTTP.post(uri, { text: text }.to_json, "Content-Type" => "application/json")
  end
end
