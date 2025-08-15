# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class DataProtectionGuardTest < ActiveSupport::TestCase
  fixtures :users, :projects, :issues, :journals, :attachments

  def setup
    @user = User.find(1)
    @project = Project.find(1)
    @issue = Issue.find(1)
    
    # 設定測試環境
    Setting.plugin_data_protection_guard = {
      'enable_sensitive_data_detection' => true,
      'enable_personal_data_detection' => true,
      'block_submission' => true,
      'log_violations' => true,
      'sensitive_patterns' => [
        'ftp://[^\\s]+',
        'password\\s*[:=]\\s*[^\\s]+',
        '\\b(?:192\\.168\\.|10\\.|172\\.(?:1[6-9]|2[0-9]|3[0-1])\\.)\\d+\\.\\d+\\b'
      ],
      'personal_patterns' => [
        '\\b[A-Z]\\d{9}\\b',
        '\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b'
      ],
      'excluded_fields' => ['subject'],
      'excluded_projects' => []
    }
  end

  def test_enabled?
    assert DataProtectionGuard.enabled?
    
    Setting.plugin_data_protection_guard['enable_sensitive_data_detection'] = false
    Setting.plugin_data_protection_guard['enable_personal_data_detection'] = false
    assert_not DataProtectionGuard.enabled?
  end

  def test_scan_sensitive_data
    content = "FTP server: ftp://user:password@192.168.1.100"
    violations = DataProtectionGuard.scan_sensitive_data(content)
    
    assert_equal 2, violations.length
    assert_equal 'sensitive_data', violations[0][:type]
    assert_equal 'ftp://user:password@192.168.1.100', violations[0][:match]
    assert_equal '192.168.1.100', violations[1][:match]
  end

  def test_scan_personal_data
    content = "User ID: A123456789, Email: test@example.com"
    violations = DataProtectionGuard.scan_personal_data(content)
    
    assert_equal 2, violations.length
    assert_equal 'personal_data', violations[0][:type]
    assert_equal 'A123456789', violations[0][:match]
    assert_equal 'test@example.com', violations[1][:match]
  end

  def test_scan_content
    content = "FTP: ftp://server.com, ID: A123456789"
    violations = DataProtectionGuard.scan_content(content)
    
    assert_equal 2, violations.length
    assert violations.any? { |v| v[:type] == 'sensitive_data' }
    assert violations.any? { |v| v[:type] == 'personal_data' }
  end

  def test_should_skip_validation
    # 測試排除專案
    Setting.plugin_data_protection_guard['excluded_projects'] = [@project.identifier]
    assert DataProtectionGuard.should_skip_validation?(@issue)
    
    # 測試非排除專案
    Setting.plugin_data_protection_guard['excluded_projects'] = []
    assert_not DataProtectionGuard.should_skip_validation?(@issue)
  end

  def test_generate_error_message
    violations = [
      { type: 'sensitive_data', match: 'ftp://server.com' },
      { type: 'personal_data', match: 'A123456789' }
    ]
    
    message = DataProtectionGuard.generate_error_message(violations)
    assert_includes message, '偵測到 1 個機敏資料項目'
    assert_includes message, '偵測到 1 個個人資料項目'
    assert_includes message, 'ftp://server.com'
    assert_includes message, 'A123456789'
  end

  def test_issue_validation_with_sensitive_data
    User.current = @user
    
    @issue.description = "Server: ftp://admin:password@192.168.1.100"
    assert_not @issue.valid?
    assert_includes @issue.errors[:base].join, '機敏資料'
  end

  def test_issue_validation_with_personal_data
    User.current = @user
    
    @issue.description = "User ID: A123456789"
    assert_not @issue.valid?
    assert_includes @issue.errors[:base].join, '個人資料'
  end

  def test_journal_validation
    User.current = @user
    
    journal = Journal.new(
      journalized: @issue,
      user: @user,
      notes: "Password: secret123"
    )
    
    assert_not journal.valid?
    assert_includes journal.errors[:base].join, '機敏資料'
  end

  def test_attachment_validation
    User.current = @user
    
    attachment = Attachment.new(
      container: @issue,
      author: @user,
      filename: "config_with_password.txt",
      description: "Contains: ftp://server.com"
    )
    
    # 模擬檔案內容檢查
    attachment.stubs(:text_file?).returns(true)
    attachment.stubs(:read_file_content).returns("password=secret123")
    
    assert_not attachment.valid?
    assert_includes attachment.errors[:base].join, '機敏資料'
  end

  def test_excluded_fields
    User.current = @user
    
    # 主旨欄位應該被排除
    @issue.subject = "FTP: ftp://server.com"
    assert @issue.valid?, "主旨欄位應該被排除檢查"
    
    # 描述欄位應該被檢查
    @issue.description = "FTP: ftp://server.com"
    assert_not @issue.valid?, "描述欄位應該被檢查"
  end

  def test_log_violation
    violation = {
      type: 'sensitive_data',
      pattern: 'ftp://[^\\s]+',
      match: 'ftp://server.com',
      severity: 'high'
    }
    
    # 測試日誌記錄
    assert_nothing_raised do
      DataProtectionGuard.log_violation(violation)
    end
  end

  def test_text_file_detection
    attachment = Attachment.new
    
    # 測試文字檔案類型
    attachment.content_type = 'text/plain'
    attachment.filename = 'test.txt'
    assert attachment.text_file?
    
    # 測試非文字檔案類型
    attachment.content_type = 'image/jpeg'
    attachment.filename = 'test.jpg'
    assert_not attachment.text_file?
  end

  def test_file_size_limit
    attachment = Attachment.new
    attachment.stubs(:readable?).returns(true)
    
    # 模擬大檔案
    file = mock
    file.stubs(:size).returns(2 * 1024 * 1024) # 2MB
    attachment.stubs(:file).returns(file)
    
    assert_nil attachment.read_file_content
  end
end
