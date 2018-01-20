require 'csv'
require 'fileutils'
require_relative 'helper'
require_relative '../config/settings'
require_relative '../lib/logger'
require_relative '../lib/mysql_client'

def import(file_name)
  Logger.write_with_runtime(:action => 'import', :file_name => file_name) do
    rates = CSV.read(file_name, :converters => :all)
    rates.map! {|rate| [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]] }

    CSV.open(Settings.tmp_file, 'w') do |csv|
      rates.each {|rate| csv << rate }
    end

    MySQLClient.new.load(Settings.tmp_file, 'rates', %w[time pair bid ask])

    FileUtils.rm(Settings.tmp_file)
  end
end
