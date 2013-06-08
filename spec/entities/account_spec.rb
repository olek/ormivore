require 'spec_helper'
require_relative 'shared'

describe App::Account do
  it_behaves_like 'an entity' do
    let(:attrs) do
      v = test_value
      { firstname: v, lastname: v, email: v, status: :active }
    end

    let(:test_attr) { :firstname }
  end
end
