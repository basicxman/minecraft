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

  sandbox_test "give command should give kits for wools" do
    ext :hops => ["basicxman"]
    call "basicxman give lightgray 2m"
    assert_match "give basicxman 35 64", output_line
    assert_match "give basicxman 351", output_line
  end

  # User points system testing.
  sandbox_test "should give a user points" do
    ext :ops => ["basicxman"], :hops => ["mike_n_7"], :users => ["blizzard4U", "Ian_zers"]
    call "basicxman points Ian_zers 1001"
    assert_equal 1000, @ext.userpoints["ian_zers"]

    call "mike_n_7 points Ian_zers 501"
    assert_equal 1500, @ext.userpoints["ian_zers"]

    call "blizzard4U points Ian_zers 2"
    assert_equal 1501, @ext.userpoints["ian_zers"]
  end

  sandbox_test "should not a let a user give herself points" do
    ext :users => ["basicxman"]
    @ext.userpoints = { "basicxman" => 0 }
    call "basicxman points basicxman"
    assert @ext.userpoints["basicxman"] < 0
  end

  sandbox_test "should print a users points" do
    ext :users => ["basicxman"]
    @ext.userpoints = { "basicxman" => 50 }
    call "basicxman board"
    assert_match "basicxman", output
    assert_match "50", output
  end

  sandbox_test "should print a leaderboard" do
    ext
    @ext.userpoints = {
      "basicxman" => 150,
      "mike_n_7" => 150,
      "blizzard4U" => 20,
      "Ian_zers" => 90,
      "horsmanjarrett" => 50,
      "someguy" => 10
    }
    @ext.board("basicxman")
    leaderboard = output_lines
    assert_match "150", leaderboard[0]
    assert_match "150", leaderboard[1]
    assert_match "Ian_zers", leaderboard[2]
    assert_match "horsmanjarrett", leaderboard[3]
    assert_match "blizzard4U", leaderboard[4]
  end

  # Kickvote testing.
  sandbox_test "should initiate a kickvote against a user" do
    ext :ops => ["basicxman"], :hops => ["mike_n_7"], :users => ["blizzard4U", "Ian_zers"]
    call "basicxman kickvote blizzard4U"
    assert_equal 3, @ext.userkickvotes["blizzard4U"][:tally]
    assert_equal "blizzard4U", @ext.last_kick_vote
  end

  sandbox_test "should expire a kickvote against a user" do
    ext :users => ["basicxman", "blizzard4U"]
    call "basicxman kickvote blizzard4U"
    @ext.counter = 9
    @ext.userkickvotes["blizzard4U"][:start] = Time.now - 300
    @ext.periodic
    assert_match "expire", output
  end

  sandbox_test "should add the correct number of votes per user type" do
    ext :ops => ["basicxman"], :hops => ["mike_n_7"], :users => ["blizzard4U", "Ian_zers"]
    @ext.vote_threshold = 7
    call "Ian_zers kickvote blizzard4U"
    assert_equal 1, @ext.userkickvotes["blizzard4U"][:tally]

    call "mike_n_7 vote"
    assert_equal 3, @ext.userkickvotes["blizzard4U"][:tally]

    call "basicxman vote"
    assert_equal 6, @ext.userkickvotes["blizzard4U"][:tally]
  end

  sandbox_test "should kick a user who has enough votes" do
    ext :ops => ["basicxman"], :hops => ["mike_n_7"], :users => ["blizzard4U", "Ian_zers"]
    call "basicxman kickvote Ian_zers"
    call "mike_n_7 vote"
    assert_match "kick Ian_zers", output
  end

  # Timer test.
  sandbox_test "should not add a timer if the item does not exist" do
    ext :hops => ["basicxman"]
    call "basicxman addtimer foo"
    assert_nil @ext.timers["basicxman"]
    assert_match "not added", output
  end

  # Stop timer test.
  sandbox_test "should stop all timers" do
    ext :hops => ["basicxman"]
    call "basicxman addtimer cobblestone"
    call "basicxman addtimer arrow"
    clear

    call "basicxman stop"
    assert_nil @ext.timers["basicxman"]
    assert_match "stopped", output
  end

  # Time commands.
  sandbox_test "should change time with time commands" do
    ext :ops => ["basicxman"]
    %w( morning evening night dawn dusk day ).each do |time|
      call "basicxman #{time}"
      assert_match "time set #{Minecraft::Data::TIME[time.to_sym]}", output
      clear
    end
  end

  # Half op privileges and !list.
  sandbox_test "should revoke and add half op privileges" do
    ext :ops => ["basicxman"], :users => ["blizzard4U", "mike_n_7"]
    call "basicxman hop blizzard4U"
    call "basicxman hop mike_n_7"
    call "basicxman dehop blizzard4U"
    call "basicxman list"
    assert_match "[@basicxman], blizzard4U, %mike_n_7", output_lines.last
  end

  # Help command.
  sandbox_test "should display help contents for regular users" do
    ext :users => ["blizzard4U"]
    call "blizzard4U help"
    t = output_line.gsub("say", "")
    assert_match "rules", t
    assert_match "list", t
    refute_match "give", t
  end

  sandbox_test "should display help contents for half ops" do
    ext :hops => ["mike_n_7"]
    call "mike_n_7 help"
    t = output_line.gsub("say", "")
    assert_match "rules", t
    assert_match "give", t
    refute_match "morning", t
  end

  sandbox_test "should display help contents for ops" do
    ext :ops => ["basicxman"]
    call "basicxman help"
    t = output_line.gsub("say", "")
    assert_match "rules", t
    assert_match "give", t
    assert_match "morning", t
  end

  sandbox_test "should display help contents for a specific command" do
    ext :users => ["basicxman"]
    call "basicxman help hop"
    assert_match "privileges to the target user", output_line
  end

  sandbox_test "should display command syntaxes" do
    ext :ops => ["basicxman"]

    # opt
    clear
    call "basicxman help warptime"
    assert_equal "say !warptime", output_lines[0]
    assert_equal "say !warptime 'time change'", output_lines[1]

    # rest
    clear
    call "basicxman help welcome"
    assert_equal "say !welcome 'arguments', '...'", output_lines[0]

    # req, rest
    clear
    call "basicxman help memo"
    assert_equal "say !memo 'target user', 'arguments', '...'", output_lines[0]

    # req
    clear
    call "basicxman help disturb"
    assert_equal "say !disturb 'target user'", output_lines[0]

    # req, opt
    clear
    call "basicxman help points"
    assert_equal "say !points 'target user'", output_lines[0]
    assert_equal "say !points 'target user', 'num points'", output_lines[1]
  end

  # Do not disturb testing.
  sandbox_test "should not allow users in dnd to be teleported to" do
    ext :hops => ["mike_n_7"], :users => ["basicxman"]
    call "basicxman dnd"
    assert_equal ["basicxman"], @ext.userdnd
    clear
    call "mike_n_7 tp basicxman"
    assert_match "disturbed", output
    call "basicxman dnd"
    assert_equal [], @ext.userdnd
  end

  sandbox_test "should allow ops to use the disturb command against users" do
    ext :ops => ["basicxman"], :users => ["mike_n_7"]
    call "mike_n_7 dnd"
    assert_equal ["mike_n_7"], @ext.userdnd
    call "basicxman disturb mike_n_7"
    assert_equal [], @ext.userdnd
  end

  # Disco.
  sandbox_test "should start the disco" do
    ext :ops => ["basicxman"]
    call "basicxman disco"
    assert_match "disco", output
    clear
    12.times { @ext.periodic }
    assert_match "time set 0", output
    assert_match "time set 16000", output
  end

  # Teleport all.
  sandbox_test "should teleport all users to an op" do
    ext :ops => ["basicxman"], :users => ["mike_n_7", "blizzard4U", "Ian_zers"]
    call "basicxman tpall"
    assert_match "mike_n_7", output
    assert_match "blizzard4U", output
    assert_match "Ian_zers", output
  end

  # Welcome message runtime change test.
  sandbox_test "should change welcome message during runtime" do
    ext :ops => ["basicxman"]
    call "basicxman welcome Foo bar."
    assert_equal "Foo bar.", @ext.welcome_message

    call "basicxman welcome + %"
    assert_equal "Foo bar. %", @ext.welcome_message
    assert_match "basicxman", output
  end

  # Memos.
  sandbox_test "should allow users to set memos" do
    ext :users => ["basicxman"]
    call "basicxman memo mike_n_7 Hi"
    assert_equal ["basicxman", "Hi"], @ext.memos["mike_n_7"][0]
  end

  sandbox_test "should add and print multiple memos" do
    ext :users => ["basicxman"]
    3.times { call "basicxman memo mike_n_7 Hi" }
    assert_equal 3, @ext.memos["mike_n_7"].length

    @ext.check_memos("mike_n_7")
    assert_equal 0, @ext.memos["mike_n_7"].length
  end

  sandbox_test "should only allow five memos per user" do
    ext :users => ["basicxman"]
    10.times { call "basicxman memo mike_n_7 Hi" }
    assert_equal 5, @ext.memos["mike_n_7"].length
  end

  # Warping time.
  sandbox_test "should warp time" do
    ext :ops => ["basicxman"]
    call "basicxman warptime 100"
    40.times { @ext.periodic }
    assert_match "time add 100", output_line
  end

  # Todo command tests.
  sandbox_test "should add, list and remove global todo items" do
    ext :users => ["basicxman"]
    call "basicxman todo foo bar"
    call "basicxman todo bar"
    assert_match "Added", output
    assert_equal "foo bar", @ext.todo_items[0]

    call "basicxman todo"
    assert_match "1. foo bar", output_lines[-2]
    assert_match "2. bar", output_lines[-1]

    call "basicxman finished foo bar"
    call "basicxman finished 1"
    assert_match "Hurray!", output
    assert_equal 0, @ext.todo_items.length

    clear
    call "basicxman finished 2"
    assert_match "not exist", output
    clear
    call "basicxman finished lolcats"
    assert_match "not exist", output
  end

  # Command history.
  sandbox_test "should keep track of command history and allow users to use previous commands" do
    ext :ops => ["basicxman"]
    @ext.command_history = {}
    call "basicxman dusk"
    call "basicxman dawn"
    clear
    call "basicxman last"
    call "basicxman last 2"
    @ext.info_command("2011-08-30 15:52:55 [INFO] <basicxman> !")
    @ext.info_command("2011-08-30 15:52:55 [INFO] <basicxman> !!")
    t = output_lines
    assert_match "time set 0", t[0]
    assert_match "time set 12000", t[1]
    assert_match "time set 0", t[2]
    assert_match "time set 12000", t[3]

    clear
    call "basicxman last 3"
    assert_match "No command found", output
  end

  sandbox_test "should print users command history" do
    ext :ops => ["basicxman"]
    call "basicxman dawn"
    call "basicxman dusk"
    call "basicxman help list"
    call "basicxman give 4 64"
    clear
    call "basicxman history"
    t = output_lines
    assert_match "1. give 4 64", t[0]
    assert_match "2. help list", t[1]
    assert_match "3. dusk", t[2]
  end

  sandbox_test "should not add the same command to history twice in a row" do
    ext :ops => ["basicxman"]
    call "basicxman day"
    call "basicxman day"
    assert_equal [["day"]], @ext.command_history["basicxman"]
  end

  sandbox_test "should not add command history from shortucts" do
    ext :users => ["basicxan"]
    call "basicxman s foo day"
    call "basicxman s foo"
    assert_nil @ext.command_history["basicxman"]
  end

  # Shortcuts
  sandbox_test "should allow hops to specify and use shortcuts" do
    ext :hops => ["basicxman"]
    call "basicxman s ga give cobblestone"
    call "basicxman s ga give arrow 2m" # Should override
    call "basicxman s ka kit armour"
    assert_match "labelled", output
    assert_equal ["give", "arrow", "2m"], @ext.usershortcuts["basicxman"]["ga"]
    clear

    call "basicxman s ga"
    assert_match "give basicxman 262 64", output_line
    clear

    call "basicxman shortcuts"
    assert_match "ka", output_line
    assert_match "ga", output_line
  end

  sandbox_test "should fall back on a kit or print an error message for shortcuts" do
    ext :hops => ["basicxman"]
    call "basicxman s diamond"
    assert_match "give basicxman 278", output_line
    clear

    call "basicxman s foo"
    assert_match "not a valid shortcut", output_line
  end

  # Kits
  sandbox_test "should print available kits" do
    ext :hops => ["basicxman"]
    call "basicxman kitlist"
    assert_match "diamond", output_line
    clear

    call "basicxman kit diamond"
    assert_match "give basicxman 278", output_line
    clear

    call "basicxman kit doesnotexist"
    assert_match "diamond", output_line
  end

  # Remaining commands testing (should test to ensure no errors are thrown in
  # the command execution).
  sandbox_test "should run commands without failure" do
    ext :ops => ["basicxman"], :hops => ["mike_n_7"], :users => ["blizzard4U", "Ian_zers"]
    call "basicxman printdnd"
    call "basicxman roulette"
    call "basicxman kit diamond"
    call "basicxman tp Ian_zers"
    call "basicxman tpall"
    call "basicxman nom"
    call "basicxman om nom nom"
    call "basicxman property spawn-monsters"
    call "basicxman property"
    call "basicxman rules"
    call "basicxman printtimer"
    call "basicxman printtime"
    call "basicxman kitlist"
  end
end
