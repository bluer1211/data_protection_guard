# frozen_string_literal: true

class DataProtectionController < ApplicationController
  before_action :require_admin, except: [:logs]
  before_action :authorize_global, except: [:logs]
  before_action :find_project, only: [:logs]

  def settings
    if request.post?
      settings = params[:settings] || {}
      
      # 處理陣列參數
      settings['sensitive_patterns'] = settings['sensitive_patterns'].split("\n").map(&:strip).reject(&:blank?) if settings['sensitive_patterns'].present?
      settings['personal_patterns'] = settings['personal_patterns'].split("\n").map(&:strip).reject(&:blank?) if settings['personal_patterns'].present?
      settings['excluded_fields'] = settings['excluded_fields'].split(",").map(&:strip).reject(&:blank?) if settings['excluded_fields'].present?
      settings['excluded_projects'] = settings['excluded_projects'].split(",").map(&:strip).reject(&:blank?) if settings['excluded_projects'].present?
      
      # 轉換布林值
      ['enable_sensitive_data_detection', 'enable_personal_data_detection', 'block_submission', 'log_violations', 'log_to_database'].each do |key|
        settings[key] = settings[key] == '1'
      end

      Setting.plugin_data_protection_guard = settings
      flash[:notice] = l(:notice_successful_update)
      redirect_to plugin_settings_path('data_protection_guard')
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
      flash[:notice] = "已清除 #{days} 天前的日誌記錄"
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
            error: "正則表達式錯誤: #{e.message}"
          }
        end
      else
        render json: {
          success: false,
          error: "請提供內容和正則表達式"
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
      csv << ['時間', '使用者', '類型', '匹配內容', '嚴重程度', 'IP位址', '上下文']
      
      violations.each do |violation|
        csv << [
          violation.created_at,
          violation.user&.name || '未知',
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
