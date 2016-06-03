module ThroughHierarchy
  class Hierarchy < BasicObject
    def initialize(klass, members)
      @klass = klass
      @members = members

      validate_hierarchy
    end

    def has_one(name, scope = nil, **options)
      options.merge!(scope: scope) if scope.present?
      assoc = ::ThroughHierarchy::Associations::HasOne.new(name, @klass, @members, options)
      ::ThroughHierarchy::Builder.new(@klass).add_association(name, assoc)
    end

    def has_many(name, scope = nil, **options)
      options.merge!(scope: scope) if scope.present?
      if options.key?(:uniq)
        assoc = ::ThroughHierarchy::Associations::HasUniq.new(name, @klass, @members, options)
      else
        assoc = ::ThroughHierarchy::Associations::HasMany.new(name, @klass, @members, options)
      end
      ::ThroughHierarchy::Builder.new(@klass).add_association(name, assoc)
    end

    private

    def validate_hierarchy
      @members.is_a?(::Array) or ::Kernel.raise ::ThroughHierarchy::ThroughHierarchyDefinitionError, "Hierarchy members: expected: Array, got: #{@members.class}"
      @members.all?{|member| @klass.reflect_on_association(member).present? or ::Kernel.raise ::ThroughHierarchy::ThroughHierarchyDefinitionError, "No association named #{member} was found. Perhaps you misspelled it?"}
    end
  end  
end
