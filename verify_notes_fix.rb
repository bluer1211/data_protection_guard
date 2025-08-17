#!/usr/bin/env ruby

# 驗證筆記欄位個人資料偵測修復
# 使用方法: ruby verify_notes_fix.rb

require_relative 'lib/data_protection_guard'

puts "=== 驗證筆記欄位個人資料偵測修復 ==="
puts

# 設定測試環境
Setting.plugin_data_protection_guard = {
  'enable_sensitive_data_detection' => true,
  'enable_personal_data_detection' => true,
  'block_submission' => true,
  'log_violations' => true,
  'personal_patterns' => [
    '[A-Z]\\d{9}',  # 身分證號（修復後）
    '[A-Z]\\d{8}',  # 護照號碼（修復後）
    '\\b\\d{4}-\\d{4}-\\d{4}-\\d{4}\\b',  # 信用卡號
    '\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b',  # 電子郵件
  ],
  'excluded_fields' => ['tracker_id', 'status_id', 'priority_id'],  # notes 欄位沒有被排除
  'excluded_projects' => []
}

puts "1. 檢查設定:"
puts "   啟用狀態: #{DataProtectionGuard.enabled?}"
puts "   個人資料偵測: #{DataProtectionGuard.personal_data_detection_enabled?}"
puts "   排除欄位: #{DataProtectionGuard.excluded_fields.inspect}"
puts "   notes 欄位是否被排除: #{DataProtectionGuard.should_skip_field_validation?('notes')}"
puts "   預期結果: false (應該被檢查)"
puts

# 測試身分證號偵測
puts "2. 測試身分證號偵測（修復後）:"
test_cases = [
  "A123456789",
  "身分證號 A123456789",
  "ID: A123456789",
  "包含 A123456789 的內容",
  "A123456789 測試",
  "用戶身分證號是 A123456789"
]

all_passed = true
test_cases.each do |test_case|
  violations = DataProtectionGuard.scan_personal_data(test_case)
  puts "   測試: '#{test_case}'"
  if violations.any?
    puts "   ✅ 偵測到 #{violations.length} 個違規"
    violations.each { |v| puts "     - #{v[:match]}" }
  else
    puts "   ❌ 沒有偵測到違規"
    all_passed = false
  end
  puts
end

puts "3. 測試結果:"
if all_passed
  puts "   ✅ 所有測試都通過！身分證號偵測功能正常"
else
  puts "   ❌ 部分測試失敗，需要進一步檢查"
end
puts

# 測試其他個人資料類型
puts "4. 測試其他個人資料類型:"
other_test_cases = [
  "護照號碼 A12345678",
  "信用卡號 1234-5678-9012-3456",
  "電子郵件 test@example.com"
]

other_test_cases.each do |test_case|
  violations = DataProtectionGuard.scan_personal_data(test_case)
  puts "   測試: '#{test_case}'"
  if violations.any?
    puts "   ✅ 偵測到 #{violations.length} 個違規"
    violations.each { |v| puts "     - #{v[:match]}" }
  else
    puts "   ❌ 沒有偵測到違規"
  end
  puts
end

# 模擬 Journal 驗證
puts "5. 模擬 Journal 驗證:"
class MockJournal
  attr_accessor :notes, :id
  
  def initialize(notes = nil, id = 1)
    @notes = notes
    @id = id
  end
  
  def should_check_data_protection?
    return false unless DataProtectionGuard.enabled?
    return false if DataProtectionGuard.should_skip_validation?(self)
    notes.present?
  end
  
  def check_data_protection
    violations = []
    
    if notes.present? && !DataProtectionGuard.should_skip_field_validation?('notes')
      context = { field: 'notes', model: 'Journal', id: id }
      violations.concat(DataProtectionGuard.scan_content(notes, context))
    end
    
    violations
  end
end

# 測試 Journal 驗證
test_journals = [
  MockJournal.new("包含身分證號 A123456789 的筆記"),
  MockJournal.new("正常的筆記內容"),
  MockJournal.new("護照號碼 A12345678 和信用卡號 1234-5678-9012-3456")
]

test_journals.each_with_index do |journal, index|
  puts "   測試 Journal #{index + 1}: '#{journal.notes}'"
  if journal.should_check_data_protection?
    violations = journal.check_data_protection
    if violations.any?
      puts "   ✅ 偵測到 #{violations.length} 個違規"
      violations.each { |v| puts "     - #{v[:match]}" }
    else
      puts "   ✅ 沒有偵測到違規"
    end
  else
    puts "   ⚠️  跳過檢查"
  end
  puts
end

puts "=== 修復驗證完成 ==="
puts "如果所有測試都通過，筆記欄位的個人資料偵測功能應該已經修復。"
puts "請重新啟動 Redmine 服務以套用設定變更。"
