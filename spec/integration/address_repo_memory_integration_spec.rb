require 'spec_helper'
require_relative 'shared_memory'

describe App::AddressRepo do
  let(:attrs) do
    v = test_value
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v,
      type: :shipping
    }
  end

  let(:test_attr) { :street_1 }
  let(:entity_class) { App::Address }
  let(:adapter) { App::AddressStorageMemoryAdapter.new }
  let(:port) { App::AddressStoragePort.new(adapter) }

  it_behaves_like 'an integrated memory repo'
end
