# coding: utf-8

module ORMivoreApp
  class AccountRepo
    def initialize(port, entity_class = nil)
      @port = port
      @entity_class = entity_class || ORMivoreApp::Account
    end

    def find_by_id(id, options = {})
      attrs_to_entity(port.find({ id: id }, options))
    end

    def persist(entity)
      if entity.new?
        attrs_to_entity(port.create(entity.to_hash))
      else
        count = port.update(entity.to_hash, { :id => to_id(entity.id) })
        raise ORMivore::StorageError, 'No records updated' if count.zero?
        raise ORMivore::StorageError, 'WTF' if count > 1

        entity
      end
    end

    private

    attr_reader :port, :entity_class

    def to_id(value)
      int_value = value.to_i
      raise ORMivore::StorageError, "Not a valid id: #{value.inspect}" unless int_value > 0

      int_value
    end

    def attrs_to_entity(attrs)
      if attrs
        entity_class.new(attrs)
      else
        nil
      end
    end
  end
end
