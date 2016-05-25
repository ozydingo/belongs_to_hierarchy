module ThroughHierarchy
  module Associations
    class HasOne
      def find
        super.first
      end
    end
  end
end
