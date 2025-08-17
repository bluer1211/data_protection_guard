# frozen_string_literal: true

module Extensions
  module Issue
    extend ActiveSupport::Concern

    included do
      validate :check_data_protection, if: :should_check_data_protection?
    end

    private

    def should_check_data_protection?
      return false unless DataProtectionGuard.enabled?
      return false if DataProtectionGuard.should_skip_validation?(self)
      
      # 對於新記錄，總是檢查
      return true if new_record?
      
      # 對於現有記錄，檢查是否有內容變更
      # 使用更寬鬆的檢查方式，避免與 Redmine 編輯流程衝突
      content_fields = ['subject', 'description']
      content_fields.any? { |field| 
        # 檢查欄位是否有實際變更，而不是僅僅被觸摸
        send("#{field}_changed?") && send(field).present?
      }
    end

    def check_data_protection
      violations = []

      # 檢查主旨（如果沒有被排除）
      if subject.present? && !DataProtectionGuard.should_skip_field_validation?('subject')
        context = { field: 'subject', model: 'Issue', id: id }
        violations.concat(DataProtectionGuard.scan_content(subject, context))
      end

      # 檢查描述（如果沒有被排除）
      if description.present? && !DataProtectionGuard.should_skip_field_validation?('description')
        context = { field: 'description', model: 'Issue', id: id }
        violations.concat(DataProtectionGuard.scan_content(description, context))
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
