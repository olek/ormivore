# coding: utf-8

module ORMivoreApp
  class AddressSqlStorageConverter
    ADDRESS_TYPE_MAP = Hash.new { |h, k|
      raise ArgumentError, "Addressable type #{k.inspect} not known"
    }.update(
      shipping: 'ShippingAddress',
      billing: 'BillingAddress'
    ).freeze

    REVERSE_ADDRESS_TYPE_MAP = Hash.new { |h, k|
      raise ArgumentError, "Addressable type #{k.inspect} not known"
    }.update(
      Hash[ADDRESS_TYPE_MAP.to_a.map(&:reverse)]
    ).freeze

    def from_storage(attrs)
      attrs.dup.tap { |copy|
        copy[:type] = REVERSE_ADDRESS_TYPE_MAP[copy[:type]]
      }
    end

    def to_storage(attrs)
      attrs.dup.tap { |copy|
        copy[:type] = ADDRESS_TYPE_MAP[copy[:type]]
      }
    end
  end
end
