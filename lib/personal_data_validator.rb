# frozen_string_literal: true

class PersonalDataValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return unless DataProtectionGuard.personal_data_detection_enabled?
    return if DataProtectionGuard.should_skip_validation?(record)

    violations = DataProtectionGuard.scan_personal_data(value.to_s, {
      field: attribute,
      model: record.class.name,
      id: record.id
    })

    violations.each do |violation|
      DataProtectionGuard.log_violation(violation)
    end

    if DataProtectionGuard.block_submission? && violations.any?
      error_message = DataProtectionGuard.generate_error_message(violations)
      record.errors.add(attribute, error_message)
    end
  end
end
