module ThroughHierarchy
  module Associations
    class Association
      def initialize(name, model, members, options = {})
        @name = name
        @model = model
        @members = members
        @as = options[:as].to_s
        @foreign_class_name = options[:class_name] || @name.to_s.classify
        @uniq = options[:uniq]

        validate_options
      end

      def find
        arel_table.where()
      end

      def create
      end

      private

      def validate_options
        @as.present? or raise ThroughHierarchyDefinitionError, "Must provide polymorphic `:as` options for through_hierarchy"
        @model.is_a?(Class) or raise ThroughHierarchyDefinitionError, "Expected: class, got: #{@model.class}"
        @model < ActiveRecord::Base or raise ThroughHierarchyDefinitionError, "Expected: ActiveRecord::Base descendant, got: #{@model}"
      end

      def klass
        @foreign_class_name.constantize
      end

      def foreign_arel_table
        klass.arel_table
      end

      def arel_foreign_resource_type
        foreign_arel_table[@as + "_type"]
      end

      def arel_foreign_resource_id
        foreign_arel_table[@as.foreign_key]
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
        model_class.foreign_arel_table[model_class.primary_key]
      end

      def arel_filter(resource)
        arel_foreign_resource_type.eq(instance_type_constraint(resource)).
          and(arel_foreign_resource_id.eq(instance_key_constraint(resource)))
      end

      def arel_filters(resource)
        hierarchy_classes.map{}
      end

      def hierarchy_classes
        @model + @members.map{|m| m.classify.constantize}
      end
    end
  end
end
