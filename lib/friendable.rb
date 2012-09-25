require "friendable/version"
require "friendable/user_methods"
require "friendable/friendship"
require "friendable/exceptions"
require "redis-namespace"

module Friendable
  extend self
  attr_accessor :resource_class

  def redis
    @redis ||= Redis::Namespace.new(:friendable, :redis => Redis.new)
  end

  # Accepts:
  #   1. A 'hostname:port' String
  #   2. A 'hostname:port:db' String (to select the Redis db)
  #   3. A 'hostname:port/namespace' String (to set the Redis namespace)
  #   4. A Redis URL String 'redis://host:port'
  #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
  #      or `Redis::Namespace`.
  def redis=(server)
    case server
    when String
      if server =~ /redis\:\/\//
        redis = Redis.connect(:url => server, :thread_safe => true)
      else
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
        redis = Redis.new(:host => host, :port => port, :thread_safe => true, :db => db)
      end
      namespace ||= :friendable

      @redis = Redis::Namespace.new(namespace, :redis => redis)
    when Redis::Namespace
      @redis = server
    else
      @redis = Redis::Namespace.new(:friendable, :redis => server)
    end
  end
end
