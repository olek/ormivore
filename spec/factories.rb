# TODO add builder classes to entities and integrate them with FactoryGirl
#   see https://github.com/thoughtbot/factory_girl/wiki/How-factory_girl-interacts-with-ActiveRecord
FactoryGirl.define do
  factory :account, class: App::AccountStorageArAdapter.ar_class do
    login 'test@test.com'
    crypted_password '1234567890'
    firstname 'John'
    lastname 'Doe'
    email 'test@test.com'
    salt '12345'
    status 1
  end

  factory :account_with_shipping_address, :parent => :account do
    after(:create) do
      |o| FactoryGirl.create(:shipping_address, addressable_id: o.id, addressable_type: 'Account')
    end
  end

  factory :shipping_address, class: App::AddressStorageArAdapter.ar_class do
    street_1 'Some street 123'
    street_2 'appartment 1'
    city 'Test'
    postal_code '12345'
    country_code :US
    region_code :PA
    type 'ShippingAddress'
    addressable_type 'Account'
  end
end
