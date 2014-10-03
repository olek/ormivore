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
      @family = options[:family]
      family_member = options.fetch(family_member, true)
      @family.add(self, @entity_class) if @family && family_member
      @session = options[:session] || Session::NULL
    end

    def clone(options)
      self.class.new(entity_class, port, options)
    end

    def create(attrs = nil)
      entity = entity_class.new_root(attributes: {}, repo: self, session: session)

      entity.apply(attrs) if attrs

      entity.pointer
    end

    def find_by_id(id, options = {})
      quiet = options.fetch(:quiet, false)

      identity_map[id].tap do |o|
        return o if o
      end

      raise RecordNotFound if identity_map.deleted?(id)

      load_entity(port.find_by_id(
          id,
          all_known_columns
        )
      ).pointer
    rescue RecordNotFound => e
      if quiet
        return nil
      else
        raise e, "#{entity_class.name} with id #{id.inspect} was not found"
      end
    end

    def find_all_by_id_as_hash(ids, options = {})
      quiet = options.fetch(:quiet, false)

      clean_ids = ids.reject { |id| identity_map.deleted?(id) }
      unless quiet || ids.length == clean_ids.length
        raise ORMivore::RecordNotFound, "#{entity_class.name} with ids #{(ids - clean_ids).inspect} were not found"
      end

      return [] if clean_ids.empty?

      entities_attrs = port.find_all_by_id(
        ids,
        all_known_columns
      )

      ids.each_with_object({}) { |id, entities_map|
        # TODO use coerce_id here (requires making repo_spec less brittle)
        # entity_attrs = entities_attrs.find { |e| e[:id] && entity_class.coerce_id(e[:id]) == id }
        entity_attrs = entities_attrs.find { |e| e[:id] && Integer(e[:id]) == id }
        if entity_attrs
          entities_map[id] = load_entity(entity_attrs).pointer
        elsif !quiet
          raise ORMivore::RecordNotFound, "#{entity_class.name} with id #{id} was not found"
        end
      }
    end

    def find_all_by_id(objects, options = {})
      find_all_by_id_as_hash(objects, options).values
    end

    # 'private'
    def persist(entity)
      validate_entity_argument(entity)

      rtn = persist_entity(entity)
      entity.dismiss unless rtn.equal?(entity)

      rtn
    end

    # 'private'
    def delete(entity)
      validate_entity_argument(entity)

      if entity.ephemeral?
        raise ORMivore::StorageError, 'Can not delete unsaved entity'
      else
        count = port.delete_one(entity.identity)
        raise ORMivore::StorageError, 'No records deleted' if count.zero?
        raise ORMivore::StorageError, 'WTF' if count > 1
        entity.dismiss
      end
    end

    def inspect(options = {})
      verbose = options.fetch(:verbose, false)

      "#<#{self.class.name}".tap { |s|
          if verbose
            s << " entity_class=#{entity_class.inspect}"
            s << " port=#{port.inspect}"
            s << " family=#{family.inspect}"
            s << " session=#{session.inspect(verbose: false)}"
          else
            s << (":0x%08x" % (object_id * 2))
          end
      } << '>'
    end

    # customizing to_yaml output
    def encode_with(encoder)
      encoder['entity_class'] = entity_class
      encoder['port'] = port
      encoder['family'] = family
      encoder['session'] = session
    end

    attr_reader :family, :session, :entity_class

    private

    attr_reader :port

    def identity_map
      session.identity_map(entity_class)
    end

    # this is 'package' or 'friendly' API, to be used only by ORMivore itself
    def find_all_by_attribute(name, value)
      entities_attrs = port.find(
        { name => value },
        all_known_columns
      )
      entities_attrs.map { |ea| load_entity(ea).pointer }
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

      changes = entity.changes

      if changes.empty?
        entity
      else
        if entity.ephemeral?
          identity_map.unset(entity)
          load_entity(port.create(changes)).tap { |o|
            identity_map.alias_identity(o.identity, entity.identity)
            update_all_references_to(entity, o.identity)
          }
        else
          count = port.update_one(entity.identity, changes)
          raise ORMivore::StorageError, 'No records updated' if count.zero?
          raise ORMivore::StorageError, 'WTF' if count > 1

          burn_phoenix(entity)
        end
      end
    end

    def update_all_references_to(entity, new_identity)
      session.association_definitions.select { |o|
        o.type == :foreign_key &&
        o.to == entity.class
      }.each do |association_definition|
        session.identity_map(association_definition.from).select { |o|
          o.attribute(association_definition.foreign_key_name) == entity.identity
        }.each do |o|
          o.apply(association_definition.foreign_key_name => new_identity)
        end
      end
    end

    def load_entity(attrs)
      if attrs
        attrs = attrs.dup
        attrs.reject! {|k,v| v.nil? }
        entity_id = attrs.delete(:id)

        preloaded = identity_map[entity_id]

        if preloaded
          preloaded
        else
          new_entity_options = { repo: self }
          new_entity_options[:session] = session
          new_entity_options[:attributes] = attrs unless attrs.empty?
          new_entity_options[:identity] = entity_id if entity_id

          identity_map.set(entity_class.new_root(new_entity_options))
        end
      else
        nil
      end
    end

    def burn_phoenix(entity)
      identity_map.unset(entity)
      load_entity(entity_to_hash(entity), entity.pointer)
    end

    def entity_to_hash(entity)
      { id: entity.identity }.
        merge!(entity.attributes)
    end

    def all_known_columns
      [:id].concat(entity_class.attributes_list)
    end
  end
end
