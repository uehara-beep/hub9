class User < ApplicationRecord
  if defined?(Devise)
    devise :database_authenticatable,
           :registerable,
           :recoverable,
           :rememberable,
           :validatable
  end
end
