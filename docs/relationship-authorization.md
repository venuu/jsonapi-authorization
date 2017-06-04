# <a name="doc-top"></a>Authorization of operations touching relationships

`JSONAPI::Authorization` (JA) is unique in the way it considers relationship changes to change the underlying models. Whenever an incoming requests changes associated resources, JA will authorize those operations are OK.

As JA runs the authorization checks _before_ any changes are made (even to in-memory objects), Pundit policies don't have the information needed to authorize changes to relationships. This is why JA provides special hooks to authorize relationship changes and falls back to checking `#update?` on all the related records.

**Table of contents**

* [Example setup](#example-setup)
* [Changing a `has-one` relationship](#change-has-one-relationship-op)
* [Removing a `has-one` relationship](#remove-has-one-relationship-op)

<a name="example-setup"></a>

[back to top ↑](#doc-top)

## Example models and resources

The examples on this page use these models:

```rb
class Article < ActiveRecord::Base
  has_many :comments
  belongs_to :author, class_name: 'User'
end

class Comment < ActiveRecord::Base
  belongs_to :article
end

class User < ActiveRecord::Base
  has_many :articles, foreign_key: :author_id
end
```

...and these resources:

```rb
class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  # `acts_as_set` allows replacing all comments at once
  has_many :comments, acts_as_set: true
  has_one :author, class_name: 'User'
end

class CommentResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_one :article
end


class UserResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_many :comments
end
```

<a name="change-has-one-relationship-op"></a>

[back to top ↑](#doc-top)

## Changing a `has-one` relationship with a relationship operation

Setup:

```rb
user_1 = User.create(id: 'user-1')
article_1 = Article.create(id: 'article-1', user: user_1)
user_2 = User.create(id: 'user-2')
```

> `PATCH /articles/article-1/relationships/author`
> 
> ```json
> {
>   "type": "users",
>   "id": "user-2"
> }
> ```

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_author?(user_2)`

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `UserPolicy.new(current_user, user_2).update?`

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be removed. This will likely be changed in the future.

<a name="remove-has-one-relationship-op"></a>

[back to top ↑](#doc-top)

## Removing a `has-one` relationship with a relationship operation

Setup:

```rb
user_1 = User.create(id: 'user-1')
article_1 = Article.create(id: 'article-1', user: user_1)
```

> `DELETE /articles/article-1/relationships/author`
> 
> (empty body)

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).remove_author?`

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be removed. This will likely be changed in the future.
