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

    def respond_to?(method_id, include_private = false)
      if should_delegate?(method_id)
        true
      else
        super
      end
    end

    private

    attr_reader :origin

    def method_missing(method_id, *arguments, &block)
      if should_delegate?(method_id, *arguments, &block)
        dereference.send(method_id)
      else
        super
      end
    end

    def should_delegate?(method_id, *arguments, &block)
      (
        origin.class.attributes_list.include?(method_id) ||
        origin.class.responsibilities.include?(method_id)
      ) && arguments.empty? && block.nil?
    end
  end
end
