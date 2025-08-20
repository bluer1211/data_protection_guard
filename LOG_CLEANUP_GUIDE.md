# 資料保護日誌清理指南

## 📋 概述

本指南說明如何使用 Data Protection Guard 插件的日誌清理功能，包括資料庫記錄清理、日誌檔案清理和統計分析。

## ⚠️ 重要說明

**定期清理功能對不同記錄類型的影響**：

- ✅ **資料庫記錄**: 完全有效，直接清理資料庫表格
- ❌ **日誌檔案記錄**: 無效，需要額外設定系統日誌清理

## 🧹 清理功能類型

### 1. 資料庫記錄清理（插件功能）

#### 手動清理

#### 透過管理介面
1. 進入 **管理** → **資料保護日誌**
2. 點擊 **清除日誌** 按鈕
3. 選擇清理類型：
   - **全部記錄**: 清理所有類型的舊記錄
   - **機敏資料**: 只清理機敏資料記錄
   - **個人資料**: 只清理個人資料記錄
   - **特定使用者**: 清理特定使用者的記錄
4. 設定清理天數（預設 30 天）
5. 確認執行

#### 透過 Rake 任務
```bash
# 清理 30 天前的所有記錄
bundle exec rake data_protection_guard:clear_old_logs[30]

# 清理 60 天前的機敏資料記錄
bundle exec rake data_protection_guard:clear_logs_by_type[sensitive_data,60]

# 清理 45 天前的個人資料記錄
bundle exec rake data_protection_guard:clear_logs_by_type[personal_data,45]

# 顯示統計資訊
bundle exec rake data_protection_guard:statistics
```

#### 自動清理

#### 設定自動清理
1. 進入 **管理** → **資料保護設定**
2. 設定 **自動清理天數**（預設 30 天）
3. 儲存設定

#### 設定 Cron 任務
```bash
# 編輯 crontab
crontab -e

# 添加每日凌晨 2 點執行自動清理
0 2 * * * cd /path/to/redmine && bundle exec rake data_protection_guard:auto_clean

# 或者每週日凌晨 3 點執行
0 3 * * 0 cd /path/to/redmine && bundle exec rake data_protection_guard:auto_clean
```

#### Docker 環境的 Cron 設定
```yaml
# docker-compose.yml
services:
  redmine:
    # ... 其他設定 ...
    command: >
      sh -c "
        echo '0 2 * * * cd /usr/src/redmine && bundle exec rake data_protection_guard:auto_clean' >> /etc/crontab &&
        cron &&
        /docker-entrypoint.sh rails server -b 0.0.0.0
      "
```

## 📊 統計分析

### 查看統計資訊
```bash
# 命令列查看
bundle exec rake data_protection_guard:statistics

# 輸出範例：
=== 資料保護日誌統計 ===
總記錄數: 1250
機敏資料記錄: 450
個人資料記錄: 800
今日記錄: 15
本週記錄: 89
本月記錄: 234
最早記錄: 2025-01-15 10:30:00
最新記錄: 2025-08-20 14:25:30
```

### 透過管理介面
1. 進入 **管理** → **資料保護日誌**
2. 查看統計資訊和最近記錄

## ⚙️ 最佳實踐

### 1. 清理策略建議

| 環境類型 | 清理頻率 | 保留天數 | 說明 |
|----------|----------|----------|------|
| **開發環境** | 每週 | 7 天 | 快速清理，節省空間 |
| **測試環境** | 每週 | 14 天 | 保留較長時間用於測試 |
| **生產環境** | 每日 | 30 天 | 平衡儲存空間和審計需求 |
| **高安全性** | 每日 | 90 天 | 保留更長時間用於合規 |

### 2. 清理前備份
```bash
# 備份清理前的記錄
bundle exec rake data_protection_guard:statistics > backup_$(date +%Y%m%d).txt

# 或者匯出 CSV
# 透過管理介面匯出 CSV 檔案
```

### 3. 監控清理效果
```bash
# 清理前後比較
echo "清理前統計："
bundle exec rake data_protection_guard:statistics

# 執行清理
bundle exec rake data_protection_guard:clear_old_logs[30]

echo "清理後統計："
bundle exec rake data_protection_guard:statistics
```

## 🔧 故障排除

### 1. 清理失敗
```bash
# 檢查資料庫連接
bundle exec rake db:migrate:status

# 檢查插件狀態
bundle exec rake redmine:plugins:status
```

### 2. 權限問題
```bash
# 確保 Redmine 用戶有寫入權限
chown -R redmine:redmine /path/to/redmine
chmod -R 755 /path/to/redmine
```

### 3. 日誌檔案過大
```bash
# 檢查日誌檔案大小
du -sh /path/to/redmine/log/*

# 清理舊日誌檔案
find /path/to/redmine/log -name "*.log" -mtime +30 -delete
```

## 📝 注意事項

1. **不可逆操作**: 清理操作無法復原，請謹慎執行
2. **備份建議**: 清理前建議備份重要記錄
3. **效能考量**: 大量記錄清理可能影響系統效能
4. **合規要求**: 確保清理策略符合組織的合規要求
5. **監控建議**: 定期檢查清理任務是否正常執行

## 🎯 建議配置

### 生產環境推薦設定
```yaml
# 設定檔建議
auto_cleanup_days: 30          # 保留 30 天
log_to_database: true          # 啟用資料庫記錄
log_violations: true           # 啟用日誌檔案記錄

# Cron 任務
0 2 * * * cd /path/to/redmine && bundle exec rake data_protection_guard:auto_clean
```

---

**最後更新**: 2025-08-20  
**版本**: v1.0.2
