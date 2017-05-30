# JSONAPI::Authorization

[![Build Status](https://img.shields.io/travis/venuu/jsonapi-authorization/master.svg?style=flat&maxAge=3600)](https://travis-ci.org/venuu/jsonapi-authorization) [![Gem Version](https://img.shields.io/gem/v/jsonapi-authorization.svg?style=flat&maxAge=3600)](https://rubygems.org/gems/jsonapi-authorization)

**NOTE:** This README is the documentation for `JSONAPI::Authorization`. If you are viewing this at the
[project page on Github](https://github.com/venuu/jsonapi-authorization) you are viewing the documentation for the `master`
branch. This may contain information that is not relevant to the release you are using. Please see the README for the
[version](https://github.com/venuu/jsonapi-authorization/releases) you are using.

 ---

`JSONAPI::Authorization` adds authorization to the [jsonapi-resources][jr] (JR) gem using [Pundit][pundit].

  [jr]: https://github.com/cerebris/jsonapi-resources "A resource-focused Rails library for developing JSON API compliant servers."
  [pundit]: https://github.com/elabs/pundit "Minimal authorization through OO design and pure Ruby classes"

## Caveats

Make sure to test for authorization in your application, too. We should have coverage of all operations, though. If that isn't the case, please [open an issue][issues].

If you're using custom processors, make sure that they extend `JSONAPI::Authorization::AuthorizingProcessor`, or authorization will not be performed for that resource.

This gem should work out-of-the box for simple cases. The default authorizer might be overly restrictive for [more complex cases][complex-case].

The API is subject to change between minor version bumps until we reach v1.0.0.

  [complex-case]: https://github.com/venuu/jsonapi-authorization/issues/15

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapi-authorization'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jsonapi-authorization

## Compatibility

* `v0.6.x` supports JR `v0.7.x`
* `v0.8.x` supports JR `v0.8.x`

We aim to support the same Ruby and Ruby on Rails versions as `jsonapi-resources` does. If that's not the case, please [open an issue][issues].

## Usage

First make sure you have a Pundit policy specified for every backing model that your JR resources use.

Hook up this gem as the default processor for JR, and optionally allow rescuing from `Pundit::NotAuthorizedError` to output better errors for unauthorized requests:

```ruby
# config/initializers/jsonapi-resources.rb
JSONAPI.configure do |config|
  config.default_processor_klass = JSONAPI::Authorization::AuthorizingProcessor
  config.exception_class_whitelist = [Pundit::NotAuthorizedError]
end
```

Make all your JR controllers specify the user in the `context` and rescue errors thrown by unauthorized requests:

```ruby
class BaseResourceController < ActionController::Base
  include JSONAPI::ActsAsResourceController
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def context
    {user: current_user}
  end

  def user_not_authorized
    head :forbidden
  end
end
```

Have your JR resources include the `JSONAPI::Authorization::PunditScopedResource` module.

```ruby
class BaseResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource
  abstract
end
```

### Policies

To check whether an action is allowed JSONAPI::Authorization calls the respective actions of your pundit policies
(`index?`, `show?`, `create?`, `update?`, `destroy?`).

For relationship operations by default `update?` is being called for all affected resources.
For a finer grained control you can define `add_to_<relation>?`, `replace_<relation>?`, and `remove_from_<relation>?`
as the following example shows.

```ruby
class ArticlePolicy

  # (...)

  def add_to_comments?(new_comments)
    record.published && new_comments.all? { |comment| comment.author == user }
  end

  def replace_comments?(new_comments)
    allowed = record.comments.all? { |comment| new_comments.include?(comment) || add_to_comments?([comment])}
    allowed && new_comments.all? { |comment| record.comments.include?(comment) || remove_from_comments?(comment) }
  end

  def remove_from_comments?(comment)
    comment.author == user || user.admin?
  end
end
```

Caveat: In case a relationship is modifiable through multiple ways it is your responsibility to ensure consistency.
For example if you have a many-to-many relationship with users and projects make sure that
`ProjectPolicy#add_to_users?(users)` and `UserPolicy#add_to_projects?(projects)` match up.

## Configuration

You can use a custom authorizer class by specifying a configure block in an initializer file. If using a custom authorizer class, be sure to require them at the top of the initializer before usage.

```ruby
JSONAPI::Authorization.configure do |config|
  config.authorizer = MyCustomAuthorizer
end
```

By default JSONAPI::Authorization uses the `:user` key from the JSONAPI context hash as the Pundit user. If you would like to use `:current_user` or some other key, it can be configured as well.

```ruby
JSONAPI::Authorization.configure do |config|
  config.pundit_user = :current_user
  # or a block can be provided
  config.pundit_user = ->(context){ context[:current_user] }
end
```

## Troubleshooting

### "Unable to find policy" exception for a request

The exception might look like this for resource class `ArticleResource` that is backed by `Article` model:

```
unable to find policy `ArticlePolicy` for `Article'
```

This means that you don't have a policy class created for your model. Create one and the error should go away.

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Credits

Originally based on discussion and code samples by [@barelyknown](https://github.com/barelyknown) and others in [cerebris/jsonapi-resources#16](https://github.com/cerebris/jsonapi-resources/issues/16).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/venuu/jsonapi-authorization.

  [issues]: https://github.com/venuu/jsonapi-authorization/issues

## Contributors

Thanks goes to these wonderful people ([emoji key](https://github.com/kentcdodds/all-contributors#emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
| [<img src="https://avatars.githubusercontent.com/u/482561?v=3" width="100px;"/><br /><sub>Vesa Laakso</sub>](http://vesalaakso.com)<br />[💻](https://github.com/Venuu/jsonapi-authorization/commits?author=valscion) [📖](https://github.com/Venuu/jsonapi-authorization/commits?author=valscion) 🚇 [⚠️](https://github.com/Venuu/jsonapi-authorization/commits?author=valscion) [🐛](https://github.com/Venuu/jsonapi-authorization/issues?q=author%3Avalscion) 💬 👀 | [<img src="https://avatars.githubusercontent.com/u/562204?v=3" width="100px;"/><br /><sub>Emil Sågfors</sub>](https://github.com/lime)<br />[💻](https://github.com/Venuu/jsonapi-authorization/commits?author=lime) [📖](https://github.com/Venuu/jsonapi-authorization/commits?author=lime) 🚇 [⚠️](https://github.com/Venuu/jsonapi-authorization/commits?author=lime) [🐛](https://github.com/Venuu/jsonapi-authorization/issues?q=author%3Alime) 💬 👀 | [<img src="https://avatars.githubusercontent.com/u/1591161?v=3" width="100px;"/><br /><sub>Matthias Grundmann</sub>](https://github.com/matthias-g)<br />[💻](https://github.com/Venuu/jsonapi-authorization/commits?author=matthias-g) [📖](https://github.com/Venuu/jsonapi-authorization/commits?author=matthias-g) [⚠️](https://github.com/Venuu/jsonapi-authorization/commits?author=matthias-g) 💬 | [<img src="https://avatars.githubusercontent.com/u/1322?v=3" width="100px;"/><br /><sub>Thibaud Guillaume-Gentil</sub>](http://thibaud.gg)<br />[💻](https://github.com/Venuu/jsonapi-authorization/commits?author=thibaudgg) | [<img src="https://avatars.githubusercontent.com/u/71660?v=3" width="100px;"/><br /><sub>Daniel Schweighöfer</sub>](http://netsteward.net)<br />[💻](https://github.com/Venuu/jsonapi-authorization/commits?author=acid) | [<img src="https://avatars.githubusercontent.com/u/5076967?v=3" width="100px;"/><br /><sub>Bruno Sofiato</sub>](https://github.com/bsofiato)<br />[💻](https://github.com/Venuu/jsonapi-authorization/commits?author=bsofiato) | [<img src="https://avatars.githubusercontent.com/u/1896026?v=3" width="100px;"/><br /><sub>Adam Robertson</sub>](https://github.com/arcreative)<br />[📖](https://github.com/Venuu/jsonapi-authorization/commits?author=arcreative) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| [<img src="https://avatars3.githubusercontent.com/u/4742306?v=3" width="100px;"/><br /><sub>Greg Fisher</sub>](https://github.com/gnfisher)<br />[💻](https://github.com/Venuu/jsonapi-authorization/commits?author=gnfisher) [⚠️](https://github.com/Venuu/jsonapi-authorization/commits?author=gnfisher) | [<img src="https://avatars3.githubusercontent.com/u/370182?v=3" width="100px;"/><br /><sub>Sam</sub>](http://samlh.com)<br />[💻](https://github.com/Venuu/jsonapi-authorization/commits?author=handlers) [⚠️](https://github.com/Venuu/jsonapi-authorization/commits?author=handlers) | [<img src="https://avatars0.githubusercontent.com/u/2738630?v=3" width="100px;"/><br /><sub>Justas Palumickas</sub>](https://jpalumickas.com)<br />[🐛](https://github.com/Venuu/jsonapi-authorization/issues?q=author%3Ajpalumickas) [💻](https://github.com/Venuu/jsonapi-authorization/commits?author=jpalumickas) [⚠️](https://github.com/Venuu/jsonapi-authorization/commits?author=jpalumickas) |
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/kentcdodds/all-contributors) specification. Contributions of any kind welcome!