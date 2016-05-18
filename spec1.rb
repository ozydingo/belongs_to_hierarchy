class ResourceConfiguration
  belongs_to_hierarchy :resource, [:service, file:, :batch, :proejct, :acccount]
end

class Service
  hierarchy_has_many :resource_configuartions, as: :resource, name: :file, uniq: :resource_configuration_type_id
end

class Project
  hierarchy_has_many :resource_configuartions, as: :resource, uniq: :resource_configuration_type_id
end