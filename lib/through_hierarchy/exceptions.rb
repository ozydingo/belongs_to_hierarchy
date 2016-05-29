module ThroughHierarchy
  class ThroughHierarchyError < StandardError
  end

  class ThroughHierarchyDefinitionError < ThroughHierarchyError
  end

  class ThroughHierarchyAssociationMissingError < ThroughHierarchyError
  end
end
