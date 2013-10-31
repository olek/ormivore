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

    def persist(entity)
      if entity.id
        count = port.update_one(entity.id, entity.changes)
        raise ORMivore::StorageError, 'No records updated' if count.zero?
        raise ORMivore::StorageError, 'WTF' if count > 1

        entity_class.construct(entity.attributes, entity.id)
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
