Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resource :mfa_challenge, only: %i[new create]
  resource :reauthentication, only: %i[new create]

  root "dashboard#show"
  resource :dashboard, only: :show

  resources :vault_items, only: %i[index new create show edit update] do
    collection { post :search }
    member do
      post :archive
      post :unarchive
      post :favorite
      post :unfavorite
    end
    resource :reveal, controller: "vault_reveals", only: :create
    resource :export, controller: "vault_exports", only: :create
    resources :versions, controller: "vault_item_versions", only: :index do
      member { post :restore }
    end
  end

  resources :audit_events, only: :index

  namespace :settings do
    resource :security, controller: "security", only: %i[show update]
    resource :mfa, controller: "mfa", only: %i[show new create destroy] do
      post :regenerate_recovery_codes
    end
    resources :sessions, only: %i[index destroy]
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "ready" => "health#ready", as: :readiness_check

  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  if ENV["ERROR_PREFLIGHT_PROBE"] == "true"
    get "__error_preflight/422" => "error_probes#unprocessable_entity"
    get "__error_preflight/500" => "error_probes#internal_server_error"
  end

  if ENV["LOGGING_PREFLIGHT_PROBE"] == "true"
    post "__logging_preflight" => "logging_probes#create"
  end
end
