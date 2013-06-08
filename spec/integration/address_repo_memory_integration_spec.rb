require 'spec_helper'
require_relative 'shared_address'
require_relative '../adapters/memory_helpers'

describe App::AddressRepo do
  include MemoryHelpers

  let(:account_adapter) { App::AccountStorageMemoryAdapter.new }

  let(:adapter) { App::AddressStorageMemoryAdapter.new }

  it_behaves_like 'an integrated address repo'
end
