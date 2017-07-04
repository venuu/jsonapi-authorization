# <a name="doc-top"></a>Authorization of operations touching relationships

`JSONAPI::Authorization` (JA) is unique in the way it considers relationship changes to change the underlying models. Whenever an incoming request changes associated resources, JA will authorize those operations are OK.

As JA runs the authorization checks _before_ any changes are made (even to in-memory objects), Pundit policies don't have the information needed to authorize changes to relationships. This is why JA provides special hooks to authorize relationship changes and falls back to checking `#update?` on all the related records.

**Table of contents**

* [Example setup](#example-setup)
* `has-one` relationships
  - [Changing a `has-one` relationship](#change-has-one-relationship-op)
  - [Removing a `has-one` relationship](#remove-has-one-relationship-op)
  - [Changing resource and replacing a `has-one` relationship](#change-and-replace-has-one-resource-op)
  - [Changing resource and removing a `has-one` relationship](#change-and-remove-has-one-resource-op)
  - [Creating a resource with a `has-one` relationship](#create-has-one-resource-op)
* `has-many` relationships
  - [Adding to a `has-many` relationship](#add-to-has-many-relationship-op)
  - [Removing from a `has-many` relationship](#remove-from-has-many-relationship-op)
  - [Replacing a `has-many` relationship](#replace-has-many-relationship-op)
  - [Removing a `has-many` relationship](#remove-has-many-relationship-op)
  - [Changing resource and replacing a `has-many` relationship](#change-and-replace-has-many-resource-op)
  - [Changing resource and removing a `has-many` relationship](#change-and-remove-has-many-resource-op)
  - [Creating a resource with a `has-many` relationship](#create-has-many-resource-op)

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

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be dissociated. This will likely be changed in the future.

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

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be dissociated. This will likely be changed in the future.

<a name="change-and-replace-has-one-resource-op"></a>

[back to top ↑](#doc-top)

## Changing resource and replacing a `has-one` relationship

Setup:

```rb
user_1 = User.create(id: 'user-1')
article_1 = Article.create(id: 'article-1', user: user_1)
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

### Always calls

* `ArticlePolicy.new(current_user, article_1).update?`

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_author?(user_2)`

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `UserPolicy.new(current_user, user_2).update?`

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be dissociated. This will likely be changed in the future.

<a name="change-and-remove-has-one-resource-op"></a>

[back to top ↑](#doc-top)

## Changing resource and removing a `has-one` relationship

Setup:

```rb
user_1 = User.create(id: 'user-1')
article_1 = Article.create(id: 'article-1', user: user_1)
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

### Always calls

* `ArticlePolicy.new(current_user, article_1).update?`

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).remove_author?`

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`

**Note:** Currently JA does not fallback to authorizing `UserPolicy#update?` on `user_1` that is about to be dissociated. This will likely be changed in the future.

<a name="create-has-one-resource-op"></a>

[back to top ↑](#doc-top)

## Creating a resource with a `has-one` relationship

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

### Always calls

* `ArticlePolicy.new(current_user, Article).create?`

**Note:** The second parameter for the policy is the `Article` _class_, not the new record. This is because JA runs the authorization checks _before_ any changes are made, even changes to in-memory objects.

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, Article).create_with_author?(user_1)`

### Fallback

* `UserPolicy.new(current_user, user_1).update?`

<a name="add-to-has-many-relationship-op"></a>

[back to top ↑](#doc-top)

## Adding to a `has-many` relationship

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

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).add_to_comments?([comment_2, comment_3])`

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`
* `CommentPolicy.new(current_user, comment_3).update?`

<a name="remove-from-has-many-relationship-op"></a>

[back to top ↑](#doc-top)

## Removing from a `has-many` relationship

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

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).remove_from_comments?([comment_1, comment_2])`

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `CommentPolicy.new(current_user, comment_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`

<a name="replace-has-many-relationship-op"></a>

[back to top ↑](#doc-top)

## Replacing a `has-many` relationship

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

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_comments?([comment_2, comment_3])`

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`
* `CommentPolicy.new(current_user, comment_3).update?`

**Note:** Currently JA does not fallback to authorizing `CommentPolicy#update?` on `comment_1` that is about to be dissociated. This will likely be changed in the future.

<a name="remove-has-many-relationship-op"></a>

[back to top ↑](#doc-top)

## Removing a `has-many` relationship

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

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_comments?([])`

**TODO:** We should probably call `remove_comments?` (with no arguments) instead. See https://github.com/venuu/jsonapi-authorization/issues/73 for more details and implementation progress.

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`

**Note:** Currently JA does not fallback to authorizing `CommentPolicy#update?` on `comment_1` that is about to be dissociated. This will likely be changed in the future.

<a name="change-and-replace-has-many-resource-op"></a>

[back to top ↑](#doc-top)

## Changing resource and replacing a `has-many` relationship

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

### Always calls

* `ArticlePolicy.new(current_user, article_1).update?`

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_comments?([comment_2, comment_3])`

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`
* `CommentPolicy.new(current_user, comment_3).update?`

**Note:** Currently JA does not fallback to authorizing `CommentPolicy#update?` on `comment_1` that is about to be dissociated. This will likely be changed in the future.

<a name="change-and-remove-has-many-resource-op"></a>

[back to top ↑](#doc-top)

## Changing resource and removing a `has-many` relationship

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

### Always calls

* `ArticlePolicy.new(current_user, article_1).update?`

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, article_1).replace_comments?([])`

**TODO:** We should probably call `remove_comments?` (with no arguments) instead. See https://github.com/venuu/jsonapi-authorization/issues/73 for more details and implementation progress.

### Fallback

* `ArticlePolicy.new(current_user, article_1).update?`

**Note:** Currently JA does not fallback to authorizing `CommentPolicy#update?` on `comment_1` that is about to be dissociated. This will likely be changed in the future.

<a name="create-has-many-resource-op"></a>

[back to top ↑](#doc-top)

## Creating a resource with a `has-many` relationship

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

### Always calls

* `ArticlePolicy.new(current_user, Article).create?`

**Note:** The second parameter for the policy is the `Article` _class_, not the new record. This is because JA runs the authorization checks _before_ any changes are made, even changes to in-memory objects.

### Custom relationship authorization method

* `ArticlePolicy.new(current_user, Article).create_with_comments?([comment_1, comment_2])`

### Fallback

* `CommentPolicy.new(current_user, comment_1).update?`
* `CommentPolicy.new(current_user, comment_2).update?`
