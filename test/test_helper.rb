# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require File.expand_path('../../../../config/environment', __FILE__)
require 'rails/test_help'

# 載入測試支援檔案
Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

class ActiveSupport::TestCase
  # 設定測試資料庫
  self.use_transactional_tests = true
  
  # 包含測試輔助方法
  include FactoryBot::Syntax::Methods if defined?(FactoryBot)
  
  # 清理測試資料
  def teardown
    super
    # 清理插件設定
    Setting.plugin_data_protection_guard = nil
  end
  
  # 建立測試使用者
  def create_test_user(attributes = {})
    User.create!({
      login: "testuser#{rand(1000)}",
      firstname: 'Test',
      lastname: 'User',
      mail: "test#{rand(1000)}@example.com",
      password: 'password123',
      password_confirmation: 'password123'
    }.merge(attributes))
  end
  
  # 建立測試專案
  def create_test_project(attributes = {})
    Project.create!({
      name: "Test Project #{rand(1000)}",
      identifier: "test-project-#{rand(1000)}"
    }.merge(attributes))
  end
  
  # 建立測試 Issue
  def create_test_issue(attributes = {})
    project = attributes[:project] || create_test_project
    Issue.create!({
      project: project,
      subject: "Test Issue #{rand(1000)}",
      description: "Test description",
      author: attributes[:author] || create_test_user,
      tracker: Tracker.first || Tracker.create!(name: 'Bug')
    }.merge(attributes))
  end
end
