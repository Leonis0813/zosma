require 'date'
require_relative '../config/settings'

def check(time_name, end_date)
  [].tap do |intervals|
    Settings.interval[time_name].each {|check_time| intervals << "#{check_time}-#{time_name}" if end_date.send(time_name) % check_time == 0 }
  end
end

def min(end_date)
  intervals = check('min', end_date)
  intervals.map {|interval| [interval, end_date - Rational(interval.split('-').first.to_i, 24 * 60)] }
end

def hour(end_date)
  intervals = end_date.min == 0 ? check('hour', end_date) : []
  intervals.map {|interval| [interval, end_date - Rational(interval.split('-').first.to_i, 24)] }
end

def day(end_date)
  intervals = (end_date.min == 0 and end_date.hour == 0) ? check('day', end_date) : []
  intervals.map {|interval| [interval, end_date - interval.split('-').first.to_i] }
end

def month(end_date)
  intervals = (end_date.min == 0 and end_date.hour == 0 and end_date.day == 1) ? check('month', end_date) : []
  intervals.map {|interval| [interval, end_date << interval.split('-').first.to_i] }
end

def year(end_date)
  intervals = (end_date.min == 0 and end_date.hour == 0 and end_date.day == 1 and end_date.month == 1) ? check('year', end_date) : []
  intervals.map {|interval| [interval, end_date << (12 * interval.split('-').first.to_i)] }
end

def rate_files(date)
  Dir[File.join(Settings.csv_dir, "*_#{date.strftime('%F')}.csv")]
end

def export_file(date)
  File.join(Settings.application_root, Settings.backup_dir, "#{date.strftime('%F')}.csv")
end
