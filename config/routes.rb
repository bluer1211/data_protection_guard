# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  resources :data_protection, only: [] do
    collection do
      get :settings
      post :settings
      get :logs
      post :clear_logs
      post :test_pattern
    end
  end
end
