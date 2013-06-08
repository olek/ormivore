require 'spec_helper'
require_relative 'shared'

describe App::Address do
  it_behaves_like 'an entity' do
    let(:attrs) do
      v = test_value
      {
        street_1: v, city: v, postal_code: v,
        country_code: v, region_code: v,
        type: :shipping, account_id: 1
      }
    end

    let(:test_attr) { :street_1 }
  end
end
