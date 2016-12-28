require "./spec_helper"

describe "Session::RedisEngine" do
  describe "options" do
    it "can config a new redis with options" do
      eng = Session::RedisEngine.new(
              host: "localhost",
              port: 6379
            )
      eng.should_not be_nil
    end

    it "can pass a connection pool" do
      pool = ConnectionPool.new(capacity: 1, timeout: 1.0) do
        Redis.new
      end
      eng = Session::RedisEngine.new({ :pool => pool })
      eng.should_not be_nil
    end
  end

  describe ".int" do
  end

  describe ".bool" do
  end

  describe ".float" do
  end

  describe ".string" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.string("bar", "kemal")
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.string("bar", "kemal")
      session.string("bar").should eq "kemal"
    end
  end
end
