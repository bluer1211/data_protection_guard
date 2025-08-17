# 設定類型處理修復報告

## 問題描述

**日期**: 2025-08-15  
**問題**: 訪問 `http://localhost:3003/issues/2` 時出現內部錯誤：

```
NoMethodError (undefined method `each_with_index' for an instance of String)
```

**錯誤位置**: `plugins/data_protection_guard/lib/data_protection_guard.rb:66:in `scan_sensitive_data'`

## 根本原因分析

### 問題分析
錯誤發生在 `scan_sensitive_data` 方法中，當嘗試對 `sensitive_patterns` 調用 `each_with_index` 方法時失敗。

### 根本原因
Redmine 的設定系統可能將陣列設定值轉換為字串格式，導致：
- `sensitive_patterns` 被當作字串而不是陣列
- `personal_patterns` 被當作字串而不是陣列  
- `excluded_fields` 被當作字串而不是陣列
- `excluded_projects` 被當作字串而不是陣列

## 修復方案

### 1. 修復 `sensitive_patterns` 方法
```ruby
def sensitive_patterns
  patterns = Setting.plugin_data_protection_guard['sensitive_patterns']
  return [] if patterns.nil?
  
  # 確保返回陣列
  if patterns.is_a?(Array)
    patterns
  elsif patterns.is_a?(String)
    patterns.split("\n").map(&:strip).reject(&:empty?)
  else
    []
  end
end
```

### 2. 修復 `personal_patterns` 方法
```ruby
def personal_patterns
  patterns = Setting.plugin_data_protection_guard['personal_patterns']
  return [] if patterns.nil?
  
  # 確保返回陣列
  if patterns.is_a?(Array)
    patterns
  elsif patterns.is_a?(String)
    patterns.split("\n").map(&:strip).reject(&:empty?)
  else
    []
  end
end
```

### 3. 修復 `excluded_fields` 方法
```ruby
def excluded_fields
  fields = Setting.plugin_data_protection_guard['excluded_fields']
  return [] if fields.nil?
  
  # 確保返回陣列
  if fields.is_a?(Array)
    fields
  elsif fields.is_a?(String)
    fields.split(",").map(&:strip).reject(&:empty?)
  else
    []
  end
end
```

### 4. 修復 `excluded_projects` 方法
```ruby
def excluded_projects
  projects = Setting.plugin_data_protection_guard['excluded_projects']
  return [] if projects.nil?
  
  # 確保返回陣列
  if projects.is_a?(Array)
    projects
  elsif projects.is_a?(String)
    projects.split(",").map(&:strip).reject(&:empty?)
  else
    []
  end
end
```

## 修復邏輯

### 陣列處理
- 如果設定值已經是陣列，直接返回
- 如果設定值是字串，根據內容類型進行分割：
  - 正則表達式模式：按換行符分割（`\n`）
  - 排除欄位/專案：按逗號分割（`,`）
- 清理空白字元並移除空項目
- 如果設定值為 nil 或其他類型，返回空陣列

### 容錯處理
- 處理 nil 值
- 處理非預期類型
- 確保始終返回陣列類型

## 測試驗證

### 修復前
```ruby
# 錯誤：嘗試對字串調用 each_with_index
sensitive_patterns.each_with_index do |pattern, index|
  # 這裡會拋出 NoMethodError
end
```

### 修復後
```ruby
# 正確：對陣列調用 each_with_index
sensitive_patterns.each_with_index do |pattern, index|
  # 正常工作
end
```

### 測試結果
```bash
測試設定處理:
sensitive_patterns 類型: Array
personal_patterns 類型: Array
excluded_fields 類型: Array
excluded_projects 類型: Array

測試個人資料偵測:
偵測到 1 個違規
  - A123456789
```

## 影響範圍

### 正面影響
1. **錯誤修復**: 解決了 `each_with_index` 方法調用錯誤
2. **相容性提升**: 支援不同格式的設定值
3. **穩定性增強**: 增加了容錯處理機制
4. **功能恢復**: Issue 編輯功能恢復正常

### 潛在影響
1. **向後相容**: 修復是向後相容的，不會影響現有功能
2. **效能**: 新增的類型檢查對效能影響很小

## 相關檔案

### 修改的檔案
- `lib/data_protection_guard.rb` - 修復設定值類型處理

### 測試檔案
- 無（使用 Rails runner 進行測試）

## 結論

修復成功解決了設定類型處理問題。現在插件可以正確處理不同格式的設定值，確保所有功能正常工作。

**修復狀態**: ✅ 完成  
**測試狀態**: ✅ 通過  
**部署狀態**: ✅ 就緒

### 驗證清單
- ✅ Issue 編輯功能正常
- ✅ 個人資料偵測功能正常
- ✅ 機敏資料偵測功能正常
- ✅ 設定值正確處理
- ✅ 錯誤處理機制正常
