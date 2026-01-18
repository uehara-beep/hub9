# Railway build / assets:precompile 対策
if ENV["SECRET_KEY_BASE_DUMMY"] == "1"
  Rails.application.routes.draw do
    root "home#index"
  end
  return
end

Rails.application.routes.draw do
  devise_for :users
  root "home#index"
end
