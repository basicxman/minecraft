require "helper"
require "minecraft"

class CommandsTest < Test
  include Minecraft::Commands

  # Item resolution and quantifiers testing.
  test "should properly check quantifiers" do
    assert is_quantifier? "1"
    assert is_quantifier? "10"
    assert is_quantifier? "9m"
    assert is_quantifier? "9mm"
    refute is_quantifier? "m"
    refute is_quantifier? "steel"
    refute is_quantifier? "!"
  end

  test "should propery quantify values" do
    assert_equal 1,    quantify("1")
    assert_equal 64,   quantify("1m")
    assert_equal 63,   quantify("1s")
    assert_equal 64,   quantify("1d")
    assert_equal 1,    quantify("1i")
    assert_equal 32,   quantify("2d")
    assert_equal 160,  quantify("2d2m")
    assert_equal 2560, quantify("41m")
    assert_equal 2560, quantify("100000")
    assert_equal 64,   quantify("0d")
  end

  test "should resolve keys" do
    @server = StringIO.new
    assert_equal "glass",       resolve_key("glass")
    assert_equal "redstone",    resolve_key("redstone")
    assert_equal "redstone",    resolve_key("reds")
    assert_equal "cobblestone", resolve_key("cobb")
    assert_equal "cobweb",      resolve_key("cob")
    assert_nil resolve_key("asdf")
  end

  test "should properly distinguish items and quantities" do
    assert_equal ["flint", 1], items_arg(1, ["flint"])
    assert_equal ["flint and steel", 1], items_arg(1, ["flint", "and", "steel"])
    assert_equal ["flint", 64], items_arg(1, ["flint", "64"])
    assert_equal ["flint and steel", 64], items_arg(1, ["flint", "and", "steel", "64"])
  end

  test "should properly resolve an item id" do
    @server = StringIO.new
    assert_equal "5",  resolve_item("5")
    assert_equal "81", resolve_item("cactus")
    assert_nil resolve_item("asdf")
  end

  # Give command testing.
  test "give command should give a single slot worth" do
    @server = StringIO.new
    give("foo", "cobblestone", "64")
    result = <<eof
give foo 4 64
eof
    assert_equal result, @server.string
  end

  test "give command should work for multiple slot spans" do
    @server = StringIO.new
    give("foo", "cobblestone", "2m")
    result = <<eof
give foo 4 64
give foo 4 64
eof
    assert_equal result, @server.string
  end

  test "give command should give less than a single slot span" do
    @server = StringIO.new
    give("foo", "cobblestone", "32")
    result = <<eof
give foo 4 32
eof
    assert_equal result, @server.string
  end

  # User points system testing.
  sandbox_test "should give a user points" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "mike_n_7", "blizzard4U", "Ian_zers"]
    @ext.ops  = ["basicxman"]
    @ext.hops = ["mike_n_7"]
    @ext.call_command("basicxman", "points", "Ian_zers", "1001")
    assert_equal 1000, @ext.userpoints["Ian_zers"]
    @ext.call_command("mike_n_7", "points", "Ian_zers", "501")
    assert_equal 1500, @ext.userpoints["Ian_zers"]
    @ext.call_command("blizzard4U", "points", "Ian_zers", "2")
    assert_equal 1501, @ext.userpoints["Ian_zers"]
  end

  sandbox_test "should not a let a user give herself points" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    @ext.userpoints = { "basicxman" => 0 }
    @ext.call_command("basicxman", "points", "basicxman")
    assert @ext.userpoints["basicxman"] < 0
  end

  sandbox_test "should print a users points" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.userpoints = { "basicxman" => 50 }
    @ext.call_command("basicxman", "board")
    assert_match "basicxman", @ext.server.string
    assert_match "50", @ext.server.string
  end

  sandbox_test "should print a leaderboard" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.userpoints = {
      "basicxman" => 150,
      "mike_n_7" => 150,
      "blizzard4U" => 20,
      "Ian_zers" => 90,
      "horsmanjarrett" => 50,
      "someguy" => 10
    }
    @ext.board("basicxman")
    leaderboard = @ext.server.string.split("\n")
    assert_match "150", leaderboard[0]
    assert_match "150", leaderboard[1]
    assert_match "Ian_zers", leaderboard[2]
    assert_match "horsmanjarrett", leaderboard[3]
    assert_match "blizzard4U", leaderboard[4]
  end

  # Kickvote testing.
  sandbox_test "should initiate a kickvote against a user" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "mike_n_7", "blizzard4U", "Ian_zers"]
    @ext.ops  = ["basicxman"]
    @ext.hops = ["mike_n_7"]
    @ext.call_command("basicxman", "kickvote", "blizzard4U")
    assert_equal 3, @ext.kickvotes["blizzard4U"][:tally]
    assert_equal "blizzard4U", @ext.last_kick_vote
  end

  sandbox_test "should expire a kickvote against a user" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "blizzard4U"]
    @ext.call_command("basicxman", "kickvote", "blizzard4U")
    @ext.counter = 9
    @ext.kickvotes["blizzard4U"][:start] = Time.now - 300
    @ext.periodic
    assert_match "expire", @ext.server.string
  end

  sandbox_test "should add the correct number of votes per user type" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "mike_n_7", "blizzard4U", "Ian_zers"]
    @ext.ops  = ["basicxman"]
    @ext.hops = ["mike_n_7"]
    @ext.vote_threshold = 7
    @ext.call_command("Ian_zers", "kickvote", "blizzard4U")
    assert_equal 1, @ext.kickvotes["blizzard4U"][:tally]
    @ext.call_command("mike_n_7", "vote")
    assert_equal 3, @ext.kickvotes["blizzard4U"][:tally]
    @ext.call_command("basicxman", "vote")
    assert_equal 6, @ext.kickvotes["blizzard4U"][:tally]
  end

  sandbox_test "should kick a user who has enough votes" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "mike_n_7", "blizzard4U", "Ian_zers"]
    @ext.ops  = ["basicxman"]
    @ext.hops = ["mike_n_7"]
    @ext.call_command("basicxman", "kickvote", "Ian_zers")
    @ext.call_command("mike_n_7", "vote")
    assert_match "kick Ian_zers", @ext.server.string
  end

  # Time commands.
  sandbox_test "should change time with time commands" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.ops = ["basicxman"]
    %w( morning evening night dawn dusk day ).each do |time|
      @ext.call_command("basicxman", time)
      assert_match "time set #{Minecraft::Data::TIME[time.to_sym]}", @ext.server.string
      @ext.server.string = ""
    end
  end

  # Half op privileges and !list.
  sandbox_test "should revoke and add half op privileges" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "blizzard4U", "mike_n_7"]
    @ext.ops = ["basicxman"]
    @ext.call_command("basicxman", "hop", "blizzard4U")
    @ext.call_command("basicxman", "hop", "mike_n_7")
    @ext.call_command("basicxman", "dehop", "blizzard4U")
    @ext.call_command("basicxman", "list")
    assert_match "[@basicxman], blizzard4U, %mike_n_7", @ext.server.string.split("\n").last
  end

  # Help command.
  sandbox_test "should display help contents for regular users" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["blizzard4U"]
    @ext.call_command("blizzard4U", "help")
    assert_match "rules", @ext.server.string
    assert_match "list", @ext.server.string
    refute_match "give", @ext.server.string
  end

  sandbox_test "should display help contents for half ops" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["mike_n_7"]
    @ext.hops  = ["mike_n_7"]
    @ext.call_command("mike_n_7", "help")
    assert_match "rules", @ext.server.string
    assert_match "give", @ext.server.string
    refute_match "morning", @ext.server.string
  end

  sandbox_test "should display help contents for ops" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    @ext.ops   = ["basicxman"]
    @ext.call_command("basicxman", "help")
    assert_match "rules", @ext.server.string
    assert_match "give", @ext.server.string
    assert_match "morning", @ext.server.string
  end
end
