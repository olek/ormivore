# coding: utf-8

module ORMivoreApp
  class AddressRepo

    def initialize(port, entity_class = nil)
      @port = port
      @entity_class = entity_class || ORMivoreApp::Address
    end

    def find_by_id(id)
      attrs_to_entity(storage_port.find(id: id))
    end

    def persist(entity)
      if entity.new?
        attrs_to_entity(port.create(entity.to_hash))
      else
        port.update_all(entity.to_hash, { :id => to_id(entity.id) })
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
