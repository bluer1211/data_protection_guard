# frozen_string_literal: true

module DataProtectionGuard
  module IssueExtension
    extend ActiveSupport::Concern

    included do
      validate :check_data_protection, if: :should_check_data_protection?
    end

    private

    def should_check_data_protection?
      return false unless DataProtectionGuard.enabled?
      return false if DataProtectionGuard.should_skip_validation?(self)
      return false if new_record? && !changed?
      
      # 檢查是否有內容變更
      content_fields = ['description', 'subject']
      content_fields.any? { |field| send("#{field}_changed?") }
    end

    def check_data_protection
      violations = []

      # 檢查描述欄位
      if description.present?
        context = { field: 'description', model: 'Issue', id: id }
        violations.concat(DataProtectionGuard.scan_content(description, context))
      end

      # 檢查主旨欄位（如果不在排除清單中）
      if subject.present? && !DataProtectionGuard.excluded_fields.include?('subject')
        context = { field: 'subject', model: 'Issue', id: id }
        violations.concat(DataProtectionGuard.scan_content(subject, context))
      end

      # 記錄違規
      violations.each { |violation| DataProtectionGuard.log_violation(violation) }

      # 如果設定了阻擋提交且有違規
      if DataProtectionGuard.block_submission? && violations.any?
        error_message = DataProtectionGuard.generate_error_message(violations)
        errors.add(:base, error_message)
      end
    end
  end
end

# 擴展會在 init.rb 中處理
