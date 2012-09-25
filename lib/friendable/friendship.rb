module Friendable
  class Friendship
    attr_accessor :resource
    alias :friend :resource

    def initialize(target_resource, attrs = {}, options = {})
      @resource = target_resource
      (@redis_key = options[:redis_key]).freeze if options[:redis_key]
      attrs[:created_at] ||= (time = Time.zone.now)
      attrs[:updated_at] ||= (time ||= Time.zone.now)
      @attributes = attrs.symbolize_keys
    end

    def write_attribute(attr_name, value)
      @attributes[attr_name.to_sym] = value
    end

    def save
      write_attribute(:updated_at, Time.zone.now)
      Friendable.redis.hset(redis_key, resource.id, self.to_msgpack)
    end

    def without_options
      Friendship.new(@resource, @attributes.slice(:created_at, :updated_at))
    end

    def to_msgpack
      serializable.to_msgpack
    end

    # Get a pretty string representation of the friendship, including the
    # user who is a friend with and attributes for inspection.
    #
    # @example Inspect the friendship.
    #   friendship.inspect
    #
    # @return [ String ] The inspection string.
    def inspect
      "#<Friendable::Friendship with: #<#{@resource.class} id: #{@resource.id}>, " <<
      "attributes: " <<
      @attributes.to_a.map{|ary| ary.join(": ") }.join(", ") << ">"
    end

    def self.deserialize!(redis_key, resource, options)
      attrs = MessagePack.unpack(options).symbolize_keys
      attrs[:created_at] = Time.zone.at(attrs[:created_at])
      attrs[:updated_at] = Time.zone.at(attrs[:updated_at])

      Friendship.new(resource, attrs, :redis_key => redis_key)
    end

    private

    def method_missing(method, *args, &block)
      if method.to_s.last == "=" && @attributes.has_key?(method.to_s[0..-2].to_sym)
        raise ArgumentError, "wrong number of arguments (#{args.size} for 1)" if args.size != 1
        write_attribute(method.to_s[0..-2], args.first)
      elsif @attributes.has_key?(method)
        return @attributes[method]
      else
        super(method, args, block)
      end
    end

    def redis_key
      @redis_key ? @redis_key : raise(::ArgumentError, "No redis key found")
    end

    def serializable
      @attributes.clone.tap do |serializable_object|
        serializable_object[:created_at] = serializable_object[:created_at].utc.to_i
        serializable_object[:updated_at] = serializable_object[:updated_at].utc.to_i
      end
    end
  end
end
