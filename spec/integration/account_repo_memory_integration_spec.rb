require 'spec_helper'
require_relative 'shared_account'
require_relative '../adapters/memory_helpers'

describe App::AccountRepo do
  include MemoryHelpers

  let(:adapter) { App::AccountStorageMemoryAdapter.new }

  it_behaves_like 'an integrated account repo'
end
