# frozen_string_literal: true

module Extensions
  module IssuesController
    extend ActiveSupport::Concern

    included do
      before_action :check_issue_data_protection, only: [:update, :create]
      before_action :check_notes_data_protection, only: [:update, :create]
      before_action :restore_form_data, only: [:edit]
    end

    private

    def check_notes_data_protection
      return unless DataProtectionGuard.enabled?
      return unless DataProtectionGuard.block_submission?
      
      # 檢查 notes 欄位
      notes = params.dig(:issue, :notes) || params[:notes]
      return if notes.blank?

      # 檢查 notes 是否被排除
      return if DataProtectionGuard.should_skip_field_validation?('notes')

      # 掃描 notes 內容
      context = { 
        field: 'notes', 
        model: 'Journal', 
        id: 'new',
        issue_id: @issue&.id || params[:id]
      }
      
      violations = DataProtectionGuard.scan_content(notes, context)
      
      if violations.any?
        # 記錄違規
        violations.each { |violation| DataProtectionGuard.log_violation(violation) }
        
        # 生成錯誤訊息
        error_message = DataProtectionGuard.generate_error_message(violations)
        
        # 設定 flash 訊息
        flash[:error] = error_message
        
        # 保留表單資料
        retain_form_data
        
        # 重新導向到編輯頁面
        redirect_to edit_issue_path(@issue || params[:id])
        return
      end
    end

    def check_issue_data_protection
      return unless DataProtectionGuard.enabled?
      return unless DataProtectionGuard.block_submission?
      
      # 檢查 issue 的主要欄位
      subject = params.dig(:issue, :subject)
      description = params.dig(:issue, :description)
      
      violations = []
      
      # 檢查主旨
      if subject.present? && !DataProtectionGuard.should_skip_field_validation?('subject')
        context = { field: 'subject', model: 'Issue', id: @issue&.id || 'new' }
        violations.concat(DataProtectionGuard.scan_content(subject, context))
      end
      
      # 檢查描述
      if description.present? && !DataProtectionGuard.should_skip_field_validation?('description')
        context = { field: 'description', model: 'Issue', id: @issue&.id || 'new' }
        violations.concat(DataProtectionGuard.scan_content(description, context))
      end
      
      if violations.any?
        # 記錄違規
        violations.each { |violation| DataProtectionGuard.log_violation(violation) }
        
        # 生成錯誤訊息
        error_message = DataProtectionGuard.generate_error_message(violations)
        
        # 設定 flash 訊息
        flash[:error] = error_message
        
        # 保留表單資料
        retain_form_data
        
        # 重新導向到編輯頁面
        redirect_to edit_issue_path(@issue || params[:id])
        return
      end
    end

    def retain_form_data
      # 將表單資料存儲在 session 中，以便在重新導向後恢復
      session[:issue_form_data] = {
        'issue[subject]' => params.dig(:issue, :subject),
        'issue[description]' => params.dig(:issue, :description),
        'issue[notes]' => params.dig(:issue, :notes) || params[:notes],
        'issue[tracker_id]' => params.dig(:issue, :tracker_id),
        'issue[status_id]' => params.dig(:issue, :status_id),
        'issue[priority_id]' => params.dig(:issue, :priority_id),
        'issue[assigned_to_id]' => params.dig(:issue, :assigned_to_id),
        'issue[start_date]' => params.dig(:issue, :start_date),
        'issue[due_date]' => params.dig(:issue, :due_date),
        'issue[estimated_hours]' => params.dig(:issue, :estimated_hours),
        'issue[done_ratio]' => params.dig(:issue, :done_ratio),
        'issue[is_private]' => params.dig(:issue, :is_private),
        'time_entry[hours]' => params.dig(:time_entry, :hours),
        'time_entry[activity_id]' => params.dig(:time_entry, :activity_id),
        'time_entry[comments]' => params.dig(:time_entry, :comments)
      }
    end

    def restore_form_data
      return unless session[:issue_form_data]
      
      # 在編輯頁面恢復表單資料
      form_data = session[:issue_form_data]
      
      # 恢復 issue 屬性
      if @issue && form_data
        form_data.each do |key, value|
          if key.start_with?('issue[') && value.present?
            # 提取欄位名稱
            field_name = key.match(/issue\[(.*)\]/)&.[](1)
            if field_name && @issue.respond_to?("#{field_name}=")
              @issue.send("#{field_name}=", value)
            end
          end
        end
      end
      
      # 設定實例變數供視圖使用
      @restored_form_data = form_data
      session.delete(:issue_form_data)
    end
  end
end
