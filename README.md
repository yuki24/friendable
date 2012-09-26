# Friendable

You don't want to implement friendship functionality with RDB any more? But you think it's still too early to use graphDB? Use Redis!

[![Build Status](https://secure.travis-ci.org/yuki24/friendable.png)](http://travis-ci.org/yuki24/friendable) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/yuki24/friendable)

## Installation

Add this line to your application's Gemfile:

    gem 'friendable'

And then execute:

    $ bundle

Next, include `Friendable::UserMethods` inside User class or something like that you use in your application:

```ruby
class User < ActiveRecord::Base
  include Friendable::UserMethods

  ...
end
```

Create a config file like below to set up Redis connection and save it as `config/initializers/friendable.rb`:

```ruby
Friendable.redis = Redis.new(host: "localhost", port: 6379)
```

## Usage

### Being a friend

```ruby
user         = User.first
another_user = User.last

user.friends                # => empty ActiveRecord::Relation
user.friend?(another_user)  # => false

 # they are now friends!
current_user.friend!(another_user)

user.friend?(another_user)           # => true
user.friends.include?(another_user)  # => true
another_user.friend?(user)           # => true
another_user.friends.include?(user)  # => true
```

You can also pass properties about their relationship. For example, if you want to store where they meet, you can do something like this:

```ruby
friendship = user.friend!(another_user, :meeting_place => "Red Rock")

friendship.meeting_place  # => "Red Rock"
friendship.created_at     # => "2012-09-23 14:24:03"
friendship.updated_at     # => "2012-09-23 14:24:03"
```

If you want to find the specific friendship with somebody and edit/save the friendship, you can do it by using `#write_attribute` and `#save`:

```ruby
friendship = user.friendship_with(another_user)
friendship.write_attribute(:close_friend, true)
friendship.save

friendship.close_friend   # => true
friendship.meeting_place  # => "Red Rock"
friendship.created_at     # => "2012-09-23 14:24:03"
friendship.updated_at     # => "2012-09-23 14:25:21"
```

**Note:** properties are not saved on the opposite direction of the friendship.

```ruby
user.friend!(another_user, :meeting_place => "Red Rock")

friendship = user.friendship_with(another_user)
friendship.meeting_place  # => "Red Rock"

friendship = another_user.friendship_with(user)  # opposite
friendship.meeting_place  # => NoMethodError
```

### Removing a friend

You can remove a user from the friend list of a user like this:

```ruby
user.unfriend!(another_user)

user.friend?(another_user)                 # => false
user.friends.include?(another_user)        # => false
user.friend_ids.include?(another_user.id)  # => false
```

For more details, have a look at the documentation.

## Support

 * Ruby version: 1.9.3, 1.9.2, 1.8.7 and REE
 * ORM: ActiveRecord

You also(and of course) need to install Redis.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright
Copyright (c) 2012 Yuki Nishijima. See LICENSE.md for further details.
