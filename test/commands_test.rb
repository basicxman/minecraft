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
    assert_equal 1000, @ext.userpoints["ian_zers"]
    @ext.call_command("mike_n_7", "points", "Ian_zers", "501")
    assert_equal 1500, @ext.userpoints["ian_zers"]
    @ext.call_command("blizzard4U", "points", "Ian_zers", "2")
    assert_equal 1501, @ext.userpoints["ian_zers"]
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
    t = @ext.server.string.gsub("\n", " ")
    assert_match "rules", t
    assert_match "list", t
    refute_match "give", t
  end

  sandbox_test "should display help contents for half ops" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["mike_n_7"]
    @ext.hops  = ["mike_n_7"]
    @ext.call_command("mike_n_7", "help")
    t = @ext.server.string.gsub("\n", " ")
    assert_match "rules", t
    assert_match "give", t
    refute_match "morning", t
  end

  sandbox_test "should display help contents for ops" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    @ext.ops   = ["basicxman"]
    @ext.call_command("basicxman", "help")
    t = @ext.server.string.gsub("\n", " ")
    assert_match "rules", t
    assert_match "give", t
    assert_match "morning", t
  end

  sandbox_test "should display help contents for a specific command" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    @ext.call_command("basicxman", "help", "hop")
    assert_match "privileges to the target user", @ext.server.string
  end

  # Do not disturb testing.
  sandbox_test "should not allow users in dnd to be teleported to" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "mike_n_7"]
    @ext.hops = ["mike_n_7"]
    @ext.call_command("basicxman", "dnd")
    assert_equal ["basicxman"], @ext.userdnd
    @ext.server.string = ""
    @ext.call_command("mike_n_7", "tp", "basicxman")
    assert_match "disturbed", @ext.server.string
    @ext.call_command("basicxman", "dnd")
    assert_equal [], @ext.userdnd
  end

  sandbox_test "should allow ops to use the disturb command against users" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "mike_n_7"]
    @ext.ops   = ["basicxman"]
    @ext.call_command("mike_n_7", "dnd")
    assert_equal ["mike_n_7"], @ext.userdnd
    @ext.call_command("basicxman", "disturb", "mike_n_7")
    assert_equal [], @ext.userdnd
  end

  # Disco.
  sandbox_test "should start the disco" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    @ext.ops = ["basicxman"]
    @ext.call_command("basicxman", "disco")
    assert_match "disco", @ext.server.string
    @ext.server.string = ""
    12.times { @ext.periodic }
    assert_match "time set 0", @ext.server.string
    assert_match "time set 16000", @ext.server.string
  end

  # Teleport all.
  sandbox_test "should teleport all users to an op" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "mike_n_7", "blizzard4U", "Ian_zers"]
    @ext.ops = ["basicxman"]
    @ext.call_command("basicxman", "tpall")
    assert_match "mike_n_7", @ext.server.string
    assert_match "blizzard4U", @ext.server.string
    assert_match "Ian_zers", @ext.server.string
  end

  # Welcome message runtime change test.
  sandbox_test "should change welcome message during runtime" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.ops = ["basicxman"]
    @ext.call_command("basicxman", "welcome", "Foo bar.")
    assert_equal "Foo bar.", @ext.welcome_message

    @ext.call_command("basicxman", "welcome", "+", "%")
    assert_equal "Foo bar. %", @ext.welcome_message
    assert_match "basicxman", @ext.server.string
  end

  # Memos.
  sandbox_test "should allow users to set memos" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    @ext.call_command("basicxman", "memo", "mike_n_7", "Hi")
    assert_equal ["basicxman", "Hi"], @ext.memos["mike_n_7"][0]

    #@ext.check_memos("mike_n_7")
    #assert_match "Hi", @ext.server.string
    #assert_equal 0, @ext.memos["mike_n_7"].length
  end

  sandbox_test "should add and print multiple memos" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    3.times { @ext.call_command("basicxman", "memo", "mike_n_7", "Hi") }
    assert_equal 3, @ext.memos["mike_n_7"].length

    @ext.check_memos("mike_n_7")
    assert_equal 0, @ext.memos["mike_n_7"].length
  end

  sandbox_test "should only allow five memos per user" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    10.times { @ext.call_command("basicxman", "memo", "mike_n_7", "Hi") }
    assert_equal 5, @ext.memos["mike_n_7"].length
  end

  # Remaining commands testing (should test to ensure no errors are thrown in
  # the command execution).
  sandbox_test "should run commands without failure" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "mike_n_7", "blizzard4U", "Ian_zers"]
    @ext.ops   = ["basicxman"]
    @ext.hops  = ["mike_n_7"]
    @ext.call_command("basicxman", "dawn")
    @ext.call_command("basicxman", "dusk")
    @ext.call_command("basicxman", "day")
    @ext.call_command("basicxman", "night")
    @ext.call_command("basicxman", "morning")
    @ext.call_command("basicxman", "evening")
    @ext.call_command("basicxman", "disco")
    @ext.call_command("mike_n_7", "dnd")
    @ext.call_command("basicxman", "printdnd")
    @ext.call_command("basicxman", "disturb", "mike_n_7")
    @ext.call_command("basicxman", "roulette")
    @ext.call_command("basicxman", "hop", "Ian_zers")
    @ext.call_command("basicxman", "dehop", "Ian_zers")
    @ext.call_command("basicxman", "kit", "diamond")
    @ext.call_command("basicxman", "tp", "Ian_zers")
    @ext.call_command("basicxman", "tpall")
    @ext.call_command("basicxman", "nom")
    @ext.call_command("basicxman", "om", "nom", "nom")
    @ext.call_command("basicxman", "property", "spawn-monsters")
    @ext.call_command("basicxman", "property")
    @ext.call_command("basicxman", "uptime")
    @ext.call_command("basicxman", "uptime", "mike_n_7")
    @ext.call_command("basicxman", "rules")
    @ext.call_command("basicxman", "list")
    @ext.call_command("basicxman", "addtimer", "cobblestone")
    @ext.call_command("basicxman", "addtimer", "4", "60")
    @ext.call_command("basicxman", "deltimer", "4")
    @ext.call_command("basicxman", "printtimer")
    @ext.call_command("basicxman", "printtime")
    @ext.call_command("basicxman", "s", "foo", "give", "cobblestone")
    @ext.call_command("basicxman", "s", "foo")
    @ext.call_command("basicxman", "shortcuts")
    @ext.call_command("basicxman", "help")
    @ext.call_command("basicxman", "help", "give")
    @ext.call_command("basicxman", "kitlist")
  end
end
