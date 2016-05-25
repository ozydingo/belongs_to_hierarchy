module ThroughHierarchy
  class Hierarchy < BasicObject
    def initailize(klass, members)
      @klass = klass
      @members = members

      validate_members
    end

    def has_one(name, scope = nil, **options)
      options.merge!(scope: scope) if scope.present?
      @klass.hierarchical_associations[name] = ::ThroughHierarchy::Associations::HasOne.new(name, @klass, @members, scope, options)
    end

    def has_many(name, scope = nil, **options)
      options.merge!(scope: scope) if scope.present?
      @klass.hierarchical_associations[name] = ::ThroughHierarchy::Associations::HasMany.new(name, @klass, @members, scope, options)
    end

    private

    def validate_members
      @members.all?{|member| klass.reflect_on_association(member).present?} or raise "No association named #{member} was found. Perhaps you misspelled it?"
    end
  end  
end
