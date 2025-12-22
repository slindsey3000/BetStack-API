Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # ============================================
  # PUBLIC WEB PAGES (SEO-optimized documentation)
  # ============================================
  root "pages#home"
  
  get "docs" => "pages#docs", as: :docs
  get "account" => "pages#account", as: :account
  post "account/login" => "pages#login", as: :account_login
  post "account/update" => "pages#update_profile", as: :account_update
  post "account/regenerate_key" => "pages#regenerate_key", as: :account_regenerate_key
  post "account/delete" => "pages#delete_account", as: :account_delete
  
  # SEO files (served dynamically)
  get "sitemap.xml" => "seo#sitemap", defaults: { format: :xml }
  get "llms.txt" => "seo#llms", defaults: { format: :text }

  # Public Usage Dashboard
  get "usage" => "usage#index"

  # ============================================
  # API ROUTES
  # ============================================
  namespace :api do
    namespace :v1 do
      resources :sports, only: [:index, :show]
      resources :leagues, only: [:index, :show]
      resources :events, only: [:index, :show]
      resources :lines, only: [:index] do
        collection do
          get :incomplete
        end
      end
      resources :results, only: [:index, :show]
      resources :teams, only: [:index, :show]
      resources :bookmakers, only: [:index, :show]
      resources :users, only: [:index, :show, :create, :update]
    end
  end
end
