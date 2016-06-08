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
        @associated.join_best_rank
      end

    end
  end
end
