module ThroughHierarchy
  module Associations
    class HasOne < Association
      def find(instance)
        results = foreign_class.
          where(arel_instance_filters(instance)).
          order(sql_hierarchy_rank)
        results = results.instance_exec(&@scope) if @scope.present?
        return results.first
      end
    end
  end
end
