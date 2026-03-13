class LineMessagingService
  BASE_URL = "https://api.line.me/v2/bot"

  def self.reply(reply_token, text)
    new.reply(reply_token, text)
  end

  def self.push(user_id, text)
    new.push(user_id, text)
  end

  def reply(reply_token, text)
    post("/message/reply", {
      replyToken: reply_token,
      messages: [{ type: "text", text: text }]
    })
  end

  def push(user_id, text)
    post("/message/push", {
      to: user_id,
      messages: [{ type: "text", text: text }]
    })
  end

  def get_content(message_id)
    uri = URI("https://api-data.line.me/v2/bot/message/#{message_id}/content")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{channel_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 30) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      response.body.force_encoding(Encoding::ASCII_8BIT)
    else
      Rails.logger.error("[LineMessagingService] Content取得失敗: #{response.code} #{response.body}")
      nil
    end
  end

  private

  def post(path, body)
    uri = URI("#{BASE_URL}#{path}")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{channel_token}"
    request.body = body.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[LineMessagingService] API呼び出し失敗: #{response.code} #{response.body}")
    end

    response
  end

  def channel_token
    ENV.fetch("LINE_CHANNEL_TOKEN")
  end
end
