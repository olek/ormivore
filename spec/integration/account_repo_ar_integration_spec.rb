require 'spec_helper'
require_relative 'shared_ar'

describe App::AccountRepo do
  let(:attrs) do
    v = test_value
    { firstname: v, lastname: v, email: v, status: :active }
  end

  let(:test_attr) { :firstname }
  let(:entity_table) { 'accounts' }
  let(:entity_class) { App::Account }
  let(:adapter) { App::AccountStorageArAdapter.new }
  let(:port) { App::AccountStoragePort.new(adapter) }

  def create_entity
    FactoryGirl.create(:account, test_attr => test_value).attributes.symbolize_keys
  end

  it_behaves_like 'an integrated activerecord repo'
end
