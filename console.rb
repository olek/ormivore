# Allows running a lightweight version of rails console
# Start it like this:
#
# irb -r ./lib/console.rb

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

#require_relative 'spec/models/

#MobileCheckout::ConnectionManager.establish_connection :development

module RequireHelpers
  class << self
    def root
      File.expand_path('..', __FILE__)
    end

    def augment_load_path
      $LOAD_PATH.unshift(File.join(root, 'lib'))
      $LOAD_PATH.unshift(File.join(root, 'spec'))
      $LOAD_PATH.unshift(File.join(root, 'spec/lib'))
      $LOAD_PATH.unshift(File.join(root))
    end

    def require_independent_files_in_dir(dir)
      Dir.glob(File.join(root, dir, '*.rb')).each do |absolute_path|
        short_path = absolute_path.sub(/^#{root}\/lib\/(.*)\.rb$/, '\1')
        require short_path
      end
    end
  end
end

RequireHelpers.augment_load_path
require File.join(File.dirname(__FILE__), 'lib', 'init.rb')

RequireHelpers.require_independent_files_in_dir 'spec/lib/models'
RequireHelpers.require_independent_files_in_dir 'spec/lib/models/storage/ar'

unless ActiveRecord::Base.connected?
  ActiveRecord::Base.establish_connection(YAML::load(File.open('./spec/database.yml')))
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
