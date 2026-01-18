class User < ApplicationRecord
  # assets:precompile中など、Deviseが完全に読み込まれていない場合はスキップ
  if respond_to?(:devise)
    devise :database_authenticatable,
           :registerable,
           :recoverable,
           :rememberable,
           :validatable
  end
end
