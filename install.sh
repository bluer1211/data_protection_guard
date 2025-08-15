#!/bin/bash

# Data Protection Guard Plugin 安裝腳本
# 適用於 Redmine 6.0+

set -e

echo "🚀 開始安裝 Data Protection Guard Plugin..."

# 檢查是否在 Redmine 根目錄
if [ ! -f "config/application.rb" ]; then
    echo "❌ 錯誤：請在 Redmine 根目錄執行此腳本"
    exit 1
fi

# 檢查插件目錄
PLUGIN_DIR="plugins/data_protection_guard"
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "❌ 錯誤：找不到插件目錄 $PLUGIN_DIR"
    exit 1
fi

echo "✅ 檢查環境..."

# 檢查 Ruby 版本
RUBY_VERSION=$(ruby -v | cut -d' ' -f2 | cut -d'p' -f1)
echo "📦 Ruby 版本: $RUBY_VERSION"

# 檢查 Rails 版本
RAILS_VERSION=$(bundle exec rails -v | cut -d' ' -f2)
echo "📦 Rails 版本: $RAILS_VERSION"

# 執行資料庫遷移
echo "🗄️  執行資料庫遷移..."
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# 清理快取
echo "🧹 清理快取..."
bundle exec rake tmp:clear RAILS_ENV=production

# 重新啟動應用程式
echo "🔄 重新啟動應用程式..."
echo "請手動重新啟動您的 Redmine 應用程式"

echo ""
echo "✅ 安裝完成！"
echo ""
echo "📋 後續步驟："
echo "1. 重新啟動 Redmine 應用程式"
echo "2. 登入管理員帳號"
echo "3. 進入 管理 → 資料保護 設定頁面"
echo "4. 啟用插件並設定偵測規則"
echo "5. 測試機敏資料偵測功能"
echo ""
echo "📖 詳細文件請參考 README.md"
