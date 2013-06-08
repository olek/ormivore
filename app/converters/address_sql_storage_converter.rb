module App
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

    def attributes_list_to_storage(list)
      list.dup.tap { |converted|
        if converted.delete(:account_id)
          converted << :addressable_id << :addressable_type
        end
      }
    end

    def from_storage(attrs)
      attrs.dup.tap { |copy|
        copy[:type] = REVERSE_ADDRESS_TYPE_MAP[copy[:type]] if copy[:type]
        addressable_id, addressable_type = copy.delete(:addressable_id), copy.delete(:addressable_type)
        if addressable_id && addressable_type
          replacement_attr = case addressable_type
          when 'Account'
            :account_id
          else
            raise ORMivore::BadAttributesError, "Unknown addressable_type #{addressable_type.inspect}"
          end
          copy[replacement_attr] = addressable_id
        end
      }
    end

    def to_storage(attrs)
      attrs.dup.tap { |copy|
        copy[:type] = ADDRESS_TYPE_MAP[copy[:type]] if copy[:type]
        account_id = copy.delete(:account_id)
        if account_id
          copy[:addressable_id] = account_id
          copy[:addressable_type] = 'Account'
        end
      }
    end
  end
end
