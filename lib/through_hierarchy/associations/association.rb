module ThroughHierarchy
  module Associations
    class Association
      def initialize(name, model, members, options = {})
        @name = name
        @model = model
        @members = members
        @as = options[:as].to_s
        @scope = options[:scope]
        @foreign_class_name = options[:class_name] || @name.to_s.classify
        @uniq = options[:uniq]

        validate_options
      end

      def find(instance)
        return uniq_find(instance) if @uniq.present?

        results = foreign_class.where(arel_instance_filters(instance))
        results = results.instance_exec(&@scope) if @scope.present?
        return results
      end

      def joins
        # TODO: make this work
        # joins = @model.arel_table.join(foreign_arel_table).on(arel_model_filters)

        # joins = joins.join(arel_uniq_subquery).on(
        #   arel_hierarchy_rank.eq(uniq_subquery_arel_table[best_hierarchy_match_name]).
        #   and(foreign_arel_table[@uniq].eq(uniq_subquery_arel_table[@uniq]))
        # ) if @uniq.present?

        # results = @model.joins(joins.join_sources)
        # results = results.merge(foreign_class.instance_exec(&@scope)) if @scope.present?
        # return results
      end

      def create(member, attributes)
        # NIY
      end

      private

      def validate_options
        @as.present? or raise ThroughHierarchyDefinitionError, "Must provide polymorphic `:as` options for through_hierarchy"
        @model.is_a?(Class) or raise ThroughHierarchyDefinitionError, "Expected: class, got: #{@model.class}"
        @model < ActiveRecord::Base or raise ThroughHierarchyDefinitionError, "Expected: ActiveRecord::Base descendant, got: #{@model}"
        @scope.blank? || @scope.is_a?(Proc) or raise ThroughHierarchyDefinitionError, "Expected scope to be a Proc, got #{@scope.class}"
      end

      def foreign_class
        @foreign_class_name.constantize
      end

      def foreign_arel_table
        foreign_class.arel_table
      end

      def sql_hierarchy_rank
        "CASE `#{foreign_class.table_name}`.`#{foreign_type_field}` " +
          hierarchy_models.map.with_index{|m, ii| "WHEN #{@model.sanitize(model_type_constraint(m))} THEN #{ii} "}.join +
          "END"
      end

      def arel_hierarchy_rank
        Arel.sql(sql_hierarchy_rank)
      end

      # TODO: generate this dynamically based on existing columns and selects
      def best_hierarchy_match_name
        "through_hierarchy_match"
      end

      def arel_best_hierarchy_member
        arel_hierarchy_rank.minimum.as(best_hierarchy_match_name)
      end

      # TODO: for model level joins, subquery needs to join to all hierarchy tables
      def arel_uniq_subquery(instance = nil)
        foreign_arel_table.
          project(foreign_arel_table[Arel.star], arel_best_hierarchy_member).
          where(instance.present? ? arel_instance_filters(instance) : arel_model_filters).
          group(foreign_arel_table[@uniq]).
          as(uniq_subquery_alias)
      end

      def uniq_subquery_alias
        "through_hierarchy_subtable"
      end

      def uniq_subquery_arel_table
        Arel::Table.new(uniq_subquery_alias)
      end

      # TODO: build join sources for model-level query
      def uniq_subquery_join_sources(instance = nil)
        foreign_arel_table.
          join(arel_uniq_subquery(instance)).
          on(
            arel_hierarchy_rank.eq(uniq_subquery_arel_table[best_hierarchy_match_name]).
            and(foreign_arel_table[@uniq].eq(uniq_subquery_arel_table[@uniq]))
          ).join_sources
      end

      def uniq_find(instance)
        join_sources = uniq_subquery_join_sources(instance)

        return foreign_class.
          joins(uniq_subquery_join_sources(instance)).
          where(arel_instance_filters(instance)).
          order(foreign_arel_table[@uniq])
      end

      def hierarchy_models
        [@model] + @members.map{|m| @model.reflect_on_association(m).klass}
      end

      def hierarchy_instances(instance)
        [instance] + @members.map{|m| instance.association(m).load_target}
      end

      def foreign_key_field
        @as.foreign_key
      end

      def foreign_type_field
        @as + "_type"
      end

      def arel_foreign_key_field
        foreign_arel_table[foreign_key_field]
      end

      def arel_foreign_type_field
        foreign_arel_table[foreign_type_field]
      end

      def arel_model_filters
        hierarchy_models.map{|model| arel_model_filter(model)}.reduce{|q, cond| q.or(cond)}
      end

      def arel_instance_filters(instance)
        hierarchy_instances(instance).map{|instance| arel_instance_filter(instance)}.reduce{|q, cond| q.or(cond)}
      end

      def arel_model_filter(model)
        arel_foreign_type_field.eq(model_type_constraint(model)).
          and(arel_foreign_key_field.eq(model_key_constraint(model)))        
      end

      def arel_instance_filter(instance)
        arel_foreign_type_field.eq(instance_type_constraint(instance)).
          and(arel_foreign_key_field.eq(instance_key_constraint(instance)))
      end

      def instance_type_constraint(resource)
        resource.class.base_class.to_s
      end

      def instance_key_constraint(resource)
        resource.attributes[resource.class.primary_key]
      end

      def model_type_constraint(model_class)
        model_class.base_class.to_s
      end

      def model_key_constraint(model_class)
        model_class.arel_table[model_class.primary_key]
      end
    end
  end
end
