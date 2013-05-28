# coding: utf-8

module ORMivoreApp
  class NoopConverter
    def from_storage(attrs)
      attrs
    end

    def to_storage(attrs)
      attrs
    end
  end
end
