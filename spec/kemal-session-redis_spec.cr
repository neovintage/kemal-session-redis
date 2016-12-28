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
      session = Session.new(create_context(SESSION_ID))
      session.int("int", 12)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.int("int", 12)
      session.int("int").should eq 12
    end
  end

  describe ".bool" do
    it "can save a value" do
      session = Session.new(create_context(SESSION_ID))
      session.bool("bool", true)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.bool("bool", true)
      session.bool("bool").should eq true
    end
  end

  describe ".float" do
    it "can save a value" do
      session = Session.new(create_context(SESSION_ID))
      session.float("float", 3.00)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.float("float", 3.00)
      session.float("float").should eq 3.00
    end
  end

  describe ".string" do
    it "can save a value" do
      session = Session.new(create_context(SESSION_ID))
      session.string("string", "kemal")
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.string("string", "kemal")
      session.string("string").should eq "kemal"
    end
  end

  describe ".destroy" do
    it "should remove session from redis" do
      session = Session.new(create_context(SESSION_ID))
      value = REDIS.get("kemal:session:#{SESSION_ID}")
      value.should_not be_nil
      session.destroy
      value = REDIS.get("kemal:session:#{SESSION_ID}")
      value.should be_nil
    end
  end

  describe "#destroy" do
    it "should remove session from redis" do
      session = Session.new(create_context(SESSION_ID))
      value = REDIS.get("kemal:session:#{SESSION_ID}")
      value.should_not be_nil
      Session.destroy(SESSION_ID)
      value = REDIS.get("kemal:session:#{SESSION_ID}")
      value.should be_nil
    end

    it "should succeed if session doesnt exist in redis" do
      session = Session.new(create_context(SESSION_ID))
      value = REDIS.get("kemal:session:#{SESSION_ID}")
      value.should_not be_nil
      Session.destroy(SESSION_ID).should be_truthy
    end
  end

  describe "#destroy_all" do
    it "should remove all sessions in redis" do
      5.times { Session.new(create_context(SecureRandom.hex)) }
      arr = Session.all
      arr.size.should eq(5)
      Session.destroy_all
      Session.all.size.should eq(0)
    end
  end

  describe "#get" do
    it "should return a valid Session" do
      session = Session.new(create_context(SESSION_ID))
      get_session = Session.get(SESSION_ID)
      get_session.should_not be_nil
      if get_session
        session.id.should eq(get_session.id)
        get_session.is_a?(Session).should be_true
      end
    end

    it "should return nil if the Session does not exist" do
      session = Session.get(SESSION_ID)
      session.should be_nil
    end
  end

  describe "#create" do
    it "should build an empty session" do
      Session.config.engine.create_session(SESSION_ID)
      value = REDIS.get("kemal:session:#{SESSION_ID}")
      value.should_not be_nil
    end
  end

  describe "#all" do
    it "should return an empty array if none exist" do
      arr = Session.all
      arr.is_a?(Array).should be_true
      arr.size.should eq(0)
    end

    it "should return an array of Sessions" do
      3.times { Session.new(create_context(SecureRandom.hex)) }
      arr = Session.all
      arr.is_a?(Array).should be_true
      arr.size.should eq(3)
    end
  end

  describe "#each" do
    it "should iterate over all sessions" do
      5.times { Session.new(create_context(SecureRandom.hex)) }
      count = 0
      Session.each do |session|
        count = count + 1
      end
      count.should eq(5)
    end
  end
end
