# frozen_string_literal: true

module DataProtectionLogger
  class << self
    def log_violation(violation, request = nil)
      return unless violation.is_a?(Hash)

      log_entry = {
        timestamp: Time.current,
        user_id: User.current&.id,
        violation_type: violation[:type],
        pattern: violation[:pattern],
        match: violation[:match],
        severity: violation[:severity],
        context: violation[:context],
        ip_address: get_client_ip(request),
        user_agent: get_user_agent(request)
      }

      Rails.logger.warn "Data Protection Violation: #{log_entry.to_json}"

      # 如果設定了資料庫記錄，則儲存到資料庫
      if Setting.plugin_data_protection_guard['log_to_database']
        save_to_database(log_entry)
      end
    end

    def get_violations(options = {})
      return [] unless Setting.plugin_data_protection_guard['log_to_database']

      violations = DataProtectionViolation.all
      
      violations = violations.by_user(options[:user_id]) if options[:user_id]
      violations = violations.where(violation_type: options[:violation_type]) if options[:violation_type]
      violations = violations.by_date_range(options[:from_date], options[:to_date]) if options[:from_date] && options[:to_date]
      
      violations = violations.limit(options[:limit]) if options[:limit]
      violations.order(created_at: :desc)
    end

    def clear_old_logs(days = 30)
      return unless Setting.plugin_data_protection_guard['log_to_database']

      cutoff_date = days.days.ago
      deleted_count = DataProtectionViolation.where('created_at < ?', cutoff_date).delete_all
      
      Rails.logger.info "Data Protection Guard: 已清理 #{deleted_count} 筆 #{days} 天前的違規記錄"
      
      deleted_count
    end

    def clear_logs_by_type(violation_type, days = 30)
      return unless Setting.plugin_data_protection_guard['log_to_database']

      cutoff_date = days.days.ago
      deleted_count = DataProtectionViolation.where(
        violation_type: violation_type,
        created_at: ...cutoff_date
      ).delete_all
      
      Rails.logger.info "Data Protection Guard: 已清理 #{deleted_count} 筆 #{days} 天前的 #{violation_type} 違規記錄"
      
      deleted_count
    end

    def clear_logs_by_user(user_id, days = 30)
      return unless Setting.plugin_data_protection_guard['log_to_database']

      cutoff_date = days.days.ago
      deleted_count = DataProtectionViolation.where(
        user_id: user_id,
        created_at: ...cutoff_date
      ).delete_all
      
      Rails.logger.info "Data Protection Guard: 已清理使用者 #{user_id} 的 #{deleted_count} 筆 #{days} 天前的違規記錄"
      
      deleted_count
    end

    def get_log_statistics
      return {} unless Setting.plugin_data_protection_guard['log_to_database']

      {
        total_count: DataProtectionViolation.count,
        sensitive_data_count: DataProtectionViolation.sensitive_data.count,
        personal_data_count: DataProtectionViolation.personal_data.count,
        today_count: DataProtectionViolation.where('created_at >= ?', Date.current.beginning_of_day).count,
        week_count: DataProtectionViolation.where('created_at >= ?', 1.week.ago).count,
        month_count: DataProtectionViolation.where('created_at >= ?', 1.month.ago).count,
        oldest_record: DataProtectionViolation.minimum(:created_at),
        newest_record: DataProtectionViolation.maximum(:created_at)
      }
    end

    private

    def get_client_ip(request = nil)
      return 'unknown' unless request

      # 優先使用 X-Forwarded-For 標頭（適用於代理環境）
      forwarded_ip = request.env['HTTP_X_FORWARDED_FOR']
      if forwarded_ip.present?
        # X-Forwarded-For 可能包含多個 IP，取第一個
        return forwarded_ip.split(',').first.strip
      end

      # 使用 X-Real-IP 標頭
      real_ip = request.env['HTTP_X_REAL_IP']
      return real_ip if real_ip.present?

      # 使用 X-Client-IP 標頭
      client_ip = request.env['HTTP_X_CLIENT_IP']
      return client_ip if client_ip.present?

      # 最後使用 remote_ip
      request.remote_ip
    rescue => e
      Rails.logger.error "Data Protection Guard: Error getting client IP: #{e.message}"
      'unknown'
    end

    def get_user_agent(request = nil)
      return 'unknown' unless request

      request.user_agent
    rescue => e
      Rails.logger.error "Data Protection Guard: Error getting user agent: #{e.message}"
      'unknown'
    end

    def save_to_database(log_entry)
      DataProtectionViolation.create!(
        user_id: log_entry[:user_id],
        violation_type: log_entry[:violation_type],
        pattern: log_entry[:pattern],
        match_content: log_entry[:match],
        severity: log_entry[:severity],
        context: log_entry[:context].to_json,
        ip_address: log_entry[:ip_address],
        user_agent: log_entry[:user_agent]
      )
    rescue => e
      Rails.logger.error "Data Protection Guard: Error saving violation to database: #{e.message}"
    end
  end
end
