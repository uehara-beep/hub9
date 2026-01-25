class ChargeEntry < ApplicationRecord
  # direction: 0=受取, 1=支払
  enum direction: { incoming: 0, outgoing: 1 }, _prefix: true

  validates :amount_yen, numericality: { greater_than: 0 }, allow_nil: true
end
