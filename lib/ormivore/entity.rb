module ORMivore
  module Entity
    module ClassMethods
      ALLOWED_ATTRIBUTE_TYPES = Coercions.constants.map { |sym| Coercions.const_get(sym) }.freeze

      attr_reader :attributes_declaration
      attr_reader :optional_attributes_list

      def attributes_list
        attributes_declaration.keys
      end

      def construct(attrs, id, repo)
        id = coerce_id(id)

        coerced_attrs = attrs.symbolize_keys.tap { |h| coerce(h) }.freeze

        base_attributes = coerced_attrs
        dirty_attributes = {}.freeze

        validate_absence_of_unknown_attributes(base_attributes, dirty_attributes)

        obj = allocate

        obj.instance_variable_set(:@id, id)
        obj.instance_variable_set(:@repo, repo)
        obj.instance_variable_set(:@base_attributes, base_attributes)
        obj.instance_variable_set(:@dirty_attributes, dirty_attributes)

        obj
      end

      def validate_absence_of_unknown_attributes(base, dirty)
        unknown_attrs = {}
        (base.keys - attributes_list).each { |k| unknown_attrs[k] = base[k] }
        (dirty.keys - attributes_list).each { |k| unknown_attrs[k] = dirty[k] }

        raise BadAttributesError, "Unknown attributes #{unknown_attrs.inspect}" unless unknown_attrs.empty?
      end

      def coerce(attrs)
        attrs.each do |name, attr_value|
          declared_type = attributes_declaration[name]
          if declared_type && !attr_value.is_a?(declared_type)
            attrs[name] =
              declared_type.coerce(attr_value)
          end
        end
      rescue ArgumentError => e
        raise ORMivore::BadArgumentError.new(e)
      end

      private

      def attributes(declaration)
        @attributes_declaration = declaration.symbolize_keys.freeze
        validate_attributes_declaration
        # @attributes_list = methods.map(&:to_sym)
        @optional_attributes_list ||= []

        attributes_list.map(&:to_s).each do |attr|
          module_eval(<<-EOS)
            def #{attr}
              @dirty_attributes[:#{attr}] || @base_attributes[:#{attr}]
            end
          EOS
          self::Builder.module_eval(<<-EOS)
            def #{attr}
              attributes[:#{attr}]
            end
            def #{attr}=(value)
              attributes[:#{attr}] = value
            end
          EOS
        end
      end

      def optional(*methods)
        @optional_attributes_list = methods.map(&:to_sym)
      end

      # now, really private methods, not part of API

      # TODO figure out how to differenciate private methods that are part of
      # ORMivore API from those that are NOT

      def validate_attributes_declaration
        attributes_declaration.each do |name, type|
          unless ALLOWED_ATTRIBUTE_TYPES.include?(type)
            raise ORMivore::BadArgumentError, "Invalid attribute type #{type.inspect}"
          end
        end
      end

      def coerce_id(value)
        value ? Integer(value) : nil
      rescue ArgumentError
        raise ORMivore::BadArgumentError, "Not a valid id: #{value.inspect}"
      end
    end

    def self.included(base)
      base.send(:include, Coercions) # how naughty of us
      base.extend(ClassMethods) # not so naughty, but still...

      base.module_eval(<<-EOS)
        class Builder
          def initialize
            @attributes = {}
          end

          def id
            attributes[:id]
          end

          def adapter=(value)
            @adapter = value
          end

          # FactoryGirl integration point
          def save!
            @attributes = @adapter.create(attributes)
          end

          attr_reader :attributes
        end
      EOS
    end

    attr_reader :id, :repo

    def attributes
      all_attributes
    end

    def changes
      @dirty_attributes
    end

    def changed?
      !changes.empty?
    end

    def apply(attrs)
      self.dup.tap { |other|
        other.expand_changes(attrs)
      }
    end

    def validate
      base = @base_attributes
      dirty = @dirty_attributes

      # doing complicated way first because it is much more memory efficient
      # but it does not allow for good error messages, so if something is
      # wrong, need to proceed to inefficient validation that produces nice
      # messages
      missing = 0
      known_counts = self.class.attributes_list.each_with_object([0, 0]) { |attr, acc|
        acc[0] += 1 if base[attr]
        acc[1] += 1 if dirty[attr]
        missing +=1 unless self.class.optional_attributes_list.include?(attr) || base[attr] || dirty[attr]
      }

      if missing > 0 || [base.length, dirty.length] != known_counts
        expensive_validate_presence_of_proper_attributes(
          base.merge(dirty)
        )
      end
    end

    protected

    # to be used only by #apply
    def expand_changes(attrs)
      attrs = attrs.symbolize_keys.tap { |h| self.class.coerce(h) }
      attrs.delete_if { |k, v| v == @base_attributes[k] }
      @dirty_attributes = @dirty_attributes.merge(attrs).freeze # melt and freeze, huh
      @all_attributes = nil # it is not valid anymore

      self.class.validate_absence_of_unknown_attributes(@base_attributes, @dirty_attributes)
    end

    private

    def all_attributes
      # memory / performance tradeoff can be played with here by keeping
      # all_attributes around or generating it each time
      @all_attributes = @base_attributes.merge(@dirty_attributes)
    end

    def initialize(attrs)
      coerced_attrs = attrs.symbolize_keys.tap { |h| self.class.coerce(h) }.freeze

      @base_attributes = {}.freeze
      @dirty_attributes = coerced_attrs

      self.class.validate_absence_of_unknown_attributes(@base_attributes, @dirty_attributes)
    end

    def expensive_validate_presence_of_proper_attributes(attrs)
      self.class.attributes_list.each do |attr|
        unless attrs.delete(attr) != nil || self.class.optional_attributes_list.include?(attr)
          raise BadAttributesError, "Missing attribute '#{attr}'"
        end
      end

      raise BadAttributesError, "Unknown attributes #{attrs.inspect}" unless attrs.empty?
    end
  end
end
