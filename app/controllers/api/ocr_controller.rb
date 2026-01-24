class Api::OcrController < ApplicationController
  protect_from_forgery with: :null_session

  # POST /api/ocr/receipt  (params: image_url)
  def receipt
    ocr = OpenaiVisionOcr.new
    json = ocr.receipt(image_url: params.require(:image_url))
    render json: { ok: true, data: JSON.parse(json) }
  rescue => e
    render json: { ok: false, error: e.message }, status: 500
  end

  # POST /api/ocr/business_card (params: image_url)
  def business_card
    ocr = OpenaiVisionOcr.new
    json = ocr.business_card(image_url: params.require(:image_url))
    render json: { ok: true, data: JSON.parse(json) }
  rescue => e
    render json: { ok: false, error: e.message }, status: 500
  end
end
