# Allows running a lightweight version of rails console
# Start it like this:
#
# irb -r ./lib/console.rb

require 'rubygems'
require 'bundler/setup'

Bundler.require(:sinatra)

require_relative 'app'

MobileCheckout::ConnectionManager.establish_connection :development
