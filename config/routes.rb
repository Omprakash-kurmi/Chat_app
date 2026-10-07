Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  mount ActionCable.server => "/cable"

  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # root to: "devise/registrations#new"
  root to: "pages#home"
  get "/pages/:slug", to: "pages#show", as: :page
  resource :profile, only: [ :show, :edit, :update ]
  resources :rooms, only: [ :index, :show, :new, :create ] do
    resources :messages, only: [ :create ]
    resources :events, only: [ :index, :new, :create, :destroy ] do
      resources :rsvps, only: [ :create, :update ]
      collection do
        get :calendar
      end
    end
  end

  get "search_home", to: "properties#choose", as: :search_home
  get "homes/:listing_type", to: "properties#index", as: :homes,
      constraints: { listing_type: /rent|buy/ }

  resources :properties, only: :show do
    resources :inquiries, only: :create                    # send an inquiry
    resource  :favorite,  only: %i[create destroy]         # ♥ save / unsave
  end

  resources :inquiries, only: %i[index show] do
    member do
      patch :accept
      patch :reject
      patch :withdraw
      patch :close_deal
    end
    resources :messages, controller: "inquiry_messages", only: :create
    resources :visits, only: :create
  end

  resources :visits, only: [] do
    member do
      patch :confirm
      patch :decline
      patch :cancel
      patch :complete
    end
  end

  namespace :vendor do
    resources :properties, except: :show do
      member { patch :reopen }
    end
  end

  resources :favorites, only: :index
  resources :saved_searches, only: %i[index create update destroy]
  resources :notifications, only: :index do
    collection { patch :read_all }
    member     { patch :read }
  end
end
