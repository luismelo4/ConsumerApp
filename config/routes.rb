
Rails.application.routes.draw do
  resources :products, only: [:index, :show] do
    collection do
      post :upload_file
      get :search
    end
  end
end  
