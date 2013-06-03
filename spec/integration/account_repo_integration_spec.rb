require 'spec_helper'
require_relative 'shared'

describe App::AccountRepo do
  let(:attrs) do
    v = 'Foo'
    { firstname: v, lastname: v, email: v, status: :active }
  end

  let(:test_attr) { :firstname }
  let(:entity_table) { 'accounts' }
  let(:entity_class) { App::Account }

  subject {
    described_class.new(
      App::AccountStoragePort.new(
        App::AccountStorageArAdapter.new
      )
    )
  }

  def create_entity
    FactoryGirl.create(:account, test_attr => test_value)
  end

  it_behaves_like 'a repo'
end
