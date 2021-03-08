require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../models/rate'

logger = ZosmaLogger.new(Settings.logger.path.import)

logger.info('============ Start Import ============')

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 7)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : Date.today
rescue ArgumentError => e
  logger.error(e.backtrace.join("\n"))
  raise e
end

logger.info('Parameter:')
logger.info("  from: #{from}")
logger.info("  to: #{to}")

(from..to).each do |date|
  Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |tmp_dir|
    tmp_file_name = File.join(tmp_dir, 'rates.csv')

    file_pattern = "*_#{date.strftime('%F')}.csv"
    logger.info("======== Import #{file_pattern}")

    target_files = Dir[File.join(Settings.import.file.rate.src_dir, file_pattern)]
    logger.info("Target Files: #{target_files}")

    FileUtils.cp(target_files, tmp_dir)

    Dir[File.join(tmp_dir, file_pattern)].each do |file|
      logger.info("==== Import #{file}")

      CSV.open(tmp_file_name, 'w') do |csv|
        rates = CSV.read(file, converters: :all).map do |rate|
          [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]]
        end
        logger.info("Read #{rates.size} lines (#{File.stat(file).size} bytes)")

        rates.uniq! {|rate| [rate[0], rate[1]] }

        rates.each {|rate| csv << rate }
        logger.info("Write #{rates.size} lines to #{tmp_file_name}")
      end

      count_before = Rate.count
      Rate.load_data(tmp_file_name)
      logger.info("Load #{Rate.count - count_before} rates to table")
    end

    logger.info('====')
  end
end
logger.info('========')

logger.info('============ Finish Import ============')
