require_relative 'config/initialize'
require_relative 'db/connect'
Dir['models/*'].each {|f| require_relative f }

ALL_DATA_TYPES = %w[rate candle_stick moving_average].freeze

logger = ZosmaLogger.new(Settings.logger.path.import)

logger.info('================ Start Import ================')

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 7)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : Date.today
  data_types = ARGV.find {|arg| arg.start_with?('--data-types') }
  data_types = data_types&.match(/\A--data-types=(.*)\z/)
  data_types = data_types ? data_types[1].split(',') : ALL_DATA_TYPES
  raise ArgumentError unless (data_types - ALL_DATA_TYPES).empty?
rescue ArgumentError => e
  logger.error(e.backtrace.join("\n"))
  raise e
end

logger.info('Parameter:')
logger.info("  from: #{from}")
logger.info("  to: #{to}")
logger.info("  data_types: #{data_types}")

(from..to).each do |date|
  logger.info("============ Import #{date} data")

  data_types.each do |data_type|
    logger.info("======== Import #{data_type}")

    klass = data_type.camelize.constantize

    Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |tmp_dir|
      tmp_file_name = File.join(tmp_dir, Settings.import.file[data_type].tmp_file)
      file_pattern = "*_#{date.strftime('%F')}.csv"

      target_files =
        Dir[File.join(Settings.import.file[data_type].src_dir, file_pattern)]
      logger.info("Target Files: #{target_files}")

      FileUtils.cp(target_files, tmp_dir)
      target_files = Dir[File.join(tmp_dir, file_pattern)]

      target_files.each do |file|
        logger.info("==== Import #{file}")

        klass.create_infile(file, tmp_file_name)
        lines = File.read(tmp_file_name).lines.size
        bytes = File.stat(tmp_file_name).size
        logger.info("Create infile (#{lines} lines, #{bytes} bytes)")

        last_id_before = Rate.select(:id).order(id: :desc).limit(1).first.id
        klass.load_data(tmp_file_name)
        last_id_after = Rate.select(:id).order(id: :desc).limit(1).first.id
        logger.info("Load #{last_id_after - last_id_before} rates to table")
      end

      logger.info('====') unless target_files.empty?
    end
  end

  logger.info('========')
end

logger.info('============')
logger.info('================ Finish Import ================')
