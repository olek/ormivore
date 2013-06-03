module ORMivore
  module Base
    module ClassMethods

      attr_reader :attributes_list
      attr_reader :optional_attributes_list

      private

=begin
      def finders(*methods)
        methods.each do |method|
          instance_eval <<-EOS
            def #{method}(*args, &block)
              storage.__send__(:#{method}, *args, &block)
            end
          EOS
        end
      end
=end

      def attributes(*methods)
        @attributes_list = methods.map(&:to_sym)
        @optional_attributes_list ||= []

        file, line = caller.first.split(':', 2)
        line = line.to_i

        methods.each do |method|
          method = method.to_s

            exception = %(raise "#{self}##{method} delegated to attributes[:#{method}], but attributes is nil: \#{self.inspect}")

            module_eval(<<-EOS, file, line - 1)
              def #{method}(*args, &block)
                attributes[:#{method}]
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

    def to_hash
      attributes.to_hash.symbolize_keys
    end

    attr_reader :id

    private

    attr_reader :attributes

    def validate_presence_of_proper_attributes(attrs)
      self.class.attributes_list.each do |attr|
        unless attrs.delete(attr) || self.class.optional_attributes_list.include?(attr)
          raise BadArgumentError, "Missing attribute '#{attr}'"
        end
      end

      raise BadArgumentError, "Unknown attributes #{attrs.inspect}" unless attrs.empty?
    end

    def initialize(attributes, id = nil)
      @id = coerce_id(id)
      validate_presence_of_proper_attributes(attributes.symbolize_keys)

      @attributes = attributes.symbolize_keys.tap { |attrs|
        coerce(attrs)
      }.freeze

      validate
    end

    def coerce_id(value)
      value ? Integer(value) : nil
    rescue ArgumentError
      raise ORMivore::BadArgumentError, "Not a valid id: #{value.inspect}"
    end

    def coerce(attrs)
      # override me!
    end

#    def prototype(attrs)
#      self.class.new(attributes.merge(attrs))
#    end
  end
end
