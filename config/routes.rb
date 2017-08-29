Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'abnormals#index'
  get "welcome" => "welcome#index"
  resources :abnormals do
    collection do
      get :download_excel
      post :import
      post :check_reason
      get :word_cloud
    end
  end
  resources :form_options do
    member do
      post :delete_item
    end
  end
end
