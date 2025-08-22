Rails.application.routes.draw do
  get "/up", to: "rails/health#show"

  root "home#index"
  resources :images, only: [:new, :create]
end
