#!/bin/bash

# 設定資料保護日誌自動清理 Cron 任務

set -e

# 設定變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP_SCRIPT="$SCRIPT_DIR/cleanup_all_logs.sh"
CRON_LOG="/var/log/data_protection_cron.log"

# 檢查腳本是否存在
if [ ! -f "$CLEANUP_SCRIPT" ]; then
    echo "錯誤: 清理腳本不存在: $CLEANUP_SCRIPT"
    exit 1
fi

# 確保腳本可執行
chmod +x "$CLEANUP_SCRIPT"

echo "設定資料保護日誌自動清理 Cron 任務..."

# 檢查是否已有相同的 Cron 任務
if crontab -l 2>/dev/null | grep -q "cleanup_all_logs.sh"; then
    echo "警告: 已存在清理腳本的 Cron 任務"
    echo "現有的 Cron 任務:"
    crontab -l | grep "cleanup_all_logs.sh"
    echo ""
    read -p "是否要移除現有任務並重新設定？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 移除現有的清理任務
        (crontab -l 2>/dev/null | grep -v "cleanup_all_logs.sh") | crontab -
        echo "已移除現有的清理任務"
    else
        echo "取消設定"
        exit 0
    fi
fi

# 建立臨時 Cron 檔案
TEMP_CRON=$(mktemp)

# 讀取現有的 Cron 任務
crontab -l 2>/dev/null > "$TEMP_CRON" || true

# 添加新的清理任務
cat >> "$TEMP_CRON" << EOF

# 資料保護日誌自動清理任務
# 每週日凌晨 2 點執行完整清理（保留 30 天）
0 2 * * 0 $CLEANUP_SCRIPT 30 >> $CRON_LOG 2>&1

# 每日凌晨 3 點執行資料庫記錄清理（保留 7 天）
0 3 * * * docker exec redmine_606-redmine-1 bundle exec rake "data_protection_guard:clear_old_logs[7]" >> $CRON_LOG 2>&1

EOF

# 安裝新的 Cron 任務
crontab "$TEMP_CRON"

# 清理臨時檔案
rm "$TEMP_CRON"

echo "✅ Cron 任務設定完成！"
echo ""
echo "📋 已設定的任務:"
echo "  - 每週日凌晨 2 點: 完整清理（30 天）"
echo "  - 每日凌晨 3 點: 資料庫記錄清理（7 天）"
echo ""
echo "📝 日誌檔案: $CRON_LOG"
echo ""
echo "🔍 查看 Cron 任務:"
crontab -l | grep -A 2 -B 2 "cleanup_all_logs.sh"

echo ""
echo "🧪 測試腳本執行:"
echo "  $CLEANUP_SCRIPT 1"
