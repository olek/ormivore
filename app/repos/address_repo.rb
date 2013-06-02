# coding: utf-8

module ORMivoreApp
  class AddressRepo

    def initialize(port, entity_class = nil)
      @port = port
      @entity_class = entity_class || ORMivoreApp::Address
    end

    def find_by_id(id, options = {})
      attrs_to_entity(port.find({ id: id }, options))
    end

    def persist(entity)
      if entity.new?
        attrs_to_entity(port.create(entity.to_hash))
      else
        count = port.update(entity.to_hash, { :id => entity.id })
        raise ORMivore::StorageError, 'No records updated' if count.zero?
        raise ORMivore::StorageError, 'WTF' if count > 1

        entity
      end
    end

    private

    attr_reader :port, :entity_class

    def attrs_to_entity(attrs)
      if attrs
        entity_id = attrs.delete(:id)
        attrs.reject! {|k,v| v.nil? }
        entity_class.new(attrs, entity_id)
      else
        nil
      end
    end
  end
end
