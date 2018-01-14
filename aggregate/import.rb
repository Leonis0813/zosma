require 'csv'
require 'fileutils'
require_relative 'helper'
require_relative '../config/settings'
require_relative '../lib/logger'
require_relative '../lib/mysql_client'

def import(date)
  target_files = rate_files(date)

  client = MySQLClient.new

  Logger.write_with_runtime(:module => 'import', :rate_files => target_files.map {|file| File.basename(file) }) do
    target_files.each do |target_file|
      rates = CSV.read(target_file, :converters => :all)
      rates.map! {|rate| [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]] }

      CSV.open(Settings.tmp_file, 'w') do |csv|
        rates.each {|rate| csv << rate }
      end

      client.import_rates(Settings.tmp_file)

      FileUtils.rm(Settings.tmp_file)
    end
  end
end
