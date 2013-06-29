require 'redis'

module ORMivore
  module RedisAdapter
    module ClassMethods
      attr_reader :default_converter_class
      attr_reader :prefix

      private
      attr_writer :default_converter_class
      attr_writer :prefix
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # TODO convert initialize to use named arguments (hash)
    def initialize(converter = nil, redis = nil)
      @converter = converter || self.class.default_converter_class.new
      @redis = redis || $redis || Redis.new
    end

    def find_by_id(id, attributes_to_load)
      raise ArgumentError unless id
      raise ArgumentError unless attributes_to_load && !attributes_to_load.empty?
      redis_reference = "#{prefix}:#{id}"
      if redis.exists(redis_reference)
        rtn = redis.mapped_hmget(redis_reference, *attributes_to_load).symbolize_keys
        [ attributes_to_load.include?(:id) ? rtn.merge(id: id) : rtn ]
      else
        []
      end
      # keys = attributes_to_load.map { |attr| "#{key_prefix}:#{attr}" }
    end

    def find(conditions, attributes_to_load, options = {})
      raise NotImplementedError, "Generic find interface not available for this adapter, please implement specific finders."
    end

    def create(attrs)
      id = attrs[:id]
      if id
        redis_reference = "#{prefix}:#{id}"
        raise RecordAlreadyExists if redis.exists(redis_reference)
      else
        id = next_id
        redis_reference = "#{prefix}:#{id}"
      end

      redis.hmset(redis_reference, attrs.to_a.flatten)
      attrs.merge(id: id)
    end

    def update_one(id, attrs)
      redis_reference = "#{prefix}:#{id}"
      if redis.exists(redis_reference)
        redis.hmset(redis_reference, attrs.to_a.flatten)
        1
      else
        0
      end
    end

    def update_all(conditions, attrs)
      raise NotImplementedError, "Generic update_all interface not available for this adapter, please implement specific update methods."
    end

    private

    attr_reader :converter, :redis

    # delegate :prefix, :to => 'self.class'

    def prefix
      self.class.prefix
    end

    def next_id
      redis_reference = "#{prefix}:next_id"
      redis.incr(redis_reference)
    end
  end
end
