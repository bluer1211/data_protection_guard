# Data Protection Guard Plugin Git 管理指南

## 概述

本文件說明如何使用 Git 來管理 Data Protection Guard Plugin 的版本控制和開發流程。

## Git 倉庫狀態

### 當前狀態
- **分支**: main
- **最後提交**: a09cd1d - 初始化 Redmine 資料保護外掛程式
- **遠端倉庫**: 未設定
- **修改檔案**: 14 個已修改，25 個未追蹤

### 檔案狀態
```
已修改檔案 (14):
- DEPLOYMENT_CHECKLIST.md
- README.md
- app/controllers/data_protection_controller.rb
- app/views/settings/_data_protection_settings.html.erb
- config/example_settings.yml
- config/locales/zh-TW.yml
- config/routes.rb
- init.rb
- lib/data_protection_guard.rb
- lib/data_protection_logger.rb
- lib/extensions/attachment.rb
- lib/extensions/data_protection_violation.rb
- lib/extensions/issue.rb
- lib/extensions/journal.rb

未追蹤檔案 (25):
- BLOCKING_BEHAVIOR_DEPLOYMENT_GUIDE.md
- FORM_RETENTION_VERIFICATION.md
- INITIALIZATION_STATUS.md
- INIT_CHECKLIST.md
- NOTES_DETECTION_FIX_SUMMARY.md
- NOTES_FIELD_FIX_REPORT.md
- ROUTE_FIX_REPORT.md
- SETTINGS_FIX_REPORT.md
- SETTINGS_TYPE_FIX_REPORT.md
- TESTING_SUMMARY.md
- TEST_CHECKLIST.md
- TEST_REPORT.md
- TRANSLATION_FIX_REPORT.md
- ZEITWERK_FIX_REPORT.md
- fix_notes_detection.rb
- lib/data_protection_guard.rb.backup
- lib/extensions/issues_controller.rb
- quick_test.rb
- test_blocking_behavior.rb
- test_complete_blocking_flow.rb
- test_current_functionality.rb
- test_form_retention.rb
- test_integration.rb
- test_notes_detection.rb
- test_redmine_controller_behavior.rb
- test_standalone.rb
- verify_notes_fix.rb
```

## Git 工作流程

### 1. 日常開發流程

```bash
# 檢查狀態
git status

# 查看修改
git diff

# 添加修改的檔案
git add <filename>

# 或添加所有修改
git add .

# 提交修改
git commit -m "描述修改內容"

# 推送到遠端倉庫
git push origin main
```

### 2. 分支管理

```bash
# 創建新功能分支
git checkout -b feature/new-feature

# 切換分支
git checkout main

# 合併分支
git merge feature/new-feature

# 刪除分支
git branch -d feature/new-feature
```

### 3. 版本標籤

```bash
# 創建版本標籤
git tag -a v1.0.0 -m "版本 1.0.0 發布"

# 推送標籤
git push origin v1.0.0

# 查看所有標籤
git tag -l
```

## 檔案分類管理

### 核心檔案 (必須追蹤)
- `init.rb` - 插件初始化檔案
- `lib/` - 核心程式碼
- `app/` - 控制器和視圖
- `config/` - 配置檔案
- `db/` - 資料庫遷移檔案

### 文檔檔案 (建議追蹤)
- `README.md` - 主要說明文件
- `*.md` - 各種說明和報告文件
- `INSTALL.md` - 安裝指南
- `CHANGELOG.md` - 更新日誌

### 測試檔案 (可選追蹤)
- `test/` - 測試檔案
- `spec/` - 規格測試檔案
- `*_test.rb` - 測試腳本

### 忽略檔案 (不追蹤)
- `*.log` - 日誌檔案
- `*.backup` - 備份檔案
- `tmp/` - 暫存檔案
- `.DS_Store` - 系統檔案

## 提交訊息規範

### 格式
```
類型(範圍): 簡短描述

詳細描述（可選）

相關問題: #123
```

### 類型
- `feat`: 新功能
- `fix`: 錯誤修復
- `docs`: 文檔更新
- `style`: 程式碼格式調整
- `refactor`: 重構
- `test`: 測試相關
- `chore`: 建置或輔助工具變動

### 範例
```
feat(detection): 新增信用卡號偵測功能

- 新增信用卡號正則表達式
- 更新個人資料偵測規則
- 新增相關測試案例

相關問題: #45
```

## 遠端倉庫設定

### 添加遠端倉庫
```bash
# GitHub
git remote add origin https://github.com/username/data_protection_guard.git

# GitLab
git remote add origin https://gitlab.com/username/data_protection_guard.git

# 自建 Git 伺服器
git remote add origin git@your-server.com:username/data_protection_guard.git
```

### 推送設定
```bash
# 設定上游分支
git push -u origin main

# 後續推送
git push
```

## 版本發布流程

### 1. 準備發布
```bash
# 確保所有修改已提交
git status

# 更新版本號
# 編輯 init.rb 中的 version 欄位

# 更新 CHANGELOG.md
```

### 2. 創建發布標籤
```bash
# 創建標籤
git tag -a v1.0.0 -m "版本 1.0.0 發布"

# 推送標籤
git push origin v1.0.0
```

### 3. 發布後清理
```bash
# 更新版本號為開發版本
# 例如: 1.0.1-dev

# 提交版本更新
git add init.rb
git commit -m "bump version to 1.0.1-dev"
git push
```

## 故障排除

### 常見問題

#### 1. 合併衝突
```bash
# 查看衝突檔案
git status

# 解決衝突後
git add <resolved-files>
git commit -m "解決合併衝突"
```

#### 2. 撤銷提交
```bash
# 撤銷最後一次提交
git reset --soft HEAD~1

# 撤銷到特定提交
git reset --hard <commit-hash>
```

#### 3. 恢復檔案
```bash
# 恢復特定檔案
git checkout HEAD -- <filename>

# 恢復所有檔案
git checkout HEAD -- .
```

## 最佳實踐

### 1. 定期提交
- 每完成一個功能就提交
- 提交訊息要清楚描述修改內容
- 避免一次提交太多不相關的修改

### 2. 分支管理
- 使用功能分支進行開發
- 保持 main 分支的穩定性
- 定期清理已合併的分支

### 3. 文檔維護
- 及時更新 README.md
- 記錄重要的修改和決策
- 維護完整的 CHANGELOG.md

### 4. 測試
- 提交前確保測試通過
- 新增功能時要包含測試
- 定期執行完整的測試套件

---

## 下一步行動

1. **設定遠端倉庫**
   ```bash
   git remote add origin <repository-url>
   git push -u origin main
   ```

2. **提交當前修改**
   ```bash
   git add .
   git commit -m "feat: 完成插件初始化和功能驗證"
   git push origin main
   ```

3. **創建版本標籤**
   ```bash
   git tag -a v1.0.0 -m "版本 1.0.0 發布"
   git push origin v1.0.0
   ```

4. **設定持續整合**
   - 配置 GitHub Actions 或 GitLab CI
   - 設定自動測試和部署
   - 配置程式碼品質檢查
