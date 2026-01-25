class ChargeEntry < ApplicationRecord
  enum direction: { in: 0, out: 1 }
  validates :amount_yen, numericality: { greater_than: 0 }, allow_nil: true
end
