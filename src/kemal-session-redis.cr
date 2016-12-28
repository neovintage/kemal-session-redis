require "uri"
require "json"
require "redis"
require "pool/connection"
require "kemal-session"

class Session
  class RedisEngine < Engine
    module StorableObjectConverter
      def self.from_json(pull : JSON::PullParser) : Hash(String, StorableObject)
        hash = Hash(String, StorableObject).new
        pull.read_object do |key|
          if pull.kind == :null
            pull.read_next
          else
            hash[key] = StorableObject.unserialize(pull)
          end
        end
        hash
      end

      def self.to_json(value : Hash(String, StorableObject), io : IO)
        if value.empty?
          io << "{}"
          return
        end

        io.json_object do |json_obj|
          value.each do |object_name, storable_obj|
            json_obj.field object_name, storable_obj.serialize
          end
        end
      end
    end

    class StorageInstance
      macro define_storage(vars)
        JSON.mapping({
          {% for name, type in vars %}
            {% if name != "object" %}
              {{name.id}}s: Hash(String, {{type}}),
            {% end %}
          {% end %}
          objects: {type: Hash(String, StorableObject), converter: StorableObjectConverter},
        })

        {% for name, type in vars %}
          @{{name.id}}s = Hash(String, {{type}}).new
          getter {{name.id}}s

          def {{name.id}}(k : String) : {{type}}
            return @{{name.id}}s[k]
          end

          def {{name.id}}?(k : String) : {{type}}?
            return @{{name.id}}s[k]?
          end

          def {{name.id}}(k : String, v : {{type}})
            @{{name.id}}s[k] = v
          end
        {% end %}

        def initialize
          {% for name, type in vars %}
            @{{name.id}}s = Hash(String, {{type}}).new
          {% end %}
        end
      end

      define_storage({int: Int32, string: String, float: Float64, bool: Bool, object: StorableObject})
    end

    @pool  : ConnectionPool(Redis)
    @cache : StorageInstance
    @cached_session_id : String

    def initialize(host = "localhost", port = 6379, unixsocket = nil, database = nil, password = nil, url = nil, pool = nil, timeout = 2.0, capacity = 20, key_prefix = "kemal:session:")
      @pool = uninitialized ConnectionPool(Redis)
      if !pool.nil?
        @pool = pool.as(ConnectionPool(Redis))
      else
        # Creates a pool of one because the storage engine gets instantiated
        # every time a sessions gets created. It's recommended a connection
        # pool be passed because connections can be managed more globally
        #
        @pool = ConnectionPool.new(capacity: capacity, timeout: timeout) do
          Redis.new(
            host: host,
            port: port,
            unixsocket: unixsocket,
            database: database,
            password: password
          )
        end
      end
      @cache             = StorageInstance.new
      @key_prefix        = key_prefix
      @cached_session_id = ""
    end

    def run_gc
      # Do Nothing. All the sessions should be set with the
      # expiration option on the keys. So long as the redis instance
      # hasn't been set up with maxmemory policy of noeviction
    end

    def prefix_session(session_id : String)
      "#{@key_prefix}#{session_id}"
    end

    def load_into_cache(session_id)
      @cached_session_id = session_id
      conn = @redis.checkout
      value = conn.get(prefix_session(session_id))
      if !value.nil?
        @cache = StorageInstance.from_json(value)
      else
        @cache = StorageInstance.new
        conn.set(prefix_session(session_id), @cache.to_json, ex: Session.config.timeout.total_seconds.to_i)
      end
      @redis.checkin(conn)
      return @cache
    end

    def save_cache
      conn = @pool.checkout
      conn.set(
        prefix_session(@cached_session_id),
        @cache.to_json,
        ex: Session.config.timeout.total_seconds.to_i
      )
      @pool.checkin(conn)
    end

    def is_in_cache?(session_id)
      return session_id == @cached_session_id
    end

    macro define_delegators(vars)
      {% for name, type in vars %}
        def {{name.id}}(session_id : String, k : String) : {{type}}
          load_into_cache(session_id) unless is_in_cache?(session_id)
          return @cache.{{name.id}}(k)
        end

        def {{name.id}}?(session_id : String, k : String) : {{type}}?
          load_into_cache(session_id) unless is_in_cache?(session_id)
          return @cache.{{name.id}}?(k)
        end

        def {{name.id}}(session_id : String, k : String, v : {{type}})
          load_into_cache(session_id) unless is_in_cache?(session_id)
          @cache.{{name.id}}(k, v)
          save_cache
        end

        def {{name.id}}s(session_id : String) : Hash(String, {{type}})
          load_into_cache(session_id) unless is_in_cache?(session_id)
          return @cache.{{name.id}}s
        end
      {% end %}
    end

    define_delegators({int: Int32, string: String, float: Float64, bool: Bool, object: StorableObject})
  end
end
