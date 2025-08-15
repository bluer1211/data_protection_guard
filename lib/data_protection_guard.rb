# frozen_string_literal: true

module DataProtectionGuard
  class << self
    def enabled?
      Setting.plugin_data_protection_guard['enable_sensitive_data_detection'] ||
      Setting.plugin_data_protection_guard['enable_personal_data_detection']
    end

    def sensitive_data_detection_enabled?
      Setting.plugin_data_protection_guard['enable_sensitive_data_detection']
    end

    def personal_data_detection_enabled?
      Setting.plugin_data_protection_guard['enable_personal_data_detection']
    end

    def block_submission?
      Setting.plugin_data_protection_guard['block_submission']
    end

    def log_violations?
      Setting.plugin_data_protection_guard['log_violations']
    end

    def excluded_fields
      Setting.plugin_data_protection_guard['excluded_fields'] || []
    end

    def excluded_projects
      Setting.plugin_data_protection_guard['excluded_projects'] || []
    end

    def sensitive_patterns
      Setting.plugin_data_protection_guard['sensitive_patterns'] || []
    end

    def personal_patterns
      Setting.plugin_data_protection_guard['personal_patterns'] || []
    end

    def scan_content(content, context = {})
      return [] unless enabled?
      return [] if content.blank?

      violations = []

      # 檢查機敏資料
      if sensitive_data_detection_enabled?
        sensitive_violations = scan_sensitive_data(content, context)
        violations.concat(sensitive_violations)
      end

      # 檢查個人資料
      if personal_data_detection_enabled?
        personal_violations = scan_personal_data(content, context)
        violations.concat(personal_violations)
      end

      violations
    end

    def scan_sensitive_data(content, context = {})
      violations = []
      
      sensitive_patterns.each_with_index do |pattern, index|
        begin
          regex = Regexp.new(pattern, Regexp::IGNORECASE | Regexp::MULTILINE)
          matches = content.scan(regex)
          
          matches.each do |match|
            violations << {
              type: 'sensitive_data',
              pattern_index: index,
              pattern: pattern,
              match: match.is_a?(Array) ? match.first : match,
              context: context,
              severity: 'high'
            }
          end
        rescue RegexpError => e
          Rails.logger.error "Data Protection Guard: Invalid regex pattern #{pattern}: #{e.message}"
        end
      end

      violations
    end

    def scan_personal_data(content, context = {})
      violations = []
      
      personal_patterns.each_with_index do |pattern, index|
        begin
          regex = Regexp.new(pattern, Regexp::IGNORECASE | Regexp::MULTILINE)
          matches = content.scan(regex)
          
          matches.each do |match|
            violations << {
              type: 'personal_data',
              pattern_index: index,
              pattern: pattern,
              match: match.is_a?(Array) ? match.first : match,
              context: context,
              severity: 'medium'
            }
          end
        rescue RegexpError => e
          Rails.logger.error "Data Protection Guard: Invalid regex pattern #{pattern}: #{e.message}"
        end
      end

      violations
    end

    def should_skip_validation?(record)
      return true unless enabled?
      
      # 檢查是否在排除的專案中
      if record.respond_to?(:project) && record.project
        return true if excluded_projects.include?(record.project.identifier)
      end

      false
    end

    def log_violation(violation)
      return unless log_violations?

      DataProtectionLogger.log_violation(violation)
    end

    def generate_error_message(violations)
      return nil if violations.empty?

      messages = []
      
      violations.group_by { |v| v[:type] }.each do |type, type_violations|
        case type
        when 'sensitive_data'
          messages << "偵測到 #{type_violations.length} 個機敏資料項目："
          type_violations.each do |violation|
            messages << "  - #{violation[:match]}"
          end
        when 'personal_data'
          messages << "偵測到 #{type_violations.length} 個個人資料項目："
          type_violations.each do |violation|
            messages << "  - #{violation[:match]}"
          end
        end
      end

      messages << "\n請移除上述機敏資料或個人資料後再提交。"
      messages.join("\n")
    end
  end
end
