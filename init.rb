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
  version '1.0.2'
  url 'https://github.com/bluer1211/data_protection_guard'
  author_url 'https://github.com/bluer1211'

  # 設定權限
  project_module :data_protection do
    permission :view_data_protection_logs, { data_protection: [:logs] }
    permission :manage_data_protection_settings, { data_protection: [:settings] }
  end

  # 設定選單
  menu :admin_menu, :data_protection, { controller: 'data_protection', action: 'settings' }, 
       caption: :label_data_protection, html: { class: 'icon icon-security' }

  # 添加日誌選單
  menu :admin_menu, :data_protection_logs, { controller: 'data_protection', action: 'logs' }, 
       caption: :label_data_protection_logs, html: { class: 'icon icon-report' }

  # 載入 JavaScript 檔案
  # 註解掉，因為 JavaScript 檔案會通過 asset pipeline 自動載入
  # 但是我們需要確保 JavaScript 檔案被正確載入

  # 設定
  settings default: {
    'enable_sensitive_data_detection' => true,
    'enable_personal_data_detection' => true,
    'block_submission' => true,
    'log_violations' => true,
    'log_to_database' => true,
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
      
      # 信用卡號（支援空格和連字號）
      '(?<!\\d)\\d{4}[- ]?\\d{4}[- ]?\\d{4}[- ]?\\d{4}(?!\\d)',
      
      # 台灣手機號碼（排除身分證號）
      '(?<!\\d)09\\d{2}-?\\d{3}-?\\d{3}(?!\\d)',
      
      # 銀行帳號（排除手機號碼和身分證號）
      '(?<!\\d)(?!09\\d{8})(?!\\d{10})\\d{6,14}(?!\\d)',
      
      # 姓名（英文格式）
      '\\b[A-Z][a-z]+\\s+[A-Z][a-z]+\\b',
      
      # 護照號碼（排除身分證號格式）
      '(?<![A-Z])[A-Z](?!\\d{8}[1-2])\\d{8}(?![A-Za-z0-9])',
      
      # 市話號碼（排除手機號碼）
      '\\b(?!09\\d{8})\\d{2,4}-\\d{3,4}-\\d{4}\\b',
      
      # 出生日期
      '\\b\\d{4}-\\d{2}-\\d{2}\\b',
      
      # 台灣地址
      '\\b(?:台北市|新北市|桃園市|台中市|台南市|高雄市|基隆市|新竹市|新竹縣|苗栗縣|彰化縣|南投縣|雲林縣|嘉義市|嘉義縣|屏東縣|宜蘭縣|花蓮縣|台東縣|澎湖縣|金門縣|連江縣)[^\\s]*\\b'
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
