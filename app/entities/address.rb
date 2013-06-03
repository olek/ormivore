# coding: utf-8

module App
  class Address
    include ORMivore::Entity

    attributes :street_1, :street_2, :city, :postal_code, :country_code, :region_code,
        :type, :account_id

    optional :street_2, :region_code, :account_id

    private

    def coerce(attrs)
      attrs[:type] = attrs[:type].to_sym
    end

    def validate
      raise "Invalid type #{type}" unless %w(shipping billing).include?(type.to_s)
    end
  end
end
