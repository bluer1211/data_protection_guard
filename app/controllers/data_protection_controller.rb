# frozen_string_literal: true

class DataProtectionController < ApplicationController
  before_action :require_admin, except: [:logs]
  before_action :authorize_global, except: [:logs]

  def settings
    # 顯示自訂設定頁面，而不是重定向
    @settings = Setting.plugin_data_protection_guard
    
    if request.post?
      Setting.plugin_data_protection_guard = params[:settings]
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: :settings
    end
  end

  def load_defaults
    if request.post?
      # 載入預設值
      default_settings = {
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
          '\\b(?:BEGIN|END)\\s+CERTIFICATE\\b'
        ],
        'personal_patterns' => [
          # 更精確的個人資料偵測模式（使用負向預查避免誤判）
          '(?<![A-Za-z0-9])[A-Z][1-2]\\d{8}(?![A-Za-z0-9])',  # 身分證號（更精確格式）
          '(?<![A-Za-z0-9._%+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}(?![A-Za-z0-9._%+-])',  # 電子郵件（更精確格式）
          '(?<!\\d)\\d{4}[- ]?\\d{4}[- ]?\\d{4}[- ]?\\d{4}(?!\\d)',  # 信用卡號（支援空格和連字號）
          '(?<!\\d)09\\d{2}-?\\d{3}-?\\d{3}(?!\\d)',  # 台灣手機號碼
          '(?<!\\d)\\d{6,14}(?!\\d)',  # 銀行帳號（6-14位數字）
          
          # 保留原有模式作為備用
          '\\b[A-Z][a-z]+\\s+[A-Z][a-z]+\\b',  # 姓名
          '[A-Z]\\d{8}',  # 護照號碼
          '\\b\\d{2,4}-\\d{3,4}-\\d{4}\\b',  # 電話號碼
          '\\b\\d{4}-\\d{2}-\\d{2}\\b',  # 出生日期
          '\\b(?:台北市|新北市|桃園市|台中市|台南市|高雄市|基隆市|新竹市|新竹縣|苗栗縣|彰化縣|南投縣|雲林縣|嘉義市|嘉義縣|屏東縣|宜蘭縣|花蓮縣|台東縣|澎湖縣|金門縣|連江縣)[^\\s]*\\b'  # 台灣地址
        ],
        'excluded_fields' => ['tracker_id', 'status_id', 'priority_id'],
        'excluded_projects' => []
      }
      
      Setting.plugin_data_protection_guard = default_settings
      flash[:notice] = l(:text_defaults_loaded)
      redirect_to action: :settings
    else
      redirect_to action: :settings
    end
  end

  def logs
    @violations = get_violations
    @total_count = @violations.count
    
    respond_to do |format|
      format.html
      format.csv { send_data violations_to_csv(@violations), filename: "data_protection_violations_#{Date.current}.csv" }
    end
  end

  def clear_logs
    if request.post?
      days = params[:days].to_i
      days = 30 if days <= 0
      
      DataProtectionLogger.clear_old_logs(days)
      flash[:notice] = l(:text_logs_cleared, days: days)
    end
    
    redirect_to action: :logs
  end

  def test_pattern
    if request.post?
      content = params[:content]
      pattern = params[:pattern]
      
      if content.present? && pattern.present?
        begin
          regex = Regexp.new(pattern, Regexp::IGNORECASE | Regexp::MULTILINE)
          matches = content.scan(regex)
          
          render json: {
            success: true,
            matches: matches.flatten.uniq,
            count: matches.flatten.count
          }
        rescue RegexpError => e
          render json: {
            success: false,
            error: l(:text_regex_error, message: e.message)
          }
        end
      else
        render json: {
          success: false,
          error: l(:text_please_provide_content_and_pattern)
        }
      end
    end
  end

  private

  def get_violations
    options = {}
    options[:user_id] = params[:user_id] if params[:user_id].present?
    options[:violation_type] = params[:violation_type] if params[:violation_type].present?
    options[:from_date] = params[:from_date] if params[:from_date].present?
    options[:to_date] = params[:to_date] if params[:to_date].present?
    options[:limit] = 1000

    DataProtectionLogger.get_violations(options)
  end

  def violations_to_csv(violations)
    require 'csv'
    
    # 取得時區設定
    time_zone = User.current&.time_zone || Setting.find_by(name: 'time_zone')&.value || 'UTC'
    
    CSV.generate(headers: true) do |csv|
      csv << [l(:field_created_on), l(:field_user), l(:field_violation_type), l(:field_match), l(:field_severity), l(:field_ip_address), l(:field_context)]
      
      violations.each do |violation|
        # 使用正確的時區格式化時間
        formatted_time = violation.created_at.in_time_zone(time_zone)
        time_display = format_time(formatted_time)
        time_display += " (#{time_zone})" if time_zone != 'UTC'
        
        csv << [
          time_display,
          violation.user&.name || l(:label_unknown),
          violation.violation_type_label,
          violation.match_content,
          violation.severity_label,
          violation.ip_address,
          violation.context_info
        ]
      end
    end
  end
end
