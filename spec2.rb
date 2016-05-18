class ResourceConfiguration
  belongs_to_hierarchy :resource, members: [:service, :media_file, :batch, :project, :account]
end

class Service
  in_hierarchy [:service, :media_file, :batch, :project, :accuont] do
    has_many :resource_configurations, uniq: :resource_configuration_type_id
  end
end

class Project
  in_hierarchy [:project, :account] do
    has_many :resource_configurations, uniq: :resource_configuration_type_id
  end
end