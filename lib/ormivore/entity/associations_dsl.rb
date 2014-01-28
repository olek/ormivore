module ORMivore
  module Entity
    module AssociationsDSL

      def self.extended(base)
        base.send(:include, Wrapper) # how naughty of us
      end

      def association_names
        association_descriptions.keys
      end

      alias_method :names, :association_names

      def association_descriptions
        @association_descriptions ||= {}
      end

      alias_method :descriptions, :association_descriptions

      def add_association_description(type, name, entity_class, options)
        name = name.to_sym
        raise BadArgumentError, "Association #{name} is already defined" if association_names.include?(name)
        raise BadArgumentError, "Association #{name} can not have nil entity class" unless entity_class

        foreign_key = options.fetch(:fk)
        cache_name = "#{self.name.demodulize}.#{name}"

        association_descriptions[name] = {
          type: type,
          entity_class: entity_class,
          foreign_key: foreign_key,
          cache_name: cache_name
        }.tap { |h|
          h[:through] = options.fetch(:through) if type == :many_to_many
        }
      end

      def many_to_one(name, entity_class, options)
        data = add_association_description(:many_to_one, name, entity_class, options)

        name = name.to_sym
        finder_name = "find_by_id"

        define_method(name) do
          unchanged = entity.cache_with_name(data[:cache_name]) {
            entity.repo.family[entity_class].public_send(finder_name, entity.attribute(data[:foreign_key]))
          }

          entity.association_changes.
            select { |o| o[:name] == name }.
            inject(unchanged) { |pick, changes|
              changes[:entities].first
            }
        end
      end

      def one_to_many(name, entity_class, options)
        data = add_association_description(:one_to_many, name, entity_class, options)

        name = name.to_sym
        finder_name = "find_all_by_#{data[:foreign_key]}"

        define_method(name) do
          unchanged = entity.cache_with_name(data[:cache_name]) {
            entity.repo.family[entity_class].public_send(finder_name, entity.id)
          }

          AssociationsDSL.apply_changes(entity, name, unchanged)
        end
      end

      def many_to_many(name, entity_class, options)
        data = add_association_description(:many_to_many, name, entity_class, options)

        name = name.to_sym
        finder_name = "find_by_ids"

        define_method(name) do
          unchanged = entity.cache_with_name(data[:cache_name]) {
            join_entities = public_send(data[:through])
            if join_entities.empty?
              []
            else
              entity.repo.family[entity_class].
                public_send(finder_name,
                  join_entities.map { |link| link.attribute(data[:foreign_key]) }.sort
                ).values
            end
          }

          AssociationsDSL.apply_changes(entity, name, unchanged)
        end
      end

      # private API

      def self.apply_changes(entity, name, unchanged)
        entity.association_changes.
          select { |o| o[:name] == name }.
          inject(unchanged) { |last, changes|
            case changes[:action]
            when :add
              last + changes[:entities]
            when :remove
              last - changes[:entities]
            else
              fail
            end
          }
      end
    end
  end
end
