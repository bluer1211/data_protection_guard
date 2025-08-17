# frozen_string_literal: true

module Extensions
  module Journal
    extend ActiveSupport::Concern

    included do
      validate :check_data_protection, if: :should_check_data_protection?
    end

    private

    def should_check_data_protection?
      return false unless DataProtectionGuard.enabled?
      return false if DataProtectionGuard.should_skip_validation?(self)
      
      # 對於新記錄，檢查是否有實際內容
      if new_record?
        return notes.present?
      end
      
      # 對於現有記錄，檢查是否有內容變更
      content_fields = ['notes']
      content_fields.any? { |field| 
        # 檢查欄位是否有實際變更，而不是僅僅被觸摸
        send("#{field}_changed?") && send(field).present?
      }
    end

    def check_data_protection
      violations = []

      # 檢查備註（如果沒有被排除）
      if notes.present? && !DataProtectionGuard.should_skip_field_validation?('notes')
        context = { field: 'notes', model: 'Journal', id: id }
        violations.concat(DataProtectionGuard.scan_content(notes, context))
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
