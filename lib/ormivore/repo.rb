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

    def initialize(port, options = {})
      @port = port
      @entity_class = options.fetch(:entity_class, self.class.default_entity_class)
      @family = options.fetch(:family, nil)
      @family.add(self, @entity_class) if @family
    end

    def find_by_id(id, options = {})
      quiet = options.fetch(:quiet, false)

      attrs_to_entity(port.find_by_id(
          id,
          [:id].concat(entity_class.attributes_list)
        )
      )
    rescue RecordNotFound => e
      if quiet
        return nil
      else
        raise e, "#{entity_class.name} with id #{id} was not found"
      end
    end

    def find_by_ids(objects, options = {})
      quiet = options.fetch(:quiet, false)

      ids =
        if block_given?
          objects.map { |o| yield(o) }
        else
          objects
        end

      entities_attrs = port.find_by_ids(
        ids,
        [:id].concat(entity_class.attributes_list)
      )

      objects.each_with_object({}) { |o, entities_map|
        id = block_given? ? yield(o) : o
        entity_attrs = entities_attrs.find { |e| e[:id] == id }
        if entity_attrs
          entities_map[o] = attrs_to_entity(entity_attrs)
        elsif !quiet
          raise ORMivore::RecordNotFound, "#{entity_class.name} with id #{id} was not found"
        end
      }
    end

    def persist(entity)
      if entity.id
        if entity.changed?
          count = port.update_one(entity.id, entity.changes)
          raise ORMivore::StorageError, 'No records updated' if count.zero?
          raise ORMivore::StorageError, 'WTF' if count > 1

          entity_class.construct(entity.attributes, entity.id)
        else
          entity
        end
      else
        attrs_to_entity(port.create(entity.changes))
      end
    end

    def delete(entity)
      if entity.id
        count = port.delete_one(entity.id)
        raise ORMivore::StorageError, 'No records deleted' if count.zero?
        raise ORMivore::StorageError, 'WTF' if count > 1

        true
      else
        raise ORMivore::StorageError, 'Can not delete unsaved entity'
      end
    end

    private

    attr_reader :port, :entity_class

    def attrs_to_entity(attrs)
      if attrs
        entity_id = attrs.delete(:id)
        attrs.reject! {|k,v| v.nil? }
        entity_class.construct(attrs, entity_id)
      else
        nil
      end
    end

=begin
    def validate_conditions(conditions)
      extra = conditions.keys - attributes.keys
      raise BadConditionsError, extra.join("\n") unless extra.empty?
    end
=end
  end
end
