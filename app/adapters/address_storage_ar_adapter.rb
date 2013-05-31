module ORMivoreApp
  class AddressStorageArAdapter

    def initialize(converter = nil)
      @converter = converter || AddressSqlStorageConverter.new
    end

    def find(conditions, options = {})
      # TODO how about other finder options, like order, limit, offset?
      quiet = options.fetch(:quiet, false)
      record = record_class.first(:conditions => conditions)
      if quiet
        record ? entity_attributes(record) : nil
      else
        raise ORMivore::RecordNotFound, "#{record_class} with conditions #{conditions} was not found" if record.nil?
        entity_attributes(record)
      end
    end

    def create(attrs)
      entity_attributes(
        record_class.create!(
          converter.to_storage(
            attrs)))
    end

    def update(attrs, conditions)
      record_class.update_all(converter.to_storage(attrs), conditions)
    end

    private

    attr_reader :converter

    def record_class
      AddressRecord
    end

    def entity_attributes(record)
      # TODO we should not be reading all those columns from database in first place - performance hit

      # TODO find out how to handle those 'optional' model attributes, do we need to load them or do we not?
      # attrs_to_ignore = %w(login crypted_password salt created_at updated_at)
      attrs_to_ignore = %w(created_at updated_at)

      converter.from_storage(record.attributes.except(*attrs_to_ignore).symbolize_keys)
    end

    class AddressRecord < ActiveRecord::Base
      set_table_name 'addresses'
      self.inheritance_column = :_type_disabled
      def attributes_protected_by_default; []; end
      # self.logger = Logger.new(STDOUT)
    end
  end
end
