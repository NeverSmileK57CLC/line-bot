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
    byebug
    result = params[:result]["0"]
    logger.info({from_line: result})
    text_message = result["content"]["text"]
    from_mid = result["content"]["from"]

    client = LineClient.new CHANNEL_ID, CHANNEL_SECRET, CHANNEL_MID, OUTBOUND_PROXY
    res = client.send [from_mid], text_message

    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end
    render nothing: true, status: :ok
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
