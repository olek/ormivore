require 'spec'

#require 'active_support'
require 'active_record'

require File.join(File.dirname(__FILE__), '..', 'lib', 'init.rb')

#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

unless ActiveRecord::Base.connected?
  ActiveRecord::Base.establish_connection(YAML::load(File.open('./spec/database.yml')))
end

require 'database_cleaner'

if true
  Spec::Runner.configure do |config|
    # config.include Rack::Test::Methods

    config.before(:suite) do
      # DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.strategy = :truncation
    end

    config.before(:each) do
      DatabaseCleaner.start
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end
  end
end

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'accounts'")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'addresses'")

ActiveRecord::Base.connection.create_table(:accounts) do |t|
    t.string   "login",                         :limit => 100,                    :null => false
    t.string   "crypted_password",              :limit => 40,                     :null => false
    t.string   "firstname",                     :limit => 100,                    :null => false
    t.string   "lastname",                      :limit => 100,                    :null => false
    t.string   "email",                         :limit => 100,                    :null => false
    t.string   "salt",                          :limit => 40
    t.integer  "status",                                       :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
end

ActiveRecord::Base.connection.create_table(:addresses) do |t|
    t.string   "type"
    t.string   "street_1",                       :null => false
    t.string   "street_2"
    t.string   "city",                           :null => false
    t.string   "postal_code",                    :null => false
    t.integer  "country_code"
    t.integer  "region_code"
    t.integer  "addressable_id",                 :null => false
    t.string   "addressable_type",               :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
end

root = File.expand_path('../..', __FILE__)
$LOAD_PATH.unshift(File.join(root))

require 'factory_girl'
require 'spec/factories'
