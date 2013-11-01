module ORMivore
  module Connections
    class << self
      attr_accessor :redis
      attr_accessor :sequel
    end
  end
end
