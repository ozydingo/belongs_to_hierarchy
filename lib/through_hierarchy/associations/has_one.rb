module ThroughHierarchy
  module Associations
    class HasOne < Association
      def find(instance)
        super.first
      end
    end
  end
end
