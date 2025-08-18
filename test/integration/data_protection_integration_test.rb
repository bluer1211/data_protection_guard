# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class DataProtectionIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    # 建立測試資料
    @admin = create_test_user(admin: true)
    @user = create_test_user
    @project = create_test_project
    
    # 設定插件 - 使用更完整的規則
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
  def test_create_issue_with_sensitive_data_should_fail
    log_in_as(@user)
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Test Issue',
          description: 'Here is my password: secret123 and ftp://user:pass@server.com'
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /機敏資料/
  end

  def test_create_issue_with_personal_data_should_fail
    log_in_as(@user)
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Test Issue',
          description: 'Contact John Doe at john.doe@example.com'
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /個人資料/
  end

  def test_create_issue_without_violations_should_succeed
    log_in_as(@user)
    
    assert_difference 'Issue.count', 1 do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Test Issue',
          description: 'This is a normal description without sensitive data.'
        }
      }
    end
    
    assert_redirected_to issue_path(Issue.last)
  end

  # 複雜的機敏資料測試
  def test_multiple_sensitive_data_violations
    log_in_as(@user)
    
    sensitive_content = <<~CONTENT
      資料庫連線資訊：
      mysql://root:password123@192.168.1.100:3306/mydb
      
      API 設定：
      api_key: sk-1234567890abcdef
      access_token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
      
      SSH 連線：
      ssh://admin@10.0.0.1:22
      
      私鑰內容：
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEA1234567890
      -----END RSA PRIVATE KEY-----
    CONTENT
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Database Configuration',
          description: sensitive_content
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /機敏資料/
  end

  def test_sensitive_data_with_special_characters
    log_in_as(@user)
    
    special_content = <<~CONTENT
      特殊字符測試：
      password = "MyP@ssw0rd!@#$%"
      api_key: "sk-1234567890abcdef_ghijklmnop"
      ftp://user:pass@server.com/path/to/file.txt
      sftp://admin@192.168.1.100:22/home/admin/
    CONTENT
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Special Characters Test',
          description: special_content
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /機敏資料/
  end

  def test_base64_and_hash_detection
    log_in_as(@user)
    
    hash_content = <<~CONTENT
      雜湊值測試：
      MD5: 5d41402abc4b2a76b9719d911017c592
      SHA256: a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3
      Base64: dGVzdC1iYXNlNjQtZW5jb2RlZC1kYXRhLWZvci10ZXN0aW5nLXB1cnBvc2Vz
    CONTENT
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Hash Detection Test',
          description: hash_content
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /機敏資料/
  end

  # 複雜的個人資料測試
  def test_multiple_personal_data_violations
    log_in_as(@user)
    
    personal_content = <<~CONTENT
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
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Customer Information',
          description: personal_content
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /個人資料/
  end

  def test_international_personal_data
    log_in_as(@user)
    
    international_content = <<~CONTENT
      國際客戶資料：
      美國 SSN：123-45-6789
      英國銀行帳號：GB29 NWBK 6016 1331 9268 19
      英國電話：+44 20 7946 0958
      美國電話：(555) 123-4567
      日期格式：12/25/2023
    CONTENT
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'International Data',
          description: international_content
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /個人資料/
  end

  def test_personal_data_with_variations
    log_in_as(@user)
    
    variations_content = <<~CONTENT
      資料變體測試：
      姓名變體：Dr. Jane Smith, Mr. John Doe, Prof. Robert Johnson
      電話變體：+886-2-1234-5678, (02) 1234-5678, 02.1234.5678
      電子郵件變體：user+tag@domain.com, user.name@sub.domain.co.uk
      地址變體：新北市板橋區文化路一段100號, 台中市西區精誠路50號
    CONTENT
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Data Variations Test',
          description: variations_content
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /個人資料/
  end

  # 混合資料測試
  def test_mixed_sensitive_and_personal_data
    log_in_as(@user)
    
    mixed_content = <<~CONTENT
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
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Mixed Data Test',
          description: mixed_content
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /機敏資料|個人資料/
  end

  # 邊界情況測試
  def test_edge_cases_and_false_positives
    log_in_as(@user)
    
    edge_content = <<~CONTENT
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
    
    assert_difference 'Issue.count', 1 do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Edge Cases Test',
          description: edge_content
        }
      }
    end
    
    assert_redirected_to issue_path(Issue.last)
  end

  def test_case_insensitive_detection
    log_in_as(@user)
    
    case_content = <<~CONTENT
      大小寫測試：
      PASSWORD: secret123
      Password: secret123
      password: secret123
      API_KEY: sk-1234567890abcdef
      Api_Key: sk-1234567890abcdef
      api_key: sk-1234567890abcdef
    CONTENT
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Case Sensitivity Test',
          description: case_content
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /機敏資料/
  end

  # 排除規則測試
  def test_excluded_fields_should_not_be_checked
    log_in_as(@user)
    
    # subject 欄位被排除，應該可以包含機敏資料
    assert_difference 'Issue.count', 1 do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Password: secret123 and ftp://user:pass@server.com',
          description: 'This is a normal description.'
        }
      }
    end
    
    assert_redirected_to issue_path(Issue.last)
  end

  def test_excluded_projects_should_not_be_checked
    log_in_as(@user)
    
    # 建立排除的專案
    excluded_project = Project.create!(
      name: 'Test Project',
      identifier: 'test-project',
      enabled_module_names: ['issue_tracking']
    )
    
    assert_difference 'Issue.count', 1 do
      post issues_path, params: {
        issue: {
          project_id: excluded_project.id,
          subject: 'Test Issue',
          description: 'Password: secret123 and John Doe at john.doe@example.com'
        }
      }
    end
    
    assert_redirected_to issue_path(Issue.last)
  end

  # 日誌記錄測試
  def test_violation_logging
    log_in_as(@user)
    
    assert_difference 'DataProtectionViolation.count', 0 do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Test Issue',
          description: 'Password: secret123'
        }
      }
    end
    
    # 檢查是否有違規記錄
    violations = DataProtectionViolation.where(user_id: @user.id)
    assert violations.any?
    
    violation = violations.last
    assert_equal 'sensitive_data', violation.violation_type
    assert_includes violation.pattern, 'password'
    assert_includes violation.match_content, 'secret123'
    assert_equal 'high', violation.severity
  end

  def test_multiple_violations_logging
    log_in_as(@user)
    
    post issues_path, params: {
      issue: {
        project_id: @project.id,
        subject: 'Test Issue',
        description: 'Password: secret123 and John Doe at john.doe@example.com'
      }
    }
    
    violations = DataProtectionViolation.where(user_id: @user.id)
    assert violations.count >= 2
    
    sensitive_violations = violations.where(violation_type: 'sensitive_data')
    personal_violations = violations.where(violation_type: 'personal_data')
    
    assert sensitive_violations.any?
    assert personal_violations.any?
  end

  # 管理員功能測試
  def test_admin_can_access_settings
    log_in_as(@admin)
    
    get plugin_settings_path('data_protection_guard')
    assert_response :success
    assert_select 'h2', /資料保護/
  end

  def test_admin_can_access_logs
    log_in_as(@admin)
    
    get data_protection_logs_path
    assert_response :success
    assert_select 'h2', /違規日誌/
  end

  def test_regular_user_cannot_access_admin_pages
    log_in_as(@user)
    
    get plugin_settings_path('data_protection_guard')
    assert_response :forbidden
    
    get data_protection_logs_path
    assert_response :forbidden
  end

  # 正則表達式測試功能
  def test_pattern_testing_functionality
    log_in_as(@admin)
    
    post test_pattern_data_protection_path, params: {
      content: 'password: secret123',
      pattern: '\\b(?:password|pwd|passwd)\\s*[:=]\\s*[^\\s]+'
    }, xhr: true
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_includes json_response['matches'], 'password: secret123'
  end

  def test_complex_pattern_testing
    log_in_as(@admin)
    
    # 測試複雜的正則表達式
    post test_pattern_data_protection_path, params: {
      content: 'mysql://root:password123@192.168.1.100:3306/mydb',
      pattern: '\\b(?:mysql|postgresql|mongodb)://[^\\s]+'
    }, xhr: true
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_includes json_response['matches'], 'mysql://root:password123@192.168.1.100:3306/mydb'
  end

  def test_invalid_pattern_handling
    log_in_as(@admin)
    
    post test_pattern_data_protection_path, params: {
      content: 'test content',
      pattern: '[invalid regex'
    }, xhr: true
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_includes json_response['error'], '正則表達式錯誤'
  end

  # 效能測試
  def test_large_content_processing
    log_in_as(@user)
    
    # 建立大量內容
    large_content = "Normal content " * 1000 + "Password: secret123 " + "Normal content " * 1000
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Large Content Test',
          description: large_content
        }
      }
    end
    
    assert_response :success
    assert_select '.error', /機敏資料/
  end

  def test_multiple_patterns_performance
    log_in_as(@user)
    
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
    
    assert_no_difference 'Issue.count' do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Performance Test',
          description: complex_content
        }
      }
    end
    
    end_time = Time.current
    processing_time = end_time - start_time
    
    # 確保處理時間在合理範圍內（少於 5 秒）
    assert processing_time < 5.seconds
    
    assert_response :success
    assert_select '.error', /機敏資料|個人資料/
  end

  # 錯誤處理測試
  def test_malformed_regex_handling
    log_in_as(@user)
    
    # 暫時設定無效的正則表達式
    original_patterns = Setting.plugin_data_protection_guard['sensitive_patterns']
    Setting.plugin_data_protection_guard['sensitive_patterns'] = ['[invalid regex']
    
    # 應該不會崩潰，而是跳過無效的模式
    assert_difference 'Issue.count', 1 do
      post issues_path, params: {
        issue: {
          project_id: @project.id,
          subject: 'Malformed Regex Test',
          description: 'This should work normally.'
        }
      }
    end
    
    # 恢復原始設定
    Setting.plugin_data_protection_guard['sensitive_patterns'] = original_patterns
    
    assert_redirected_to issue_path(Issue.last)
  end

  # 上下文資訊測試
  def test_context_information_logging
    log_in_as(@user)
    
    post issues_path, params: {
      issue: {
        project_id: @project.id,
        subject: 'Context Test',
        description: 'Password: secret123'
      }
    }
    
    violation = DataProtectionViolation.where(user_id: @user.id).last
    context_info = JSON.parse(violation.context)
    
    assert_equal 'description', context_info['field']
    assert_equal 'Issue', context_info['model']
    assert_equal @user.id, violation.user_id
    assert_not_nil violation.ip_address
  end

  private

  def log_in_as(user)
    post login_path, params: {
      username: user.login,
      password: 'password123'
    }
  end
end
