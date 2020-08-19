module ThroughHierarchy
  module RailsUtils
    module_function

    def sanitize_sql(string)
      if rails_major_minor_version < 5.1
        ActiveRecord::Base.sanitize(string)
      else
        ActiveRecord::Base.sanitize_sql_array(["?", string])
      end
    end

    def rails_major_minor_version
      Rails.version.split(".").first(2).join(".").to_f
    end
  end
end
