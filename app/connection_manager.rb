module ConnectionManager
  def self.establish_connection(env, logger=nil)
    raise unless env

    unless ActiveRecord::Base.connected?
      configuration = YAML::load(
        File.open(File.join(RequireHelpers.root, 'db', 'database.yml'))
      )[env.to_s]

      puts "Connecting to database #{configuration['database']}"

      ActiveRecord::Base.establish_connection(configuration)

      ActiveRecord::Base.logger = logger
    end
  end
end
