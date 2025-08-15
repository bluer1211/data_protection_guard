# frozen_string_literal: true

module DataProtectionGuard
  module JournalExtension
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
      content_fields = ['notes']
      content_fields.any? { |field| send("#{field}_changed?") }
    end

    def check_data_protection
      violations = []

      # 檢查備註欄位
      if notes.present?
        context = { field: 'notes', model: 'Journal', id: id, journalized_type: journalized_type, journalized_id: journalized_id }
        violations.concat(DataProtectionGuard.scan_content(notes, context))
      end

      # 檢查詳細變更
      if details.any?
        details.each do |detail|
          if detail.value.present? && detail.value.is_a?(String)
            context = { field: "detail_#{detail.prop_key}", model: 'Journal', id: id, journalized_type: journalized_type, journalized_id: journalized_id }
            violations.concat(DataProtectionGuard.scan_content(detail.value, context))
          end
        end
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
