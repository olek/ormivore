FactoryGirl.define do
  factory :account, class: App::Account::Builder do
    firstname 'John'
    lastname 'Doe'
    email 'test@test.com'
    status :active
  end

  factory :shipping_address, class: App::Address::Builder do
    street_1 'Some street 123'
    street_2 'appartment 1'
    city 'Test'
    postal_code '12345'
    country_code :US
    region_code :PA
    type :shipping
  end
end
