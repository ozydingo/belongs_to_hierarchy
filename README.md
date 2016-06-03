# Has Many Through Hierarchy
## Define hierarchically polymorphic has_one and has_many assocaitions between ActiveRecord models

Through Hierarchy allows you to construct associations that span across associaiton hierarchies. For example, consider the models `Document`, `Folder`, and `Project`. These models might be organized into a hierarchy where `Project` `has_many :folders`, `Folder` `has_many :documents`, and `Project` `has_many :documents, through: folders`.

Now consider a polymorphically assocaited `Tag` model. A given `Tag` can belong to any member of this hierarchy. So how do you get all the tags under a `Project`? Through Hierarchy allows you to very simply, and dynamically, define this association that run reasonably efficiently and return an `ActiveRecord::Relation` so that you can chain other scopes and queries to the result, taking advantage of lazy loading and everything else ActiveRecord has to offer.

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

### Hierarchy order

You could also choose to define the resource hierarchy in the other order. In this mode, rather than `Project.tags` returning all the tags belonging to it or its sub-hierarchy, we want `Document.tags` to return the tags of itself and its hierarchy superiors.

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

### Fetching by closest hierarchy member (shadowing)

A common use case for this are configurations that may be applied at the `Project`, `Folder`, or `Document` level, where applying a configuration at a lower level shadows a higher-level configuration.

To illustrate this, consider first a very simplified and totally-not-overkill-at-all `ShareSetting` model that `belongs_to :shareable, polymorphic: true` and has a boolean `shared` column. The idea would be to create a `ShareSetting` record for a `Project`, say we set it to `true`, and it would be inherited implicity by all of its `Folder`s and `Document`s. However, you could override this at a lower resource level by, for example, creating another `ShareSetting` record for one of this Project's folders. The desired behavior would look like this:

```ruby
class Document < ActiveRecord::Base
  through_hierarchy [:folder, :project] do
    has_one :share_settting, as: :resource
  end
end

project = Project.first
ShareSetting.create(shareable: project, shared: true)
doc = project.documents.first
doc.share_setting
# => #<ShareSetting id: 1, shareable_type: "Project", shareable_id: 1, shared: true>
# Override the project config for a single folder:
ShareSetting.create(shareable: doc.folder, shared: false)
# Be sure to reload the asoociation by passing true!
doc.share_setting(true)
# => #<ShareSetting id: 2, shareable_type: "Folder", shareable_id: 1, shared: false>
```

### Fetching many by closest hierarchy member

In the context of a plain `has_many` association, this shadowing behavior doesn't make sense as you would expect it to return *all* `ShareSetting` belonging to the hierarchy:

```ruby
class Document < ActiveRecord::Base
  through_hierarchy [:folder, :project] do
    has_many :share_setttings, as: :resource
  end
end

Document.first.share_settings
# => #<ActiveRecord::Relation [#<ShareSetting id: 1, shareable_type: "Project", shareable_id: 1, shared: true>, #<ShareSetting id: 2, shareable_type: "Folder", shareable_id: 1, shared: false>]>
```

But for a more complicated `ShareSetting` model, this gets more interesting, and so we have the `uniq` feature. Let's add a `group` column to ShareSetting so we can indepednently turn on or off sharing for different groups, again at any resource level:

```ruby
project = Project.first
project.share_settings.destroy_all
project.share_settings.create(group: "dev", shared: true)
project.share_settings.create(group: "ops", shared: false)
doc = project.documents.first
doc.share_settings.where(group: "dev").first
# => #<ShareSetting id: 3, shareable_type: "Project", shareable_id: 1, group: "dev", shared: true>
```

But because this is still a plain `has_many`, we lose the shadowing:

```ruby
doc.share_settings.create(group: "ops", shared: true)
doc.share_settings.where(group: "ops")
# => #<ActiveRecord::Relation [#<ShareSetting id: 4, shareable_type: "Project", shareable_id: 1, group: "ops", shared: false>, #<ShareSetting id: 5, shareable_type: "Document", shareable_id: 1, group: "ops", shared: false>]>
```

In order to retrive only one `ShareSetting` per group, you simply need to specify it thusly:

```ruby
class Document < ActiveRecord::Base
  through_hierarchy [:folder, :project] do
    has_many :share_setttings, as: :resource, uniq: :group
  end
end

Document.first.share_settings.where(group: "ops")
# => #<ActiveRecord::Relation [#<ShareSetting id: 5, shareable_type: "Document", shareable_id: 1, group: "ops", shared: true>]>

Document.first.share_settings
# => #<ActiveRecord::Relation [#<ShareSetting id: 3, shareable_type: "Project", shareable_id: 1, group: "dev", shared: true>, #<ShareSetting id: 5, shareable_type: "Document", shareable_id: 1, group: "ops", shared: true>]>

```

Notice that we correclty select only the `ShareSetting` for each group that belongs to the lower level resource in the hierarchy: the project is not shared with "ops", but this specific document has a `ShareSetting` that overrides that.

### Joining to hierarchical Assocaitions
Beware that this feature is still slightly experiemntal

You can join to hierarchical associations! That is, for example you can find a `Documnet` that has any `ShareSetting` *at a relevant hierarchy level* that matches whatever query your heart desires. This is as simple as

```ruby
Document.joins_through_hierarchy(:share_settings)
```

Query on, queryer.

For `HasMany` associations, this is rather straightforward as all hierarchy levels are relevant and can be included in the resulting join. That is, a given target row can be joined to its associated model through multiple levels of the hierarchy.

However, for `HasOne` and `HasMany :uniq` associations, this suddenyl becomes very complicated. The trick is to join *only* to the closest hierarchy match *for each* target row. This is not a rapid query, but I have been optimizing it to acceptable levels of performance. Suggestions and PRs welcome!
