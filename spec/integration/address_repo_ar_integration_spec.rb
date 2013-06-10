require 'spec_helper'
require_relative 'shared_address'
require_relative '../adapters/ar_helpers'

describe App::AddressRepo, :relational_db do
  include ArHelpers

  let(:account_adapter) { App::AccountStorageArAdapter.new }
  let(:entity_table) { 'addresses' }
  let(:adapter) { App::AddressStorageArAdapter.new }

  it_behaves_like 'an integrated address repo'
end
