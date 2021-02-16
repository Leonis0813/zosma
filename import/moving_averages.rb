require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../models/moving_average'

logger = ZosmaLogger.new(Settings.logger.path.import)
ApplicationRecord.logger = logger

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 2)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : Date.today
rescue ArgumentError => e
  logger.error(e.backtrace.join("\n"))
  raise e
end

(from..to).each do |date|
  Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |tmp_dir|
    tmp_file_name = File.join(tmp_dir, 'moving_averages.csv')

    file_pattern = "*_#{date.strftime('%F')}.csv"
    target_files =
      Dir[File.join(Settings.import.file.moving_average.src_dir, file_pattern)]
    FileUtils.cp(target_files, tmp_dir)
    target_files = Dir[File.join(tmp_dir, file_pattern)]

    target_files.each do |file|
      logger.info(action: 'read', file: file, size: File.stat(file).size)
      FileUtils.cp(file, tmp_file_name)
      MovingAverage.load_data(tmp_file_name)
    end
  end
end
