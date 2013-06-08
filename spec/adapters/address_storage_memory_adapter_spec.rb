require 'spec_helper'

require_relative 'shared_address'
require_relative 'memory_helpers'

describe App::AddressStorageMemoryAdapter do
  include MemoryHelpers

  let(:account_adapter) { App::AccountStorageMemoryAdapter.new }
  let(:adapter) { App::AddressStorageMemoryAdapter.new }

  it_behaves_like 'an address adapter'
end
