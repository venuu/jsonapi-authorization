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

This gem should work out-of-the box for simple cases. The default authorizer might be overly restrictive for [more complex cases][complex-case].

The API is subject to change between minor version bumps until we reach v1.0.0.

  [issues]: https://github.com/venuu/jsonapi-authorization/issues
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

## Configuration

You can use a custom authorizer class by specifying a configure block in an initializer file. If using a custom authorizer class, be sure to require them at the top of the initializer before usage.

```ruby
JSONAPI::Authorization.configure do |config|
  config.authorizer = MyCustomAuthorizer
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
