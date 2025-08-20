# frozen_string_literal: true

class DataProtectionController < ApplicationController
  before_action :require_admin, except: [:logs]
  before_action :authorize_global, except: [:logs]

  def settings
    @settings = Setting.plugin_data_protection_guard
    
    if request.post?
      Setting.plugin_data_protection_guard = params[:settings]
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: :settings
    end
  end

  def load_defaults
    if request.post?
      # 載入預設值（簡化版本，只保留核心設定）
      default_settings = {
        'enable_sensitive_data_detection' => true,
        'enable_personal_data_detection' => true,
        'block_submission' => true,  # 保留但預設啟用，不在設定頁面顯示
        'log_violations' => false,
        'log_to_database' => true,
        'auto_cleanup_days' => 30
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
      
      # 根據清理類型執行不同的清理操作
      case params[:clear_type]
      when 'all'
        deleted_count = DataProtectionLogger.clear_old_logs(days)
        flash[:notice] = l(:text_logs_cleared, days: days, count: deleted_count)
      when 'sensitive_data'
        deleted_count = DataProtectionLogger.clear_logs_by_type('sensitive_data', days)
        flash[:notice] = l(:text_sensitive_logs_cleared, days: days, count: deleted_count)
      when 'personal_data'
        deleted_count = DataProtectionLogger.clear_logs_by_type('personal_data', days)
        flash[:notice] = l(:text_personal_logs_cleared, days: days, count: deleted_count)
      when 'user'
        user_id = params[:user_id].to_i
        if user_id > 0
          deleted_count = DataProtectionLogger.clear_logs_by_user(user_id, days)
          flash[:notice] = l(:text_user_logs_cleared, days: days, count: deleted_count, user_id: user_id)
        else
          flash[:error] = l(:text_invalid_user_id)
        end
      else
        deleted_count = DataProtectionLogger.clear_old_logs(days)
        flash[:notice] = l(:text_logs_cleared, days: days, count: deleted_count)
      end
    end
    
    redirect_to action: :logs
  end

  def log_statistics
    @statistics = DataProtectionLogger.get_log_statistics
    @violations = get_violations(limit: 10) # 只顯示最近 10 筆
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
