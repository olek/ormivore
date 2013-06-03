# coding: utf-8

module App
  class Account
    include ORMivore::Entity

    STATUSES = %w(active inactive deleted).map(&:to_sym).freeze

    attributes :firstname, :lastname, :email, :status

    private

    def validate
      raise "Invalid status #{status}" unless STATUSES.include?(status)
    end
  end
end
