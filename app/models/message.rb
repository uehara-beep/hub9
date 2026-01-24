class Message < ApplicationRecord
  belongs_to :conversation, optional: true
  validates :role, :content, presence: true
end
