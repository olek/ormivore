module ORMivore
  module Repo
    module ClassMethods
      attr_reader :default_entity_class

      private
      attr_writer :default_entity_class
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.extend(RepoDSL)
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

      load_entity(port.find_by_id(
          id,
          all_known_columns
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
        all_known_columns
      )

      objects.each_with_object({}) { |o, entities_map|
        id = block_given? ? yield(o) : o
        entity_attrs = entities_attrs.find { |e| e[:id] && Integer(e[:id]) == id }
        if entity_attrs
          entities_map[o] = load_entity(entity_attrs)
        elsif !quiet
          raise ORMivore::RecordNotFound, "#{entity_class.name} with id #{id} was not found"
        end
      }
    end

    def persist(entity)
      validate_entity_argument(entity)

      rtn = persist_entity(entity)
      if persist_entity_associations(entity) && rtn.equal?(entity)
        # FIXME those associations are stale, new entities may have been persisted
        # if we had identity map, we could just refresh them
        #associations = entity.loaded_associations
        #associations.each do |k, v|
        #  associations[k] = v.sort_by(&:id) if v.respond_to?(:length)
        #end

        rtn = burn_phoenix(entity)
      end
      entity.dismiss unless rtn.equal?(entity)

      rtn
    end

    def delete(entity)
      validate_entity_argument(entity)

      if entity.id
        count = port.delete_one(entity.id)
        raise ORMivore::StorageError, 'No records deleted' if count.zero?
        raise ORMivore::StorageError, 'WTF' if count > 1
        entity.dismiss

        true
      else
        raise ORMivore::StorageError, 'Can not delete unsaved entity'
      end
    end

    attr_reader :family, :entity_class

    private

    attr_reader :port

    def validate_entity_argument(entity)
      # in case you are wondering, trying to stay friendly to unit tests
      if entity.is_a?(Entity) && entity.class != entity_class
        raise BadArgumentError, "Entity #{entity} is not right for repo #{self}"
      end
      raise InvalidStateError, "Dismissed entities are not allowed to affect database" if entity.dismissed?
    end

    def persist_entity(entity)
      entity.validate

      changes = entity.changes.merge(foreign_key_changes(entity))

      if changes.empty?
        entity
      else
        if entity.id
          count = port.update_one(entity.id, changes)
          raise ORMivore::StorageError, 'No records updated' if count.zero?
          raise ORMivore::StorageError, 'WTF' if count > 1

          burn_phoenix(entity)
        else
          load_entity(port.create(changes))
        end
      end
    end

    def foreign_key_changes(entity)
      ad = entity_class.association_descriptions
      entity.association_changes.
        select { |o| [:many_to_one, :one_to_one].include?(ad[o[:name]][:type]) }.
        each_with_object({}) { |o, acc|
          acc[ad[o[:name]][:foreign_key]] = o[:entities].first.id
        }
    end

    def persist_entity_associations(entity)
      alterations_hash = collect_association_alterations(entity)
      alterations_hash.each do |name, (add, remove, e_class, foreign_key, inverse_of)|
        association_repo = family[e_class]
        remove.each do |e|
          association_repo.delete(e)
        end
        add.each do |e|
          # inverse_of must be specified if inverse relation exists, othervise plain fk attribute is acceptible substitute
          if inverse_of
            e = e.apply(inverse_of => entity)
          else
            e = e.apply(foreign_key => entity.id)
          end
          e = association_repo.persist(e)
        end
      end

      !alterations_hash.empty?
    end

    def collect_association_alterations(entity)
      ad = entity_class.association_descriptions
      entity.association_changes.
        select { |o| ad[o[:name]][:type] == :one_to_many }.
        each_with_object({}) { |o, acc|
          add_remove_pair = acc[o[:name]] ||= [[], [], ad[o[:name]][:entity_class], ad[o[:name]][:foreign_key], ad[o[:name]][:inverse_of]]
          entities = o[:entities]
          case o[:action]
          when :add
            add_remove_pair[0].concat(entities)
            add_remove_pair[1].delete_if { |e| entities.include?(e) }
          when :remove
            entities.each do |e|
              add_remove_pair[0].delete(e)
              add_remove_pair[1] << e if e.persisted?
            end
          end
        }
    end

    def load_entity(attrs)
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

    def burn_phoenix(entity)
      load_entity(entity_to_attrs(entity))
    end

    def entity_to_attrs(entity)
      { id: entity.id }.
        merge!(entity.foreign_keys).
        merge!(entity.attributes)
    end

    def all_known_columns
      [:id].concat(entity_foreign_keys).concat(entity_class.attributes_list)
    end

    # TODO cache this
    def entity_foreign_keys
      entity_class.foreign_key_association_descriptions.map { |k, v| v[:foreign_key] }
    end

=begin
    def validate_conditions(conditions)
      extra = conditions.keys - attributes.keys
      raise BadConditionsError, extra.join("\n") unless extra.empty?
    end
=end
  end
end
