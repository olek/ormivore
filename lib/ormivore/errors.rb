require 'nested_exceptions'

module ORMivore
  class ORMivoreError < StandardError
    include NestedExceptions
  end

  class BadArgumentError < ORMivoreError; end
  class AbstractMethodError < ORMivoreError; end
  class StorageError < ORMivoreError; end
  class RecordNotFound < StorageError; end
  class RecordAlreadyExists < StorageError; end
  class NotImplementedYet < StandardError; end
end
