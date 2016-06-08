module ThroughHierarchy
  module Associations
    class HasUniq < Association
      private

      def set_options(options)
        super
        @uniq = options[:uniq]
      end

      # Use subquery method to select best hierarchy match for each @uniq
      # Order by @uniq can result in better performance than default order (id)
      def get_matches(instance)
        associated_instance = @associated.with_instance(instance)
        arel = @associated.with_instance(instance).select_best_rank(group_by: @uniq)
        result = foreign_class.
          where(associated_instance.filters).
          joins(arel.join_sources).
          order(arel.orders)
        arel.constraints.each{|cc| result = result.where(cc)}
        return result
      end

      def get_joins
        @associated.join_best_rank(group_by: @uniq)
      end

    end
  end
end
