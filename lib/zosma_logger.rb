require 'json'
require 'logger'

class ZosmaLogger < Logger
  def initialize(file_path)
    super(file_path)

    self.formatter = proc do |severity, datetime, progname, message|
      time = datetime.utc.strftime(Settings.logger.time_format)
      message = message.to_json if message.kind_of?(Hash)
      log = "[#{severity}] [#{time}]: #{message}"
      puts log if ENV['STDOUT'] == 'on'
      "#{log}\n"
    end
  end
end
