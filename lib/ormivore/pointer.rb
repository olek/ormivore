module ORMivore
  class Pointer
    extend Forwardable

    def initialize(entity)
      @origin = entity || fail
      #@session = entity.session
      #@entity_class = entity.class
      #@identity = entity.identity
    end

    def dereference
      origin.current
    end

    def apply(attrs)
      dereference.apply(attrs)

      self
    end

    def ==(other)
      dereference == other.dereference
    end

    def eql?(other)
      dereference.eql?(other.dereference)
    end

    def equal?(other)
      dereference.equal?(other.dereference)
    end

    def_delegator :dereference, :identity
    def_delegator :dereference, :session
    def_delegator :dereference, :dismissed?
    def_delegator :dereference, :attributes
    def_delegator :dereference, :attribute
    def_delegator :dereference, :changes
    def_delegator :dereference, :changed?
    def_delegator :dereference, :ephemeral?
    def_delegator :dereference, :durable?
    def_delegator :dereference, :revised?
    def_delegator :dereference, :dismiss
    def_delegator :dereference, :validate
    def_delegator :dereference, :hash
    def_delegator :dereference, :inspect
    def_delegator :dereference, :encode_with

    private

    attr_reader :origin
  end
end
