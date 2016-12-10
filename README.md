# kemal-session-redis

Redis session store for [kemal-session](https://github.com/kemalcr/kemal-session).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  kemal-session-redis:
    github: neovintage/kemal-session-redis
    version: 0.1.0
```

## Usage

```crystal
require "kemal"
require "kemal-session"
require "kemal-session-redis"

Session.config do |config|
  config.cookie_name = "redis_test"
  config.secret = "a_secret"
  config.engine = Session::RedisEngine.new(host: "localhost", port: 1234)
  config.timeout = Time::Span.new(1, 0, 0)
end

get "/" do
  puts "Hello World"
end

post "/sign_in" do |context|
  context.session.int("see-it-works", 1)
end

Kemal.run
```

The engine comes with a number of configuration options:

| Option | Description |
| ------ | ----------- |
| host   | where your redis instance lives |
| port   | assigned port for redis instance |
| unixsocket | Use a socket instead of host/port. This will override host / port settings |
| database | which database to use when after connecting to redis. defaults to 0 |
| capacity | how many connections the connection pool should create. defaults to 20 |
| timeout | how long until a connection is considered long-running. defaults to 2.0 (seconds) |
| pool | an instance of `ConnectionPool(Redis)`. This overrides any setting in host or unixsocket |
| key_prefix | when saving sessions to redis, how should the keys be namespaced. defaults to `kemal:session:` |

When the Redis engine is instantiated and a connection pool isn't passed,
RedisEngine will create a connection pool for you. The pool will have 20 connections
and a timeout of 2 seconds. It's recommended that a connection pool be created
to serve the wider application and then that passed to the RedisEngine initializer.

If no options are passed the `RedisEngine` will try to connect to a Redis using 
default settings.

### Best Practice

It's very easy for client code to leak Redis connections and you should 
pass a pool of connections that's used throughout Kemal and the 
session engine.

## Development

Redis must be running on localhost and bound to the default port to run
specs.

## Contributing

1. Fork it ( https://github.com/neovintage/kemal-session-redis/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[neovintage](https://github.com/neovintage)] Rimas Silkaitis - creator, maintainer
