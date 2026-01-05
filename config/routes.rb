Rails.application.routes.draw do
  # Authentication
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  # Dashboard (authenticated home)
  resource :dashboard, only: :show

  # Medical Folders
  resources :medical_folders do
    resources :documents
    resources :shareable_links, only: %i[create destroy]
  end

  # Public shared folder access (no auth required)
  get "shared/:token", to: "public/folders#show", as: :shared_folder

  # Landing page
  root "home#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
