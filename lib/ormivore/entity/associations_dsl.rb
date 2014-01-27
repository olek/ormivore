module ORMivore
  module Entity
    module AssociationsDSL

      def self.extended(base)
        base.send(:include, Wrapper) # how naughty of us
      end

      def association_names
        @association_names ||= []
      end

      alias_method :names, :association_names

      def many_to_one(name, entity_class, options)
        name = name.to_sym
        foreign_key = options.fetch(:fk)
        cache_name = "#{self.name.demodulize}.#{name}"
        finder_name = "find_by_id"

        raise BadArgumentError, "Association #{name} is already defined" if association_names.include?(name)
        association_names << name

        define_method(name) do
          unchanged = entity.cache_with_name(cache_name) {
            entity.repo.family[entity_class].public_send(finder_name, entity.attribute(foreign_key))
          }

          entity.association_changes.
            select { |o| o[:name] == name }.
            inject(unchanged) { |pick, changes|
              changes[:entities].first
            }
        end
      end

      def one_to_many(name, entity_class, options)
        name = name.to_sym
        foreign_key = options.fetch(:fk)
        cache_name = "#{self.name.demodulize}.#{name}"
        finder_name = "find_all_by_#{foreign_key}"

        raise BadArgumentError, "Association #{name} is already defined" if association_names.include?(name)
        association_names << name

        define_method(name) do
          unchanged = entity.cache_with_name(cache_name) {
            entity.repo.family[entity_class].public_send(finder_name, entity.id)
          }

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

      def many_to_many(name, entity_class, options)
        name = name.to_sym
        through = options.fetch(:through)
        far_side_fk = options.fetch(:fk)
        cache_name = "#{self.name.demodulize}.#{name}"

        raise BadArgumentError, "Association #{name} is already defined" if association_names.include?(name)
        association_names << name

        define_method(name) do
          unchanged = entity.cache_with_name(cache_name) {
            join_entities = public_send(through)
            if join_entities.empty?
              []
            else
              entity.repo.family[entity_class].
                find_by_ids(
                  join_entities.map { |link| link.attribute(far_side_fk) }.sort
                ).values
            end
          }

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
end
