require "helper"
require "minecraft"

class ExtensionsTest < Test
  # Coloured line testing.
  sandbox_test "should colour server side lines properly" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
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
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    @ext.call_command("basicxman", "list")
    assert_equal 0, @ext.server.string.index("say")
  end

  sandbox_test "should not call an all command for a regular user" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman"]
    @ext.call_command("basicxman", "giveall", "cobblestone")
    assert_match "not a", @ext.server.string
  end

  sandbox_test "should not let regular users run privileged commands" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["blizzard4U"]
    @ext.call_command("blizzard4U", "give", "cobblestone")
    assert_match "not a", @ext.server.string
  end

  sandbox_test "should not call an all command if not available" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "blizzard4U", "mike_n_7"]
    @ext.ops = ["basicxman"]
    @ext.call_command("basicxman", "rouletteall")
    assert_equal 2, @ext.server.string.split("\n").length
  end

  sandbox_test "should let ops execute an all command" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "blizzard4U", "mike_n_7"]
    @ext.ops = ["basicxman"]
    @ext.call_command("basicxman", "giveall", "cobblestone")
    assert_match "basicxman is", @ext.server.string
  end

  sandbox_test "should not let hops or execute an all command" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.users = ["basicxman", "blizzard4U", "mike_n_7"]
    @ext.hops = ["mike_n_7"]
    @ext.call_command("mike_n_7", "giveall", "cobblestone")
    assert_match "not a", @ext.server.string
  end

  sandbox_test "should not let hops run op commands" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.hops = ["mike_n_7"]
    @ext.call_command("mike_n_7", "morning")
    assert_match "not a", @ext.server.string
  end

  sandbox_test "should let ops run op privileged commands" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.ops = ["basicxman"]
    @ext.call_command("basicxman", "morning")
    refute_match "not a", @ext.server.string
  end

  sandbox_test "should remove excess arguments" do
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.call_command("basicxman", "help", "foo", "bar")
    refute_empty @ext.server.string

    @ext.call_command("basicxman", "day", "foo")
    refute_empty @ext.server.string
  end

  # Command valiation testing.
  sandbox_test "should print an arguments error if not enough arguments are given" do
    ts, $stderr = $stderr, StringIO.new
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.ops = ["basicxman"]
    @ext.call_command("basicxman", "give")
    assert_match "at least one argument", @ext.server.string
    @ext.server.string = ""

    @ext.call_command("basicxman", "kit")
    assert_match "Expected", @ext.server.string
    assert_match "group", @ext.server.string
    @ext.server.string = ""

    @ext.call_command("basicxman", "hop")
    assert_match "Expected", @ext.server.string
    assert_match "target user", @ext.server.string
    $stderr = ts
  end
end
