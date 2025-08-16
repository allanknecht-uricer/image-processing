Rails.application.routes.draw do
  get "/up", to: "rails/health#show"

  root "home#index"

  get "/images/ping", to: "images#ping", defaults: { format: :json }

  post "/images", to: "images#matrix", as: :images, defaults: { format: :json }
end
