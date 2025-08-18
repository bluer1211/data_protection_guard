# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class DataProtectionGuardTest < ActiveSupport::TestCase
  def setup
    # 設定測試環境
    Setting.plugin_data_protection_guard = {
      'enable_sensitive_data_detection' => true,
      'enable_personal_data_detection' => true,
      'block_submission' => true,
      'log_violations' => true,
      'sensitive_patterns' => [
        'ftp://[^\\s]+',
        '\\b(?:password|pwd|passwd)\\s*[:=]\\s*[^\\s]+',
        '\\b(?:192\\.168\\.|10\\.|172\\.(?:1[6-9]|2[0-9]|3[0-1])\\.)\\d+\\.\\d+\\b'
      ],
      'personal_patterns' => [
        '\\b[A-Z][a-z]+\\s+[A-Z][a-z]+\\b',
        '\\b[A-Z]\\d{9}\\b',
        '\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b'
      ],
      'excluded_fields' => ['subject'],
      'excluded_projects' => []
    }
  end

  def test_enabled?
    assert DataProtectionGuard.enabled?
  end

  def test_sensitive_data_detection_enabled?
    assert DataProtectionGuard.sensitive_data_detection_enabled?
  end

  def test_personal_data_detection_enabled?
    assert DataProtectionGuard.personal_data_detection_enabled?
  end

  def test_scan_sensitive_data
    content = "Here is my password: secret123 and ftp://user:pass@server.com"
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    assert_equal 2, violations.length
    assert_equal 'sensitive_data', violations.first[:type]
    assert_equal 'high', violations.first[:severity]
  end

  def test_scan_personal_data
    content = "Contact John Doe at john.doe@example.com"
    violations = DataProtectionGuard.scan_personal_data(content)
    
    # 修正期望值：John Doe (姓名) + john.doe@example.com (電子郵件) = 2個匹配
    assert_equal 2, violations.length
    assert_equal 'personal_data', violations.first[:type]
    assert_equal 'medium', violations.first[:severity]
  end

  def test_scan_content
    content = "Password: secret123, Contact: John Doe"
    violations = DataProtectionGuard.scan_content(content)
    
    assert violations.length >= 2
    assert violations.any? { |v| v[:type] == 'sensitive_data' }
    assert violations.any? { |v| v[:type] == 'personal_data' }
  end

  def test_generate_error_message
    violations = [
      { type: 'sensitive_data', match: 'password: secret123' },
      { type: 'personal_data', match: 'John Doe' }
    ]
    
    message = DataProtectionGuard.generate_error_message(violations)
    assert_includes message, '機敏資料'
    assert_includes message, '個人資料'
    assert_includes message, '請移除'
  end

  def test_should_skip_validation
    # 測試正常情況 - 使用 stub 而不是 mock
    record = Object.new
    record.stubs(:project).returns(nil)
    assert !DataProtectionGuard.should_skip_validation?(record)
  end
end
