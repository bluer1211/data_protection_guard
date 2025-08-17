# Data Protection Guard Plugin - Notes 欄位保留調試報告

## 問題概述

**報告日期**: 2025-08-17  
**問題版本**: 1.0.5  
**問題類型**: 功能缺陷  
**影響範圍**: Notes 欄位保留功能

## 問題描述

### 用戶報告
用戶報告 notes 欄位被阻擋後沒有保留原值，其他欄位（如 subject、description）都能正常保留。

### 問題分析

#### 可能的原因
1. **Notes 欄位不是 Issue 模型屬性**: Notes 欄位屬於 Journal 模型，不是 Issue 模型的直接屬性
2. **JavaScript 恢復機制未正確載入**: 表單恢復的 JavaScript 可能沒有被正確載入到頁面中
3. **視圖中沒有正確顯示恢復的 notes 值**: 即使資料被恢復，視圖中可能沒有正確顯示
4. **資料保存和恢復流程有問題**: 在保存或恢復過程中可能有邏輯錯誤

#### 當前實現狀況

**資料保存** (`retain_form_data`):
```ruby
def retain_form_data
  session[:issue_form_data] = {
    'issue[subject]' => params.dig(:issue, :subject),
    'issue[description]' => params.dig(:issue, :description),
    'issue[notes]' => params.dig(:issue, :notes) || params[:notes],  # ✅ 有保存
    # ... 其他欄位
  }
end
```

**資料恢復** (`restore_form_data`):
```ruby
def restore_form_data
  # ... 恢復 issue 屬性 ...
  
  # 特別處理 notes 欄位，因為它不是 Issue 模型的屬性
  if form_data['issue[notes]'].present?
    @notes = form_data['issue[notes]']  # ✅ 有設定實例變數
  end
  
  # 設定 JavaScript 來恢復表單資料
  set_form_restoration_script(form_data)  # ✅ 有設定 JavaScript
end
```

**JavaScript 恢復**:
```javascript
function restoreServerFormData(formDataJson) {
  try {
    var formData = JSON.parse(formDataJson);
    
    // 恢復表單資料
    Object.keys(formData).forEach(function(fieldName) {
      var $field = $('[name="' + fieldName + '"]');
      if ($field.length > 0) {
        $field.val(formData[fieldName]);  // ✅ 有恢復邏輯
        $field.trigger('change');
      }
    });
    
    showRestoreMessage();
    
  } catch (e) {
    console.log('Data Protection Guard: Error restoring server form data:', e);
  }
}
```

## 調試方案

### 1. 創建調試測試腳本
創建了 `test_notes_retention_debug.rb` 來調試問題：

**調試功能**:
- 自動登入 Redmine
- 提交包含違規 notes 的表單
- 檢查重新導向後的頁面內容
- 分析表單資料保留狀況
- 檢查 JavaScript 變數和腳本載入

**調試檢查項目**:
1. 各個欄位的資料保留狀況
2. JavaScript 恢復變數是否設定
3. 恢復的資料內容
4. Notes 欄位的 HTML 和值
5. 實例變數的存在狀況

### 2. 可能的解決方案

#### 方案 A: 確保 JavaScript 正確載入
- 檢查 JavaScript 檔案是否被正確載入到頁面中
- 確保 `restoredFormDataJson` 變數被正確設定
- 驗證 JavaScript 恢復函數是否被調用

#### 方案 B: 改進伺服器端恢復
- 在視圖中直接使用 `@notes` 實例變數
- 確保 notes 欄位的值被正確設定到 HTML 中
- 添加更多的調試日誌

#### 方案 C: 使用 localStorage 備用方案
- 如果伺服器端恢復失敗，使用 localStorage 作為備用
- 在表單提交前保存所有資料到 localStorage
- 在頁面載入時檢查並恢復資料

### 3. 調試步驟

#### 步驟 1: 運行調試腳本
```bash
cd /Users/jason/redmine/redmine_6.0.6/redmine/plugins/data_protection_guard
ruby test_notes_retention_debug.rb
```

#### 步驟 2: 手動驗證
1. 訪問 `http://localhost:3003/issues/1/edit`
2. 在 Notes 欄位輸入: "A123456789"
3. 點擊送出
4. 檢查是否被阻擋並重新導向
5. 檢查 Notes 欄位是否保留了原值

#### 步驟 3: 檢查瀏覽器開發者工具
1. 打開瀏覽器開發者工具
2. 檢查 Console 中的日誌訊息
3. 檢查 Network 標籤中的請求
4. 檢查 Elements 標籤中的 HTML 結構

## 技術細節

### 當前實現的資料流程
1. **表單提交** → 觸發違規偵測
2. **資料保存** → `retain_form_data` 保存到 session
3. **重新導向** → 導向編輯頁面
4. **資料恢復** → `restore_form_data` 處理恢復
5. **JavaScript 變數設定** → 設定 `restoredFormDataJson` 變數
6. **客戶端恢復** → JavaScript 檢查變數並恢復表單資料

### 可能的問題點
1. **JavaScript 載入**: 腳本可能沒有被正確載入到頁面中
2. **變數設定**: `restoredFormDataJson` 變數可能沒有被正確設定
3. **欄位選擇器**: jQuery 選擇器可能沒有找到正確的 notes 欄位
4. **時機問題**: JavaScript 可能在 DOM 完全載入前執行

## 下一步行動

### 立即行動
1. **運行調試腳本**: 執行 `test_notes_retention_debug.rb`
2. **手動測試**: 在瀏覽器中進行手動測試
3. **檢查日誌**: 查看 Redmine 和瀏覽器的日誌
4. **分析結果**: 根據調試結果確定問題根源

### 預期結果
調試腳本應該能夠：
- 確認資料是否被正確保存到 session
- 確認 JavaScript 變數是否被正確設定
- 確認 notes 欄位的 HTML 結構
- 提供詳細的調試資訊

### 後續修復
根據調試結果，將實施相應的修復方案：
1. 如果 JavaScript 載入問題 → 修復載入機制
2. 如果變數設定問題 → 修復變數設定
3. 如果欄位選擇器問題 → 修復選擇器
4. 如果時機問題 → 調整執行時機

## 相關檔案

### 調試檔案
- `test_notes_retention_debug.rb` - 調試測試腳本

### 相關文檔
- `NOTES_RETENTION_FIX_REPORT.md` - Notes 欄位保留修復報告
- `FORM_RETENTION_AND_NOTES_DETECTION_FIX_REPORT.md` - 表單保留修復報告

---

## 總結

Notes 欄位保留問題需要進一步的調試來確定根本原因。通過創建專門的調試腳本，我們可以系統性地分析問題的每個環節，找出確切的問題點，然後實施針對性的修復方案。

**調試狀態**: ⏳ 進行中  
**問題狀態**: 🔍 調查中  
**修復狀態**: ⏳ 等待調試結果
