require 'spec_helper'
require_relative 'shared_memory'

describe App::AccountRepo do
  let(:attrs) do
    v = test_value
    { firstname: v, lastname: v, email: v, status: :active }
  end

  let(:test_attr) { :firstname }
  let(:entity_class) { App::Account }
  let(:adapter) { App::AccountStorageMemoryAdapter.new }
  let(:port) { App::AccountStoragePort.new(adapter) }

  it_behaves_like 'an integrated memory repo'
end
