require 'spec_helper'

# Suppose the following class exists:
#
#   class User < ActiveRecord::Base
#     include Friendable::UserMethods
#   end

describe Friendable::Friendship do
  def redis; Friendable.redis; end
  before(:each) { redis.flushdb }
  let(:current_user) { User.first }
  let(:target_user) { User.last }

  describe "initialization" do
    context "without options" do
      subject { Friendable::Friendship.new(current_user, target_user) }
      its(:created_at) { should be_nil }
      its(:updated_at) { should be_nil }
    end
  end

  describe "dynamic accessors" do
    let(:friendship) { Friendable::Friendship.new(current_user, target_user, :foo => "bar", :hoge => "fuga") }
    subject { friendship }
    its(:foo) { should == "bar" }
    its(:hoge) { should == "fuga" }

    it "should not allow to dynamically set a new value" do
      expect { friendship.new_attr = "new value" }.to raise_exception(NoMethodError)
    end

    describe "#write_attribute" do
      specify { friendship.write_attribute(:another_attr, "another value").should == "another value" }

      context "after the definition" do
        before { friendship.write_attribute(:another_attr, "another value") }
        its(:another_attr) { should == "another value" }        
        specify do
          friendship.another_attr = "new value"
          friendship.another_attr.should == "new value"
        end
      end
    end
=begin
    describe "#remove_attribute" do
      specify { friendship.remove_attribute(:foo).should == "bar" }

      context "after the removal" do
        before { friendship.remove_attribute(:foo) }

        it "can no longer get a new value from foo" do
          expect { friendship.foo }.to raise_exception(NoMethodError)
        end

        it "can no longer set a new value to foo" do
          expect { friendship.foo = "bar" }.to raise_exception(NoMethodError)
        end
      end
    end
=end
  end

  describe "serialization" do
    context "with options" do
      let(:friendship) { Friendable::Friendship.new(current_user, target_user, :foo => "bar", :hoge => "fuga") }
      specify do
        MessagePack.unpack(friendship.to_msgpack).should == {
          "foo" => "bar",
          "hoge" => "fuga",
          "created_at" => nil,
          "updated_at" => nil
        }
      end
    end
  end

  describe "deserialization" do
    let(:current_timestamp) { Time.now.to_i }
    let(:msgpacked_data) { {:created_at => current_timestamp, :updated_at => current_timestamp}.to_msgpack }

    context "with options" do
      subject { Friendable::Friendship.deserialize!(current_user, target_user, msgpacked_data) }
      it { should be_a(Friendable::Friendship) }
      its(:source_resource) { should == current_user }
      its(:target_resource) { should == target_user }
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

  describe "#inspect" do
    subject { Friendable::Friendship.new(current_user, target_user, :foo => "bar", :hoge => "fuga") }
    its(:inspect) { should ==
      "#<Friendable::Friendship with: User(id: #{target_user.id}), attributes: foo: bar, hoge: fuga, created_at: , updated_at: >"
    }
  end
end
