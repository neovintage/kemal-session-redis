require "uri"
require "json"
require "redis"
require "pool/connection"
require "kemal-session"

class Session
  class RedisEngine < Engine
    class StorageInstance
      macro define_storage(vars)
        JSON.mapping({
          {% for name, type in vars %}
               {{name.id}}s: Hash(String, {{type}}),
          {% end %}
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

      define_storage({int: Int32, string: String, float: Float64, bool: Bool})
    end

    @redis : ConnectionPool(Redis)
    @cache : StorageInstance
    @cached_session_id : String

    def initialize(options : Hash(Symbol, String))
      @redis = uninitialized ConnectionPool(Redis)

      if options.has_key?(:uri)
        uri = URI.parse(options[:uri])
        options[:host] = uri.host
        options[:post] = uri.port
      end
      block = { Redis.new(options) }

      @redis = ConnectionPool.new({capacity: 1, timeout: 5.0}, &block) unless options.has_key?(:connection_pool)
      @cache = StorageInstance.new
      @key_prefix = options.has_key?(:key_prefix) ? options[:key_prefix] : "kemal:session:"
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
      conn = @redis.checkout
      conn.set(
        prefix_session(@cached_session_id)
        @cache.to_json,
        ex: Session.config.timeout.total_seconds.to_i
      )
      @redis.checkin(conn)
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

    define_delegators({int: Int32, string: String, float: Float64, bool: Bool})
  end
end
