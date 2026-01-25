Rails.application.routes.draw do
  # Auth routes
  get    "/login",  to: "auth#login",  as: :login
  post   "/login",  to: "auth#create"
  delete "/logout", to: "auth#logout", as: :logout

  root "hub#index"
  get  "/hub", to: "hub#index"
  post "/hub/send", to: "hub#send_message"

  namespace :vault do
    resources :entries, only: [:index, :new, :create, :show, :destroy]
    get  "transfer", to: "transfers#new"
    post "transfer", to: "transfers#create"
  end
  get "/vault", to: "vault#index"
  post "/vault/unlock", to: "vault#unlock"
  get "/vault/home", to: "vault#home"
  get "/vault/money", to: "vault#money"
  post "/vault/money", to: "vault#money_create"
  # Notifications
  get "/notifications", to: "notifications#index"
  get "/notifications/:id/read", to: "notifications#read", as: :read_notification

  namespace :api do
    get "health", to: "health#index"
    post "chat", to: "chat#create"
    post "vault/unlock", to: "vault#unlock"
    post "ocr/receipt", to: "ocr#receipt"
    post "ocr/business_card", to: "ocr#business_card"
    post "vault/wipe_all", to: "vault_admin#wipe_all"
    post "vault/ocr/:id", to: "vault_ocr#create", as: :vault_ocr
  end
  unless ENV["SECRET_KEY_BASE_DUMMY"]
    devise_for :users
  end
end
