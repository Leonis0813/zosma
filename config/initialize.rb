require 'active_record'
require 'config'
require 'csv'
require 'fileutils'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../lib/zosma_logger'
require_relative '../models/application_record'

APPLICATION_ROOT = File.expand_path(File.dirname('..'))
Config.load_and_set_settings(File.join(APPLICATION_ROOT, 'config/settings.yml'))
