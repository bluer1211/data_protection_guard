# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class DataProtectionIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    # 建立測試資料
    @admin = create_test_user(admin: true)
    @user = create_test_user
    @project = create_test_project
    
    # 設定插件
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

  private

  def log_in_as(user)
    post login_path, params: {
      username: user.login,
      password: 'password123'
    }
  end
end
