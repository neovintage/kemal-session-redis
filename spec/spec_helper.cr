require "spec"
require "io"
require "../src/kemal-session-redis"

Kemal::Session.config.secret = "super-awesome-secret"
Kemal::Session.config.engine = Kemal::Session::RedisEngine.new

REDIS      = Redis.new
SESSION_ID = Random::Secure.hex

Spec.before_each do
  REDIS.flushall
end

def create_context(session_id : String)
  response = HTTP::Server::Response.new(IO::Memory.new)
  headers = HTTP::Headers.new

  # I would rather pass nil if no cookie should be created
  # but that throws an error
  unless session_id == ""
    Kemal::Session.config.engine.create_session(session_id)
    cookies = HTTP::Cookies.new
    cookies << HTTP::Cookie.new(Kemal::Session.config.cookie_name, Kemal::Session.encode(session_id))
    cookies.add_request_headers(headers)
  end

  request = HTTP::Request.new("GET", "/", headers)
  return HTTP::Server::Context.new(request, response)
end

class UserJsonSerializer
  include JSON::Serializable
  include Kemal::Session::StorableObject

  property id : Int32
  property name : String

  def initialize(@id : Int32, @name : String); end
end
