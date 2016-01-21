Rails.application.routes.draw do
  #root to: "top#index"
  root to: "articles#index"

  resources :articles do
    member do
      delete :rm_hatena
    end
  end
  resources :keywords do
    member do
      put :to_active
      put :to_inactive
    end
  end
  resources :animations do
    member do
      put :post_article
    end
  end
end
