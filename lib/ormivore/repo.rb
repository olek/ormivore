module ORMivore
  module Repo
    module ClassMethods
      attr_reader :default_entity_class

      private
      attr_writer :default_entity_class
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(port, entity_class = nil)
      @port = port
      @entity_class = entity_class || self.class.default_entity_class
    end

    def find_by_id(id, options = {})
      attrs_to_entity(port.find({ id: id }, options))
    end

    def persist(entity)
      if entity.id
        count = port.update(entity.changes, { :id => entity.id })
        raise ORMivore::StorageError, 'No records updated' if count.zero?
        raise ORMivore::StorageError, 'WTF' if count > 1

        entity.create(entity.attributes, entity.id)
      else
        attrs_to_entity(port.create(entity.changes))
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
