# frozen_string_literal: true

module Extensions
  module Attachment
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
        return filename.present? || description.present?
      end
      
      # 對於現有記錄，檢查是否有內容變更
      content_fields = ['filename', 'description']
      content_fields.any? { |field| 
        # 檢查欄位是否有實際變更，而不是僅僅被觸摸
        send("#{field}_changed?") && send(field).present?
      }
    end

    def check_data_protection
      violations = []

      # 檢查檔案名稱（如果沒有被排除）
      if filename.present? && !DataProtectionGuard.should_skip_field_validation?('filename')
        context = { field: 'filename', model: 'Attachment', id: id }
        violations.concat(DataProtectionGuard.scan_content(filename, context))
      end

      # 檢查檔案描述（如果沒有被排除）
      if description.present? && !DataProtectionGuard.should_skip_field_validation?('description')
        context = { field: 'description', model: 'Attachment', id: id }
        violations.concat(DataProtectionGuard.scan_content(description, context))
      end

      # 檢查檔案內容（如果是文字檔案且沒有被排除）
      if readable? && text_file? && !DataProtectionGuard.should_skip_field_validation?('file_content')
        begin
          content = read_file_content
          if content.present?
            context = { field: 'file_content', model: 'Attachment', id: id, filename: filename }
            violations.concat(DataProtectionGuard.scan_content(content, context))
          end
        rescue => e
          Rails.logger.error "Data Protection Guard: Error reading file content: #{e.message}"
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

    def text_file?
      return false unless content_type.present?
      
      text_types = [
        'text/plain',
        'text/html',
        'text/xml',
        'text/css',
        'text/javascript',
        'application/json',
        'application/xml',
        'application/javascript',
        'application/x-yaml',
        'application/x-www-form-urlencoded'
      ]
      
      text_types.any? { |type| content_type.start_with?(type) } ||
      filename.match?(/\.(txt|log|ini|conf|config|yml|yaml|json|xml|html|css|js|sql|sh|bat|ps1|md|rst)$/i)
    end

    def read_file_content
      return nil unless readable?
      
      # 限制檔案大小，避免讀取過大的檔案
      max_size = 1024 * 1024 # 1MB
      return nil if file.size > max_size
      
      file.read
    rescue => e
      Rails.logger.error "Data Protection Guard: Error reading file: #{e.message}"
      nil
    end
  end
end

# 擴展會在 init.rb 中處理
