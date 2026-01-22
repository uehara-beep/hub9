Rails.application.routes.draw do
  namespace :api do
    get "health", to: "health#index"
    post "chat", to: "chat#create"
  end
  unless ENV["SECRET_KEY_BASE_DUMMY"]
    devise_for :users
  end
  root "home#index"
end
