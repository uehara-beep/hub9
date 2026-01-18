class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  unless ENV["SECRET_KEY_BASE_DUMMY"].present?
    devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  end
end
