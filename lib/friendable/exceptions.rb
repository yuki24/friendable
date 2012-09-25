module Friendable
  # A general Friendable exception
  class Error < StandardError; end

  class FriendshipNotFound < Error; end
end
