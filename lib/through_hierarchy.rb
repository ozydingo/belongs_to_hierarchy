require 'through_hierarchy/base.rb'
require 'through_hierarchy/hierarchy.rb'
require 'through_hierarchy/builder.rb'
require 'through_hierarchy/associations/association.rb'
require 'through_hierarchy/associations/has_one.rb'
require 'through_hierarchy/associations/has_many.rb'
require 'through_hierarchy/exceptions.rb'

ActiveRecord::Base.include(ThroughHierarchy::Base)
