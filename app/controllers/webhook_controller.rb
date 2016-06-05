class WebhookController < ApplicationController
  protect_from_forgery with: :null_session

  CHANNEL_ID = ENV["LINE_CHANNEL_ID"]
  CHANNEL_SECRET = ENV["LINE_CHANNEL_SECRET"]
  CHANNEL_MID = ENV["LINE_CHANNEL_MID"]
  OUTBOUND_PROXY = ENV["LINE_OUTBOUND_PROXY"]

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end

    logger.info({from_line: params})

    client = LineClient.new CHANNEL_ID, CHANNEL_SECRET, CHANNEL_MID, OUTBOUND_PROXY
    if params[:result]
      result = params[:result][0]
      text_message = result["content"]["text"]
      from_mid = result["content"]["from"]
      fromChannel = result["fromChannel"]
      res = client.send [from_mid], "Response: " + text_message
    else
      text_message = params["content"]["text"]
      to_mid = params["to"]
      res = client.send [to_mid["0"]], text_message
    end

    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end
    render json: {messageID: res.body["messageId"], message: text_message, status: :ok}
  end

  private
  def is_validate_signature
    signature = "qlloGXY5QAZcFgQFPGaD74aCeE3AQ2emik3YZ3nnJH4="
    http_request_body = request.raw_post
    hash = OpenSSL::HMAC::digest OpenSSL::Digest::SHA256.new, CHANNEL_SECRET, http_request_body
    signature_answer = Base64.strict_encode64 hash
    signature == signature_answer
  end
end
