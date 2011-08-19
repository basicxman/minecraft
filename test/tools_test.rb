require "helper"
require "minecraft/tools"

class ToolsTest < Test
  test "should get minecraft download url" do
    url = Minecraft::Tools.get_minecraft_page
    refute_nil url.index "minecraft_server.jar"
  end

  test "should generate a proper default command" do
    command = Minecraft::Tools.command({})
    assert_equal "java -Xmx1024M -Xms1024M -jar minecraft_server.jar nogui", command
  end

  test "should properly modify server properties when toggling mobs" do
    File.open("server.properties", "w") do |f| f.print <<-eof
#Minecraft server properties
#Thu May 26 15:19:31 EDT 2011
view-distance=10
spawn-monsters=false
online-mode=true
eof
    end
    assert_equal "true", Minecraft::Tools.toggle_mobs
    refute_nil File.read("server.properties").index("spawn-monsters=true")
    assert_equal "false", Minecraft::Tools.toggle_mobs
    refute_nil File.read("server.properties").index("spawn-monsters=false")
    FileUtils.rm_f("server.properties")
  end
end
