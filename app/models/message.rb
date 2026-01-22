class Message < ApplicationRecord
  belongs_to :user, optional: true
end
