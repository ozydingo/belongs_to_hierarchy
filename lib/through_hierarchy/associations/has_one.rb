module ThroughHierarchy
  module Associations
    class HasOne < Association
      def find(instance)
        q = super
        q.reorder(sql_hierarchy_rank).order(q.order_values).first
      end
    end
  end
end
