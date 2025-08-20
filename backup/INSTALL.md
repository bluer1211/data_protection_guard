# Data Protection Guard Plugin 安裝指南

## 系統需求

- Redmine 6.0.6 或更高版本
- Ruby 2.7 或更高版本
- Rails 6.0 或更高版本

## 安裝步驟

### 1. 下載插件

將插件檔案複製到 Redmine 的 plugins 目錄：

```bash
cd /path/to/redmine
cp -r data_protection_guard plugins/
```

### 2. 設定權限

確保插件目錄具有正確的權限：

```bash
chmod -R 755 plugins/data_protection_guard
```

### 3. 執行資料庫遷移

執行以下命令來創建必要的資料庫表格：

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

### 4. 重新啟動 Redmine

重新啟動 Redmine 服務：

```bash
# 如果使用 Passenger
touch tmp/restart.txt

# 如果使用其他伺服器，請重新啟動相應的服務
```

### 5. 啟用插件

1. 登入 Redmine 管理員帳號
2. 進入「管理」→「插件」
3. 找到「Data Protection Guard」插件
4. 點擊「設定」按鈕
5. 配置偵測規則和設定

## 初始設定

### 基本設定

1. **啟用機敏資料偵測**: 建議開啟
2. **啟用個人資料偵測**: 建議開啟
3. **阻擋違規提交**: 建議開啟
4. **記錄違規事件**: 建議開啟
5. **記錄到資料庫**: 可選，用於詳細分析

### 偵測規則

插件預設包含常用的偵測規則，您可以根據需要調整：

#### 機敏資料規則範例
```
ftp://[^\s]+
sftp://[^\s]+
ssh://[^\s]+
\b(?:password|pwd|passwd)\s*[:=]\s*[^\s]+
\b(?:api_key|api_token|access_token|secret_key)\s*[:=]\s*[^\s]+
\b(?:192\.168\.|10\.|172\.(?:1[6-9]|2[0-9]|3[0-1])\.)\d+\.\d+\b
```

#### 個人資料規則範例
```
\b[A-Z]\d{9}\b
\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b
\b\d{4}-\d{4}-\d{4}-\d{4}\b
```

### 排除設定

- **排除欄位**: 指定不進行檢查的欄位（如：subject, tracker_id）
- **排除專案**: 指定不進行檢查的專案識別碼

## 測試安裝

### 1. 測試機敏資料偵測

創建一個新的 Issue，在描述中輸入：
```
FTP server: ftp://user:password@192.168.1.100
```

應該會收到錯誤訊息並阻止提交。

### 2. 測試個人資料偵測

創建一個新的 Issue，在描述中輸入：
```
User ID: A123456789, Email: test@example.com
```

應該會收到錯誤訊息並阻止提交。

### 3. 測試正則表達式

使用管理介面中的測試工具來驗證正則表達式是否正確。

## 故障排除

### 常見問題

1. **插件未顯示**
   - 檢查插件目錄權限
   - 確認 init.rb 檔案存在
   - 重新啟動 Redmine

2. **資料庫錯誤**
   - 執行 `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`
   - 檢查資料庫連線

3. **正則表達式錯誤**
   - 使用測試工具驗證語法
   - 檢查特殊字元轉義

4. **效能問題**
   - 減少檔案大小限制
   - 調整排除設定
   - 檢查日誌記錄設定

### 日誌檢查

查看 Redmine 日誌檔案：
```bash
tail -f log/production.log
```

### 資料庫檢查

檢查違規記錄：
```sql
SELECT * FROM data_protection_violations ORDER BY created_at DESC LIMIT 10;
```

## 升級

### 從舊版本升級

1. 備份當前設定
2. 更新插件檔案
3. 執行資料庫遷移
4. 重新啟動 Redmine
5. 檢查設定是否正確

### 備份設定

備份插件設定：
```sql
SELECT * FROM settings WHERE name = 'plugin_data_protection_guard';
```

## 支援

如果遇到問題，請：

1. 檢查日誌檔案
2. 確認系統需求
3. 查看故障排除章節
4. 提交 Issue 到專案頁面

## 安全注意事項

1. 定期檢查違規日誌
2. 定期清理舊日誌記錄
3. 確保管理員權限控制
4. 監控系統效能影響
