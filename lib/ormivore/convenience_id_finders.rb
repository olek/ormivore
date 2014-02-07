module ORMivore
  module ConvenienceIdFinders
    def find_by_id(id, attributes_to_load)
      found = find({ id: id }, attributes_to_load)
      case found.length
      when 0
        raise RecordNotFound, "Entity with id #{id} does not exist"
      when 1
        found.first
      else
        # should never happen, right?
        raise StorageError, "More than one entity with id #{id} exists"
      end
    end

    def find_all_by_id(ids, attributes_to_load)
      find(
        { id: ids },
        attributes_to_load
      )
    end
  end
end
