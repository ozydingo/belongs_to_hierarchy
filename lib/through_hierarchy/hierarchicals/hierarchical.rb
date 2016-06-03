module ThroughHierarchy
  module Hierarchicals
    class Hierarchical
      attr_reader :source

      # source should be an Arel::Table or Arel::TableAlias
      # TODO: parent only on derived tables. Make that a separate class or module.
      def initialize(source, target, hierarchy, as:, parent: nil)
        @source = source
        set_target(target)
        @hierarchy = hierarchy
        @polymorphic_name = as.to_s
        @parent = parent
      end

      def set_target(target)
        @target = target
        @model = @target
      end

      # Initialize a new copy of self bound to a specific instance
      def with_instance(instance)
        instance.is_a?(@model) or raise ThroughHierarchyInstanceError, "#{instance} is not an instance of #{@model}"
        Instance.new(@source, instance, @hierarchy, as: @polymorphic_name)
      end

      # Intialize a copy of self with a new / derived source table
      def spawn(source)
        return self.class.new(source, @target, @hierarchy, as: @polymorphic_name, parent: self)
      end

      def hierarchy_models
        [@model] + @hierarchy.map{|m| @model.reflect_on_association(m).klass}
      end

      # TODO: some of these may be :through others, so this may generate redundant joins
      def hierarchy_joins
        @hierarchy
      end

      def and_conditions(conditions)
        conditions.reduce{|q, cond| q.and(cond)}
      end

      def or_conditions(conditions)
        conditions.reduce{|q, cond| q.or(cond)}
      end

      def filters
        or_conditions(hierarchy_models.map{|model| filter(model)})
      end

      def filter(model)
        foreign_type_column.eq(model_type(model)).
          and(foreign_key_column.eq(model_key(model)))
      end

      # Sort order for hierarchy shadowing queries
      def hierarchy_rank
        Arel.sql(
          "CASE `#{@source.name}`.`#{foreign_type_name}` " +
          hierarchy_models.map.with_index do |model, ii|
            "WHEN #{model.sanitize(model.base_class.to_s)} THEN #{ii} "
          end.join +
          "END"
        )
      end

      def foreign_key_name
        @polymorphic_name.foreign_key
      end

      def foreign_type_name
        @polymorphic_name + "_type"
      end

      def foreign_key_column
        @source[foreign_key_name]
      end

      def foreign_type_column
        @source[foreign_type_name]
      end

      def model_type(model)
        model.base_class.to_s
      end

      def model_key(model)
        model.arel_table[model.primary_key]
      end

      # Join @model to @source only on best hierarchy matches
      ### FASTER METHOD: join source to source alias on source.rank < alias.rank where alias does not exist
      # This performs OK.
      def join_best_rank(group_by: nil)
        better_rank = spawn(@source.alias("better_hierarchy"))
        @model.joins(@hierarchy).arel.
          join(@source).on(filters).
          join(better_rank.source, Arel::Nodes::OuterJoin).
          on(
            better_rank.filters.
              and(better_rank.hierarchy_rank.lt(hierarchy_rank))
          ).
          where(better_rank.source[:id].eq(nil))
      end

      # # TODO: generate this dynamically based on existing columns and selects
      # def best_rank_column_name
      #   "through_hierarchy_best_rank"
      # end

      # def best_rank_column
      #   @source[best_rank_column_name]
      # end

      # def best_rank
      #   hierarchy_rank.minimum.as(best_rank_column_name)
      # end

      # def best_rank_table_name
      #   "through_hierarchy_best_rank"
      # end

      # SLOW METHOD: subquery, gorup, min(priority). This performs abysmally.
      # # TODO: replace model_key(@model) with target_key?
      # def join_best_rank(group_by: nil)
      #   sub = best_rank_subquery(*group_by)
      #   @model.joins(@hierarchy).arel.
      #     join(sub.source).
      #     on(sub.source["model_key"].eq(model_key(@model))).
      #     join(@source).on(
      #       and_conditions([
      #         filters,
      #         hierarchy_rank.eq(sub.best_rank_column),
      #         *[*group_by].map{|gg| @source[gg].eq(sub.source[gg])}
      #       ])
      #     ).
      #     order(model_key(@model), *group_by)
      # end

      # # TODO: does ordering the subquery increase performance?
      # # TODO: override model_key in spawn to refer to projected column
      # def best_rank_subquery(*group_bys)
      #   @source.respond_to?(:project) or raise ThroughHierarchySourceError, "#{@source} cannot be converted into a subquery"
      #   group_nodes = group_bys.map{|gg|@source[gg]}
      #   subq = @model.joins(@hierarchy).arel.
      #     project(model_key(@model).as("model_key"), *group_nodes, best_rank).
      #     join(@source).on(filters).
      #     group(model_key(@model), *group_nodes).
      #     as(best_rank_table_name)
      #   spawn(subq)
      # end

    end
  end
end