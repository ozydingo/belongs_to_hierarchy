module ThroughHierarchy
  module Associations
    class HasOne < Association
      def find(instance)
        super.first
      end

      private

      # We always prefer better hierarchy matches regardless of scope ordering
      def get_matches(instance)
        super.order(arel_hierarchy_rank)
      end
    end
  end
end
