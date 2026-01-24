class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy
  validates :mode, presence: true
end
