require 'models/account'

module ORMivore
  module Storage
    module AR
      class AccountStorage
        def self.find_by_id(account_id)
          to_model(
            AccountARModel.find_by_id(account_id).tap { |o|
              raise RecordNotFound, "#{model_class} with id #{account_id} was not found" if o.nil?
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
          ORMivore::Account
        end

        def self.update(model)
          if model.new?
            raise RecordNotFound
          else
            attrs = model.to_hash

            count = 0
            begin
              count = AccountARModel.update_all(attrs, { :id => model.id })
            rescue => e
              raise StorageError, e.message
            end

            raise StorageError, 'No records updated' if count.zero?
            raise StorageError, 'WTF' if count > 1
          end
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

ORMivore::Account.storage = ORMivore::Storage::AR::AccountStorage
