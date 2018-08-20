require 'csv'
require 'fileutils'
require 'logger'
require_relative '../config/initialize'
require_relative '../db/connect'
Dir['models/*'].each {|f| require_relative f }

TARGET_DATE = (Date.today - 2).strftime('%F')
TARGET_FILES = Dir[File.join(Settings.import.src_dir, "*_#{TARGET_DATE}.csv")]

rates_file = TARGET_FILES.inject([]) do |rates, file|
  CSV.read(file, :converters => :all).each do |rate|
    rates << [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]]
  end
end.uniq {|rate| [rate[0], rate[1]] }

FileUtils.rm(TARGET_FILES) if rates_file.size == Rate.where('DATE(`time`) = ?', TARGET_DATE).size
