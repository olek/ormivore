module App
  class Account
    include ORMivore::Entity

    STATUSES = %w(active inactive deleted).map(&:to_sym).freeze

    attributes(
      firstname: String,
      lastname: String,
      email: String,
      status: Symbol
    )

    private

    def validate
      raise "Invalid status #{status}" unless STATUSES.include?(status)
    end
  end
end
