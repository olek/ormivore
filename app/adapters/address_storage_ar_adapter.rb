module ORMivoreApp
  class AddressStorageArAdapter

    def initialize(converter = nil)
      @converter = converter || AddressSqlStorageConverter.new
    end

    def find(conditions, options = {})
      quiet = options.fetch(:quiet, false)
      record = AddressRecord.first(:conditions => conditions)
      if quiet
        record ? entity_attributes(record) : nil
      else
        raise ORMivore::RecordNotFound, "#{AddressRecord} with conditions #{conditions} was not found" if record.nil?
        entity_attributes(record)
      end
    end

    def create(attrs)
      entity_attributes(AddressRecord.create!(attrs))
    end

    def update(attrs, conditions)
      AddressRecord.update_all(attrs, conditions)
    end

    private

    attr_reader :converter

    def entity_attributes(record)
      # TODO we should not be reading all those columns from database in first place - performance hit

      attrs_to_ignore = %w(created_at updated_at)

      converter.from_storage(record.attributes.except(*attrs_to_ignore).symbolize_keys)
    end

    class AddressRecord < ActiveRecord::Base
      set_table_name 'addresses'
      def attributes_protected_by_default; []; end
      # self.logger = Logger.new(STDOUT)
    end
  end
end
