# 貢獻指南

感謝您對 Data Protection Guard Plugin 的關注！我們歡迎所有形式的貢獻。

## 🤝 如何貢獻

### 🐛 回報錯誤
如果您發現了錯誤，請：
1. 檢查現有的 [Issues](https://github.com/bluer1211/data_protection_guard/issues)
2. 使用 [錯誤回報模板](.github/ISSUE_TEMPLATE/bug_report.md)
3. 提供詳細的重現步驟和環境資訊

### 💡 建議新功能
如果您有新功能建議，請：
1. 使用 [功能建議模板](.github/ISSUE_TEMPLATE/feature_request.md)
2. 描述使用案例和預期效果
3. 討論可能的實現方案

### 🔧 提交程式碼
如果您想貢獻程式碼：

#### 開發環境設置
```bash
# 1. Fork 儲存庫
# 2. Clone 您的 fork
git clone https://github.com/YOUR_USERNAME/data_protection_guard.git

# 3. 創建功能分支
git checkout -b feature/amazing-feature

# 4. 安裝依賴
cd data_protection_guard
bundle install

# 5. 執行測試
ruby test_standalone.rb
```

#### 開發規範
- **程式碼風格**: 遵循 Ruby 慣例
- **測試覆蓋**: 新增功能需要包含測試
- **文件更新**: 更新相關文件
- **提交訊息**: 使用清晰的提交訊息

#### 提交流程
```bash
# 1. 添加變更
git add .

# 2. 提交變更
git commit -m "feat: 新增某某功能"

# 3. 推送到您的分支
git push origin feature/amazing-feature

# 4. 創建 Pull Request
```

### 📝 提交訊息格式
使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

類型：
- `feat`: 新功能
- `fix`: 錯誤修復
- `docs`: 文件更新
- `style`: 程式碼格式調整
- `refactor`: 重構
- `test`: 測試相關
- `chore`: 建置或輔助工具變更

### 🧪 測試指南
- 執行現有測試：`ruby test_standalone.rb`
- 新增測試案例
- 確保測試覆蓋率不降低

### 📖 文件貢獻
- 更新 README.md
- 改進安裝指南
- 新增使用範例
- 翻譯文件

## 🏷️ 標籤說明

### Issues 標籤
- `bug`: 錯誤回報
- `enhancement`: 功能改進
- `documentation`: 文件相關
- `good first issue`: 適合新手的問題
- `help wanted`: 需要協助
- `question`: 問題討論

### Pull Requests 標籤
- `ready for review`: 準備審查
- `work in progress`: 開發中
- `needs review`: 需要審查
- `approved`: 已批准

## 📋 審查流程

1. **創建 Pull Request**
2. **自動化測試**: CI/CD 會自動執行測試
3. **程式碼審查**: 維護者會審查程式碼
4. **討論和修改**: 根據回饋進行修改
5. **合併**: 審查通過後合併到主分支

## 🎯 貢獻者權益

- 您的貢獻會被記錄在 [CONTRIBUTORS.md](CONTRIBUTORS.md)
- 符合條件的貢獻者會被邀請成為協作者
- 重大貢獻者會被列為共同維護者

## 📞 聯絡方式

- **GitHub Issues**: [https://github.com/bluer1211/data_protection_guard/issues](https://github.com/bluer1211/data_protection_guard/issues)
- **GitHub Discussions**: [https://github.com/bluer1211/data_protection_guard/discussions](https://github.com/bluer1211/data_protection_guard/discussions)

## 📄 授權

透過提交 Pull Request，您同意您的貢獻將在 [GNU General Public License v2.0](LICENSE) 下發布。

---

感謝您的貢獻！🙏
