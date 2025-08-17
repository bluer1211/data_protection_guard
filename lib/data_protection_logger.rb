# frozen_string_literal: true

module DataProtectionLogger
  class << self
    def log_violation(violation)
      return unless violation.is_a?(Hash)

      log_entry = {
        timestamp: Time.current,
        user_id: User.current&.id,
        violation_type: violation[:type],
        pattern: violation[:pattern],
        match: violation[:match],
        severity: violation[:severity],
        context: violation[:context],
        ip_address: get_client_ip,
        user_agent: get_user_agent
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
      DataProtectionViolation.where('created_at < ?', cutoff_date).delete_all
    end

    private

    def get_client_ip
      defined?(RequestStore) ? RequestStore.store[:request]&.remote_ip : 'unknown'
    end

    def get_user_agent
      defined?(RequestStore) ? RequestStore.store[:request]&.user_agent : 'unknown'
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
