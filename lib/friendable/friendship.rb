module Friendable
  class Friendship < Hashie::Mash
    attr_accessor :resource
    alias :friend :resource

    def initialize(target_resource, attrs = {}, options = {})
      @resource = target_resource
      (@redis_key = options[:redis_key]).freeze if options[:redis_key]
      attrs["created_at"] ||= (time = Time.zone.now)
      attrs["updated_at"] ||= (time ||= Time.zone.now)

      super(attrs)
    end

    def sync?
      self.sync.nil? || self.sync == "true" || self.sync == true
    end

    def to_msgpack
      serializable.to_msgpack
    end

    def without_options
      Friendship.new(@resource, :created_at => created_at, :updated_at => updated_at)
    end

    def save
      self.updated_at = Time.zone.now
      Friendable.redis.hset(redis_key, resource.id, self.to_msgpack)
    end

    def self.deserialize!(redis_key, resource, options)
      attrs = MessagePack.unpack(options)
      attrs["created_at"] = Time.zone.at(attrs["created_at"])
      attrs["updated_at"] = Time.zone.at(attrs["updated_at"])

      Friendship.new(resource, attrs, :redis_key => redis_key)
    end

    private

    def redis_key
      @redis_key ? @redis_key : raise(::ArgumentError, "No redis key found")
    end

    def serializable
      clone.tap do |serializable_object|
        serializable_object.created_at = serializable_object.created_at.utc.to_i
        serializable_object.updated_at = serializable_object.updated_at.utc.to_i
      end.to_hash
    end
  end
end
