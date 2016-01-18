Rails.application.routes.draw do
  root to: "articles#index"

  resources :articles
  resources :keywords
  resources :animations do
    member do
      put :post_article
    end

  end
end
