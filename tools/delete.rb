require 'fileutils'
require_relative '../lib/logger'

TARGET_DATE = Date.today - 2
EXPORT_FILE = File.join(Settings.application_root, Settings.backup_dir, "#{TARGET_DATE.strftime('%F')}.csv")
REMOVED_FILES = Dir[File.join(Settings.csv_dir, "*_#{TARGET_DATE.strftime('%F')}.csv")]

if File.exists?(EXPORT_FILE) and not REMOVED_FILES.empty?
  rates_count = REMOVED_FILES.inject(0) {|count, csv| count + File.read(csv).lines.size }
  if rates_count == File.read(EXPORT_FILE).lines.size
    FileUtils.rm(REMOVED_FILES)
    Logger.info(:export_file => EXPORT_FILE, :removed_files => REMOVED_FILES, :num_of_rates => rates_count)
  end
end
