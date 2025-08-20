# 資料保護日誌清理執行計劃

## 📋 執行計劃概述

本計劃提供完整的資料保護日誌管理解決方案，包括自動清理、監控和維護。

## 🚀 執行步驟

### 步驟 1: 基礎設定（立即執行）

#### 1.1 重啟 Docker 服務以套用日誌輪轉設定
```bash
# 重啟 Docker Compose 服務
docker-compose down
docker-compose up -d

# 確認服務狀態
docker-compose ps
```

#### 1.2 測試清理功能
```bash
# 測試完整清理腳本
./redmine/plugins/data_protection_guard/scripts/cleanup_all_logs.sh 1

# 測試監控腳本
./redmine/plugins/data_protection_guard/scripts/monitor_logs.sh
```

### 步驟 2: 自動化設定（建議執行）

#### 2.1 設定 Cron 任務
```bash
# 執行 Cron 設定腳本
./redmine/plugins/data_protection_guard/scripts/setup_cron.sh
```

#### 2.2 驗證 Cron 任務
```bash
# 查看設定的 Cron 任務
crontab -l

# 檢查 Cron 服務狀態
sudo systemctl status cron
```

### 步驟 3: 監控設定（可選）

#### 3.1 設定定期監控
```bash
# 添加監控 Cron 任務（每小時執行一次）
echo "0 * * * * /path/to/redmine/plugins/data_protection_guard/scripts/monitor_logs.sh >> /var/log/data_protection_monitor.log 2>&1" | crontab -
```

#### 3.2 設定警報通知（可選）
```bash
# 創建警報腳本
cat > /usr/local/bin/data_protection_alert.sh << 'EOF'
#!/bin/bash
# 當記錄數超過閾值時發送通知
# 可以整合到現有的監控系統中
EOF
chmod +x /usr/local/bin/data_protection_alert.sh
```

## 📊 執行時間表

| 任務 | 頻率 | 時間 | 工具 |
|------|------|------|------|
| **資料庫記錄清理** | 每日 | 凌晨 3:00 | Rake 任務 |
| **完整清理** | 每週 | 週日凌晨 2:00 | 完整清理腳本 |
| **系統監控** | 每小時 | 整點 | 監控腳本 |
| **日誌輪轉** | 自動 | 超過 50MB | Docker 設定 |

## 🔧 維護任務

### 每月維護
```bash
# 1. 檢查清理效果
./redmine/plugins/data_protection_guard/scripts/monitor_logs.sh

# 2. 檢查磁碟空間
df -h

# 3. 檢查 Docker 日誌大小
docker system df

# 4. 備份重要設定
cp /etc/crontab /etc/crontab.backup.$(date +%Y%m%d)
```

### 每季維護
```bash
# 1. 更新清理腳本
git pull origin main

# 2. 檢查效能
docker exec redmine_606-redmine-1 bundle exec rake data_protection_guard:statistics

# 3. 調整清理策略（如需要）
# 根據實際使用情況調整清理頻率和保留天數
```

## ⚠️ 注意事項

### 重要提醒
1. **備份**: 執行清理前確保重要資料已備份
2. **測試**: 在生產環境執行前先在測試環境驗證
3. **監控**: 定期檢查清理任務的執行狀態
4. **調整**: 根據實際使用情況調整清理策略

### 故障排除
```bash
# 檢查 Cron 任務執行狀態
tail -f /var/log/data_protection_cron.log

# 檢查監控日誌
tail -f /var/log/data_protection_monitor.log

# 手動執行清理測試
./redmine/plugins/data_protection_guard/scripts/cleanup_all_logs.sh 1
```

## 📈 效能指標

### 監控指標
- **資料庫記錄數**: 目標 < 1000 條
- **Docker 日誌大小**: 目標 < 500MB
- **磁碟使用率**: 目標 < 80%
- **清理執行時間**: 目標 < 5 分鐘

### 警報閾值
- **記錄數警告**: > 1000 條
- **日誌大小警告**: > 500MB
- **磁碟使用警告**: > 80%
- **清理失敗**: 任何清理任務失敗

## 🎯 成功標準

### 短期目標（1 週內）
- [ ] Docker 日誌輪轉正常運作
- [ ] 自動清理任務成功執行
- [ ] 監控腳本正常運作
- [ ] 無清理相關錯誤

### 中期目標（1 個月內）
- [ ] 資料庫記錄數穩定在 < 1000 條
- [ ] Docker 日誌大小穩定在 < 500MB
- [ ] 清理任務執行時間 < 5 分鐘
- [ ] 無手動干預需求

### 長期目標（3 個月內）
- [ ] 完全自動化運作
- [ ] 效能指標達標
- [ ] 維護成本最小化
- [ ] 系統穩定性提升

## 📞 支援聯絡

如有問題或需要協助，請聯絡：
- **開發者**: Jason Liu (GitHub: @bluer1211)
- **GitHub 專案**: https://github.com/bluer1211/data_protection_guard
- **問題回報**: https://github.com/bluer1211/data_protection_guard/issues

---

**最後更新**: 2025-08-20  
**版本**: v1.0.3  
**狀態**: 準備執行
