require 'fileutils'
require 'json'
require_relative '../config/settings'

module Logger
  LOG_DIR = "#{Settings.application_root}/log"

  class << self
    def info(body)
      FileUtils.mkdir_p(LOG_DIR)
      body = ['[I]', "[#{Time.now.strftime('%F %T.%6N')}]", body.to_json].join('')
      File.open("#{LOG_DIR}/#{caller[-1][/^(.*)\./, 1]}.log", 'a') {|file| file.puts(body) }
      puts body if ENV['STDOUT'].to_s == 'on'
    end

    def write_with_runtime(body)
      start_time = Time.now
      result = yield
      end_time = Time.now
      info body.merge(:runtime => end_time - start_time)
      result
    end
  end
end
