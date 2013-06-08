require 'spec_helper'
require_relative 'shared_account'
require_relative '../adapters/ar_helpers'

describe App::AccountRepo do
  include ArHelpers

  let(:entity_table) { 'accounts' }
  let(:adapter) { App::AccountStorageArAdapter.new }

  it_behaves_like 'an integrated account repo'
end
