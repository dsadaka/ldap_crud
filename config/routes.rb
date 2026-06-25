Rails.application.routes.draw do
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
end