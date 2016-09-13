module ThroughHierarchy
  module Associations
    class Association
      def initialize(name, model, members, options = {})
        @name = name
        @model = model
        @members = members

        set_options(options)
        validate_options

        @associated = Hierarchicals::Hierarchical.new(foreign_arel_table, model, members, as: @polymorphic_name)
      end

      def find(instance)
        results = get_matches(instance)
        results = results.create_with(associated_instance(instance).create_with)
        results = results.instance_exec(&@scope) if @scope.present?
        return results
      end

      def join
        results = get_joins
        results = results.merge(foreign_class.instance_exec(&@scope)) if @scope.present?
        return results
      end

      def create(member, attributes)
        # NIY
      end

      private

      def set_options(options)
        @polymorphic_name = options[:as].to_s
        @scope = options[:scope]
        @foreign_class_name = options[:class_name] || @name.to_s.classify
      end

      def validate_options
        @polymorphic_name.present? or raise ThroughHierarchyDefinitionError, "Must provide polymorphic `:as` options for through_hierarchy"
        @model.is_a?(Class) or raise ThroughHierarchyDefinitionError, "Expected: class, got: #{@model.class}"
        @model < ActiveRecord::Base or raise ThroughHierarchyDefinitionError, "Expected: ActiveRecord::Base descendant, got: #{@model}"
        @scope.blank? || @scope.is_a?(Proc) or raise ThroughHierarchyDefinitionError, "Expected scope to be a Proc, got #{@scope.class}"
      end

      def associated_instance(instance)
        @associated.with_instance(instance)
      end

      def get_matches(instance)
        return foreign_class.where(associated_instance(instance).filters)
      end

      # TODO: we might generate fewer join sources if we figure out which members
      # are :through associations. Currently those generate redundant joins.
      def get_joins
        join_sources = @model.arel_table.
          join(@associated.source).
          on(@associated.filters).
          join_sources
        return @model.joins(@members + join_sources)
      end

      def foreign_class
        @foreign_class_name.constantize
      end

      def foreign_arel_table
        foreign_class.arel_table
      end
    end
  end
end
