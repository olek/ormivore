module App
  class Address
    include ORMivore::Entity

    attributes(
      street_1: String,
      street_2: String,
      city: String,
      postal_code: String,
      country_code: String,
      region_code: String,
      type: Symbol,
      account_id: Integer
    )

    optional :street_2, :region_code, :account_id

    private

    def validate
      raise "Invalid type #{type}" unless %w(shipping billing).include?(type.to_s)
    end
  end
end
