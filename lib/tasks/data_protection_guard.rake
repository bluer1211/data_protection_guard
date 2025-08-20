namespace :data_protection_guard do
  desc "清理舊的違規記錄"
  task :clear_old_logs, [:days] => :environment do |task, args|
    days = (args[:days] || 30).to_i
    puts "開始清理 #{days} 天前的違規記錄..."
    
    deleted_count = DataProtectionLogger.clear_old_logs(days)
    puts "已清理 #{deleted_count} 筆記錄"
  end

  desc "清理特定類型的舊記錄"
  task :clear_logs_by_type, [:type, :days] => :environment do |task, args|
    type = args[:type] || 'sensitive_data'
    days = (args[:days] || 30).to_i
    
    unless ['sensitive_data', 'personal_data'].include?(type)
      puts "錯誤：類型必須是 'sensitive_data' 或 'personal_data'"
      exit 1
    end
    
    puts "開始清理 #{days} 天前的 #{type} 記錄..."
    
    deleted_count = DataProtectionLogger.clear_logs_by_type(type, days)
    puts "已清理 #{deleted_count} 筆 #{type} 記錄"
  end

  desc "顯示日誌統計資訊"
  task :statistics => :environment do
    stats = DataProtectionLogger.get_log_statistics
    
    if stats.empty?
      puts "沒有找到任何記錄"
    else
      puts "=== 資料保護日誌統計 ==="
      puts "總記錄數: #{stats[:total_count]}"
      puts "機敏資料記錄: #{stats[:sensitive_data_count]}"
      puts "個人資料記錄: #{stats[:personal_data_count]}"
      puts "今日記錄: #{stats[:today_count]}"
      puts "本週記錄: #{stats[:week_count]}"
      puts "本月記錄: #{stats[:month_count]}"
      puts "最早記錄: #{stats[:oldest_record]}"
      puts "最新記錄: #{stats[:newest_record]}"
    end
  end

  desc "自動清理任務（建議加入 cron）"
  task :auto_clean => :environment do
    # 從設定中取得清理天數，預設 30 天
    cleanup_days = Setting.plugin_data_protection_guard['auto_cleanup_days'] || 30
    
    puts "執行自動清理任務，清理 #{cleanup_days} 天前的記錄..."
    
    deleted_count = DataProtectionLogger.clear_old_logs(cleanup_days)
    puts "自動清理完成，已清理 #{deleted_count} 筆記錄"
  end
end
