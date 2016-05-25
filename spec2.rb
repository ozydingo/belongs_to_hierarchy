class Service
  through_hierarchy [:media_file, :batch, :project, :account] do
    has_many :resource_configurations, uniq: :resource_configuration_type_id
  end
end

class Project
  through_hierarchy [:project, :account] do
    has_many :resource_configurations, uniq: :resource_configuration_type_id
  end
end

class MediaFile
  through_hierarchy [:batch, :project, :account] do
    has_many :special_instructions
  end

  through_hierarchy [:services] do
    has_many :processing_errors
  end
end

