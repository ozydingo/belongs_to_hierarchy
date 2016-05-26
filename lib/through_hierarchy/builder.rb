module ThroughHierarchy
  class Builder
    def initialize(model)
      @model = model
      initialize_methods_class
    end

    def initialize_methods_class
      @model.const_set("ThroughHierarchyAssociationMethods", Module.new) unless defined? @model::ThroughHierarchyAssociationMethods
      @model.include @model::ThroughHierarchyAssociationMethods if !@model.ancestors.include?(@model::ThroughHierarchyAssociationMethods)
    end

    def add_association(name, assoc)
      @model.hierarchical_associations[name] = assoc

      @model::ThroughHierarchyAssociationMethods.class_eval do
        define_method(name) do |reload = false|
          return @hierarchical_association_cache[name] if !reload && @hierarchical_association_cache.key?(name)
          @hierarchical_association_cache[name] = self.hierarchical_associations[name].find(self)
        end
      end
    end
  end
end