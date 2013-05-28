# coding: utf-8

module ORMivoreApp
  class Address
    include ORMivore::Base

    attributes :id, :street_1, :street_2, :city, :postal_code, :country_code, :region_code,
        :type, :addressable

    optional :id, :street_2, :region_code

    private

    def coerce(attrs)
      attrs.type = attrs.type.to_sym
    end

    def validate
      type = attributes.type
      raise "Invalid type #{type}" unless %w(shipping billing).include?(type.to_s)
    end
  end
end
