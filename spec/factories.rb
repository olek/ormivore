# creating this one here only to get access to the builder in it
account_class = 
    ORMivore::AnonymousFactory::create_entity do
      attributes do
        string :firstname, :lastname, :email
        symbol :status
      end
    end

FactoryGirl.define do
  factory :account, class: account_class::Builder do
    firstname 'John'
    lastname 'Doe'
    email 'test@test.com'
  end

  #factory :shipping_address, class: App::Address::Builder do
  #  street_1 'Some street 123'
  #  street_2 'appartment 1'
  #  city 'Test'
  #  postal_code '12345'
  #  country_code :US
  #  region_code :PA
  #  type :shipping
  #end
end
