# Data Protection Guard Plugin for Redmine

[![Ruby](https://img.shields.io/badge/Ruby-2.7+-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-6.0+-green.svg)](https://rubyonrails.org/)
[![Redmine](https://img.shields.io/badge/Redmine-6.0+-blue.svg)](https://www.redmine.org/)
[![License](https://img.shields.io/badge/License-GPL%20v2-orange.svg)](https://www.gnu.org/licenses/gpl-2.0.html)

## 📋 概述

Data Protection Guard 是一個 Redmine 插件，用於防止機敏資料與個人資料的提交與儲存。該插件會自動檢查 Issue、Journal 和 Attachment 中的內容，偵測並阻止包含機敏資訊或個人資料的提交。

## ✨ 功能特色

### 🔒 機敏資料偵測
- FTP/SFTP/SSH 帳號與密碼
- 伺服器或系統 IP 位址
- 資料庫帳號與密碼
- API Key、Token、憑證檔
- 內部網域名稱、伺服器路徑
- 私鑰和憑證內容

### 👤 個人資料偵測
- 姓名、身分證號、護照號碼
- 電話號碼、電子郵件、住址
- 銀行帳號、信用卡號
- 出生日期
- 台灣地區地址

### 🛡️ 核心功能
- 自動驗證提交內容
- 可設定阻擋或僅記錄違規
- 詳細的違規日誌記錄
- 支援排除特定欄位和專案
- 正則表達式測試工具
- CSV 匯出功能

## 👨‍💻 作者

**Jason Liu** ([GitHub: @bluer1211](https://github.com/bluer1211))

## 🚀 快速開始

### 安裝

1. **下載插件**
   ```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/bluer1211/data_protection_guard.git data_protection_guard
   ```

2. **執行安裝**
   ```bash
   cd /path/to/redmine
   ./plugins/data_protection_guard/install.sh
   ```

3. **重新啟動 Redmine**
   ```bash
   # 停止 Redmine 服務
   sudo systemctl stop redmine
   
   # 重新啟動
   sudo systemctl start redmine
   ```

### 配置

1. 登入管理員帳號
2. 進入 **管理** → **資料保護**
3. 啟用所需功能：
   - ✅ 啟用機敏資料偵測
   - ✅ 啟用個人資料偵測
   - ✅ 阻擋違規提交
   - ✅ 記錄違規事件

## 📖 詳細文件

- [📋 安裝指南](INSTALL.md)
- [🔧 部署檢查清單](DEPLOYMENT_CHECKLIST.md)
- [📊 初始化報告](INITIALIZATION_REPORT.md)

## 🧪 測試

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

## ⚙️ 配置範例

### 基本設定
```yaml
enable_sensitive_data_detection: true
enable_personal_data_detection: true
block_submission: true
log_violations: true
```

### 偵測規則範例
```yaml
sensitive_patterns:
  - 'ftp://[^\\s]+'
  - '\\b(?:password|pwd|passwd)\\s*[:=]\\s*[^\\s]+'
  - '\\b(?:api_key|api_token|access_token|secret_key)\\s*[:=]\\s*[^\\s]+'

personal_patterns:
  - '\\b[A-Z][a-z]+\\s+[A-Z][a-z]+\\b'
  - '\\b[A-Z]\\d{9}\\b'
  - '\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b'
```

## 📊 測試結果

| 測試項目 | 狀態 | 結果 |
|----------|------|------|
| 機敏資料偵測 | ✅ | 6/6 測試通過 |
| 個人資料偵測 | ✅ | 6/6 測試通過 |
| 綜合功能測試 | ✅ | 100% 通過 |
| 正則表達式驗證 | ✅ | 7/7 測試通過 |

**總成功率：100% (26/26 測試通過)**

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

### 開發環境設置
1. Fork 本專案
2. 創建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交變更 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

## 📄 授權

本專案採用 [GNU General Public License v2.0](LICENSE) 授權。

## 🆘 支援

- 📧 問題回報：[GitHub Issues](https://github.com/bluer1211/data_protection_guard/issues)
- 📖 文件：[Wiki](https://github.com/bluer1211/data_protection_guard/wiki)
- 💬 討論：[GitHub Discussions](https://github.com/bluer1211/data_protection_guard/discussions)

## 🙏 致謝

感謝所有貢獻者和 Redmine 社群的支持！

---

**⭐ 如果這個專案對您有幫助，請給我們一個星標！**
