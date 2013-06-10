require 'spec_helper'

require_relative 'shared_account'
require_relative 'ar_helpers'

describe App::AccountStorageArAdapter, :relational_db do
  include ArHelpers

  let(:entity_table) { 'accounts' }
  let(:adapter) { App::AccountStorageArAdapter.new }

  it_behaves_like 'an account adapter'
end
