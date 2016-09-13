# Has Many Through Hierarchy
## Define an association between an ActiveRecord model and a hierachy of various other models

Through Hierarchy allows you to construct associations that span across different models via a defined hierarchy. Supported associations include `has_one`, `has_many`, and `has)many :uniq` associations.

* A `has_many` assocaition fetches any objects associated to a target through any of its hierarchy members.

* A `has_one` will always fetch the association belonging to the closest hierarchy member (e.g. Document < Folder < Project).

* A `has_many :uniq` assocaition retrieves multiple assocaited objects, but groups them by a specified field (e.g. a type or type_id column), and fetches only the object belonging to the closest hierarchy member *within* each group. In essense, a `has_many :uniq` association can be described as a `has_many has_one`s of the same model.

### Example

For example, consider the models `Document`, `Folder`, and `Project`. These models might be organized into a hierarchy where `Project` `has_many :folders`, `Folder` `has_many :documents`, and `Project` `has_many :documents, through: folders`.

Now let's make a `Tag` model that can (polymorphically) belong to any of these three models. Through Hierarchy allows you to very simply fetch all tags across the hierarchy as an ActiveRecord Relation. Thus you can chain the result, and get all the benefits of ActiveRecord, including lazy loading.

We can set up the hierarchy as follows:

```ruby
class Project < ActiveRecord::Base
  through_hierarchy [:folders, :documents] do
    has_many :tags, as: :resource
  end
end

class Folder < ActiveRecord::Base
  through_hierarchy [:documents] do
    has_many :tags, as: :resource
  end
end

class Document < ActiveRecord::Base
  has_many :tags, as: :resource
end
```

Note that, as a polymorphic association, the `:as` keyword is required.

Now, `project.tags` will retrieve *all* tags attached to that project, any of its folders, and any of their documents.

### Hierarchy order

You could also choose to define the resource hierarchy in the other order. That is, maybe you actually want `document.tags` to return all tags associated with that document, its folder, or its project. Easy:

```ruby
class Project < ActiveRecord::Base
  has_many :tags, as: :resource
end

class Folder < ActiveRecord::Base
  through_hierarchy [:project] do
    has_many :tags, as: :resource
  end
end

class Document < ActiveRecord::Base
  through_hierarchy [:folder, :project] do
    has_many :tags, as: :resource
  end
end
```

### Shadowing: fetching only the closest hierarchy member

A common use case for this are settings that may be applied at the `Project`, `Folder`, or `Document` level, where applying a setting at a lower level shadows / overrides a higher-level setting. E.g., a project may have setting x == ABC, but a folder within that project overrides that and uses setting x = DEF instead. Any documents in this folder will automatically inherit this new overridden setting (DEF), while documents in other folders will get the project's setting (ABC).

To illustrate this, consider first a very simplified and totally-not-overkill-at-all `ShareSetting` model that `belongs_to :shareable, polymorphic: true` and has a boolean `shared` column. If we create a `ShareSetting` record for a project with a `true` value, this setting would be shared by all folders and doucments in this project.

```ruby
# set up Document to inherit ShareSettings from :folder and :project
class Document < ActiveRecord::Base
  through_hierarchy [:folder, :project] do
    has_one :share_settting, as: :resource
  end
end

## Enable sharing on the project
project = Project.first
ShareSetting.create(shareable: project, shared: true)
## And the docs inherit it
doc = project.documents.first
doc.share_setting
# => #<ShareSetting id: 1, shareable_type: "Project", shareable_id: 1, shared: true>
```

But we can still disable sharing on a folder or document level within this project by creating another `ShareSetting` record on the appropriate resource:

```ruby
## Override the project config for a single folder:
ShareSetting.create(shareable: doc.folder, shared: false)
## Be sure to reload the asoociation by passing true!
doc.share_setting(true)
# => #<ShareSetting id: 2, shareable_type: "Folder", shareable_id: 1, shared: false>
doc.folder.share_setting
# => #<ShareSetting id: 2, shareable_type: "Folder", shareable_id: 1, shared: false>
```

And the project, as well as other folders and document of other folders inside this project, is still shared via the project setting:

```ruby
doc.project.share_setting(true)
# => #<ShareSetting id: 1, shareable_type: "Project", shareable_id: 1, shared: true>
doc.project.folders.second.share_setting  ## different folder
# => #<ShareSetting id: 1, shareable_type: "Project", shareable_id: 1, shared: true>
```

### `has_many :uniq`: Fetching many by closest hierarchy member

Here's where it gets interesting. Let's make `ShareSetting` a little more complicated: let's add a `group` column to ShareSetting so we can indepednently turn on or off sharing for different groups, again at any resource level. For example, maybe we want to share a project with the "dev" group but not the "ops" group.

```ruby
project = Project.first
project.share_settings.destroy_all
ShareSetting.create(shareable: project, group: "dev", shared: true)
ShareSetting.create(shareable: project, group: "ops", shared: false)
doc = project.documents.first
doc.share_settings.find_by(group: "dev")
# => #<ShareSetting id: 3, shareable_type: "Project", shareable_id: 1, group: "dev", shared: true>
doc.share_settings.find_by(group: "ops")
# => #<ShareSetting id: 4, shareable_type: "Project", shareable_id: 1, group: "ops", shared: false>
```

With `has_many :uniq`, we can override this setting for a specific group at a specific resource. That is, we could share a specific folder or document in this project with the "ops" group by creating another ShareSetting, and the `has_many :uniq` association will obey this shadowing in all finds and joins:

```ruby
class Document < ActiveRecord::Base
  through_hierarchy [:folder, :project] do
    has_many :share_setttings, as: :resource, uniq: :group
  end
end

## On the same doc as above, override sharing for "ops"
ShareSetting.create(shareable: doc, group: "ops", shared: true)
Document.first.share_settings.find_by(group: "ops")
# => #<ShareSetting id: 5, shareable_type: "Document", shareable_id: 1, group: "ops", shared: true>
## But the folder above it still correctly inherits the project setting
Document.first.folder.share_settings.find_by(group: "ops")
# => #<ShareSetting id: 4, shareable_type: "Project", shareable_id: 1, group: "ops", shared: false>

## The full returned list of ShareSettings can contain objects with different hierarchy levels, each being the closest for the `:group` column:
Document.first.share_settings
# => #<ActiveRecord::Relation [#<ShareSetting id: 3, shareable_type: "Project", shareable_id: 1, group: "dev", shared: true>, #<ShareSetting id: 5, shareable_type: "Document", shareable_id: 1, group: "ops", shared: true>]>

```

### Joining to hierarchical Assocaitions
Beware that this feature is still slightly experiemntal

You can join to hierarchical associations! That is, for example you can find a `Documnet` that has any `ShareSetting` *at a relevant hierarchy level* that matches whatever query your heart desires. This is as simple as

```ruby
Document.joins_through_hierarchy(:share_settings)
```

Query on, queryer.

For `has_many` associations, this is rather straightforward as all hierarchy levels are relevant and can be included in the resulting join. That is, a given target row can be joined to its associated model through multiple levels of the hierarchy.

However, for `has_one` and `has_many :uniq` associations, this suddenly becomes rather complicated. The trick is to join *only* to the closest hierarchy match *for each* target row. This is not a rapid query, but I have been optimizing it to acceptable levels of performance. Suggestions and PRs welcome!
