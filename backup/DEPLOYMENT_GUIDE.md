# Data Protection Guard Plugin - 完整部署指南

## 部署概述

**版本**: 1.0.6  
**最後更新**: 2025-08-17  
**部署類型**: 生產環境部署  
**相容性**: Redmine 6.0.6, Ruby 3.3+, Rails 7.2+

## 部署前準備

### 1. 環境檢查清單

#### 系統要求
- [ ] Redmine 6.0.6 或更高版本
- [ ] Ruby 3.3+ 
- [ ] Rails 7.2+
- [ ] MySQL 8.0+ 或 PostgreSQL 12+
- [ ] 足夠的磁碟空間（至少 100MB）

#### 權限檢查
- [ ] 確認 plugins 目錄可寫入
- [ ] 確認 log 目錄可寫入
- [ ] 確認 tmp 目錄可寫入
- [ ] 確認資料庫連線權限

### 2. 備份準備

#### 資料備份
```bash
# 備份資料庫
mysqldump -u redmine -p redmine > redmine_backup_$(date +%Y%m%d_%H%M%S).sql

# 備份檔案
tar -czf redmine_files_backup_$(date +%Y%m%d_%H%M%S).tar.gz /path/to/redmine/files

# 備份設定
cp config/database.yml config/database.yml.backup
cp config/configuration.yml config/configuration.yml.backup
```

#### 插件備份
```bash
# 備份現有插件
cp -r plugins plugins_backup_$(date +%Y%m%d_%H%M%S)
```

## 部署步驟

### 步驟 1: 插件安裝

#### 1.1 下載插件
```bash
cd /path/to/redmine
git clone https://github.com/your-repo/data_protection_guard.git plugins/data_protection_guard
```

#### 1.2 設定權限
```bash
chmod -R 755 plugins/data_protection_guard
chown -R redmine:redmine plugins/data_protection_guard
```

#### 1.3 安裝依賴
```bash
bundle install
```

### 步驟 2: 資料庫遷移

#### 2.1 執行遷移
```bash
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

#### 2.2 驗證遷移
```bash
# 檢查資料表是否建立
bundle exec rake db:migrate:status RAILS_ENV=production
```

### 步驟 3: 重新啟動服務

#### 3.1 重啟 Redmine
```bash
# 如果使用 Passenger
touch tmp/restart.txt

# 如果使用 Puma
pkill -f puma
bundle exec puma -C config/puma.rb

# 如果使用 Docker
docker-compose restart redmine
```

#### 3.2 清除快取
```bash
bundle exec rake tmp:clear RAILS_ENV=production
bundle exec rake tmp:cache:clear RAILS_ENV=production
```

### 步驟 4: 插件配置

#### 4.1 進入管理介面
1. 登入 Redmine 管理員帳號
2. 前往「管理」→「插件」
3. 找到「Data Protection Guard」插件
4. 點擊「設定」

#### 4.2 基本設定
- [ ] **啟用個人資料偵測**: ✅
- [ ] **啟用機敏資料偵測**: ✅
- [ ] **阻擋提交**: ✅
- [ ] **記錄違規**: ✅
- [ ] **記錄到資料庫**: ✅

#### 4.3 偵測規則設定
```yaml
# 個人資料模式（已修復中文環境支援）
personal_patterns:
  - '[A-Z]\d{9}'  # 身分證號
  - '[A-Z]\d{8}'  # 護照號碼
  - '\b\d{4}-\d{4}-\d{4}-\d{4}\b'  # 信用卡號
  - '\b\d{10,16}\b'  # 銀行帳號
  - '\b\d{2,4}-\d{3,4}-\d{4}\b'  # 電話號碼
  - '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'  # 電子郵件

# 機敏資料模式
sensitive_patterns:
  - 'ftp://[^\s]+'
  - 'sftp://[^\s]+'
  - 'ssh://[^\s]+'
  - '\b(?:password|pwd|passwd)\s*[:=]\s*[^\s]+'
  - '\b(?:api_key|api_token|access_token|secret_key)\s*[:=]\s*[^\s]+'
  - '\b(?:192\.168\.|10\.|172\.(?:1[6-9]|2[0-9]|3[0-1])\.)\d+\.\d+\b'

# 排除欄位（notes 欄位未被排除）
excluded_fields:
  - tracker_id
  - status_id
  - priority_id
```

## 功能驗證

### 1. 基本功能測試

#### 1.1 個人資料偵測測試
```bash
# 執行自動化測試
cd plugins/data_protection_guard
ruby test_current_functionality.rb
```

#### 1.2 手動測試步驟
1. **訪問問題編輯頁面**: `http://your-redmine/issues/1/edit`
2. **測試身分證號偵測**:
   - 在 Notes 欄位輸入: "A123456789"
   - 點擊送出
   - 應該被阻擋並顯示錯誤訊息
3. **測試表單資料保留**:
   - 檢查 Notes 欄位是否保留原值
   - 檢查其他欄位是否正常保留

### 2. 進階功能測試

#### 2.1 新建問題測試
1. **訪問新建問題頁面**: `http://your-redmine/projects/your-project/issues/new`
2. **輸入違規內容**: 在各個欄位輸入個人資料
3. **提交測試**: 確認被阻擋並重新導向到新建頁面

#### 2.2 編輯問題測試
1. **訪問編輯頁面**: `http://your-redmine/issues/1/edit`
2. **輸入違規內容**: 在 Notes 欄位輸入個人資料
3. **提交測試**: 確認被阻擋並保留表單資料

### 3. 調試功能測試

#### 3.1 執行調試腳本
```bash
cd plugins/data_protection_guard
ruby test_notes_retention_debug.rb
```

#### 3.2 檢查日誌
```bash
# 檢查 Redmine 日誌
tail -f /path/to/redmine/log/production.log

# 檢查資料保護日誌
tail -f /path/to/redmine/log/data_protection.log
```

## 監控和維護

### 1. 效能監控

#### 1.1 系統監控
```bash
# 監控記憶體使用
free -h

# 監控磁碟使用
df -h

# 監控 CPU 使用
top
```

#### 1.2 應用程式監控
```bash
# 監控 Redmine 進程
ps aux | grep redmine

# 監控資料庫連線
mysql -u redmine -p -e "SHOW PROCESSLIST;"
```

### 2. 日誌監控

#### 2.1 設定日誌輪轉
```bash
# 編輯 logrotate 配置
sudo nano /etc/logrotate.d/redmine

# 配置內容
/path/to/redmine/log/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 redmine redmine
}
```

#### 2.2 監控關鍵日誌
```bash
# 監控錯誤日誌
tail -f /path/to/redmine/log/production.log | grep ERROR

# 監控資料保護日誌
tail -f /path/to/redmine/log/production.log | grep "Data Protection"
```

### 3. 定期維護

#### 3.1 每日檢查
- [ ] 檢查服務狀態
- [ ] 檢查日誌錯誤
- [ ] 檢查磁碟空間
- [ ] 檢查資料庫連線

#### 3.2 每週檢查
- [ ] 檢查效能指標
- [ ] 檢查使用者回饋
- [ ] 檢查安全性更新
- [ ] 備份重要資料

#### 3.3 每月檢查
- [ ] 更新偵測規則
- [ ] 檢查系統效能
- [ ] 更新文件
- [ ] 檢查備份完整性

## 故障排除

### 1. 常見問題

#### 1.1 插件無法載入
```bash
# 檢查檔案權限
ls -la plugins/data_protection_guard/

# 檢查 Ruby 語法
ruby -c plugins/data_protection_guard/init.rb

# 檢查日誌
tail -f log/production.log
```

#### 1.2 資料庫錯誤
```bash
# 檢查遷移狀態
bundle exec rake db:migrate:status RAILS_ENV=production

# 重新執行遷移
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

#### 1.3 表單資料不保留
```bash
# 檢查 session 設定
grep -r "session" config/

# 檢查 JavaScript 載入
# 在瀏覽器開發者工具中檢查 Console
```

### 2. 回滾方案

#### 2.1 快速回滾
```bash
# 停用插件
mv plugins/data_protection_guard plugins/data_protection_guard.disabled

# 重新啟動服務
touch tmp/restart.txt
```

#### 2.2 完整回滾
```bash
# 恢復備份
cp -r plugins_backup_YYYYMMDD_HHMMSS plugins/

# 恢復資料庫
mysql -u redmine -p redmine < redmine_backup_YYYYMMDD_HHMMSS.sql

# 重新啟動服務
touch tmp/restart.txt
```

## 安全考量

### 1. 資料保護
- [ ] 確保個人資料不會被記錄到日誌
- [ ] 設定適當的檔案權限
- [ ] 加密敏感設定
- [ ] 定期清理舊日誌

### 2. 存取控制
- [ ] 限制管理員存取
- [ ] 設定適當的檔案權限
- [ ] 監控異常存取
- [ ] 定期更新密碼

### 3. 監控和警報
- [ ] 設定錯誤警報
- [ ] 監控異常活動
- [ ] 定期安全掃描
- [ ] 記錄安全事件

## 文件更新

### 1. 技術文件
- [ ] 更新安裝指南
- [ ] 更新配置文件
- [ ] 更新故障排除指南
- [ ] 更新 API 文件

### 2. 使用者文件
- [ ] 更新使用者手冊
- [ ] 更新管理員手冊
- [ ] 更新常見問題
- [ ] 更新最佳實踐

### 3. 開發文件
- [ ] 更新開發指南
- [ ] 更新測試文件
- [ ] 更新貢獻指南
- [ ] 更新版本記錄

## 部署確認

### 部署檢查清單
- [ ] 插件正確安裝
- [ ] 資料庫遷移成功
- [ ] 服務正常啟動
- [ ] 基本功能測試通過
- [ ] 進階功能測試通過
- [ ] 效能測試通過
- [ ] 安全檢查通過
- [ ] 文件更新完成

### 簽署確認

**部署負責人**: _________________  
**部署日期**: _________________  
**部署環境**: _________________  
**部署狀態**: _________________  

**驗證人員**: _________________  
**驗證日期**: _________________  
**驗證結果**: _________________  

**備註**:

---

## 聯絡資訊

**技術支援**: [您的聯絡資訊]  
**文件更新**: [您的聯絡資訊]  
**問題回報**: [您的聯絡資訊]  

**版本**: 1.0.6  
**最後更新**: 2025-08-17  
**文件狀態**: 完整
