require 'date'
require_relative 'config/settings'
require_relative 'lib/logger'
require_relative 'lib/mysql_client'
Dir['aggregate/*.rb'].each {|file| require_relative file }

TARGET_DATE = Date.today - 2

unless rate_files(TARGET_DATE).empty?
  import(TARGET_DATE)
  export(TARGET_DATE)

  aggregation_date = TARGET_DATE.to_datetime

  client = MySQLClient.new

  Logger.write_with_runtime(:module => 'aggregate', :date => TARGET_DATE.strftime('%F')) do
    (1..1440).each do |offset|
      end_date = aggregation_date + Rational(offset, 24 * 60)

      Settings.interval.keys.each do |time_name|
        send(time_name, end_date).each do |interval, begin_date|
          Settings.pairs.each do |pair|
            param = {
              :begin => begin_date.strftime('%F %T'),
              :end => (end_date - Rational(1, 24 * 60 * 60)).strftime('%F %T'),
              :pair => pair,
              :interval => interval,
            }
            client.create_candle_sticks(param)
          end
        end
      end
    end
  end
end
