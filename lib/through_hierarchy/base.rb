module ThroughHierarchy
  module Base
    extend ActiveSupport::Concern

    included do
      class_attribute :hierarchical_associations
      self.hierarchical_associations = {}
      attr_reader :hierarchical_association_cache
      after_initialize :reset_hierarchical_association_cache
    end

    def reset_hierarchical_association_cache
      @hierarchical_association_cache = {}
    end

    module ClassMethods
      def through_hierarchy(members, &blk)
        Hierarchy.new(self, members).instance_eval(&blk)
      end
    end
  end
end
