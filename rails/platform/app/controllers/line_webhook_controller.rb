class LineWebhookController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection

  before_action :verify_line_signature

  def receive
    body = request.body.read
    events = JSON.parse(body)["events"] || []

    events.each { |event| handle_event(event) }

    head :ok
  end

  private

  def verify_line_signature
    body = request.body.read
    request.body.rewind

    signature = request.headers["X-Line-Signature"]
    unless signature.present?
      head :unauthorized
      return
    end

    channel_secret = ENV.fetch("LINE_CHANNEL_SECRET")
    digest = OpenSSL::HMAC.digest("SHA256", channel_secret, body)
    expected = Base64.strict_encode64(digest)

    unless ActiveSupport::SecurityUtils.secure_compare(expected, signature)
      head :unauthorized
      return
    end
  end

  def handle_event(event)
    case event["type"]
    when "message"
      handle_message(event) if event.dig("message", "type") == "image"
    when "follow"
      handle_follow(event)
    end
  end

  def handle_message(event)
    line_user_id = event.dig("source", "userId")
    client = Client.find_by(line_user_id: line_user_id)

    unless client
      LineMessagingService.reply(
        event["replyToken"],
        "このLINEアカウントは未登録です。管理者にお問い合わせください。"
      )
      return
    end

    ReceiptLineProcessJob.perform_later(
      client_id: client.id,
      message_id: event.dig("message", "messageId"),
      line_user_id: line_user_id
    )
  end

  def handle_follow(event)
    line_user_id = event.dig("source", "userId")
    client = Client.find_by(line_user_id: line_user_id)

    message = if client
      "#{client.name}さん、友だち追加ありがとうございます！\n領収書・レシートの画像を送信すると、自動で仕訳データを作成します。"
    else
      "友だち追加ありがとうございます！\nこのLINEアカウントはまだ登録されていません。管理者にお問い合わせください。"
    end

    LineMessagingService.reply(event["replyToken"], message)
  end
end
