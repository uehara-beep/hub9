Rails.application.routes.draw do
  root "hub#index"
  get  "/hub", to: "hub#index"
  post "/hub/send", to: "hub#send_message"

  namespace :vault do
    resources :entries, only: [:index, :new, :create, :show, :destroy]
  end
  get "/vault", to: "vault#index"
  get "/vault/home", to: "vault#home"
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
  end
  unless ENV["SECRET_KEY_BASE_DUMMY"]
    devise_for :users
  end
end
