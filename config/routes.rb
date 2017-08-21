Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'abnormals#index'

  resources :abnormals do
    collection do
      get :download_excel
    end
  end
  resources :form_options do
    member do
      post :delete_item
    end
  end
end
