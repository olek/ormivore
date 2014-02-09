module ORMivore
  class NoopConverter
    def attributes_list_to_storage(list)
      list
    end

    def from_storage(attrs)
      attrs
    end

    def to_storage(attrs)
      attrs
    end
  end
end
