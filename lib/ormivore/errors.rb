require 'nested_exceptions'

module ORMivore
  class NotImplementedYet < StandardError; end

  class ORMivoreError < StandardError
    include NestedExceptions
  end

  class BadArgumentError < ORMivoreError; end
  class BadAttributesError < BadArgumentError; end
  class BadConditionsError < BadArgumentError; end

  class InvalidStateError < ORMivoreError; end

  class AbstractMethodError < ORMivoreError; end

  class StorageError < ORMivoreError; end
  class RecordNotFound < StorageError; end
  class RecordAlreadyExists < StorageError; end
end
