require "helper"
require "minecraft"

class ExtensionsTest < Test
  # Coloured line testing.
  sandbox_test "should colour server side lines properly" do
    ext
    result = "\033[0;37m2011-08-21 13:45:13\033[0m [INFO] Starting minecraft server version Beta 1.7.3"
    assert_equal result, @ext.colour("2011-08-21 13:45:13 [INFO] Starting minecraft server version Beta 1.7.3")

    result = "\033[0;37m2011-08-21 13:45:28\033[0m [INFO] <\033[1;34mbasicxman\033[0m> \033[1;33m!list\033[0m"
    assert_equal result, @ext.colour("2011-08-21 13:45:28 [INFO] <basicxman> !list")

    result = "\033[0;37m2011-08-21 13:45:35\033[0m [INFO] <\033[1;34mbasicxman\033[0m> \033[1;33m!hop basicxman\033[0m"
    assert_equal result, @ext.colour("2011-08-21 13:45:35 [INFO] <basicxman> !hop basicxman")

    result = "\033[0;37m2011-08-21 14:03:10\033[0m [INFO] \033[1;30mbasicxman lost connection: disconnect.quitting\033[0m"
    assert_equal result, @ext.colour("2011-08-21 14:03:10 [INFO] basicxman lost connection: disconnect.quitting")

    result = "\033[0;37m2011-08-21 13:53:09\033[0m [INFO] \033[1;36mCONSOLE:\033[0m Forcing save.."
    assert_equal result, @ext.colour("2011-08-21 13:53:09 [INFO] CONSOLE: Forcing save..")
  end

  # call_comamnd testing.
  sandbox_test "should call a command for a regular user" do
    ext :users => ["basicxman"]
    call "basicxman list"
    assert_equal 0, output.index("say")
  end

  sandbox_test "should not call an all command for a regular user" do
    ext :users => ["basicxman"]
    call "basicxman giveall cobblestone"
    assert_match "not a", output
  end

  sandbox_test "should not let regular users run privileged commands" do
    ext :users => ["blizzard4U"]
    call "blizzard4U give cobblestone"
    assert_match "not a", output
  end

  sandbox_test "should not call an all command if not available" do
    ext :users => ["blizzard4U", "mike_n_7"], :ops => ["basicxman"]
    call "basicxman rouletteall"
    refute_match "basicxman is", output_line
  end

  sandbox_test "should let ops execute an all command" do
    ext :users => ["blizzard4U", "mike_n_7"], :ops => ["basicxman"]
    call "basicxman giveall cobblestone"
    assert_match "basicxman is", output
  end

  sandbox_test "should not let hops or execute an all command" do
    ext :users => ["blizzard4U", "basicxman"], :hops => ["mike_n_7"]
    call "mike_n_7 giveall cobblestone"
    assert_match "not a", output
  end

  sandbox_test "should not let hops run op commands" do
    ext :hops => ["mike_n_7"]
    call "mike_n_7 morning"
    assert_match "not a", output
  end

  sandbox_test "should let ops run op privileged commands" do
    ext :ops => ["basicxman"]
    call "basicxman morning"
    refute_match "not a", output
  end

  sandbox_test "should remove excess arguments" do
    ext :users => ["basicxman"]
    call "basicxman help foo bar"
    refute_empty output

    call "basicxman day foo"
    refute_empty output
  end

  # Command valiation testing.
  sandbox_test "should print an arguments error if not enough arguments are given" do
    ts, $stderr = $stderr, StringIO.new
    ext :ops => ["basicxman"]
    call "basicxman give"
    assert_match "at least one argument", output
    clear

    call "basicxman hop"
    assert_match "Expected", output
    assert_match "target user", output
    $stderr = ts
  end
end
