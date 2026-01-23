class Message < ApplicationRecord
  belongs_to :user, optional: true

  enum :role, { user: 0, assistant: 1 }
end
