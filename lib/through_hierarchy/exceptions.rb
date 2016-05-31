module ThroughHierarchy
  class ThroughHierarchyError < StandardError
  end

  class ThroughHierarchyDefinitionError < ThroughHierarchyError
  end

  class ThroughHierarchyAssociationMissingError < ThroughHierarchyError
  end

  class ThroughHierarchySourceError < ThroughHierarchyError
  end

  class ThroughHierarchyInstanceError < ThroughHierarchyError
  end
end
