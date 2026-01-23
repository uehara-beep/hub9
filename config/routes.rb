Rails.application.routes.draw do
  get "/vault", to: "vault#index"
  get "/vault/home", to: "vault#home"
  namespace :api do
    get "health", to: "health#index"
    post "chat", to: "chat#create"
    post "vault/unlock", to: "vault#unlock"
  end
  unless ENV["SECRET_KEY_BASE_DUMMY"]
    devise_for :users
  end
  root "home#index"
end
