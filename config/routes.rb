Rails.application.routes.draw do
  root to: "rookie_awards#index"
  #root to: "top#index"
  #root to: "articles#index"
  
  resources :rookie_awards, only: [:index, :show]
  namespace :admin do
    resources :articles do
      collection do
        get :all_articles
      end
      member do
        post :post_hatena
        delete :rm_hatena
        delete :rm_blog
      end
    end
    resources :keywords do
      collection do
        get :inactive
      end
      member do
        put :to_active
        put :to_inactive
      end
    end
    resources :ng_words
    resources :animations do
      member do
        put :post_article
      end
    end
    resources :rookie_awards
  end
end
