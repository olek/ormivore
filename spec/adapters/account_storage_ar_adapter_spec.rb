require 'spec_helper'
require_relative 'shared'

describe App::AccountStorageArAdapter do
  include Helpers

  let(:attrs) do
    v = 'Foo'
    { firstname: v, lastname: v, email: v, status: 1 }
  end

  let(:test_attr) { :firstname }
  let(:entity_table) { 'accounts' }

  def create_entity
    FactoryGirl.create(:account)
  end

  it_behaves_like 'an adapter'
end
