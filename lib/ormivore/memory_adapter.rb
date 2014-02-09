module ORMivore
  module MemoryAdapter
    include ConvenienceIdFinders

    module ClassMethods
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(options = {})
      @converter = options[:converter] || NoopConverter.new
    end

    def find(conditions, attributes_to_load, options = {})
      order = options.fetch(:order, {})
      limit = options[:limit]
      offset = options[:offset]

      reorder(
        filter_from_storage(conditions, attributes_to_load),
        order
      ).tap { |rtn|
        rtn.slice!(0, Integer(offset)) if offset
        rtn.slice!(Integer(limit)..-1) if limit
      }

    end

    def create(attrs)
      id = attrs[:id]
      if id
        raise RecordAlreadyExists if storage.any? { |o| o[:id] == id }
      else
        id = next_id
      end
      attrs.merge(id: id).tap { |attrs_with_id|
        storage << attrs_with_id
      }
    end

    def update_one(id, attrs)
      update_all({ id: id }, attrs)
    end

    def update_all(conditions, attrs)
      select_from_storage(conditions).each { |record|
        record.merge!(attrs)
      }.length
    end

    def delete_one(id)
      delete_all({ id: id })
    end

    def delete_all(conditions)
      select_from_storage(conditions).each { |record|
        storage.delete(record)
      }.length
    end

    # open for tests, not to be used by any other code
    def storage
      @storage ||= []
    end

    private

    attr_reader :converter

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

    def filter_from_storage(conditions, attributes_to_load)
      select_from_storage(conditions).map { |record|
        record.select { |k, v| attributes_to_load.include?(k) }
      }
    end

    def reorder(records, order)
      return records if order.empty?

      records.sort { |x, y|
        order.inject(0) { |acc, (k, v)|
          break unless acc.zero?

          multiplier =
            case v
            when :ascending
              1
            when :descending
              -1
            else
              raise BadArgumentError, "Order direction #{v} is invalid"
            end
          (x[k] <=> y[k]) * multiplier
        }
      }
    end

    def next_id
      (@next_id ||= 1).tap { |current_id|
        @next_id = current_id + 1
      }
    end
  end
end
