#!/bin/bash

# 資料保護日誌監控腳本

set -e

# 設定變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REDMINE_CONTAINER="redmine_606-redmine-1"
ALERT_THRESHOLD=1000  # 超過 1000 條記錄時發出警告

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 記錄函數
log_message() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

# 檢查 Docker 容器狀態
check_container() {
    if ! docker ps | grep -q "$REDMINE_CONTAINER"; then
        log_error "Redmine 容器未運行: $REDMINE_CONTAINER"
        return 1
    fi
    log_success "Redmine 容器運行正常"
    return 0
}

# 獲取資料庫記錄統計
get_db_stats() {
    log_message "檢查資料庫記錄統計..."
    
    if ! check_container; then
        return 1
    fi
    
    # 執行統計查詢
    STATS=$(docker exec "$REDMINE_CONTAINER" bundle exec rake data_protection_guard:statistics 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "$STATS"
        
        # 提取總記錄數
        TOTAL_RECORDS=$(echo "$STATS" | grep "總記錄數" | grep -o '[0-9]*' | head -1)
        
        if [ -n "$TOTAL_RECORDS" ] && [ "$TOTAL_RECORDS" -gt "$ALERT_THRESHOLD" ]; then
            log_warning "資料庫記錄數過多: $TOTAL_RECORDS (閾值: $ALERT_THRESHOLD)"
            return 1
        else
            log_success "資料庫記錄數正常: $TOTAL_RECORDS"
        fi
    else
        log_error "無法獲取資料庫統計"
        return 1
    fi
}

# 檢查磁碟空間
check_disk_space() {
    log_message "檢查磁碟空間..."
    
    # 檢查 Docker 日誌大小
    DOCKER_LOGS_SIZE=$(docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}" | grep "Logs" | awk '{print $3}')
    
    if [ -n "$DOCKER_LOGS_SIZE" ]; then
        echo "Docker 日誌大小: $DOCKER_LOGS_SIZE"
        
        # 提取數字部分（MB）
        LOGS_SIZE_MB=$(echo "$DOCKER_LOGS_SIZE" | sed 's/[^0-9.]//g')
        
        if [ -n "$LOGS_SIZE_MB" ] && [ "$(echo "$LOGS_SIZE_MB > 500" | bc -l 2>/dev/null || echo "0")" = "1" ]; then
            log_warning "Docker 日誌大小過大: ${LOGS_SIZE_MB}MB"
        else
            log_success "Docker 日誌大小正常: ${LOGS_SIZE_MB}MB"
        fi
    fi
    
    # 檢查系統磁碟空間
    DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 80 ]; then
        log_warning "磁碟使用率過高: ${DISK_USAGE}%"
    else
        log_success "磁碟使用率正常: ${DISK_USAGE}%"
    fi
}

# 檢查最近的違規記錄
check_recent_violations() {
    log_message "檢查最近的違規記錄..."
    
    if ! check_container; then
        return 1
    fi
    
    # 獲取最近 24 小時的違規記錄
    RECENT_COUNT=$(docker exec "$REDMINE_CONTAINER" bundle exec rails runner "
        count = DataProtectionViolation.where('created_at > ?', 24.hours.ago).count
        puts count
    " 2>/dev/null)
    
    if [ -n "$RECENT_COUNT" ]; then
        echo "最近 24 小時違規記錄: $RECENT_COUNT"
        
        if [ "$RECENT_COUNT" -gt 100 ]; then
            log_warning "最近 24 小時違規記錄過多: $RECENT_COUNT"
        else
            log_success "最近 24 小時違規記錄正常: $RECENT_COUNT"
        fi
    else
        log_error "無法獲取最近違規記錄"
    fi
}

# 檢查清理任務狀態
check_cleanup_status() {
    log_message "檢查清理任務狀態..."
    
    # 檢查 Cron 任務
    if crontab -l 2>/dev/null | grep -q "cleanup_all_logs.sh"; then
        log_success "自動清理 Cron 任務已設定"
    else
        log_warning "自動清理 Cron 任務未設定"
    fi
    
    # 檢查清理腳本
    if [ -f "$SCRIPT_DIR/cleanup_all_logs.sh" ]; then
        log_success "清理腳本存在"
    else
        log_error "清理腳本不存在"
    fi
}

# 主函數
main() {
    echo "🔍 資料保護日誌監控報告"
    echo "================================"
    echo ""
    
    # 執行各項檢查
    check_container
    echo ""
    
    get_db_stats
    echo ""
    
    check_disk_space
    echo ""
    
    check_recent_violations
    echo ""
    
    check_cleanup_status
    echo ""
    
    echo "================================"
    echo "✅ 監控檢查完成"
}

# 執行主函數
main "$@"
