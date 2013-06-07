module ORMivore
  module MemoryAdapter
    module ClassMethods
      attr_reader :default_converter_class

      private
      attr_writer :default_converter_class
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(converter = nil)
      @converter = converter || self.class.default_converter_class.new
    end

    def find(conditions, options = {})
      select_from_storage(conditions)
    end

    def create(attrs)
      id = attrs[:id]
      if id
        raise RecordAlreadyExists if storage.any? { |o| o[:id] == id }
      else
        id = next_id
      end
      attrs.merge(id: id).tap { |attr_with_id|
        storage << attr_with_id
      }
    end

    def update(attrs, conditions)
      select_from_storage(conditions).each { |record|
        record.merge!(attrs)
      }.length
    end

    # open for tests, not to be used by any other code
    def storage
      @storage ||= []
    end

    private

    def select_from_storage(conditions)
      storage.select { |o|
        conditions.all? { |k, v|
          if v.is_a?(Enumerable)
            v.include?(o[k])
          else
            o[k] == v
          end
        }
      }
    end

    attr_reader :converter

    def next_id
      (@next_id ||= 1).tap { |current_id|
        @next_id = current_id + 1
      }
    end
  end
end
