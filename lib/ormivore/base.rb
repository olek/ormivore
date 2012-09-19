module ORMivore
  module Base
    module ClassMethods

      attr_accessor :storage

      def primary_key
        :id
      end

      attr_reader :attributes_list
      attr_reader :optional_attributes_list

      private

      def finders(*methods)
        methods.each do |method|
          instance_eval <<-EOS
            def #{method}(*args, &block)
              storage.__send__(:#{method}, *args, &block)
            end
          EOS
        end
      end

      def attributes(*methods)
        @attributes_list = methods.map(&:to_sym)
        @optional_attributes_list ||= []

        file, line = caller.first.split(':', 2)
        line = line.to_i

        methods.each do |method|
          method = method.to_s

            exception = %(raise "#{self}##{method} delegated to attributes.#{method}, but attributes is nil: \#{self.inspect}")

            module_eval(<<-EOS, file, line - 1)
              def #{method}(*args, &block)
                attributes.__send__(:#{method}, *args, &block)
              rescue NoMethodError
                if attributes.nil?
                  #{exception}
                else
                  raise
                end
              end
            EOS
        end
      end

      def optional(*methods)
        @optional_attributes_list = methods.map(&:to_sym)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def save
      new? ? create : update
    end

    def new?
      !attributes[primary_key]
    end

    def to_hash
      attributes.to_hash.symbolize_keys
    end

    def storage
      self.class.storage
    end

    def primary_key
      self.class.primary_key
    end

    private

    attr_reader :attributes

    def create
      storage.create(self)
    end

    def update
      storage.update(self)
    end

    def validate_presence_of_proper_attributes(attrs)
      self.class.attributes_list.each do |attr|
        unless attrs.delete(attr) || self.class.optional_attributes_list.include?(attr)
          raise BadArgumentError, "Missing attribute '#{attr}'"
        end
      end

      raise BadArgumentError, "Unknown attributes #{attrs.inspect}" unless attrs.empty?
    end

    def initialize(attr_options)
      validate_presence_of_proper_attributes(attr_options.symbolize_keys)

      @attributes = Hashie::Mash.new(attr_options).tap { |attrs|
        coerce_primary_key(attrs)
        coerce(attrs)
      }.freeze

      validate
    end

    def coerce_primary_key(attrs)
      pk = attrs[primary_key]
      attrs[primary_key] = Integer(pk) if pk
    end

    def coerce(attrs)
      # override me!
    end

#    def prototype(attrs)
#      self.class.new(attributes.merge(attrs))
#    end
  end
end
