# frozen_string_literal: true

# Redmine Data Protection Guard Plugin
# Copyright (C) 2024
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'redmine'

Redmine::Plugin.register :data_protection_guard do
  name 'Data Protection Guard'
  author 'Jason Liu (GitHub: @bluer1211)'
  description '防止機敏資料與個人資料的提交與儲存'
  version '1.0.7'
  url 'https://github.com/bluer1211/data_protection_guard'
  author_url 'https://github.com/bluer1211'

  # 設定權限
  project_module :data_protection do
    permission :view_data_protection_logs, { data_protection: [:logs] }
    permission :manage_data_protection_settings, { data_protection: [:load_defaults, :test_pattern] }
  end

  # 添加日誌選單
  menu :admin_menu, :data_protection_logs, { controller: 'data_protection', action: 'logs' }, 
       caption: :label_data_protection_logs, html: { class: 'icon icon-report' }

  # 設定
  settings default: {
    'enable_sensitive_data_detection' => true,
    'enable_personal_data_detection' => true,
    'block_submission' => true,
    'log_violations' => false,
    'log_to_database' => true,
    'auto_cleanup_days' => 30,
    'sensitive_patterns' => [
      # 網路協議連接字串
      '(?:ftp|sftp|ssh)://[^\\s]+',
      
      # 認證資訊
      '\\b(?:password|pwd|passwd|api_key|api_token|access_token|secret_key)\\s*[:=]\\s*[^\\s]+',
      
      # 私有網路位址
      '\\b(?:192\\.168\\.|10\\.|172\\.(?:1[6-9]|2[0-9]|3[0-1])\\.)\\d+\\.\\d+\\b',
      '\\b(?:localhost|127\\.0\\.0\\.1)\\b',
      
      # 系統管理員帳號
      '\\b(?:root@|admin@)[^\\s]+',
      
      # 資料庫連接字串
      '\\b(?:mysql|postgresql|mongodb)://[^\\s]+',
      
      # 加密憑證
      '\\b(?:BEGIN|END)\\s+(?:RSA|DSA|EC)\\s+PRIVATE KEY\\b',
      '\\b(?:BEGIN|END)\\s+CERTIFICATE\\b'
    ],
    'personal_patterns' => [
      # 身分證號（台灣格式）
      '(?<![A-Za-z0-9])[A-Z][1-2]\\d{8}(?![A-Za-z0-9])',
      
      # 電子郵件地址
      '(?<![A-Za-z0-9._%+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}(?![A-Za-z0-9._%+-])',
      
      # 台灣手機號碼（排除身分證號）
      '(?<!\\d)09\\d{2}-?\\d{3}-?\\d{3}(?!\\d)'
    ],
    'excluded_fields' => ['tracker_id', 'status_id', 'priority_id'],  # notes 欄位沒有被排除，應該被檢查
    'excluded_projects' => []
  }, partial: 'settings/data_protection_settings'
end

# 載入核心模組
require_relative 'lib/data_protection_guard'
require_relative 'lib/sensitive_data_validator'
require_relative 'lib/personal_data_validator'
require_relative 'lib/data_protection_logger'

# 載入控制器
require_relative 'app/controllers/data_protection_controller'

# 擴展模型和控制器 - 使用新的 Extensions 命名約定
Rails.application.config.after_initialize do
  Issue.include Extensions::Issue if defined?(Issue)
  Journal.include Extensions::Journal if defined?(Journal)
  Attachment.include Extensions::Attachment if defined?(Attachment)
  IssuesController.include Extensions::IssuesController if defined?(IssuesController)
  
  # 設定 DataProtectionViolation 類別別名
  DataProtectionViolation = Extensions::DataProtectionViolation
end
