module ORMivoreApp
  module Storage
    module AR
      class AddressStorage
        def self.find_by_account_id(account_id)
          to_model(
            AddressARModel.find(:first, :conditions => { addressable_id: account_id, addressable_type: 'Account' })
          )
        end

        def self.to_model(storage_object)
          if storage_object
            # puts "DDDDD: storage_object.attributes: #{storage_object.attributes.inspect}"
            model_class.new(storage_object.to_model_attributes)
          else
            nil
          end
        end

        def self.model_class
          ORMivoreApp::Address
        end

        def self.create(model)
          if model.new?
            attrs = extract_attributes_from(model)

            begin
              AddressARModel.create!(attrs)
            rescue => e
              raise ORMivore::StorageError, e.message
            end
          else
            raise ORMivore::RecordAlreadyExists
          end
        end

        def self.update(model)
          if model.new?
            raise ORMivore::RecordNotFound
          else
            attrs = extract_attributes_from(model)

            count = 0
            begin
              count = AddressARModel.update_all(attrs, { :id => to_id(model.id) })
            rescue => e
              raise ORMivore::StorageError, e.message
            end

            raise StorageError, 'No records updated' if count.zero?
            raise StorageError, 'WTF' if count > 1
          end
        end

        def self.extract_attributes_from(model)
          model.to_hash.merge(
              addressable_id: to_id(model.addressable.id),
              addressable_type: model.addressable.class.name.demodulize
          ).tap { |attrs|
            attrs.delete(:addressable)

            attrs[:type] = AddressTypeConverter.model_to_storage(attrs.delete(:type))
          }
        end

        def self.to_id(value)
          int_value = value.to_i
          raise ORMivore::StorageError, "Not a valid id: #{value.inspect}" unless int_value > 0

          int_value
        end
      end

      class AddressARModel < ActiveRecord::Base
        set_table_name 'addresses'
        self.store_full_sti_class = false
        self.inheritance_column = :_type_disabled
        # self.logger = Logger.new(STDOUT)

        def attributes_protected_by_default; []; end

        def to_model_attributes
          attributes.except(*%w(type addressable_id addressable_type created_at updated_at)).tap { |attrs|
            attrs[:type] = AddressTypeConverter.storage_to_model(type)
            # TODO sometimes lazy loading is needed
            attrs[:addressable] = ORMivoreApp.const_get(addressable_type, false).
              find_by_id(addressable_id)
          }
        end
      end

      class AddressTypeConverter
        MAPPING = [
          [:shipping, 'ShippingAddress'],
          [:billing, 'BillingAddress'],
        ]

        def self.model_to_storage(type)
          MAPPING.assoc(type).try(:last) or raise "Unknown type #{type}"
        end

        def self.storage_to_model(type)
          MAPPING.rassoc(type).try(:first) or raise "Unknown type #{type}"
        end
      end
    end
  end
end

ORMivoreApp::Address.storage = ORMivoreApp::Storage::AR::AddressStorage
