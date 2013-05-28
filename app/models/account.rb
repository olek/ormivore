# coding: utf-8

module ORMivoreApp
  class Account
    include ORMivore::Base

=begin
    module STATUS
      ACTIVE = 1
      INACTIVE = 2
      DELETED = 3

      ALL = (0..3).to_a.freeze
    end

    finders :find_by_id
=end

    STATUSES = %w(active inactive deleted).map(&:to_sym).freeze

    attributes :id, :firstname, :lastname, :email, :status
    optional :id

    private

    def validate
      status = attributes.status
      raise "Invalid status #{status}" unless STATUSES.include?(status)
    end

=begin
    def create
      raise ORMivore::NotImplementedYet, 'Account can not be created yet, to be implemented later if needed'
    end
=end
  end
end
