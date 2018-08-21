require 'csv'
require 'fileutils'
require 'logger'
require 'tmpdir'
require_relative 'config/initialize'
require_relative 'db/connect'
Dir['models/*'].each {|f| require_relative f }

TARGET_DATE = (Date.today - 2).strftime('%F')
TARGET_FILES = Dir[File.join(Settings.import.src_dir, "*_#{TARGET_DATE}.csv")]
BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.backup_dir)

Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |dir|
  tmp_file_name = File.join(dir, 'rates.csv')

  TARGET_FILES.each do |file|
    CSV.open(tmp_file_name, 'w') do |csv|
      rates = CSV.read(file, :converters => :all).map do |rate|
        [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]]
      end.uniq {|rate| [rate[0], rate[1]] }

      rates.each {|rate| csv << rate }
    end

    id = Settings.import.columns.size.times.map {|i| "@#{i + 1}" }.join(',')
    variable = Settings.import.columns.map.with_index(1) do |column, i|
      "#{column}=@#{i}"
    end.join(',')

    sql = <<"EOF"
LOAD DATA LOCAL INFILE '#{tmp_file_name}'
  INTO TABLE #{Rate.table_name}
  FIELDS TERMINATED BY ',' (#{id}) SET #{variable}
EOF
    ActiveRecord::Base.connection.execute(sql)

    rate_size = CSV.read(tmp_file_name).size
    sql = "ALTER TABLE #{Rate.table_name} AUTO_INCREMENT = #{rate_size + 1}"
    ActiveRecord::Base.connection.execute(sql)
  end
end

rates = Rate.where('DATE(`time`) = ?', TARGET_DATE)
unless rates.empty?
  FileUtils.mkdir_p(BACKUP_DIR)

  CSV.open(File.join(BACKUP_DIR, "#{TARGET_DATE}.csv"), 'w') do |csv|
    rates.each do |rate|
      csv << [rate.id, rate.time.strftime('%F %T'), rate.pair, rate.bid, rate.ask]
    end
  end
end
