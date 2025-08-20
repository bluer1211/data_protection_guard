# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  resources :data_protection, only: [] do
    collection do
      get :settings
      post :settings
      post :load_defaults
      get :logs
      post :clear_logs
      get :log_statistics
      post :test_pattern
    end
  end
end
