Rails.application.routes.draw do
  devise_for :users, only: []

  root "home#index"

  resources :applications do
    get "raw", on: :collection, as: "raw"
  end
  resources :initial_reviews, only: [:index] do
    collection do
      get "review_one"  # Route for getting next application to review
    end
    member do
      get "create_pending"  # Route for creating pending review
    end
  end
  get "initial_reviews/review/:id", to: "initial_reviews#review", as: "review_application"
  post "initial_reviews/submit/:id", to: "initial_reviews#submit", as: "submit_review"
  resources :link, only: [:index, :create]
  resources :documents, only: [:new, :create]

  # Login routes
  resources :logins, only: [:new, :create, :destroy]
  get "logins", to: "logins#show", as: "login_with_token"  # For handling ?token=xyz

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
