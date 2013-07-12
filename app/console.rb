# Allows running a lightweight version of rails console
# Start it like this:
#
# irb -r ./lib/console.rb

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require 'active_record'
require 'logger'

require_relative 'require_helpers'

RequireHelpers.require_all

ConnectionManager.establish_connection(:dev, Logger.new(STDOUT))
