module ORMivoreApp
  module Storage
    module AR
      class AccountStorage
        def self.find_by_id(account_id)
          to_model(
            AccountARModel.find_by_id(account_id).tap { |o|
              raise ORMivore::RecordNotFound, "#{model_class} with id #{account_id} was not found" if o.nil?
            }
          )
        end

        def self.to_model(storage_object)
          if storage_object
            model_class.new(storage_object.to_model_attributes)
          else
            nil
          end
        end

        def self.model_class
          ORMivoreApp::Account
        end

        def self.update(model)
          if model.new?
            raise ORMivore::RecordNotFound
          else
            attrs = model.to_hash

            count = 0
            begin
              count = AccountARModel.update_all(attrs, { :id => to_id(model.id) })
            rescue => e
              raise StorageError, e.message
            end

            raise ORMivore::StorageError, 'No records updated' if count.zero?
            raise ORMivore::StorageError, 'WTF' if count > 1
          end
        end

        def self.to_id(value)
          int_value = value.to_i
          raise ORMivore::StorageError, "Not a valid id: #{value.inspect}" unless int_value > 0

          int_value
        end
      end

      class AccountARModel < ActiveRecord::Base
        set_table_name 'accounts'
        def attributes_protected_by_default; []; end
        # self.logger = Logger.new(STDOUT)

        def to_model_attributes
          # TODO we should not be reading all those columns from database in first place - performance hit

          attrs_to_ignore = %w(login crypted_password salt created_at updated_at)

          attributes.except(*attrs_to_ignore)
        end
      end
    end
  end
end

ORMivoreApp::Account.storage = ORMivoreApp::Storage::AR::AccountStorage
