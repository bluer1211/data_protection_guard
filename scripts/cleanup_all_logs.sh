#!/bin/bash

# 資料保護日誌完整清理腳本
# 清理資料庫記錄和日誌檔案

set -e

# 設定變數
REDMINE_PATH="/usr/src/redmine"
CLEANUP_DAYS=${1:-30}
LOG_FILE="/var/log/data_protection_cleanup.log"

# 記錄函數
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 開始清理
log_message "開始執行資料保護日誌清理任務"

# 1. 清理資料庫記錄
log_message "步驟 1: 清理資料庫記錄（${CLEANUP_DAYS} 天前）"
cd "$REDMINE_PATH"
if bundle exec rake "data_protection_guard:clear_old_logs[${CLEANUP_DAYS}]"; then
    log_message "資料庫記錄清理完成"
else
    log_message "錯誤: 資料庫記錄清理失敗"
    exit 1
fi

# 2. 清理 Docker 日誌
log_message "步驟 2: 清理 Docker 日誌"
if docker system prune -f; then
    log_message "Docker 日誌清理完成"
else
    log_message "警告: Docker 日誌清理失敗"
fi

# 3. 清理系統日誌（如果權限允許）
log_message "步驟 3: 清理系統日誌"
if command -v journalctl >/dev/null 2>&1; then
    if sudo journalctl --vacuum-time="${CLEANUP_DAYS}d" 2>/dev/null; then
        log_message "系統日誌清理完成"
    else
        log_message "警告: 系統日誌清理失敗（可能需要 sudo 權限）"
    fi
else
    log_message "跳過系統日誌清理（journalctl 不可用）"
fi

# 4. 顯示清理後統計
log_message "步驟 4: 顯示清理後統計"
if bundle exec rake data_protection_guard:statistics; then
    log_message "統計資訊顯示完成"
else
    log_message "警告: 統計資訊顯示失敗"
fi

# 5. 檢查磁碟空間
log_message "步驟 5: 檢查磁碟空間"
df -h | grep -E "(Filesystem|/dev/)" | tee -a "$LOG_FILE"

log_message "資料保護日誌清理任務完成"

# 清理舊的日誌檔案（保留最近 30 天）
find /var/log -name "data_protection_cleanup.log" -mtime +30 -delete 2>/dev/null || true

exit 0
