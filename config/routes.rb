Rails.application.routes.draw do
  root "hub#index"
  get  "/hub", to: "hub#index"
  post "/hub/send", to: "hub#send_message"

  namespace :vault do
    resources :entries, only: [:index, :new, :create, :show, :destroy]
  end
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
end
