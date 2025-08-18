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
      fields = Setting.plugin_data_protection_guard['excluded_fields']
      return [] if fields.nil?
      
      # 確保返回陣列
      if fields.is_a?(Array)
        fields
      elsif fields.is_a?(String)
        fields.split(",").map(&:strip).reject(&:empty?)
      else
        []
      end
    end

    def excluded_projects
      projects = Setting.plugin_data_protection_guard['excluded_projects']
      return [] if projects.nil?
      
      # 確保返回陣列
      if projects.is_a?(Array)
        projects
      elsif projects.is_a?(String)
        projects.split(",").map(&:strip).reject(&:empty?)
      else
        []
      end
    end

    def sensitive_patterns
      patterns = Setting.plugin_data_protection_guard['sensitive_patterns']
      return [] if patterns.nil?
      
      # 確保返回陣列
      if patterns.is_a?(Array)
        patterns
      elsif patterns.is_a?(String)
        patterns.split("\n").map(&:strip).reject(&:empty?)
      else
        []
      end
    end

    def personal_patterns
      patterns = Setting.plugin_data_protection_guard['personal_patterns']
      return [] if patterns.nil?
      
      # 確保返回陣列
      if patterns.is_a?(Array)
        patterns
      elsif patterns.is_a?(String)
        patterns.split("\n").map(&:strip).reject(&:empty?)
      else
        []
      end
    end

    def scan_content(content, context = {})
      return [] unless enabled?
      return [] if content.nil? || content.to_s.strip.empty?

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
          # 在獨立測試環境中，Rails.logger 可能不存在
          if defined?(Rails) && Rails.logger
            Rails.logger.error "Data Protection Guard: Invalid regex pattern #{pattern}: #{e.message}"
          else
            puts "Data Protection Guard: Invalid regex pattern #{pattern}: #{e.message}"
          end
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
          # 在獨立測試環境中，Rails.logger 可能不存在
          if defined?(Rails) && Rails.logger
            Rails.logger.error "Data Protection Guard: Invalid regex pattern #{pattern}: #{e.message}"
          else
            puts "Data Protection Guard: Invalid regex pattern #{pattern}: #{e.message}"
          end
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

    def should_skip_field_validation?(field_name)
      return false unless enabled?
      
      # 檢查欄位是否在排除清單中
      excluded_fields.include?(field_name.to_s)
    end

    def log_violation(violation, request = nil)
      return unless log_violations?

      DataProtectionLogger.log_violation(violation, request)
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
