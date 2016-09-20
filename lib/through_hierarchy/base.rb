module ThroughHierarchy
  module Base
    extend ActiveSupport::Concern

    included do
      class_attribute :hierarchical_associations
      self.hierarchical_associations = {}
      attr_reader :hierarchical_association_cache
      after_initialize :clear_hierarchical_association_cache
    end

    def clear_hierarchical_association_cache(name = nil)
      if name.nil?
        @hierarchical_association_cache = {}
      else
        @hierarchical_association_cache.delete(name)
      end
    end

    module ClassMethods
      # deep_dup these class attributes on inheritance so we can safely use in-place modifiers
      def inherited(child)
        child.hierarchical_associations = self.hierarchical_associations.deep_dup
        super
      end

      def through_hierarchy(members, &blk)
        Hierarchy.new(self, members).instance_eval(&blk)
      end

      def joins_through_hierarchy(name)
        hierarchical_associations.key?(name) or raise ThroughHierarchyAssociationMissingError, "No association named #{name} was found. Perhaps you misspelled it?"
        hierarchical_associations[name].join
      end

      # TODO: create_through_hierarchy(member = self, attributes)
    end
  end
end
