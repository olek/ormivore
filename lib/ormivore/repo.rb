module ORMivore
  module Repo
    module ClassMethods
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.extend(RepoDSL)
    end

    def initialize(entity_class, port, options = {})
      raise BadArgumentError unless entity_class
      raise BadArgumentError unless port

      @port = port
      @entity_class = entity_class
      @family = options.fetch(:family, nil)
      @family.add(self, @entity_class) if @family
    end

    def create(attrs = nil)
      entity = entity_class.new(attributes: {}, repo: self)

      if attrs
        entity.apply(attrs)
      else
        entity
      end
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

    def find_all_by_id_as_hash(objects, options = {})
      quiet = options.fetch(:quiet, false)

      ids =
        if block_given?
          objects.map { |o| yield(o) }
        else
          objects
        end

      entities_attrs = port.find_all_by_id(
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

    def find_all_by_id(objects, options = {})
      find_all_by_id_as_hash(objects, options).values
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

    # this is 'package' or 'friendly' API, to be used only by ORMivore itself
    def find_all_by_attribute(name, value)
      entities_attrs = port.find(
        { name => value },
        all_known_columns
      )
      entities_attrs.map { |ea| load_entity(ea) }
    end

    def validate_entity_argument(entity)
      # in case you are wondering, just trying to stay friendly to mocks in unit tests
      if entity.is_a?(Entity) && entity.class != entity_class
        raise BadArgumentError, "Entity #{entity} is not right for repo #{self}"
      end
      raise InvalidStateError, "Dismissed entities are not allowed to affect database" if entity.dismissed?
    end

    def persist_entity(entity)
      entity.validate

      changes = entity.changes.merge(entity.foreign_key_changes)

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

    # NOTE this seems to belong to new AssociationChanges class, with entity.inspect_applied_associations
    def collect_association_alterations(entity)
      ads = entity_class.association_definitions
      entity.association_adjustments.
        select { |o| ads[o.name].type == :one_to_many }.
        each_with_object({}) { |o, acc|
          add_remove_pair = acc[o.name] ||= [[], [], ads[o.name].entity_class, ads[o.name].foreign_key, ads[o.name].inverse_of]
          entities = o.entities
          case o.action
          when :add
            add_remove_pair[0].concat(entities)
            add_remove_pair[1].delete_if { |e| entities.include?(e) }
          when :remove
            entities.each do |e|
              add_remove_pair[0].delete(e)
              add_remove_pair[1] << e unless e.ephemeral?
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
      entity_class.foreign_key_association_definitions.each_with_object({}) do |(name, ad), acc|
        foreign_key = ad.foreign_key
        foreign_key_value = entity_class.coerce_id(attrs.delete(foreign_key))
        if foreign_key_value
          acc[name] = Entity::Placeholder.new(family[ad.entity_class], foreign_key_value)
        end
      end
    end

    def burn_phoenix(entity)
      load_entity(entity_to_hash(entity))
    end

    def entity_to_hash(entity)
      { id: entity.id }.
        merge!(entity.foreign_keys).
        merge!(entity.attributes)
    end

    def all_known_columns
      [:id].concat(entity_class.foreign_keys).concat(entity_class.attributes_list)
    end
  end
end
