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

    def create(attrs = {})
      entity_class.new(attributes: {}, repo: self).apply(attrs)
    end

    def find_by_id(id, options = {})
      quiet = options.fetch(:quiet, false)

      attrs_to_entity(port.find_by_id(
          id,
          columns_to_fetch
        )
      )
    rescue RecordNotFound => e
      if quiet
        return nil
      else
        raise e, "#{entity_class.name} with id #{id.inspect} was not found"
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
        columns_to_fetch
      )

      objects.each_with_object({}) { |o, entities_map|
        id = block_given? ? yield(o) : o
        entity_attrs = entities_attrs.find { |e| e[:id] && Integer(e[:id]) == id }
        if entity_attrs
          entities_map[o] = attrs_to_entity(entity_attrs)
        elsif !quiet
          raise ORMivore::RecordNotFound, "#{entity_class.name} with id #{id} was not found"
        end
      }
    end

    def persist(entity)
      persist_entity(entity).tap {
        persist_entity_associations(entity)
      }
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

    attr_reader :family, :entity_class

    private

    attr_reader :port

    def persist_entity(entity)
      entity.validate

      changes = entity.changes.merge(foreign_key_changes(entity))


      if entity.id
        if entity.changed?
          count = port.update_one(entity.id, changes)
          raise ORMivore::StorageError, 'No records updated' if count.zero?
          raise ORMivore::StorageError, 'WTF' if count > 1

          entity_class.new(attributes: entity.attributes, id: entity.id, repo: self)
        else
          entity
        end
      else
        attrs_to_entity(port.create(changes))
      end
    end

    def foreign_key_changes(entity)
      ad = entity_class.association_descriptions
      entity.association_changes.
        select { |o| ad[o[:name]][:type] == :many_to_one }.
        each_with_object({}) { |o, acc|
          acc[ad[o[:name]][:foreign_key]] = o[:entities].first.id
        }
    end

    def persist_entity_associations(entity)
    end

    def attrs_to_entity(attrs)
      if attrs
        attrs = attrs.dup
        attrs.reject! {|k,v| v.nil? }
        entity_id = attrs.delete(:id)
        direct_link_associations = extract_direct_link_associations(attrs)

        new_entity_options = { repo: self }
        new_entity_options[:attributes] = attrs unless attrs.empty?
        new_entity_options[:associations] = direct_link_associations unless direct_link_associations.empty?
        new_entity_options[:id] = entity_id if entity_id

        entity_class.new(new_entity_options)
      else
        nil
      end
    end

    def extract_direct_link_associations(attrs)
      entity_class.association_descriptions.select { |n, d| d[:type] == :many_to_one }.each_with_object({}) do |(name, description), acc|
        foreign_key = description[:foreign_key]
        foreign_key_value = entity_class.coerce_id(attrs.delete(foreign_key))
        if foreign_key_value
          acc[name] = Entity::Placeholder.new(family[description[:entity_class]], foreign_key_value)
        end
      end
    end

    def columns_to_fetch
      [:id].concat(entity_class.attributes_list).concat(entity_class.foreign_keys)
      [:id].concat(entity_class.foreign_keys).concat(entity_class.attributes_list)
    end

=begin
    def validate_conditions(conditions)
      extra = conditions.keys - attributes.keys
      raise BadConditionsError, extra.join("\n") unless extra.empty?
    end
=end
  end
end
