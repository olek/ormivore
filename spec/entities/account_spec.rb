require 'spec_helper'
require_relative 'shared'

describe ORMivoreApp::Account do
  it_behaves_like 'an entity' do
    let(:attrs) do
      v = test_value
      { firstname: v, lastname: v, email: v, status: :active }
    end

    let(:test_attr) { :firstname }

    describe '#firstname' do
      it 'should return first name' do
        subject.firstname.should == test_value
      end
    end

    describe '#status' do
      it 'should return proper symbol' do
        subject.status.should == :active
      end
    end
  end
end
