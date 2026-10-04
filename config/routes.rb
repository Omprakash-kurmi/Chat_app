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
end
