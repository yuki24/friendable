require 'spec_helper'

# Suppose the following class exists:
#
#   class User < ActiveRecord::Base
#     include Friendable::UserMethods
#   end

describe Friendable::Friendship do
  def redis; Friendable.redis; end
  before(:each) { redis.flushdb }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:target_user) { FactoryGirl.create(:another_user) }

  describe "initialization" do
    context "without options" do
      subject { Friendable::Friendship.new(target_user) }
      its(:created_at) { should be_a(ActiveSupport::TimeWithZone) }
      its(:updated_at) { should be_a(ActiveSupport::TimeWithZone) }
    end

    context "with several options" do
      subject { Friendable::Friendship.new(target_user, :foo => "bar", :hoge => "fuga") }
      its(:foo) { should == "bar" }
      its(:hoge) { should == "fuga" }
    end
  end

  describe "serialization" do
    context "with options" do
      let(:friendship) { Friendable::Friendship.new(target_user, :foo => "bar", :hoge => "fuga") }
      specify do
        MessagePack.unpack(friendship.to_msgpack).should == {
          "foo" => "bar",
          "hoge" => "fuga",
          "created_at" => friendship.created_at.utc.to_i,
          "updated_at" => friendship.updated_at.utc.to_i
        }
      end
    end
  end

  describe "deserialization" do
    let(:current_timestamp) { Time.now.to_i }
    let(:msgpacked_data) { {:created_at => current_timestamp, :updated_at => current_timestamp}.to_msgpack }

    context "with options" do
      subject { Friendable::Friendship.deserialize!(current_user.friend_list_key, target_user, msgpacked_data) }
      it { should be_a(Friendable::Friendship) }
      its(:resource) { should == target_user }
      its(:created_at) { should == Time.zone.at(current_timestamp) }
      its(:updated_at) { should == Time.zone.at(current_timestamp) }
    end
  end

  describe "#save" do
    before { current_user.friend!(target_user) }
    let(:friendship) { current_user.friendship_with(target_user) }

    it "should persist the newly assigned value" do
      friendship.write_attribute(:another_option, "another_value")
      friendship.save

      current_user.friendship_with(target_user).another_option.should == "another_value"
    end

    it "should persist the newly assigned value" do
      created_at = friendship.created_at
      updated_at = friendship.updated_at
      sleep 1
      friendship.save

      friendship = current_user.friendship_with(target_user)
      friendship.created_at.to_i.should == created_at.to_i
      friendship.updated_at.to_i.should_not == updated_at.to_i
    end
  end
end
