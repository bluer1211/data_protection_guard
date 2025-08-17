# frozen_string_literal: true

# Data Protection Guard Plugin - JavaScript 載入器
# 用於在 Redmine 中載入表單保留功能的 JavaScript

Redmine::Plugin.register :data_protection_guard do
  # 這個檔案會在 init.rb 中被載入
  # 實際的 JavaScript 載入會在 application.js 中處理
end

# 在 Redmine 的 application.js 中載入我們的 JavaScript
Rails.application.config.after_initialize do
  # 確保 JavaScript 檔案被包含在資產編譯中
  if defined?(Rails) && Rails.application
    # 這個方法會在 Redmine 的資產管道中註冊我們的 JavaScript
    # 實際的載入會在 application.js 中處理
  end
end
