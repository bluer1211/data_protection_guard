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
  version '1.0.5'
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
    'block_submission' => true,  # 保留但預設啟用，不在設定頁面顯示
    'log_violations' => false,
    'log_to_database' => true,
    'auto_cleanup_days' => 30
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
