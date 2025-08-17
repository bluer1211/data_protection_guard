# 阻擋行為部署指南

## 概述

本指南說明如何部署和測試 Data Protection Guard 插件的阻擋行為功能，確保在偵測到個人資料時：
- 留在原頁面
- 保留原值
- 顯示阻擋訊息

## 部署步驟

### 1. 檔案部署

確保以下檔案已正確部署：

```bash
# 核心檔案
redmine/plugins/data_protection_guard/init.rb
redmine/plugins/data_protection_guard/lib/data_protection_guard.rb
redmine/plugins/data_protection_guard/lib/extensions/journal.rb
redmine/plugins/data_protection_guard/lib/extensions/issue.rb
redmine/plugins/data_protection_guard/lib/extensions/issues_controller.rb

# 測試檔案
redmine/plugins/data_protection_guard/test_blocking_behavior.rb
redmine/plugins/data_protection_guard/test_redmine_controller_behavior.rb
redmine/plugins/data_protection_guard/test_complete_blocking_flow.rb
```

### 2. 重新啟動服務

```bash
# 重新啟動 Redmine 服務
docker-compose restart redmine

# 或者如果使用其他部署方式
sudo systemctl restart redmine
# 或
sudo service redmine restart
```

### 3. 驗證插件載入

檢查 Redmine 日誌確認插件正確載入：

```bash
# 查看 Redmine 日誌
docker-compose logs redmine

# 或檢查應用程式日誌
tail -f /var/log/redmine/production.log
```

應該看到類似以下的訊息：
```
Data Protection Guard Plugin 已載入
IssuesController 擴展已載入
```

## 測試步驟

### 1. 執行測試腳本

在插件目錄中執行測試腳本：

```bash
cd redmine/plugins/data_protection_guard

# 執行基本阻擋行為測試
ruby test_blocking_behavior.rb

# 執行控制器行為測試
ruby test_redmine_controller_behavior.rb

# 執行完整流程測試
ruby test_complete_blocking_flow.rb
```

### 2. 實際環境測試

#### 測試案例 1: 筆記欄位個人資料偵測

1. **開啟編輯頁面**
   ```
   http://localhost:3003/issues/2/edit
   ```

2. **輸入測試內容**
   在筆記欄位輸入：
   ```
   用戶身分證號是 A123456789，請處理這個問題
   ```

3. **點擊提交按鈕**

4. **預期結果**
   - ✅ 頁面停留在編輯頁面
   - ✅ 表單值保留
   - ✅ 顯示錯誤訊息
   - ✅ 個人資料被正確偵測

#### 測試案例 2: 多個個人資料偵測

1. **輸入複雜內容**
   在筆記欄位輸入：
   ```
   用戶資料：身分證號 A123456789，信用卡號 1234-5678-9012-3456，電子郵件 test@example.com
   ```

2. **點擊提交按鈕**

3. **預期結果**
   - ✅ 頁面停留在編輯頁面
   - ✅ 表單值保留
   - ✅ 顯示包含所有違規的錯誤訊息
   - ✅ 所有個人資料被正確偵測

#### 測試案例 3: 正常內容通過

1. **輸入正常內容**
   在筆記欄位輸入：
   ```
   這是一個正常的筆記內容，不包含個人資料
   ```

2. **點擊提交按鈕**

3. **預期結果**
   - ✅ 提交成功
   - ✅ 重定向到問題頁面
   - ✅ 顯示成功訊息

## 驗證檢查清單

### 功能驗證

- [ ] 個人資料偵測功能正常
- [ ] 阻擋提交功能正常
- [ ] 錯誤訊息正確顯示
- [ ] 頁面正確停留在原位置
- [ ] 表單值正確保留
- [ ] Flash 訊息正確顯示

### 使用者體驗驗證

- [ ] 錯誤訊息清楚易懂
- [ ] 使用者知道問題所在
- [ ] 使用者不需要重新輸入其他欄位
- [ ] 使用者可以修正後重新提交
- [ ] 頁面載入速度正常

### 技術驗證

- [ ] 控制器擴展正確載入
- [ ] 模型驗證正確執行
- [ ] 日誌記錄正常
- [ ] 效能影響可接受
- [ ] 沒有 JavaScript 錯誤

## 故障排除

### 常見問題

#### 1. 插件未載入

**症狀**: 個人資料偵測不工作

**解決方案**:
```bash
# 檢查插件目錄權限
ls -la redmine/plugins/data_protection_guard/

# 檢查 init.rb 檔案
cat redmine/plugins/data_protection_guard/init.rb

# 重新啟動服務
docker-compose restart redmine
```

#### 2. 控制器擴展未載入

**症狀**: 阻擋後頁面行為不正確

**解決方案**:
```bash
# 檢查 IssuesController 擴展
grep -r "IssuesController" redmine/plugins/data_protection_guard/

# 檢查 Rails 日誌
docker-compose logs redmine | grep "IssuesController"
```

#### 3. 正則表達式問題

**症狀**: 身分證號無法偵測

**解決方案**:
```bash
# 檢查正則表達式設定
grep -A 5 -B 5 "personal_patterns" redmine/plugins/data_protection_guard/init.rb

# 執行測試腳本
ruby test_notes_detection.rb
```

#### 4. 設定問題

**症狀**: 功能未啟用

**解決方案**:
1. 進入 Redmine 管理介面
2. 前往「管理」→「插件」→「Data Protection Guard」
3. 確認以下設定：
   - ✅ 啟用個人資料偵測
   - ✅ 啟用機敏資料偵測
   - ✅ 阻擋提交
   - ✅ 日誌記錄

### 日誌檢查

檢查相關日誌以診斷問題：

```bash
# Redmine 應用程式日誌
docker-compose logs redmine

# 資料保護日誌（如果啟用）
tail -f /var/log/redmine/data_protection.log

# Rails 日誌
tail -f /var/log/redmine/production.log
```

## 效能監控

### 監控指標

- **回應時間**: 確保頁面載入時間正常
- **記憶體使用**: 監控記憶體使用量
- **資料庫查詢**: 檢查是否有額外的資料庫查詢
- **錯誤率**: 監控錯誤發生率

### 效能測試

```bash
# 執行效能測試腳本
ruby test_performance.rb

# 或使用 Apache Bench
ab -n 100 -c 10 http://localhost:3003/issues/2/edit
```

## 回滾方案

如果部署後發現問題，可以快速回滾：

```bash
# 1. 備份當前設定
cp redmine/plugins/data_protection_guard/init.rb redmine/plugins/data_protection_guard/init.rb.backup

# 2. 恢復備份
cp redmine/plugins/data_protection_guard/init.rb.backup redmine/plugins/data_protection_guard/init.rb

# 3. 重新啟動服務
docker-compose restart redmine
```

## 後續維護

### 定期檢查

- 每月檢查功能正常性
- 每季檢查效能表現
- 定期更新偵測規則
- 監控使用者回饋

### 更新維護

- 監控插件更新
- 測試新版本相容性
- 準備更新流程
- 維護測試腳本

---

**部署完成日期**: ___________  
**部署人員**: ___________  
**驗證人員**: ___________  
**部署狀態**: ___________
