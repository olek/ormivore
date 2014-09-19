module ORMivore
  class IdentityMap
    include Enumerable

    NULL = Object.new.tap do |o|
      def o.to_s; "#{Module.nesting.first.name}::NULL"; end
      def o.[](identity); nil; end
      def o.set(entity); entity; end
      def o.unset(entity); nil; end
      def o.delete(entity); nil; end
      def o.deleted?(identity); false; end
      def o.current(entity); entity end
      def o.current_or_set(entity); entity end
      def o.alias_identity(new_identity, old_identity); end
    end

    def initialize(entity_class)
      @entity_class = entity_class or fail
      @storage = {}
      @trash = {}
      @old_to_new_identity_aliases = {}

      freeze
    end

    def each
      storage.values.each do |o|
        yield(o)
      end
    end

    def [](identity)
      raise BadArgumentError, "No identity provided for identity map #{self.inspect}" unless identity
      identity = @entity_class.coerce_id(identity)

      storage[identity] || storage[old_to_new_identity_aliases[identity]]
    end

    def set(entity)
      fail unless entity
      fail unless entity.class == entity_class

      storage[entity.identity] = entity
    end

    def unset(entity)
      fail unless entity
      fail unless entity.class == entity_class

      storage.delete(entity.identity)
    end

    def delete(entity)
      fail unless entity
      fail unless entity.class == entity_class

      entity = current(entity)

      trash[entity.identity] = entity
      storage.delete(entity.identity)
    end

    def deleted?(identity)
      !!trash[identity]
    end

    def current(entity)
      fail unless entity
      fail unless entity.class == entity_class

      self[entity.identity]
    end

    def current_or_set(entity)
      fail unless entity
      fail unless entity.class == entity_class

      current(entity) || set(entity)
    end

    def alias_identity(new_identity, old_identity)
      fail unless new_identity && new_identity > 0
      fail unless old_identity && old_identity < 0

      old_to_new_identity_aliases[old_identity] = new_identity
    end

    def current_identity(entity)
      old_to_new_identity_aliases[entity.identity] || entity.identity
    end

    def deleted
      trash.values
    end

    def inspect(options = {})
      verbose = options.fetch(:verbose, false)

      "#<#{self.class.name}".tap { |s|
          if verbose
            s << " entity_class=#{entity_class.inspect}"
            s << " storage=#{inspect_entities_map(storage)}"
            s << " trash=#{inspect_entities_map(trash)}"
            s << " identity_aliases=#{old_to_new_identity_aliases.inspect}"
          else
            s << (":0x%08x" % (object_id * 2))
          end
      } << '>'
    end

    # customizing to_yaml output
    def encode_with(encoder)
      encoder['entity_class'] = entity_class
      encoder['storage'] = storage
      encoder['trash'] = trash
      encoder['identity_aliases'] = old_to_new_identity_aliases
    end

    private

    attr_reader :entity_class, :storage, :trash, :old_to_new_identity_aliases

    def inspect_entities(entities)
      return 'NIL' unless entities
      if entities.respond_to?(:length)
        entities.map { |e|
          e.inspect(verbose: false)
        }.join(', ').prepend('[') << ']'
      else
        entities.inspect(verbose: false)
      end
    end

    def inspect_entities_map(map)
      map.map { |k, v|
        "#{k.inspect}=>#{inspect_entities(v)}"
      }.join(', ').prepend('{') << '}'
    end
  end
end
