require 'spec_helper'

require_relative 'shared_account'
require_relative 'memory_helpers'

describe App::AccountStorageMemoryAdapter do
  include MemoryHelpers

  let(:adapter) { App::AccountStorageMemoryAdapter.new }

  it_behaves_like 'an account adapter'
end
