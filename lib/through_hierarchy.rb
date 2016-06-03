require 'through_hierarchy/base.rb'
require 'through_hierarchy/hierarchy.rb'
require 'through_hierarchy/builder.rb'
require 'through_hierarchy/associations/association.rb'
require 'through_hierarchy/associations/has_one.rb'
require 'through_hierarchy/associations/has_many.rb'
require 'through_hierarchy/associations/has_uniq.rb'
require 'through_hierarchy/exceptions.rb'
require 'through_hierarchy/hierarchicals/hierarchical.rb'
require 'through_hierarchy/hierarchicals/instance.rb'

ActiveRecord::Base.include(ThroughHierarchy::Base)
