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

    # Returns an array object of the friend ids of your friends.
    #
    # ==== Examples
    #   current_user.friend!(target_user)
    #
    #   current_user.friend_ids.include?(target_user.id) # => true
    #
    def friend_ids
      @_friend_ids ||= (@_raw_friend_hashes ? @_raw_friend_hashes.keys : raw_friend_ids).map(&:to_i)
    end

    # Returns an collection of user ressources(ActiveRecord::Relation).
    #
    # ==== Examples
    #   current_user.friends       # => [#<User id: 1, ...>, #<User id: 2, ...>, ...]
    #   current_user.friends.first # => #<User id: 1, ...>
    #   current_user.friends.class # => ActiveRecord::Relation
    #
    def friends
      @_friends ||= Friendable.resource_class.where(:id => friend_ids)
    end

    # Returns an array of friendship objects. Currently this method does not support
    # pagination.
    #
    # ==== Examples
    #   current_user.friendships       # => [#<Friendable::Friendship>, ...]
    #   current_user.friendships.first # => #<Friendable::Friendship>
    #   current_user.friendships.class # => Array
    #
    def friendships
      @_friendships ||= Friendable.resource_class.find(raw_friend_hashes.keys).map do |resource|
        Friendship.deserialize!(self, resource, raw_friend_hashes[resource.id.to_s])
      end
    end

    # Returns a friendship object that indicates the relation from a user to another user.
    #
    # ==== Examples
    #   current_user.friend!(target_user, :foo => "bar")
    #
    #   friendship = current_user.friendship_with(target_user)
    #   friendship.friend == target_user # => true
    #   friendship.foo                   # => "bar"
    #   friendship.bar                   # => NoMethodError
    #
    def friendship_with(target_resource)
      raw_friendship = @_raw_friend_hashes.try(:[], target_resource.id.to_s) || redis.hget(friend_list_key, target_resource.id)

      if raw_friendship
        Friendship.deserialize!(self, target_resource, raw_friendship)
      else
        raise Friendable::FriendshipNotFound, "user:#{self.id} is not a friend of the user:#{target_resource.id}"
      end
    end

    # Returns the number of the user's friends.
    #
    # ==== Examples
    #   current_user.friends_count        # => 0
    #
    #   current_user.friend!(target_user)
    #   current_user.friends_count        # => 1
    #
    def friends_count
      @_raw_friend_ids.try(:count) || @_raw_friend_hashes.try(:count) || redis.hlen(friend_list_key)
    end

    # Returns if the given user is friend of you or not.
    #
    # ==== Examlpes
    #   current_user.friend?(target_user) # => false
    #
    #   current_user.friend!(target_user)
    #
    #   current_user.friend?(target_user) # => true
    #
    def friend?(resource)
       @_raw_friend_ids.try(:include?, resource.id.to_s) || @_raw_friend_hashes.try(:has_key?, resource.id.to_s) || redis.hexists(friend_list_key, resource.id)
    end

    # Adds the given user to your friend list. If the given user is already
    # a friend of you and different options are given, the existing options
    # will be replaced with the new options. It returns an object of
    # Friendable::Friendship.
    #
    # ==== Examples
    #   current_user.friends.include?(target_user) # => false
    #   current_user.friend!(target_user)          # => #<Friendable::Friendship>
    #   current_user.friends.include?(target_user) # => true
    #
    #   friendship = current_user.friend!(target_user, :foo => "bar")
    #   friendship.foo # => "bar"
    #   friendship.bar # => NoMethodError
    #
    def friend!(resource, options = {})
      # TODO: in the near future, I want to change to something like this:
      #   redis.multi do
      #     Friendship.new(self, resource, options).save(inverse: true)
      #   end
      Friendship.new(self, resource, options).tap do |friendship|
        redis.multi do
          friendship.save
          Friendship.new(resource, self).save
        end
      end
    end

    # Removes the given user from your friend list. If the given user is not
    # a friend of you, it doesn't affect anything.
    #
    # ==== Examples
    #   current_user.friend!(target_user)
    #   current_user.friends.include?(target_user) # => true
    #
    #   current_user.unfriend!(target_user)
    #   current_user.friends.include?(target_user) # => false
    #
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
