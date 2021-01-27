require 'active_record'
require 'config'
require_relative '../models/application_record'

APPLICATION_ROOT = File.expand_path(File.dirname('..'))
Config.load_and_set_settings(File.join(APPLICATION_ROOT, 'config/settings.yml'))
