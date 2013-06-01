# coding: utf-8

module ORMivoreApp
  class Account
    include ORMivore::Base

    STATUSES = %w(active inactive deleted).map(&:to_sym).freeze

    attributes :id, :firstname, :lastname, :email, :status
    optional :id

    private

    def validate
      raise "Invalid status #{status}" unless STATUSES.include?(status)
    end
  end
end
