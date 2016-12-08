require "./spec_helper"

describe "Session::RedisEngine" do
  describe "options" do
    describe "url" do
      it "raises an ArgumentError if not passed" do
        expect_raises(ArgumentError) do
          Session::RedisEngine.new({ :whatever => "else" })
        end
      end

      it "can be successfully set up" do
      end
    end

  end
end
