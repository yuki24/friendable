require 'spec_helper'

describe Friendable do
  it { should respond_to :redis }
  it { should respond_to :resource_class }
  it { should respond_to :resource_class= }
  its(:redis) { should be_a(Redis::Namespace) }

  describe "confgiruration" do
    context "with the default redis" do
      subject { Friendable.redis.client }
      it { should be_a(Redis::Client) }
      its(:host) { should == "127.0.0.1" }
      its(:port) { should == 6379 }
    end

    context "with an object of Redis class" do
      before { Friendable.redis = Redis.new(:host => "127.0.0.1", :port => 6379) }
      subject { Friendable.redis.client }
      it { should be_a(Redis::Client) }
      its(:host) { should == "127.0.0.1" }
      its(:port) { should == 6379 }
    end
  end
end
