require "helper"

class ExtensionsTest < Test
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
end
