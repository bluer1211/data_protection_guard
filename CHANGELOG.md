# 變更日誌

## [1.0.0] - 2024-12-19

### 新增功能
- 初始版本發布
- 機敏資料偵測功能
  - FTP/SFTP/SSH 帳號與密碼偵測
  - 伺服器 IP 位址偵測
  - 資料庫連線資訊偵測
  - API Key、Token、憑證檔偵測
  - 內部網域名稱偵測
  - 私鑰和憑證內容偵測

- 個人資料偵測功能
  - 台灣身分證號偵測
  - 護照號碼偵測
  - 信用卡號偵測
  - 銀行帳號偵測
  - 電話號碼偵測
  - 電子郵件偵測
  - 出生日期偵測
  - 台灣地址偵測

- 核心功能
  - 自動驗證 Issue、Journal、Attachment 內容
  - 可設定阻擋或僅記錄違規
  - 詳細的違規日誌記錄
  - 支援排除特定欄位和專案
  - 正則表達式測試工具
  - CSV 匯出功能

- 管理介面
  - 完整的設定頁面
  - 違規日誌查看
  - 日誌篩選和搜尋
  - 日誌清理功能

- 技術架構
  - 模組化設計
  - 可擴展的驗證器系統
  - 資料庫支援
  - 完整的測試覆蓋

### 技術特色
- 支援 Redmine 6.0.6+
- 繁體中文介面
- 效能優化（檔案大小限制、排除設定）
- 安全性考量（不儲存實際機敏資料）
- 完整的文件說明

### 檔案結構
```
data_protection_guard/
├── init.rb                          # 插件初始化
├── README.md                        # 主要說明文件
├── INSTALL.md                       # 安裝指南
├── CHANGELOG.md                     # 變更日誌
├── app/
│   ├── controllers/
│   │   └── data_protection_controller.rb
│   ├── models/
│   │   ├── issue.rb
│   │   ├── journal.rb
│   │   ├── attachment.rb
│   │   └── data_protection_violation.rb
│   └── views/
│       ├── data_protection/
│       │   └── logs.html.erb
│       └── settings/
│           └── _data_protection_settings.html.erb
├── config/
│   ├── locales/
│   │   └── zh-TW.yml
│   ├── routes.rb
│   └── example_settings.yml
├── db/
│   └── migrate/
│       └── 001_create_data_protection_violations.rb
├── lib/
│   ├── data_protection_guard.rb
│   ├── data_protection_logger.rb
│   ├── sensitive_data_validator.rb
│   └── personal_data_validator.rb
└── test/
    └── test_data_protection_guard.rb
```

### 已知限制
- 僅支援文字檔案內容檢查
- 檔案大小限制為 1MB
- 需要管理員權限進行設定

### 未來計劃
- 支援更多檔案格式
- 增加自定義規則編輯器
- 支援批次檢查現有資料
- 增加統計報表功能
- 支援多語言介面
