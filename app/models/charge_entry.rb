class ChargeEntry < ApplicationRecord
  # 方向: 0=受信(入金/チャージ/立替回収) / 1=送信(出金/支払い/立替)
  # prefix を付けて direction_incoming? / direction_outgoing? を使えるようにする
  enum :direction, { incoming: 0, outgoing: 1 }, prefix: true

  validates :amount_yen, numericality: { greater_than: 0 }, allow_nil: true
end
