module ORMivore
  module AnonymousFactory
    class << self
      def create_entity(&block)
        Class.new {
          include ORMivore::Entity
        }.tap { |cl|
          cl.instance_eval(&block) if block_given?
        }
      end

      def create_repo_family(&block)
        Class.new {
          include ORMivore::RepoFamily
        }.tap { |cl|
          cl.instance_eval(&block) if block_given?
        }
      end

      def create_repo(&block)
        Class.new {
          include ORMivore::Repo
        }.tap { |cl|
          cl.instance_eval(&block) if block_given?
        }
      end

      def create_port(&block)
        Class.new {
          include ORMivore::Port
        }.tap { |cl|
          cl.instance_eval(&block) if block_given?
        }
      end

      def create_memory_adapter(&block)
        Class.new {
          include ORMivore::MemoryAdapter
        }.tap { |cl|
          cl.instance_eval(&block) if block_given?
        }
      end

      def create_ar_adapter(table_name, &block)
        Class.new {
          include ORMivore::ArAdapter
          self.table_name = table_name
        }.tap { |cl|
          cl.instance_eval(&block) if block_given?
        }
      end

      def create_sequel_adapter(table_name, &block)
        Class.new {
          include ORMivore::SequelAdapter
          self.table_name = table_name
        }.tap { |cl|
          cl.instance_eval(&block) if block_given?
        }
      end

      def create_prepared_sequel_adapter(table_name, &block)
        Class.new {
          include ORMivore::PreparedSequelAdapter
          self.table_name = table_name
        }.tap { |cl|
          cl.instance_eval(&block) if block_given?
        }
      end

      def create_redis_adapter(prefix, &block)
        Class.new {
          include ORMivore::RedisAdapter
          self.prefix = prefix
        }.tap { |cl|
          cl.instance_eval(&block) if block_given?
        }
      end
    end
  end
end
