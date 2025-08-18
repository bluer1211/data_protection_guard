# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class DataProtectionGuardTest < ActiveSupport::TestCase
  def setup
    # 設定測試環境 - 使用更完整的規則
    Setting.plugin_data_protection_guard = {
      'enable_sensitive_data_detection' => true,
      'enable_personal_data_detection' => true,
      'block_submission' => true,
      'log_violations' => true,
      'log_to_database' => true,
      'sensitive_patterns' => [
        'ftp://[^\\s]+',
        'sftp://[^\\s]+',
        'ssh://[^\\s]+',
        '\\b(?:password|pwd|passwd)\\s*[:=]\\s*[^\\s]+',
        '\\b(?:api_key|api_token|access_token|secret_key)\\s*[:=]\\s*[^\\s]+',
        '\\b(?:192\\.168\\.|10\\.|172\\.(?:1[6-9]|2[0-9]|3[0-1])\\.)\\d+\\.\\d+\\b',
        '\\b(?:localhost|127\\.0\\.0\\.1)\\b',
        '\\b(?:root@|admin@)[^\\s]+',
        '\\b(?:mysql|postgresql|mongodb)://[^\\s]+',
        '\\b(?:BEGIN|END)\\s+(?:RSA|DSA|EC)\\s+PRIVATE KEY\\b',
        '\\b(?:BEGIN|END)\\s+CERTIFICATE\\b',
        '\\b[A-Za-z0-9+/]{40,}={0,2}\\b',  # Base64 編碼的密鑰
        '\\b[A-Fa-f0-9]{32,}\\b',  # MD5/SHA 雜湊
        '\\b(?:AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY)\\s*[:=]\\s*[^\\s]+',
        '\\b(?:DATABASE_URL|REDIS_URL|MONGODB_URL)\\s*[:=]\\s*[^\\s]+'
      ],
      'personal_patterns' => [
        '\\b[A-Z][a-z]+\\s+[A-Z][a-z]+\\b',
        '[A-Z]\\d{9}',
        '[A-Z]\\d{8}',
        '\\b\\d{4}-\\d{4}-\\d{4}-\\d{4}\\b',
        '\\b\\d{10,16}\\b',
        '\\b\\d{2,4}-\\d{3,4}-\\d{4}\\b',
        '\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b',
        '\\b\\d{4}-\\d{2}-\\d{2}\\b',
        '\\b(?:台北市|新北市|桃園市|台中市|台南市|高雄市|基隆市|新竹市|新竹縣|苗栗縣|彰化縣|南投縣|雲林縣|嘉義市|嘉義縣|屏東縣|宜蘭縣|花蓮縣|台東縣|澎湖縣|金門縣|連江縣)[^\\s]*\\b',
        '\\b\\d{3}-\\d{2}-\\d{4}\\b',  # 美國 SSN
        '\\b[A-Z]{2}\\d{2}\\s?\\d{4}\\s?\\d{4}\\s?\\d{4}\\s?\\d{4}\\b',  # 英國銀行帳號
        '\\b\\d{1,2}/\\d{1,2}/\\d{4}\\b'  # 日期格式
      ],
      'excluded_fields' => ['subject', 'tracker_id', 'status_id'],
      'excluded_projects' => ['test-project']
    }
  end

  # 基本功能測試
  def test_enabled?
    assert DataProtectionGuard.enabled?
  end

  def test_sensitive_data_detection_enabled?
    assert DataProtectionGuard.sensitive_data_detection_enabled?
  end

  def test_personal_data_detection_enabled?
    assert DataProtectionGuard.personal_data_detection_enabled?
  end

  def test_block_submission?
    assert DataProtectionGuard.block_submission?
  end

  def test_log_violations?
    assert DataProtectionGuard.log_violations?
  end

  # 機敏資料掃描測試
  def test_scan_sensitive_data_basic
    content = "Here is my password: secret123 and ftp://user:pass@server.com"
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    assert_equal 2, violations.length
    assert_equal 'sensitive_data', violations.first[:type]
    assert_equal 'high', violations.first[:severity]
  end

  def test_scan_sensitive_data_comprehensive
    content = <<~CONTENT
      資料庫連線：mysql://root:password123@192.168.1.100:3306/mydb
      API 金鑰：api_key: sk-1234567890abcdef
      SSH 連線：ssh://admin@10.0.0.1:22
      私鑰：-----BEGIN RSA PRIVATE KEY-----
      Base64 密鑰：dGVzdC1iYXNlNjQtZW5jb2RlZC1kYXRhLWZvci10ZXN0aW5n
      MD5 雜湊：5d41402abc4b2a76b9719d911017c592
      AWS 金鑰：AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
    CONTENT
    
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    assert violations.length >= 6
    assert violations.all? { |v| v[:type] == 'sensitive_data' }
    assert violations.all? { |v| v[:severity] == 'high' }
  end

  def test_scan_sensitive_data_with_special_characters
    content = <<~CONTENT
      特殊字符測試：
      password = "MyP@ssw0rd!@#$%"
      api_key: "sk-1234567890abcdef_ghijklmnop"
      ftp://user:pass@server.com/path/to/file.txt
      sftp://admin@192.168.1.100:22/home/admin/
    CONTENT
    
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    assert violations.length >= 4
    assert violations.all? { |v| v[:type] == 'sensitive_data' }
  end

  def test_scan_sensitive_data_case_insensitive
    content = <<~CONTENT
      大小寫測試：
      PASSWORD: secret123
      Password: secret123
      password: secret123
      API_KEY: sk-1234567890abcdef
      Api_Key: sk-1234567890abcdef
      api_key: sk-1234567890abcdef
    CONTENT
    
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    assert violations.length >= 6
    assert violations.all? { |v| v[:type] == 'sensitive_data' }
  end

  # 個人資料掃描測試
  def test_scan_personal_data_basic
    content = "Contact John Doe at john.doe@example.com"
    violations = DataProtectionGuard.scan_personal_data(content)
    
    assert_equal 2, violations.length
    assert_equal 'personal_data', violations.first[:type]
    assert_equal 'medium', violations.first[:severity]
  end

  def test_scan_personal_data_comprehensive
    content = <<~CONTENT
      客戶資料：
      姓名：John Doe
      身分證號：A123456789
      護照號碼：B87654321
      電話：02-1234-5678
      手機：0912-345-678
      電子郵件：john.doe@example.com
      地址：台北市信義區信義路五段7號
      出生日期：1990-01-01
      信用卡號：1234-5678-9012-3456
      銀行帳號：1234567890123456
    CONTENT
    
    violations = DataProtectionGuard.scan_personal_data(content)
    
    assert violations.length >= 8
    assert violations.all? { |v| v[:type] == 'personal_data' }
    assert violations.all? { |v| v[:severity] == 'medium' }
  end

  def test_scan_personal_data_international
    content = <<~CONTENT
      國際客戶資料：
      美國 SSN：123-45-6789
      英國銀行帳號：GB29 NWBK 6016 1331 9268 19
      英國電話：+44 20 7946 0958
      美國電話：(555) 123-4567
      日期格式：12/25/2023
    CONTENT
    
    violations = DataProtectionGuard.scan_personal_data(content)
    
    assert violations.length >= 5
    assert violations.all? { |v| v[:type] == 'personal_data' }
  end

  def test_scan_personal_data_variations
    content = <<~CONTENT
      資料變體測試：
      姓名變體：Dr. Jane Smith, Mr. John Doe, Prof. Robert Johnson
      電話變體：+886-2-1234-5678, (02) 1234-5678, 02.1234.5678
      電子郵件變體：user+tag@domain.com, user.name@sub.domain.co.uk
      地址變體：新北市板橋區文化路一段100號, 台中市西區精誠路50號
    CONTENT
    
    violations = DataProtectionGuard.scan_personal_data(content)
    
    assert violations.length >= 6
    assert violations.all? { |v| v[:type] == 'personal_data' }
  end

  # 混合內容掃描測試
  def test_scan_content_mixed
    content = "Password: secret123, Contact: John Doe"
    violations = DataProtectionGuard.scan_content(content)
    
    assert violations.length >= 2
    assert violations.any? { |v| v[:type] == 'sensitive_data' }
    assert violations.any? { |v| v[:type] == 'personal_data' }
  end

  def test_scan_content_complex
    content = <<~CONTENT
      系統管理員帳號：
      姓名：Admin User
      電子郵件：admin@company.com
      密碼：AdminP@ssw0rd123
      
      資料庫連線：
      mysql://admin:dbpassword@192.168.1.100:3306/production
      
      客戶資料：
      姓名：John Doe
      電話：02-1234-5678
      信用卡：1234-5678-9012-3456
    CONTENT
    
    violations = DataProtectionGuard.scan_content(content)
    
    assert violations.length >= 6
    sensitive_count = violations.count { |v| v[:type] == 'sensitive_data' }
    personal_count = violations.count { |v| v[:type] == 'personal_data' }
    
    assert sensitive_count >= 3
    assert personal_count >= 3
  end

  # 邊界情況測試
  def test_scan_content_empty
    violations = DataProtectionGuard.scan_content("")
    assert_equal [], violations
    
    violations = DataProtectionGuard.scan_content(nil)
    assert_equal [], violations
  end

  def test_scan_content_no_violations
    content = "This is a normal description without any sensitive or personal data."
    violations = DataProtectionGuard.scan_content(content)
    assert_equal [], violations
  end

  def test_scan_content_false_positives
    content = <<~CONTENT
      邊界情況測試：
      正常 IP 討論：我們使用 8.8.8.8 作為 DNS 伺服器
      正常密碼討論：請設定強密碼，至少8個字符
      正常 API 討論：我們使用 REST API 進行整合
      正常資料庫討論：我們使用 MySQL 資料庫
      
      看起來像但實際不是：
      password123（沒有冒號）
      api_key_value（沒有冒號）
      192.168.1.1.1（無效 IP）
      john.doe（沒有 @ 符號）
    CONTENT
    
    violations = DataProtectionGuard.scan_content(content)
    
    # 應該只偵測到有效的機敏資料，不應該有誤判
    assert violations.length <= 2  # 只應該偵測到有效的 IP 和資料庫討論
  end

  # 排除規則測試
  def test_excluded_fields
    assert DataProtectionGuard.excluded_fields.include?('subject')
    assert DataProtectionGuard.excluded_fields.include?('tracker_id')
    assert DataProtectionGuard.excluded_fields.include?('status_id')
  end

  def test_excluded_projects
    assert DataProtectionGuard.excluded_projects.include?('test-project')
  end

  def test_should_skip_field_validation
    assert DataProtectionGuard.should_skip_field_validation?('subject')
    assert DataProtectionGuard.should_skip_field_validation?('tracker_id')
    assert_not DataProtectionGuard.should_skip_field_validation?('description')
  end

  def test_should_skip_validation_with_excluded_project
    record = mock('record')
    project = mock('project')
    project.stubs(:identifier).returns('test-project')
    record.stubs(:project).returns(project)
    
    assert DataProtectionGuard.should_skip_validation?(record)
  end

  def test_should_skip_validation_with_non_excluded_project
    record = mock('record')
    project = mock('project')
    project.stubs(:identifier).returns('normal-project')
    record.stubs(:project).returns(project)
    
    assert_not DataProtectionGuard.should_skip_validation?(record)
  end

  def test_should_skip_validation_without_project
    record = mock('record')
    record.stubs(:project).returns(nil)
    
    assert_not DataProtectionGuard.should_skip_validation?(record)
  end

  # 錯誤訊息生成測試
  def test_generate_error_message_sensitive_only
    violations = [
      { type: 'sensitive_data', match: 'password: secret123' },
      { type: 'sensitive_data', match: 'ftp://user:pass@server.com' }
    ]
    
    message = DataProtectionGuard.generate_error_message(violations)
    assert_includes message, '機敏資料'
    assert_includes message, 'password: secret123'
    assert_includes message, 'ftp://user:pass@server.com'
    assert_includes message, '請移除'
  end

  def test_generate_error_message_personal_only
    violations = [
      { type: 'personal_data', match: 'John Doe' },
      { type: 'personal_data', match: 'john.doe@example.com' }
    ]
    
    message = DataProtectionGuard.generate_error_message(violations)
    assert_includes message, '個人資料'
    assert_includes message, 'John Doe'
    assert_includes message, 'john.doe@example.com'
    assert_includes message, '請移除'
  end

  def test_generate_error_message_mixed
    violations = [
      { type: 'sensitive_data', match: 'password: secret123' },
      { type: 'personal_data', match: 'John Doe' }
    ]
    
    message = DataProtectionGuard.generate_error_message(violations)
    assert_includes message, '機敏資料'
    assert_includes message, '個人資料'
    assert_includes message, 'password: secret123'
    assert_includes message, 'John Doe'
    assert_includes message, '請移除'
  end

  def test_generate_error_message_empty
    message = DataProtectionGuard.generate_error_message([])
    assert_nil message
  end

  # 設定處理測試
  def test_sensitive_patterns_parsing
    patterns = DataProtectionGuard.sensitive_patterns
    assert patterns.is_a?(Array)
    assert patterns.length >= 14
    assert patterns.any? { |p| p.include?('password') }
    assert patterns.any? { |p| p.include?('ftp://') }
  end

  def test_personal_patterns_parsing
    patterns = DataProtectionGuard.personal_patterns
    assert patterns.is_a?(Array)
    assert patterns.length >= 12
    assert patterns.any? { |p| p.include?('@') }
    assert patterns.any? { |p| p.include?('台北市') }
  end

  def test_excluded_fields_parsing
    fields = DataProtectionGuard.excluded_fields
    assert fields.is_a?(Array)
    assert fields.include?('subject')
    assert fields.include?('tracker_id')
    assert fields.include?('status_id')
  end

  def test_excluded_projects_parsing
    projects = DataProtectionGuard.excluded_projects
    assert projects.is_a?(Array)
    assert projects.include?('test-project')
  end

  # 效能測試
  def test_large_content_performance
    # 建立大量內容
    large_content = "Normal content " * 1000 + "Password: secret123 " + "Normal content " * 1000
    
    start_time = Time.current
    violations = DataProtectionGuard.scan_content(large_content)
    end_time = Time.current
    
    processing_time = end_time - start_time
    
    # 確保處理時間在合理範圍內（少於 1 秒）
    assert processing_time < 1.second
    assert violations.any? { |v| v[:type] == 'sensitive_data' }
  end

  def test_multiple_patterns_performance
    # 測試多個模式同時匹配
    complex_content = <<~CONTENT
      複雜內容測試：
      password: secret123
      api_key: sk-1234567890abcdef
      ftp://user:pass@server.com
      mysql://root:password@192.168.1.100:3306/db
      John Doe at john.doe@example.com
      A123456789
      02-1234-5678
      台北市信義區信義路五段7號
    CONTENT
    
    start_time = Time.current
    violations = DataProtectionGuard.scan_content(complex_content)
    end_time = Time.current
    
    processing_time = end_time - start_time
    
    # 確保處理時間在合理範圍內（少於 1 秒）
    assert processing_time < 1.second
    assert violations.length >= 8
  end

  # 錯誤處理測試
  def test_malformed_regex_handling
    # 暫時設定無效的正則表達式
    original_patterns = Setting.plugin_data_protection_guard['sensitive_patterns']
    Setting.plugin_data_protection_guard['sensitive_patterns'] = ['[invalid regex']
    
    # 應該不會崩潰，而是跳過無效的模式
    content = "Password: secret123"
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    # 恢復原始設定
    Setting.plugin_data_protection_guard['sensitive_patterns'] = original_patterns
    
    # 應該沒有違規（因為正則表達式無效）
    assert_equal [], violations
  end

  def test_mixed_valid_and_invalid_regex
    # 設定混合的有效和無效正則表達式
    original_patterns = Setting.plugin_data_protection_guard['sensitive_patterns']
    Setting.plugin_data_protection_guard['sensitive_patterns'] = [
      '\\b(?:password|pwd|passwd)\\s*[:=]\\s*[^\\s]+',  # 有效的
      '[invalid regex',  # 無效的
      'ftp://[^\\s]+'  # 有效的
    ]
    
    content = "Password: secret123 and ftp://user:pass@server.com"
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    # 恢復原始設定
    Setting.plugin_data_protection_guard['sensitive_patterns'] = original_patterns
    
    # 應該只偵測到有效的模式
    assert violations.length >= 2
    assert violations.all? { |v| v[:type] == 'sensitive_data' }
  end

  # 上下文資訊測試
  def test_context_information
    context = {
      field: 'description',
      model: 'Issue',
      id: 123
    }
    
    content = "Password: secret123"
    violations = DataProtectionGuard.scan_sensitive_data(content, context)
    
    assert violations.any?
    violation = violations.first
    assert_equal context, violation[:context]
  end

  # 設定變更測試
  def test_dynamic_setting_changes
    # 測試動態啟用/停用功能
    Setting.plugin_data_protection_guard['enable_sensitive_data_detection'] = false
    
    content = "Password: secret123"
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    assert_equal [], violations
    
    # 恢復設定
    Setting.plugin_data_protection_guard['enable_sensitive_data_detection'] = true
  end

  def test_dynamic_pattern_changes
    # 測試動態模式變更
    original_patterns = Setting.plugin_data_protection_guard['sensitive_patterns']
    Setting.plugin_data_protection_guard['sensitive_patterns'] = ['custom_pattern: [^\\s]+']
    
    content = "custom_pattern: test_value"
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    assert violations.any?
    assert_equal 'custom_pattern: test_value', violations.first[:match]
    
    # 恢復設定
    Setting.plugin_data_protection_guard['sensitive_patterns'] = original_patterns
  end

  # 特殊字符和編碼測試
  def test_unicode_content
    content = "密碼：secret123 和 電子郵件：測試@example.com"
    violations = DataProtectionGuard.scan_content(content)
    
    # 應該能處理 Unicode 內容
    assert violations.any?
  end

  def test_special_characters_in_patterns
    content = "password = \"MyP@ssw0rd!@#$%\""
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    assert violations.any?
    assert violations.any? { |v| v[:match].include?('MyP@ssw0rd!@#$%') }
  end

  # 記憶體使用測試
  def test_memory_usage_with_large_content
    # 建立非常大的內容
    large_content = "Normal content " * 10000
    
    # 記錄記憶體使用
    memory_before = GC.stat[:total_allocated_objects]
    violations = DataProtectionGuard.scan_content(large_content)
    memory_after = GC.stat[:total_allocated_objects]
    
    # 記憶體使用應該在合理範圍內
    memory_increase = memory_after - memory_before
    assert memory_increase < 10000  # 不應該分配過多物件
  end
end
