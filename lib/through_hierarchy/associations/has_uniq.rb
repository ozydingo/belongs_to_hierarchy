module ThroughHierarchy
  module Associations
    class HasUniq < Association
      def join
        raise "Unfortunately, joining to a has_uniq association is not yet supported"
        # TODO: make this work
        # joins = @model.arel_table.join(foreign_arel_table).on(arel_model_filters)

        # joins = joins.join(arel_subquery).on(
        #   arel_hierarchy_rank.eq(subquery_arel_table[best_hierarchy_match_name]).
        #   and(foreign_arel_table[@uniq].eq(subquery_arel_table[@uniq]))
        # )

        # results = @model.joins(joins.join_sources)
        # results = results.merge(foreign_class.instance_exec(&@scope)) if @scope.present?
        # return results
      end

      private

      def set_options(options)
        super
        @uniq = options[:uniq]
      end

      def validate_options
        super
        @uniq # TODO
      end

      # Use subquery method to select best hierarchy match for each @uniq
      # Order by @uniq can result in better performance than default order (id)
      def get_matches(instance)
        super.joins(subquery_join_sources(instance)).order(foreign_arel_table[@uniq])
      end

      def subquery_alias
        "through_hierarchy_subtable"
      end

      def subquery_arel_table
        Arel::Table.new(subquery_alias)
      end

      # TODO: generate this dynamically based on existing columns and selects
      def best_hierarchy_match_name
        "through_hierarchy_match"
      end

      def arel_best_hierarchy_member
        arel_hierarchy_rank.minimum.as(best_hierarchy_match_name)
      end

      # TODO: for model level joins, subquery needs to join to all hierarchy tables
      def arel_subquery(instance = nil)
        foreign_arel_table.
          project(foreign_arel_table[Arel.star], arel_best_hierarchy_member).
          where(instance.present? ? arel_instance_filters(instance) : arel_model_filters).
          group(foreign_arel_table[@uniq]).
          as(subquery_alias)
      end

      # TODO: build join sources for model-level query
      def subquery_join_sources(instance = nil)
        foreign_arel_table.
          join(arel_subquery(instance)).
          on(
            arel_hierarchy_rank.eq(subquery_arel_table[best_hierarchy_match_name]).
            and(foreign_arel_table[@uniq].eq(subquery_arel_table[@uniq]))
          ).join_sources
      end
    end
  end
end
