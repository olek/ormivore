module ORMivore
  module Entity
    # TODO see if using Coercible project is of benefit https://github.com/solnic/coercible
    module Coercions
      class Symbol
        def self.coerce(value)
          value.to_sym
        end
      end

      class Boolean
        def self.coerce(value)
          case value
          when true, :true, 'true', 'TRUE'
            true
          else
            false
          end
        end
      end

      class Time
        def self.coerce(value)
          case value
          when ::ActiveSupport::TimeWithZone, ::Time, ::DateTime
            value.in_time_zone
          else
            ::Time.zone.parse(value.to_s)
          end
        end
      end

      class Integer
        def self.coerce(value)
          Kernel.Integer(value)
        end
      end

      class BigDecimal
        def self.coerce(value)
          Kernel.BigDecimal(value)
        end
      end

      class Float
        def self.coerce(value)
          Kernel.Float(value)
        end
      end

      class Rational
        def self.coerce(value)
          Kernel.Rational(value)
        end
      end

      class String
        def self.coerce(value)
          Kernel.String(value)
        end
      end
    end
  end
end
