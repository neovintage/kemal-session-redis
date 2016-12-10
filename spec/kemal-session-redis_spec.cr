require "./spec_helper"

describe "Session::RedisEngine" do
  describe ".new" do
    it "can be set up with no params" do
      redis = Session::RedisEngine.new
      redis.should_not be_nil
    end

    it "can be set up with a connection pool" do
      pool = ConnectionPool.new(capacity: 1, timeout: 2.0) do
        Redis.new
      end
      redis = Session::RedisEngine.new(pool: pool)
      redis.should_not be_nil
    end
  end

  describe ".int" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.int("int", 12)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.int("int", 12)
      session.int("int").should eq 12
    end
  end

  describe ".bool" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.bool("bool", true)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.bool("bool", true)
      session.bool("bool").should eq true
    end
  end

  describe ".float" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.float("float", 3.00)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.float("float", 3.00)
      session.float("float").should eq 3.00
    end
  end

  describe ".string" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.string("string", "kemal")
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.string("string", "kemal")
      session.string("string").should eq "kemal"
    end
  end
end
