require 'active_support/concern'
require 'keytar'

module Friendable
  module UserMethods
    extend ActiveSupport::Concern

    included do
      Friendable.resource_class = self
      include Keytar
      define_key :friend_list, :key_case => nil
    end

    def friend_ids
      @_friend_ids ||= (@_raw_friend_hashes ? @_raw_friend_hashes.keys : raw_friend_ids).map(&:to_i)
    end

    def friends
      @_friends ||= User.where(id: friend_ids)
    end

    def friendships
      @_friendships ||= Friendable.resource_class.find(raw_friend_hashes.keys).map do |resource|
        Friendship.deserialize!(friend_list_key, resource, raw_friend_hashes[resource.id.to_s])
      end
    end

    def friendship_with(target_resource)
      raw_friendship = @_raw_friend_hashes.try(:[], target_resource.id.to_s) || redis.hget(friend_list_key, target_resource.id)

      if raw_friendship
        Friendship.deserialize!(friend_list_key, target_resource, raw_friendship)
      else
        raise Friendable::FriendshipNotFound, "user:#{self.id} is not a friend of the user:#{target_resource.id}"
      end
    end

    def friends_count
      @_raw_friend_ids.try(:count) || @_raw_friend_hashes.try(:count) || redis.hlen(friend_list_key)
    end

    def has_friends?(resource)
       @_raw_friend_ids.try(:include?, resource.id.to_s) || @_raw_friend_hashes.try(:has_key?, resource.id.to_s) || redis.hexists(friend_list_key, resource.id)
    end

    def friend!(resource, options = {})
      Friendship.new(resource, options).tap do |friendship|
        redis.multi do
          redis.hsetnx(friend_list_key, friendship.resource.id, friendship.to_msgpack)
          redis.hsetnx(resource.friend_list_key, self.id, friendship.without_options.to_msgpack)
        end
      end
    end

    def unfriend!(resource)
      redis.multi do
        redis.hdel(friend_list_key, resource.id)
        redis.hdel(resource.friend_list_key, self.id)
      end
    end

    private

    def raw_friend_hashes
      @_raw_friend_hashes ||= redis.hgetall(friend_list_key)
    end

    def raw_friend_ids
      @_raw_friend_ids ||= redis.hkeys(friend_list_key)
    end

    def redis
      @_redis ||= Friendable.redis
    end
  end
end
