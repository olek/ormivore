require 'spec_helper'
require_relative 'shared_memory'

describe App::AddressStorageMemoryAdapter do
  let(:attrs) do
    v = test_value
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v,
      addressable_type: 'Account',
      addressable_id: 123
    }
  end

  let(:test_attr) { :street_1 }

  it_behaves_like 'a memory adapter'
end


