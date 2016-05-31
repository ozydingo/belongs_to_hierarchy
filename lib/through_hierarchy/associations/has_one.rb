module ThroughHierarchy
  module Associations
    class HasOne < Association
      def find(instance)
        matches = super
        # ensure we order by hierarchy rank, but preserve scope orders
        matches.reorder(@associated.hierarchy_rank).order(matches.orders).first
      end

      private

      def get_joins
        arel = @associated.join_best_rank
        result = @model.joins(arel.join_sources).order(arel.orders)
        arel.constraints.each{|cc| result = result.where(cc)}
        return result
      end

    end
  end
end
