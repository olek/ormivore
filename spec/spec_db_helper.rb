require 'logger'

ConnectionManager.establish_connection 'test' #, Logger.new(STDOUT)

require 'database_cleaner'

if true
  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true

    relational_db = { relational_db: true }
    redis_db = { redis_db: true }

    # it would be nice to be able to specify redis connection itself, so that
    # cleanup is logged, but redis-rb does not allow for that
    DatabaseCleaner[:redis, { :connection => ORMivore::Connections.redis.id }]

    config.before(:each) do
      DatabaseCleaner[:active_record].strategy = nil
      DatabaseCleaner[:redis].strategy = nil
    end

    config.before(:each, relational_db) do
      DatabaseCleaner[:active_record].strategy = :transaction
      DatabaseCleaner.start
    end

    config.before(:each, redis_db) do
      DatabaseCleaner[:redis].strategy = :truncation
      DatabaseCleaner.start
    end

    config.after(:each, relational_db) do
      DatabaseCleaner.clean
    end

    config.after(:each, redis_db) do
      DatabaseCleaner.clean
    end
  end
end

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'accounts'")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'addresses'")

ActiveRecord::Base.connection.create_table(:accounts) do |t|
    t.string   "login",               limit: 100,       null: false
    t.string   "crypted_password",    limit: 40,        null: false
    t.string   "firstname",           limit: 100,       null: false
    t.string   "lastname",            limit: 100,       null: false
    t.string   "email",               limit: 100,       null: false
    t.string   "salt",                limit: 40
    t.integer  "status",              default: 1
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
end

ActiveRecord::Base.connection.create_table(:addresses) do |t|
    t.string   "type",                limit: 40
    t.string   "street_1",            limit: 100,       null: false
    t.string   "street_2",            limit: 100
    t.string   "city",                limit: 100,       null: false
    t.string   "postal_code",         limit: 100,       null: false
    t.string   "country_code",        limit: 10
    t.string   "region_code",         limit: 10
    t.integer  "addressable_id",      limit: 100,       null: false
    t.string   "addressable_type",    limit: 100,       null: false
    t.datetime "created_at",          limit: 100,       null: false
    t.datetime "updated_at",          limit: 100,       null: false
end

require 'factory_girl'
require 'spec/factories'
