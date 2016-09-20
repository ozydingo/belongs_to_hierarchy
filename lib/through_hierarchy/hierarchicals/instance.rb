module ThroughHierarchy
  module Hierarchicals
    class Instance < Hierarchical
      def set_target(target)
        @target = target
        @instance = @target
        @model = @target.class        
      end

      def hierarchy_instances
        [@instance] + @hierarchy.map{|m| @instance.association(m).load_target}
      end

      def filters
        or_conditions(hierarchy_instances.compact.map{|instance| filter(instance)})
      end

      def filter(instance)
        foreign_type_column.eq(instance_type(instance)).
          and(foreign_key_column.eq(instance_key(instance)))
      end

      def create_with
        {
          foreign_type_name => instance_type(@instance),
          foreign_key_name => instance_key(@instance)
        }
      end

      def instance_type(instance)
        instance.class.base_class.to_s
      end

      def instance_key(instance)
        instance.attributes[@model.primary_key]
      end

      def best_rank_column_name
        "through_hierarchy_best_rank"
      end

      def best_rank_column
        @source[best_rank_column_name]
      end

      def best_rank
        hierarchy_rank.minimum.as(best_rank_column_name)
      end

      def best_rank_table_name
        "through_hierarchy_best_rank"
      end

      # Select only sources with best hierarchy rank for target instance
      # Uses subquery grouped by specified column to compute best rank
      # TODO: experiment with the model-style double-join method instead
      def select_best_rank(group_by:)
        sub = best_rank_subquery(group_by)
        @source.
          join(sub.source).
          on(
            hierarchy_rank.eq(sub.best_rank_column).
              and(@source[group_by].eq(sub.source[group_by]))
          ).
          order(@source[group_by])
      end

      # Return a new Hierarchical::Instance representing a subquery that contains
      # only best-rank sources.
      def best_rank_subquery(group_by)
        @source.respond_to?(:project) or raise ThroughHierarchySourceError, "#{@source} cannot be converted into a subquery"
        subq = source.
          project(foreign_type_column, foreign_key_column, group_by, best_rank).
          where(filters).
          group(source[group_by]).
          as(best_rank_table_name)

        spawn(subq)
      end

    end
  end
end