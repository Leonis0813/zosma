require 'date'
require_relative 'config/settings'
require_relative 'lib/logger'
require_relative 'lib/mysql_client'

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

TARGET_DATE = Date.today - 2

client = MysqlClient.new

Logger.write_with_runtime(:action => 'aggregate', :date => TARGET_DATE.strftime('%F')) do
  (1..1440).each do |offset|
    end_date = TARGET_DATE.to_datetime + Rational(offset, 24 * 60)

    Settings.interval.keys.each do |time_name|
      send(time_name, end_date).each do |interval, begin_date|
        Settings.pairs.each do |pair|
          param = {
            :begin => begin_date.strftime('%F %T'),
            :end => (end_date - Rational(1, 24 * 60 * 60)).strftime('%F %T'),
            :pair => pair,
            :interval => interval,
          }

          query = File.read(File.join(Settings.application_root, 'aggregate/candle_sticks.sql'))
          param.each {|key, value| query.gsub!("$#{key.upcase}", value) }

          start_time = Time.now
          client.execute_query(query)
          end_time = Time.now
          body = {
            :sql => 'candle_sticks.sql',
            :param => param,
            :mysql_runtime => (end_time - start_time),
          }
          Logger.info(body)
        end
      end
    end
  end
end
