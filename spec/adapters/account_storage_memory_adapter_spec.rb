require 'spec_helper'
require_relative 'shared_memory'

describe App::AccountStorageMemoryAdapter do
  let(:attrs) do
    v = test_value
    { firstname: v, lastname: v, email: v, status: :active }
  end

  let(:test_attr) { :firstname }

  it_behaves_like 'a memory adapter'
end

