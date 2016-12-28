require "spec"
require "io"
require "../src/kemal-session-redis"

Session.config.secret = "super-awesome-secret"
Session.config.engine = Session::RedisEngine.new

REDIS      = Redis.new
SESSION_ID = SecureRandom.hex

Spec.before_each do
  REDIS.flushall
end

def create_context(session_id : String)
  response = HTTP::Server::Response.new(IO::Memory.new)
  headers = HTTP::Headers.new

  # I would rather pass nil if no cookie should be created
  # but that throws an error
  unless session_id == ""
    Session.config.engine.create_session(session_id)
    cookies = HTTP::Cookies.new
    cookies << HTTP::Cookie.new(Session.config.cookie_name, Session.encode(session_id))
    cookies.add_request_headers(headers)
  end

  request = HTTP::Request.new("GET", "/", headers)
  return HTTP::Server::Context.new(request, response)
end

class UserJsonSerializer < Session::StorableObject
  JSON.mapping({
    id: Int32,
    name: String
  })

  def initialize(@id : Int32, @name : String); end

  def serialize
    self.to_json
  end

  def self.unserialize(value : String)
    UserJsonSerializer.from_json(value)
  end
end

class UserCommaSerializer < Session::StorableObject
  property id, name

  def initialize(@id : Int32, @name : String); end

  def serialize
    return "#{@id},#{@name}"
  end

  def self.unserialize(value : String)
    parts = value.split(",")
    return self.new(parts[0], parts[1])
  end
end
