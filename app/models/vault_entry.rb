class VaultEntry < ApplicationRecord
  has_one_attached :receipt

  enum :kind, { expense: 0, income: 1 }, prefix: true

  validates :occurred_on, presence: true
  validates :amount_yen, presence: true, numericality: { only_integer: true }
  validates :memo, length: { maximum: 2000 }, allow_blank: true
  validates :tag, length: { maximum: 50 }, allow_blank: true
end
