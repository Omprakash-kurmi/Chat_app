Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  mount ActionCable.server => "/cable"

  resource :profile, only: [:show, :edit, :update]
  resources :rooms, only: [:index, :show, :new, :create] do
    resources :messages, only: [:create]
  end
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # root to: "devise/registrations#new"
  root to: "pages#home"
end