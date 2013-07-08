module ConnectionManager
  class << self
    def establish_connection(env, logger=nil)
      raise unless env

      establish_activerecord_connection(env, logger)
      establish_redis_connection(env, logger)
    end

    private

    def establish_activerecord_connection(env, logger)
      unless ActiveRecord::Base.connected?
        configuration = load_configuration('database', env)

        puts "Connecting to activerecord database #{configuration[:database]}"

        ActiveRecord::Base.establish_connection(configuration)

        ActiveRecord::Base.logger = logger
      end
    end

    def establish_redis_connection(env, logger)
      configuration = load_configuration('redis', env)

      host = configuration[:host] or fail 'No host specified'
      port = configuration[:port] or fail 'No port specified'
      db = configuration[:db] or fail 'No db specified'

      puts "Connecting to redis database redis://#{host}:#{port}/#{db}"

      ORMivore::Connections.redis = Redis.new(host: host, port: port, db: db).tap do |redis|
        redis.client.logger = logger
      end
    end

    def load_configuration(name, env)
      YAML::load(
        File.open(File.join(RequireHelpers.root, 'db', "#{name}.yml"))
      )[env.to_s].symbolize_keys
    end
  end
end
