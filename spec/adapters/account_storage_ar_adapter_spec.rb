require 'spec_helper'
require_relative 'shared_ar'

describe App::AccountStorageArAdapter do
  let(:attrs) do
    v = 'Foo'
    { firstname: v, lastname: v, email: v, status: 1 }
  end

  let(:test_attr) { :firstname }
  let(:entity_table) { 'accounts' }

  def create_entity(overrides = {})
    FactoryGirl.create(:account, overrides).attributes.symbolize_keys
  end

  it_behaves_like 'an activerecord adapter'
end
