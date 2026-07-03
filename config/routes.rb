Rails.application.routes.draw do

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get  "login",  to: "sessions#new",     as: :login
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
  
  root 'spam_user_records#index'

  resources :spam_user_records, only: [:index, :new, :create] do
    collection do
      get :edit
      put :update, as: :update
      delete :destroy, as: :destroy
    end
  end

  resources :customers
end