# Data Protection Guard Plugin for Redmine

[![Ruby](https://img.shields.io/badge/Ruby-2.7+-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-6.0+-green.svg)](https://rubyonrails.org/)
[![Redmine](https://img.shields.io/badge/Redmine-6.0+-blue.svg)](https://www.redmine.org/)
[![License](https://img.shields.io/badge/License-GPL%20v2-orange.svg)](https://www.gnu.org/licenses/gpl-2.0.html)
[![GitHub release](https://img.shields.io/github/v/release/bluer1211/data_protection_guard.svg)](https://github.com/bluer1211/data_protection_guard/releases)
[![GitHub stars](https://img.shields.io/github/stars/bluer1211/data_protection_guard.svg)](https://github.com/bluer1211/data_protection_guard/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/bluer1211/data_protection_guard.svg)](https://github.com/bluer1211/data_protection_guard/network)
[![GitHub issues](https://img.shields.io/github/issues/bluer1211/data_protection_guard.svg)](https://github.com/bluer1211/data_protection_guard/issues)

> 🛡️ **強大的 Redmine 資料保護插件**  
> 自動偵測並防止機敏資料與個人資料的提交與儲存，保護您的 Redmine 系統安全。

## 📋 目錄

- [🎯 功能特色](#-功能特色)
- [📋 系統需求](#-系統需求)
- [🚀 安裝方法](#-安裝方法)
- [⚙️ 配置說明](#️-配置說明)
- [🧪 測試指南](#-測試指南)
- [📚 文檔](#-文檔)
- [🔧 開發指南](#-開發指南)
- [📝 變更日誌](#-變更日誌)
- [🤝 貢獻指南](#-貢獻指南)
- [📄 授權條款](#-授權條款)

## 🎯 功能特色

### 🔒 機敏資料偵測
- **網路服務憑證**: FTP/SFTP/SSH 帳號與密碼
- **伺服器資訊**: 內部 IP 位址和網域名稱
- **資料庫連線**: 資料庫帳號、密碼和連線字串
- **API 憑證**: API Key、Token、Access Token
- **加密憑證**: RSA/DSA/EC 私鑰和憑證內容
- **系統管理**: Root/Admin 帳號資訊

### 👤 個人資料偵測
- **身份識別**: 姓名、身分證號、護照號碼
- **聯絡資訊**: 電話號碼、電子郵件地址
- **金融資料**: 銀行帳號、信用卡號碼
- **地址資訊**: 台灣地區完整地址
- **個人日期**: 出生日期等個人時間資訊

### 🛡️ 核心功能
- **自動驗證**: 即時檢查 Issue、Journal、Attachment 內容
- **智慧阻擋**: 可設定阻擋或僅記錄違規事件
- **詳細日誌**: 完整的違規記錄和審計追蹤
- **靈活配置**: 支援排除特定欄位和專案
- **測試工具**: 內建正則表達式測試功能
- **資料匯出**: CSV 格式的違規記錄匯出

## 📋 系統需求

| 組件 | 最低版本 | 推薦版本 |
|------|----------|----------|
| **Redmine** | 6.0.0 | 6.0.6+ |
| **Ruby** | 2.7 | 3.3.9+ |
| **Rails** | 6.0 | 7.2.2.1+ |

## 🚀 安裝方法

### 方法一：Git 克隆安裝（推薦）

```bash
# 進入 Redmine 插件目錄
cd redmine/plugins

# 克隆插件
git clone https://github.com/bluer1211/data_protection_guard.git data_protection_guard

# 執行安裝腳本
cd /path/to/redmine
./plugins/data_protection_guard/install.sh

# 重新啟動 Redmine 服務
sudo systemctl restart redmine
```

### 方法二：手動下載安裝

1. **下載插件**
   - 前往 [Releases](https://github.com/bluer1211/data_protection_guard/releases) 頁面
   - 下載最新版本的 ZIP 檔案
   - 解壓縮到 `redmine/plugins/data_protection_guard` 目錄

2. **執行安裝**
   ```bash
   cd redmine/plugins/data_protection_guard
   chmod +x install.sh
   ./install.sh
   ```

3. **重新啟動服務**
   ```bash
   sudo systemctl restart redmine
   ```

## ⚙️ 配置說明

### 基本配置

1. **登入管理員帳號**
2. **進入設定頁面**
   - 前往「管理」→「資料保護」
   - 或直接訪問 `/settings/plugin/data_protection_guard`

3. **啟用功能**
   - ✅ 啟用機敏資料偵測
   - ✅ 啟用個人資料偵測
   - ✅ 阻擋違規提交
   - ✅ 記錄違規事件

### 進階配置

#### 偵測規則設定
```yaml
# 機敏資料偵測規則
sensitive_patterns:
  - '(?:ftp|sftp|ssh)://[^\\s]+'                    # 網路協議
  - '\\b(?:password|pwd|passwd)\\s*[:=]\\s*[^\\s]+' # 密碼
  - '\\b(?:api_key|api_token|access_token)\\s*[:=]\\s*[^\\s]+' # API 憑證
  - '\\b(?:192\\.168\\.|10\\.|172\\.(?:1[6-9]|2[0-9]|3[0-1])\\.)\\d+\\.\\d+\\b' # 私有 IP

# 個人資料偵測規則
personal_patterns:
  - '(?<![A-Za-z0-9])[A-Z][1-2]\\d{8}(?![A-Za-z0-9])' # 身分證號
  - '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}' # 電子郵件
  - '(?<!\\d)09\\d{2}-?\\d{3}-?\\d{3}(?!\\d)'         # 手機號碼
```

#### 排除設定
```yaml
# 排除特定欄位
excluded_fields:
  - 'tracker_id'
  - 'status_id'
  - 'priority_id'

# 排除特定專案
excluded_projects:
  - 'test-project'
  - 'sandbox'
```

## 🧪 測試指南

### 獨立測試
```bash
cd plugins/data_protection_guard
ruby test_standalone.rb
```

### 功能測試
```bash
# 在 Redmine 根目錄執行
bundle exec ruby -Itest plugins/data_protection_guard/test/unit/data_protection_guard_test.rb
bundle exec ruby -Itest plugins/data_protection_guard/test/integration/data_protection_integration_test.rb
```

### 測試結果

| 測試項目 | 狀態 | 結果 |
|----------|------|------|
| 機敏資料偵測 | ✅ | 6/6 測試通過 |
| 個人資料偵測 | ✅ | 6/6 測試通過 |
| 綜合功能測試 | ✅ | 100% 通過 |
| 正則表達式驗證 | ✅ | 7/7 測試通過 |

**總成功率：100% (26/26 測試通過)**

## 📚 文檔

### 主要文檔
- [📋 安裝指南](INSTALL.md) - 詳細的安裝步驟
- [🔧 部署檢查清單](GITHUB_RELEASE_CHECKLIST.md) - 部署前檢查項目
- [📊 變更日誌](CHANGELOG.md) - 完整的版本變更記錄
- [📝 發布說明](RELEASE_NOTES.md) - 各版本發布說明

### 操作指南
- [🔄 載入預設值診斷](LOAD_DEFAULTS_DIAGNOSIS.md) - 預設設定載入指南
- [🧹 日誌清理指南](LOG_CLEANUP_GUIDE.md) - 日誌檔案清理說明
- [📋 執行計劃](EXECUTION_PLAN.md) - 插件執行計劃

## 🔧 開發指南

### 開發環境設置

1. **Fork 專案**
   ```bash
   git clone https://github.com/your-username/data_protection_guard.git
   cd data_protection_guard
   ```

2. **安裝依賴**
   ```bash
   bundle install
   ```

3. **運行測試**
   ```bash
   bundle exec rake test
   ```

### 貢獻流程

1. Fork 本專案
2. 創建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交變更 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

## 📝 變更日誌

### v1.0.7 (2025-08-21)
- 🔧 修復日誌頁面連結錯誤
- 🛠️ 改善路由一致性
- 🎯 提升使用者體驗

### v1.0.6 (2024-12-XX)
- 🚀 統一設定頁面
- ✨ 新增資料庫日誌記錄
- �� 新增自動清理功能
- 🌐 完整多語言支援

### v1.0.5 (2024-XX-XX)
- 🔧 移除「未實作」標記
- ✅ 確認功能完整性

### v1.0.4 (2024-XX-XX)
- 📝 簡化個人資料偵測規則
- 🎯 精簡預設設定

### v1.0.3 (2024-XX-XX)
- 🔧 預設設定調整
- 📊 日誌記錄優化

### v1.0.2 (2024-XX-XX)
- 🚀 性能優化
- 🔧 模式優化
- 📚 新增文檔

### v1.0.0 (2024-XX-XX)
- 🎉 首次發布
- ✨ 完整功能實作

## 🤝 貢獻指南

我們歡迎所有形式的貢獻！請查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解詳細的貢獻指南。

### 貢獻方式

- 🐛 **報告 Bug**: 使用 [Issues](https://github.com/bluer1211/data_protection_guard/issues) 頁面
- 💡 **功能建議**: 開啟新的 Issue 或討論
- 🔧 **代碼貢獻**: 提交 Pull Request
- 📚 **文檔改進**: 更新文檔和說明

## 📄 授權條款

本專案採用 [GNU General Public License v2.0](LICENSE) 授權。

## 🆘 支援

### 取得協助

- **Issues**: [GitHub Issues](https://github.com/bluer1211/data_protection_guard/issues)
- **Discussions**: [GitHub Discussions](https://github.com/bluer1211/data_protection_guard/discussions)
- **Wiki**: [專案 Wiki](https://github.com/bluer1211/data_protection_guard/wiki)

### 作者

**Jason Liu** ([GitHub: @bluer1211](https://github.com/bluer1211))

## 🙏 致謝

感謝所有貢獻者和 Redmine 社群的支持！

---

<div align="center">

**如果這個專案對您有幫助，請給我們一個 ⭐️**

[![GitHub stars](https://img.shields.io/github/stars/bluer1211/data_protection_guard.svg?style=social&label=Star)](https://github.com/bluer1211/data_protection_guard/stargazers)

</div>
