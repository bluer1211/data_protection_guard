#!/usr/bin/env ruby

# 修復筆記欄位個人資料偵測問題
# 問題分析：
# 1. 身分證號模式使用 \b 單詞邊界，在中文環境中可能不正確工作
# 2. 需要檢查 notes 欄位是否被正確排除
# 3. 需要驗證個人資料偵測功能是否正常工作

require_relative 'lib/data_protection_guard'

puts "=== 筆記欄位個人資料偵測問題修復 ==="
puts

# 檢查當前設定
puts "1. 檢查當前設定:"
puts "   啟用狀態: #{DataProtectionGuard.enabled?}"
puts "   個人資料偵測: #{DataProtectionGuard.personal_data_detection_enabled?}"
puts "   排除欄位: #{DataProtectionGuard.excluded_fields.inspect}"
puts "   notes 欄位是否被排除: #{DataProtectionGuard.should_skip_field_validation?('notes')}"
puts

# 測試身分證號偵測
puts "2. 測試身分證號偵測:"
test_cases = [
  "A123456789",
  "身分證號 A123456789",
  "ID: A123456789",
  "包含 A123456789 的內容",
  "A123456789 測試"
]

test_cases.each do |test_case|
  violations = DataProtectionGuard.scan_personal_data(test_case)
  puts "   測試: '#{test_case}'"
  puts "   結果: #{violations.length} 個違規"
  if violations.any?
    violations.each { |v| puts "     - #{v[:match]}" }
  else
    puts "     ❌ 沒有偵測到違規"
  end
  puts
end

# 檢查個人資料模式
puts "3. 檢查個人資料模式:"
patterns = DataProtectionGuard.personal_patterns
puts "   模式數量: #{patterns.length}"
patterns.each_with_index do |pattern, index|
  puts "   模式 #{index + 1}: #{pattern}"
end
puts

# 測試身分證號模式
puts "4. 測試身分證號模式:"
id_pattern = '\\b[A-Z]\\d{9}\\b'
puts "   當前模式: #{id_pattern}"

# 測試不同的測試案例
test_strings = [
  "A123456789",
  "身分證號 A123456789",
  "ID: A123456789",
  "包含 A123456789 的內容"
]

test_strings.each do |test_string|
  begin
    regex = Regexp.new(id_pattern, Regexp::IGNORECASE | Regexp::MULTILINE)
    matches = test_string.scan(regex)
    puts "   測試 '#{test_string}': #{matches.length} 個匹配"
    matches.each { |match| puts "     - #{match}" }
  rescue => e
    puts "   測試 '#{test_string}': 錯誤 - #{e.message}"
  end
end
puts

# 建議修復方案
puts "5. 建議修復方案:"
puts "   問題: 身分證號模式使用 \\b 單詞邊界，在中文環境中可能不正確工作"
puts "   解決方案: 修改身分證號模式，移除單詞邊界或使用更寬鬆的模式"
puts "   建議模式: '[A-Z]\\d{9}' (移除單詞邊界)"
puts

# 測試修復後的模式
puts "6. 測試修復後的模式:"
fixed_pattern = '[A-Z]\\d{9}'
puts "   修復後模式: #{fixed_pattern}"

test_strings.each do |test_string|
  begin
    regex = Regexp.new(fixed_pattern, Regexp::IGNORECASE | Regexp::MULTILINE)
    matches = test_string.scan(regex)
    puts "   測試 '#{test_string}': #{matches.length} 個匹配"
    matches.each { |match| puts "     - #{match}" }
  rescue => e
    puts "   測試 '#{test_string}': 錯誤 - #{e.message}"
  end
end
puts

puts "=== 修復建議 ==="
puts "1. 修改 init.rb 中的身分證號模式，從 '\\b[A-Z]\\d{9}\\b' 改為 '[A-Z]\\d{9}'"
puts "2. 確保 notes 欄位沒有被排除在 excluded_fields 中"
puts "3. 重新啟動 Redmine 服務以套用設定變更"
puts "4. 測試筆記欄位的個人資料偵測功能"
