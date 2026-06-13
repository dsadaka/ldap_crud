Rails.application.routes.draw do
  root 'spam_user_records#index'

  resources :spam_user_records, only: [:index, :new, :create] do
    collection do
      get :edit
      put :update
      delete :destroy
    end
  end
end