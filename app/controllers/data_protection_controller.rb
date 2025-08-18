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
    
    CSV.generate(headers: true) do |csv|
      csv << [l(:field_created_on), l(:field_user), l(:field_violation_type), l(:field_match), l(:field_severity), l(:field_ip_address), l(:field_context)]
      
      violations.each do |violation|
        csv << [
          violation.created_at,
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
