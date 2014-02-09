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

      namespace = container_module.const_set(name, Module.new)

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
            self.default_converter_class = NoopConverter
          end
        EOC
      end

      if define_ar_adapter
        namespace.module_eval <<-EOC
          class StorageArAdapter
            include ORMivore::ArAdapter
            self.default_converter_class = NoopConverter
          end
        EOC
      end

      if define_sequel_adapter
        namespace.module_eval <<-EOC
          class StorageSequelAdapter
            include ORMivore::SequelAdapter
            self.default_converter_class = NoopConverter
          end
        EOC
      end

      if define_prepared_sequel_adapter
        namespace.module_eval <<-EOC
          class PreparedSequelAdapter
            include ORMivore::PreparedSequelAdapter
            self.default_converter_class = NoopConverter
          end
        EOC
      end

      if define_redis_adapter
        namespace.module_eval <<-EOC
          class RedisAdapter
            include ORMivore::RedisAdapter
            self.default_converter_class = NoopConverter
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
