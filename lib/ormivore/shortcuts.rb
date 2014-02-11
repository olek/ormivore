module ORMivore
  class << self
    def create_entity_skeleton(container_module, name, options = {}, &block)
      define_repo = options.fetch(:repo, false)
      define_port = options.fetch(:port, false)
      define_memory_adapter = options.fetch(:memory_adapter, false)
      define_ar_adapter = options.fetch(:ar_adapter, false)
      define_sequel_adapter = options.fetch(:sequel_adapter, false)
      define_prepared_sequel_adapter = options.fetch(:prepared_sequel_adapter, false)
      define_redis_adapter = options.fetch(:redis_adapter, false)

      storage_key = options[:storage_key]

      if (define_ar_adapter || define_sequel_adapter || define_prepared_sequel_adapter ||
          define_prepared_sequel_adapter || define_redis_adapter) && !storage_key
        raise BadArgumentError, "Unable to create adapter without storage_key"
      end

      namespace = container_module.const_set(name.to_s.camelize, Module.new)

      if define_repo
        namespace.module_eval <<-EOC
          class Repo
            include ORMivore::Repo
          end
        EOC
      end

      if define_port
        namespace.module_eval <<-EOC
          class StoragePort
            include ORMivore::Port
          end
        EOC
      end

      if define_memory_adapter
        namespace.module_eval <<-EOC
          class StorageMemoryAdapter
            include ORMivore::MemoryAdapter
          end
        EOC
      end

      if define_ar_adapter
        namespace.module_eval <<-EOC
          class StorageArAdapter
            include ORMivore::ArAdapter
            self.table_name = '#{storage_key}'
          end
        EOC
      end

      if define_sequel_adapter
        namespace.module_eval <<-EOC
          class StorageSequelAdapter
            include ORMivore::SequelAdapter
            self.table_name = '#{storage_key}'
          end
        EOC
      end

      if define_prepared_sequel_adapter
        namespace.module_eval <<-EOC
          class PreparedSequelAdapter
            include ORMivore::PreparedSequelAdapter
            self.table_name = '#{storage_key}'
          end
        EOC
      end

      if define_redis_adapter
        namespace.module_eval <<-EOC
          class RedisAdapter
            include ORMivore::RedisAdapter
            self.prefix = '#{storage_key}'
          end
        EOC
      end

      entity_class = namespace.module_eval <<-EOC
        class Entity
          include ORMivore::Entity
        end
      EOC

      if block_given?
        entity_class.instance_eval(&block)
      end

      entity_class
    end
  end
end
