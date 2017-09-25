# <a name="doc-top"></a>Authorization of operations touching relationships

`JSONAPI::Authorization` (JA) is unique in the way it considers relationship changes to change the underlying models. Whenever an incoming request changes associated resources, JA will authorize those operations are OK.

As JA runs the authorization checks _before_ any changes are made (even to in-memory objects), Pundit policies don't have the information needed to authorize changes to relationships. This is why JA provides special hooks to authorize relationship changes and falls back to checking `#update?` on all the related records.

Caveat: In case a relationship is modifiable through multiple ways it is your responsibility to ensure consistency.
For example if you have a many-to-many relationship with users and projects make sure that
`ProjectPolicy#add_to_users?(users)` and `UserPolicy#add_to_projects?(projects)` match up.

**Table of contents**

* `has-one` relationships
  - [Example setup for `has-one` examples](#example-setup-has-one)
  - [`PATCH /articles/article-1/relationships/author`](#change-has-one-relationship-op)
    * Changing a `has-one` relationship
  - [`DELETE /articles/article-1/relationships/author`](#remove-has-one-relationship-op)
    * Removing a `has-one` relationship
  - [`PATCH /articles/article-1/` with different `author` relationship](#change-and-replace-has-one-resource-op)
    * Changing resource and replacing a `has-one` relationship
  - [`PATCH /articles/article-1/` with null `author` relationship](#change-and-remove-has-one-resource-op)
    * Changing resource and removing a `has-one` relationship
  - [`POST /articles` with an `author` relationship](#create-has-one-resource-op)
    * Creating a resource with a `has-one` relationship
* `has-many` relationships
  - [Example setup for `has-many` examples](#example-setup-has-many)
  - [`POST /articles/article-1/relationships/comments`](#add-to-has-many-relationship-op)
    * Adding to a `has-many` relationship
  - [`DELETE /articles/article-1/relationships/comments`](#remove-from-has-many-relationship-op)
    * Removing from a `has-many` relationship
  - [`PATCH /articles/article-1/relationships/comments` with different `comments`](#replace-has-many-relationship-op)
    * Replacing a `has-many` relationship
  - [`PATCH /articles/article-1/relationships/comments` with empty `comments`](#remove-has-many-relationship-op)
    * Removing a `has-many` relationship
  - [`PATCH /articles/article-1` with different `comments` relationship](#change-and-replace-has-many-resource-op)
    * Changing resource and replacing a `has-many` relationship
  - [`PATCH /articles/article-1` with empty `comments` relationship](#change-and-remove-has-many-resource-op)
    * Changing resource and removing a `has-many` relationship
  - [`POST /articles` with a `comments` relationship](#create-has-many-resource-op)
    * Creating a resource with a `has-many` relationship


<a name="example-setup-has-one"></a>

[back to top ↑](#doc-top)

## `has-one` relationships

### Example setup for `has-one` examples

The examples for `has-one` relationship authorization use these models and resources:

```rb
class Article < ActiveRecord::Base
  belongs_to :author, class_name: 'User'
end

class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource
  has_one :author, class_name: 'User'
end
```

```rb
class User < ActiveRecord::Base
  has_many :articles, foreign_key: :author_id
end

class UserResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource
  has_many :articles
end
```

<a name="change-has-one-relationship-op"></a>

[back to top ↑](#doc-top)

### `PATCH /articles/article-1/relationships/author`

_Changing a `has-one` relationship with a relationship operation_

Setup:

```rb
user_1 = User.create(id: 'user-1')
article_1 = Article.create(id: 'article-1', author: user_1)
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

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_author?(user_2)`

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `UserPolicy.new(current_user, user_2).update?`

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be dissociated. This will likely be changed in the future.

<a name="remove-has-one-relationship-op"></a>

[back to top ↑](#doc-top)

### `DELETE /articles/article-1/relationships/author`

_Removing a `has-one` relationship with a relationship operation_

Setup:

```rb
user_1 = User.create(id: 'user-1')
article_1 = Article.create(id: 'article-1', author: user_1)
```

> `DELETE /articles/article-1/relationships/author`
>
> (empty body)

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).remove_author?`

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be dissociated. This will likely be changed in the future.

<a name="change-and-replace-has-one-resource-op"></a>

[back to top ↑](#doc-top)

### `PATCH /articles/article-1/` with different `author` relationship

_Changing resource and replacing a `has-one` relationship_

Setup:

```rb
user_1 = User.create(id: 'user-1')
article_1 = Article.create(id: 'article-1', author: user_1)
user_2 = User.create(id: 'user-2')
```

> `PATCH /articles/article-1`
>
> ```json
> {
>   "type": "articles",
>   "id": "article-1",
>   "relationships": {
>     "author": {
>       "data": {
>         "type": "users",
>         "id": "user-2"
>       }
>     }
>   }
> }
> ```

#### Always calls

* `ArticlePolicy.new(current_user, article_1).update?`

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_author?(user_2)`

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `UserPolicy.new(current_user, user_2).update?`

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be dissociated. This will likely be changed in the future.

<a name="change-and-remove-has-one-resource-op"></a>

[back to top ↑](#doc-top)

### `PATCH /articles/article-1/` with null `author` relationship

_Changing resource and removing a `has-one` relationship_

Setup:

```rb
user_1 = User.create(id: 'user-1')
article_1 = Article.create(id: 'article-1', author: user_1)
```

> `PATCH /articles/article-1`
>
> ```json
> {
>   "type": "articles",
>   "id": "article-1",
>   "relationships": {
>     "author": {
>       "data": null
>     }
>   }
> }
> ```

#### Always calls

* `ArticlePolicy.new(current_user, article_1).update?`

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).remove_author?`

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be dissociated. This will likely be changed in the future.

<a name="create-has-one-resource-op"></a>

[back to top ↑](#doc-top)

### `POST /articles` with an `author` relationship

_Creating a resource with a `has-one` relationship_

Setup:

```rb
user_1 = User.create(id: 'user-1')
```

> `POST /articles`
>
> ```json
> {
>   "type": "articles",
>   "relationships": {
>     "author": {
>       "data": {
>         "type": "users",
>         "id": "user-1"
>       }
>     }
>   }
> }
> ```

#### Always calls

* `ArticlePolicy.new(current_user, Article).create?`

**Note:** The second parameter for the policy is the `Article` _class_, not the new record. This is because JA runs the authorization checks _before_ any changes are made, even changes to in-memory objects.

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, Article).create_with_author?(user_1)`

#### Fallback

* `UserPolicy.new(current_user, user_1).update?`


<a name="example-setup-has-many"></a>

[back to top ↑](#doc-top)

## `has-many` relationships

### Example setup for `has-many` examples

The examples for `has-many` relationship authorization use these models and resources:

```rb
class Article < ActiveRecord::Base
  has_many :comments
end

class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource
  # `acts_as_set` allows replacing all comments at once
  has_many :comments, acts_as_set: true
end
```

```rb
class Comment < ActiveRecord::Base
  belongs_to :article
end

class CommentResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource
  has_one :article
end
```

<a name="add-to-has-many-relationship-op"></a>

[back to top ↑](#doc-top)

### `POST /articles/article-1/relationships/comments`

_Adding to a `has-many` relationship_

Setup:

```rb
comment_1 = Comment.create(id: 'comment-1')
article_1 = Article.create(id: 'article-1', comments: [comment_1])
comment_2 = Comment.create(id: 'comment-2')
comment_3 = Comment.create(id: 'comment-3')
```

> `POST /articles/article-1/relationships/comments`
>
> ```json
> {
>   "data": [
>     { "type": "comments", "id": "comment-2" },
>     { "type": "comments", "id": "comment-3" }
>   ]
> }
> ```

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).add_to_comments?([comment_2, comment_3])`

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`
* `CommentPolicy.new(current_user, comment_3).update?`

<a name="remove-from-has-many-relationship-op"></a>

[back to top ↑](#doc-top)

### `DELETE /articles/article-1/relationships/comments`

_Removing from a `has-many` relationship_

Setup:

```rb
comment_1 = Comment.create(id: 'comment-1')
comment_2 = Comment.create(id: 'comment-2')
comment_3 = Comment.create(id: 'comment-3')
article_1 = Article.create(id: 'article-1', comments: [comment_1, comment_2, comment_3])
```

> `DELETE /articles/article-1/relationships/comments`
>
> ```json
> {
>   "data": [
>     { "type": "comments", "id": "comment-1" },
>     { "type": "comments", "id": "comment-2" }
>   ]
> }
> ```

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).remove_from_comments?([comment_1, comment_2])`

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `CommentPolicy.new(current_user, comment_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`

<a name="replace-has-many-relationship-op"></a>

[back to top ↑](#doc-top)

### `PATCH /articles/article-1/relationships/comments` with different `comments`

_Replacing a `has-many` relationship_

Setup:

```rb
comment_1 = Comment.create(id: 'comment-1')
article_1 = Article.create(id: 'article-1', comments: [comment_1])
comment_2 = Comment.create(id: 'comment-2')
comment_3 = Comment.create(id: 'comment-3')
```

> `PATCH /articles/article-1/relationships/comments`
>
> ```json
> {
>   "data": [
>     { "type": "comments", "id": "comment-2" },
>     { "type": "comments", "id": "comment-3" }
>   ]
> }
> ```

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_comments?([comment_2, comment_3])`

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`
* `CommentPolicy.new(current_user, comment_3).update?`

**Note:** Currently JA does not fallback to authorizing `CommentPolicy#update?` on `comment_1` that is about to be dissociated. This will likely be changed in the future.

<a name="remove-has-many-relationship-op"></a>

[back to top ↑](#doc-top)

### `PATCH /articles/article-1/relationships/comments` with empty `comments`

_Removing a `has-many` relationship_

Setup:

```rb
comment_1 = Comment.create(id: 'comment-1')
article_1 = Article.create(id: 'article-1', comments: [comment_1])
```

> `PATCH /articles/article-1/relationships/comments`
>
> ```json
> {
>   "data": []
> }
> ```

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_comments?([])`

**TODO:** We should probably call `remove_comments?` (with no arguments) instead. See https://github.com/venuu/jsonapi-authorization/issues/73 for more details and implementation progress.

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`

**Note:** Currently JA does not fallback to authorizing `CommentPolicy#update?` on `comment_1` that is about to be dissociated. This will likely be changed in the future.

<a name="change-and-replace-has-many-resource-op"></a>

[back to top ↑](#doc-top)

### `PATCH /articles/article-1` with different `comments` relationship

_Changing resource and replacing a `has-many` relationship_

Setup:

```rb
comment_1 = Comment.create(id: 'comment-1')
article_1 = Article.create(id: 'article-1', comments: [comment_1])
comment_2 = Comment.create(id: 'comment-2')
comment_3 = Comment.create(id: 'comment-3')
```

> `PATCH /articles/article-1`
>
> ```json
> {
>   "type": "articles",
>   "id": "article-1",
>   "relationships": {
>     "comments": {
>       "data": [
>         { "type": "comments", "id": "comment-2" },
>         { "type": "comments", "id": "comment-3" }
>       ]
>     }
>   }
> }
> ```

#### Always calls

* `ArticlePolicy.new(current_user, article_1).update?`

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_comments?([comment_2, comment_3])`

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`
* `CommentPolicy.new(current_user, comment_3).update?`

**Note:** Currently JA does not fallback to authorizing `CommentPolicy#update?` on `comment_1` that is about to be dissociated. This will likely be changed in the future.

<a name="change-and-remove-has-many-resource-op"></a>

[back to top ↑](#doc-top)

### `PATCH /articles/article-1` with empty `comments` relationship

_Changing resource and removing a `has-many` relationship_

Setup:

```rb
comment_1 = Comment.create(id: 'comment-1')
article_1 = Article.create(id: 'article-1', comments: [comment_1])
```

> `PATCH /articles/article-1`
>
> ```json
> {
>   "type": "articles",
>   "id": "article-1",
>   "relationships": {
>     "comments": {
>       "data": []
>     }
>   }
> }
> ```

#### Always calls

* `ArticlePolicy.new(current_user, article_1).update?`

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_comments?([])`

**TODO:** We should probably call `remove_comments?` (with no arguments) instead. See https://github.com/venuu/jsonapi-authorization/issues/73 for more details and implementation progress.

#### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`

**Note:** Currently JA does not fallback to authorizing `CommentPolicy#update?` on `comment_1` that is about to be dissociated. This will likely be changed in the future.

<a name="create-has-many-resource-op"></a>

[back to top ↑](#doc-top)

### `POST /articles` with a `comments` relationship

_Creating a resource with a `has-many` relationship_

Setup:

```rb
comment_1 = Comment.create(id: 'comment-1')
comment_2 = Comment.create(id: 'comment-2')
```

> `POST /articles`
>
> ```json
> {
>   "type": "articles",
>   "relationships": {
>     "comments": {
>       "data": [
>         { "type": "comments", "id": "comment-1" },
>         { "type": "comments", "id": "comment-2" }
>       ]
>     }
>   }
> }
> ```

#### Always calls

* `ArticlePolicy.new(current_user, Article).create?`

**Note:** The second parameter for the policy is the `Article` _class_, not the new record. This is because JA runs the authorization checks _before_ any changes are made, even changes to in-memory objects.

#### Custom relationship authorization method

* `ArticlePolicy.new(current_user, Article).create_with_comments?([comment_1, comment_2])`

#### Fallback

* `CommentPolicy.new(current_user, comment_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`

[back to top ↑](#doc-top)
