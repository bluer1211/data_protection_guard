# frozen_string_literal: true

class DataProtectionViolation < ActiveRecord::Base
  belongs_to :user, optional: true

  validates :violation_type, presence: true, inclusion: { in: %w[sensitive_data personal_data] }
  validates :pattern, presence: true
  validates :match_content, presence: true
  validates :severity, inclusion: { in: %w[low medium high] }

  scope :sensitive_data, -> { where(violation_type: 'sensitive_data') }
  scope :personal_data, -> { where(violation_type: 'personal_data') }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_date_range, ->(from_date, to_date) { where(created_at: from_date..to_date) }
  scope :recent, ->(days = 30) { where('created_at >= ?', days.days.ago) }

  def violation_type_label
    case violation_type
    when 'sensitive_data'
      I18n.t(:label_sensitive_data)
    when 'personal_data'
      I18n.t(:label_personal_data)
    else
      violation_type
    end
  end

  def severity_label
    case severity
    when 'high'
      I18n.t(:label_high)
    when 'medium'
      I18n.t(:label_medium)
    when 'low'
      I18n.t(:label_low)
    else
      severity
    end
  end

  def context_info
    return nil unless context.present?
    
    begin
      JSON.parse(context)
    rescue JSON::ParserError
      context
    end
  end
end
