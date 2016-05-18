module BelongsToHierarchy
  class Base
    extend ActiveRecord::Concern

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
      # name members in order of priority
      # e.g. :file, :project, :account
      # ResourceConfigruation.belongs_to_hierarchy :resource, [:service, file:, :batch, :proejct, :acccount]
      # BillingConfiguration.belongs_to_hierarchy :billing_resource, [:project, :account]
      def belongs_to_hierarchy(name, *members)
      end

      # Project.hierarchy_has_one :billing_setting, as: :billing_resource
      def hierarchy_has_one()
      end

      # MediaFile.hierarchy_has_many :resource_configuartions, as: :resource, name: :file, unique: :resource_configuration_type_id
      def hierarchy_has_many()
      end
    end
  end
end
