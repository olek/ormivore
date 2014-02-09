require 'logger'

ConnectionManager.establish_connection 'test' #, Logger.new(STDOUT)

require 'database_cleaner'

if true
  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true

    ar_db = { ar_db: true }
    sequel_db = { sequel_db: true }
    redis_db = { redis_db: true }

    # it would be nice to be able to specify redis connection itself, so that
    # cleanup is logged, but redis-rb does not allow for that
    DatabaseCleaner[:redis, { :connection => ORMivore::Connections.redis.id }]
    DatabaseCleaner[:sequel, { :connection => ORMivore::Connections.sequel }]

    config.before(:each) do
      DatabaseCleaner[:active_record].strategy = nil
      DatabaseCleaner[:sequel].strategy = nil
      DatabaseCleaner[:redis].strategy = nil
    end

    config.before(:each, ar_db) do
      DatabaseCleaner[:active_record].strategy = :transaction
      DatabaseCleaner.start
    end

    config.before(:each, sequel_db) do
      DatabaseCleaner[:sequel].strategy = :transaction
      DatabaseCleaner.start
    end

    config.before(:each, redis_db) do
      DatabaseCleaner[:redis].strategy = :truncation
      DatabaseCleaner.start
    end

    config.after(:each, ar_db) do
      DatabaseCleaner.clean
    end

    config.after(:each, sequel_db) do
      DatabaseCleaner.clean
    end

    config.after(:each, redis_db) do
      DatabaseCleaner.clean
    end
  end
end

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'accounts'")

ActiveRecord::Base.connection.create_table(:accounts) do |t|
    t.string   "firstname",           limit: 100,       null: false
    t.string   "lastname",            limit: 100
    t.string   "email",               limit: 100
    t.integer  "status"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
end

require 'factory_girl'
require 'spec/factories'
