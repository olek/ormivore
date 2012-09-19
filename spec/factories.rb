FactoryGirl.define do
  factory :account, class: ORMivoreApp::Storage::AR::AccountARModel do |account|
    account.login 'test@test.com'
    account.crypted_password '1234567890'
    account.firstname 'John'
    account.lastname 'Doe'
    account.email 'test@test.com'
    account.salt '12345'
    account.status 1
  end

  factory :account_with_shipping_address, :parent => :account do |account|
    account.after_create { |o| Factory(:shipping_address, addressable_id: o.id, addressable_type: 'Account') }
  end

  factory :shipping_address, class: ORMivoreApp::Storage::AR::AddressARModel do
    street_1 'Some street 123'
    street_2 'appartment 1'
    city 'Test'
    postal_code '12345'
    country_code :US
    region_code :PA
    type 'ShippingAddress'
  end
end
