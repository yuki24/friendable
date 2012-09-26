require 'msgpack'

module Friendable
  class Friendship
    attr_accessor :target_resource, :source_resource
    alias :friend :target_resource

    def initialize(source_resource, target_resource, attrs = {})
      # options = attrs.delete(:options) if attrs[:options]
      @source_resource = source_resource
      @target_resource = target_resource
      @attributes = attrs.reverse_merge!(:created_at => nil, :updated_at => nil).symbolize_keys
    end

    def write_attribute(attr_name, value)
      @attributes[attr_name.to_sym] = value
    end

    def save
      write_attribute(:created_at, Time.zone.now) unless @attributes[:created_at]
      write_attribute(:updated_at, Time.zone.now)

      Friendable.redis.hset(redis_key, target_resource.id, self.to_msgpack)
    end

    def to_msgpack
      serializable.to_msgpack
    end

    # Get a pretty string representation of the friendship, including the
    # user who is a friend with and attributes for inspection.
    #
    def inspect
      "#<Friendable::Friendship with: #{@target_resource.class}(id: #{@target_resource.id}), " <<
      "attributes: " <<
      @attributes.to_a.map{|ary| ary.join(": ") }.join(", ") << ">"
    end

    def self.deserialize!(source_resource, target_resource, options)
      attrs = MessagePack.unpack(options).symbolize_keys
      attrs[:created_at] = Time.zone.at(attrs[:created_at])
      attrs[:updated_at] = Time.zone.at(attrs[:updated_at])

      Friendship.new(source_resource, target_resource, attrs)
    end

    private

    def method_missing(method, *args, &block)
      if method.to_s.last == "=" && @attributes.has_key?(method.to_s[0..-2].to_sym)
        write_attribute(method.to_s[0..-2], args.first)
      elsif @attributes.has_key?(method)
        return @attributes[method]
      else
        super(method, args, block)
      end
    end

    def redis_key
      source_resource.friend_list_key
    end

    def serializable
      @attributes.clone.tap do |serializable_object|
        serializable_object[:created_at] = serializable_object[:created_at].try(:utc).try(:to_i)
        serializable_object[:updated_at] = serializable_object[:updated_at].try(:utc).try(:to_i)
      end
    end
  end
end
