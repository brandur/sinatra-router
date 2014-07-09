sinatra-router
==============

A tiny vendorable router that makes it easy to try routes from a number of different modular Sinatra applications.

The motivation behind the project is to provide an easy way of composing a larger application that's been split out into a number of discrete Sinatra apps for purposes of code modularity and isolation.

In your `Gemfile`:

``` ruby
gem 'sinatra-router'
```

Now as part of a builder or rackup (i.e. `config.ru`):

``` ruby
module API
  class Apps < Sinatra::Base
    get "/apps" do
      200
    end
  end

  class Users < Sinatra::Base
    get "/users" do
      200
    end
  end
end

# config.ru
run Sinatra::Router do
  mount API::Apps     # /apps
  mount API::Users    # /users
end
```

Or mount it as middleware:

``` ruby
use Sinatra::Router do
  mount API::Apps
  mount API::Users
end
run Sinatra::Application
```

### Why not just mount Sinatra apps as middleware?

An alternative is to just mount Sinatra apps as middleware, which is supported by Sinatra out of the box:

``` ruby
run Rack::Builder.new {
  use API::Apps
  use API::Users
}
```

This does get you most of the way there, but may have undesireable side effects. For example, a request always gets passed through each middleware, whether that middleware can handle the route or not. So `before` filters in all your apps will be run until one app in the stack successfully handles the request. This can make it somewhat more difficult to modularize your app.

## Conditional Routing

Add routing conditions with arguments or blocks:

``` ruby
run Sinatra::Router do
  with_conditions(lambda { |e| e["HTTP_X_VERSION"] == "2" }) do
    mount API::V2::Apps
    mount API::V2::Users
  end

  mount API::V1::Users, lambda { |e| e["HTTP_X_VERSION"] == "1" }
end
```

Or extend the router class to create your own concise DSL:

``` ruby
module API
  class Router < Sinatra::Router
    version(version, &block)
      condition = lambda { |e| version == e["HTTP_X_VERSION"] }
      if block
        with_conditions(condition, &block)
      else
        condition
      end
    end
  end
end

# config.ru
run API::Router do
  version 2 do
    mount API::V2::Apps
    mount API::V2::Users
  end

  mount API::V1::Users, version(1)
end
```

## Passing and X-Cascade

Sinatra and sinatra-router support Rack's `X-Cascade` standard so that modules are able to transparently pass from one to the other as if they were part of the same application:

``` ruby
module API
  module V1
    class Apps < Sinatra::Base
      get "/apps" do
        # drops through to AppsV2 GET / unless request is version 1
        pass unless version == 1
        200
      end
    end
  end

  module V2
    class Apps < Sinatra::Base
      get "/apps" do
        200
      end
    end
  end
end

# config.ru
run Sinatra::Router do
  mount API::V1::Apps
  mount API::V2::Apps
end
```

## Development

Run the tests:

``` bash
ruby test/sinatra/router_test.rb
```
