# TODO ArAdapter is really ugly; replace it with some simple Sql adapter without AR 'goodness'
module ORMivore
  module ArAdapter
    module ClassMethods
      attr_reader :default_converter_class
      attr_reader :ignored_columns
      attr_reader :table_name
      attr_reader :default_attributes

      def ar_class
        finalize
        self::ArRecord
      end

      private
      attr_writer :default_converter_class
      attr_writer :ignored_columns
      attr_writer :table_name

      def define_default_attributes(&block)
        @default_attributes = block
      end

      def finalize
        unless @finalized
          @finalized = true

          file, line = caller.first.split(':', 2)
          line = line.to_i

          module_eval(<<-EOS, file, line - 1)
            class ArRecord < ActiveRecord::Base
              self.table_name = '#{table_name}'
              self.inheritance_column = :_type_disabled
              def attributes_protected_by_default; []; end
            end
          EOS
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(converter = nil)
      @converter = converter || self.class.default_converter_class.new
    end

    def find(conditions, options = {})
      # TODO how about other finder options, like order, limit, offset?
      quiet = options.fetch(:quiet, false)
      record = ar_class.first(:conditions => conditions)
      if quiet
        record ? entity_attributes(record) : nil
      else
        raise ORMivore::RecordNotFound, "#{ar_class} with conditions #{conditions} was not found" if record.nil?
        entity_attributes(record)
      end
    end

    def create(attrs)
      entity_attributes(
        ar_class.create!(
          extend_with_defaults(
            converter.to_storage(attrs))) { |o| o.id = attrs[:id] }
      )
    end

    def update(attrs, conditions)
      ar_class.update_all(converter.to_storage(attrs), conditions)
    end

    private

    attr_reader :converter

    def extend_with_defaults(attrs)
      if self.class.default_attributes
        attrs.merge(self.class.default_attributes.call(attrs))
      else
        attrs
      end
    end

    def ar_class
      self.class.ar_class
    end

    def entity_attributes(record)
      # TODO we should not be reading all those columns from database in first place - performance hit
      attrs_to_ignore = self.class.ignored_columns

      converter.from_storage(record.attributes.except(*attrs_to_ignore).symbolize_keys)
    end
  end
end
