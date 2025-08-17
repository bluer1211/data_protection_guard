#!/bin/bash

# Data Protection Guard Plugin - 快速部署腳本
# 版本: 1.0.6
# 最後更新: 2025-08-17

set -e  # 遇到錯誤時停止執行

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查是否為 root 用戶
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "不建議使用 root 用戶執行此腳本"
        read -p "是否繼續？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 檢查系統要求
check_requirements() {
    log_info "檢查系統要求..."
    
    # 檢查 Ruby
    if ! command -v ruby &> /dev/null; then
        log_error "Ruby 未安裝"
        exit 1
    fi
    
    # 檢查 Bundler
    if ! command -v bundle &> /dev/null; then
        log_error "Bundler 未安裝"
        exit 1
    fi
    
    # 檢查 Git
    if ! command -v git &> /dev/null; then
        log_error "Git 未安裝"
        exit 1
    fi
    
    log_success "系統要求檢查通過"
}

# 備份現有資料
backup_data() {
    log_info "備份現有資料..."
    
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # 備份插件
    if [ -d "plugins/data_protection_guard" ]; then
        log_info "備份現有插件..."
        cp -r plugins/data_protection_guard "$BACKUP_DIR/"
    fi
    
    # 備份設定
    if [ -f "config/database.yml" ]; then
        log_info "備份資料庫設定..."
        cp config/database.yml "$BACKUP_DIR/"
    fi
    
    if [ -f "config/configuration.yml" ]; then
        log_info "備份應用程式設定..."
        cp config/configuration.yml "$BACKUP_DIR/"
    fi
    
    log_success "備份完成: $BACKUP_DIR"
}

# 安裝插件
install_plugin() {
    log_info "安裝 Data Protection Guard 插件..."
    
    # 創建插件目錄
    mkdir -p plugins/data_protection_guard
    
    # 複製插件檔案
    log_info "複製插件檔案..."
    cp -r . plugins/data_protection_guard/
    
    # 設定權限
    log_info "設定檔案權限..."
    chmod -R 755 plugins/data_protection_guard
    find plugins/data_protection_guard -type f -name "*.rb" -exec chmod 644 {} \;
    find plugins/data_protection_guard -type f -name "*.yml" -exec chmod 644 {} \;
    
    log_success "插件安裝完成"
}

# 執行資料庫遷移
run_migrations() {
    log_info "執行資料庫遷移..."
    
    if bundle exec rake redmine:plugins:migrate RAILS_ENV=production; then
        log_success "資料庫遷移完成"
    else
        log_error "資料庫遷移失敗"
        exit 1
    fi
}

# 清除快取
clear_cache() {
    log_info "清除快取..."
    
    bundle exec rake tmp:clear RAILS_ENV=production 2>/dev/null || true
    bundle exec rake tmp:cache:clear RAILS_ENV=production 2>/dev/null || true
    
    log_success "快取清除完成"
}

# 重新啟動服務
restart_service() {
    log_info "重新啟動服務..."
    
    # 檢查是否使用 Docker
    if [ -f "docker-compose.yml" ]; then
        log_info "檢測到 Docker 環境，重啟容器..."
        docker-compose restart redmine
    else
        # 檢查是否使用 Passenger
        if [ -d "tmp" ]; then
            log_info "使用 Passenger 重啟..."
            touch tmp/restart.txt
        else
            log_warning "無法自動重啟服務，請手動重啟"
        fi
    fi
    
    log_success "服務重啟完成"
}

# 驗證安裝
verify_installation() {
    log_info "驗證安裝..."
    
    # 檢查插件檔案
    if [ ! -f "plugins/data_protection_guard/init.rb" ]; then
        log_error "插件檔案未找到"
        exit 1
    fi
    
    # 檢查資料表
    if bundle exec rake db:migrate:status RAILS_ENV=production | grep -q "data_protection_violations"; then
        log_success "資料表檢查通過"
    else
        log_warning "資料表可能未正確建立"
    fi
    
    log_success "安裝驗證完成"
}

# 顯示後續步驟
show_next_steps() {
    echo
    log_info "部署完成！請執行以下步驟："
    echo
    echo "1. 登入 Redmine 管理介面"
    echo "2. 前往「管理」→「插件」"
    echo "3. 找到「Data Protection Guard」並點擊「設定」"
    echo "4. 配置偵測規則和設定"
    echo "5. 測試功能："
    echo "   - 訪問 http://your-redmine/issues/1/edit"
    echo "   - 在 Notes 欄位輸入: A123456789"
    echo "   - 點擊送出，應該被阻擋"
    echo "   - 檢查表單資料是否保留"
    echo
    echo "如需幫助，請查看 DEPLOYMENT_GUIDE.md"
}

# 主函數
main() {
    echo "=========================================="
    echo "Data Protection Guard Plugin 部署腳本"
    echo "版本: 1.0.6"
    echo "=========================================="
    echo
    
    # 檢查是否在 Redmine 根目錄
    if [ ! -f "config/database.yml" ]; then
        log_error "請在 Redmine 根目錄執行此腳本"
        exit 1
    fi
    
    check_root
    check_requirements
    backup_data
    install_plugin
    run_migrations
    clear_cache
    restart_service
    verify_installation
    show_next_steps
    
    log_success "部署完成！"
}

# 執行主函數
main "$@"
