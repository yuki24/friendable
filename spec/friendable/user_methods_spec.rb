require 'spec_helper'

# Suppose the following class exists:
#
#   class User < ActiveRecord::Base
#     include Friendable::UserMethods
#   end

describe Friendable::UserMethods do
  def redis; Friendable.redis; end
  before(:each) { redis.flushdb }
  let(:current_user) { User.first }
  let(:target_user) { User.last }

  subject { current_user }
  its(:friend_list_key) { should == "Users:friend_list:1" }

  describe "#friend!" do
    context "to add a friend" do
      before { current_user.friend!(target_user) }
      subject { current_user }
      specify { redis.hkeys(current_user.friend_list_key).should include(target_user.id.to_s) }
      specify { redis.hkeys(target_user.friend_list_key).should include(current_user.id.to_s) }
    end

    context "to add a friend without options" do
      subject { current_user.friend!(target_user) }
      it { should be_a(Friendable::Friendship) }
      its(:friend){ should == target_user }
    end

    context "to add a friend with several options" do
      subject { current_user.friend!(target_user, :foo => "bar", :hoge => "fuga") }
      it { should be_a(Friendable::Friendship) }
      its(:friend){ should == target_user }
      its(:foo){ should == "bar" }
      its(:hoge){ should == "fuga" }
    end
  end

  describe "#unfriend!" do
    context "to remove a friendship" do
      before do
        current_user.friend!(target_user)
        current_user.unfriend!(target_user)
      end

      subject { current_user }
      specify { redis.hexists(current_user.friend_list_key, target_user.id.to_s).should be_false }
      specify { redis.hexists(target_user.friend_list_key, current_user.id.to_s).should be_false }
    end
  end

  describe "#friends" do
    context "without friends" do
      specify { current_user.friends.count.should == 0 }
    end

    context "with one friend" do
      before { current_user.friend!(target_user) }
      subject { current_user.friends }
      it { should include(target_user) }
    end
  end

  describe "#friendships" do
    context "without friends" do
      specify { current_user.friendships.count.should == 0 }
    end

    context "with one friend" do
      before { current_user.friend!(target_user) }
      subject { current_user.friendships.first }
      it { should be_a(Friendable::Friendship) }
      its(:resource) { should == target_user }
      its(:created_at) { should be_a(ActiveSupport::TimeWithZone) }
      its(:updated_at) { should be_a(ActiveSupport::TimeWithZone) }
    end

    context "with one friend and several options" do
      before { current_user.friend!(target_user, :foo => "bar", :hoge => "fuga") }
      subject { current_user.friendships.first }
      it { should be_a(Friendable::Friendship) }
      its(:foo) { should == "bar" }
      its(:hoge) { should == "fuga" }
    end
  end

  describe "#friendship_with" do
    context "without friends" do
      specify do
        expect {
          current_user.friendship_with(target_user)
        }.to raise_exception(Friendable::FriendshipNotFound)
      end
    end

    context "with one friend" do
      before { current_user.friend!(target_user, :foo => "bar", :hoge => "fuga") }
      subject { current_user.friendship_with(target_user) }
      it { should be_a(Friendable::Friendship) }
      its(:foo) { should == "bar" }
      its(:hoge) { should == "fuga" }
    end
  end

  describe "#friend_ids" do
    context "without friends" do
      specify { current_user.friend_ids.count.should == 0 }
    end

    context "with one friend" do
      before { current_user.friend!(target_user) }
      subject { current_user.friend_ids }
      it { should be_an(Array) }
      it { should include(target_user.id) }
      its(:count) { should == 1 }
    end

    context "without friends after unfriend" do
      before do
        current_user.friend!(target_user)
        current_user.unfriend!(target_user)
      end

      subject { current_user.friend_ids }
      it { should be_an(Array) }
      its(:count) { should == 0 }
    end
  end

  describe "#friends_count" do
    context "without friends" do
      specify { current_user.friends_count.should == 0 }
    end

    context "with one friend" do
      before { current_user.friend!(target_user) }
      subject { current_user }
      its(:friends_count) { should == 1 }
    end

    context "without friends after unfriend" do
      before do
        current_user.friend!(target_user)
        current_user.unfriend!(target_user)
      end

      subject { current_user }
      its(:friends_count) { should == 0 }
    end
  end
end
