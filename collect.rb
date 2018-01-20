require 'date'
require_relative 'collect/import'
require_relative 'collect/export'
require_relative 'config/settings'
require_relative 'lib/logger'

TARGET_DATE = Date.today - 2
RATE_FILES = Dir[File.join(Settings.csv_dir, "*_#{TARGET_DATE.strftime('%F')}.csv")]

RATE_FILES.each do |rate_file|
  import(rate_file)
end

export_rates(TARGET_DATE) unless RATE_FILES.empty?
