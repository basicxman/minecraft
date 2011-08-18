require "net/http"

module Minecraft
  module Tools
    def self.check_jarfile
      download_minecraft unless File.exists? "minecraft_server.jar"
    end

    def self.download_minecraft
      url = get_minecraft_page
      puts "[+] Downloading Minecraft server..."
      `wget http://minecraft.net/#{url} -O minecraft_server.jar -q`
    end

    def self.get_minecraft_page
      page = Net::HTTP.get("www.minecraft.net", "/download.jsp")
      data = page.match /\"([0-9a-zA-Z_\/]*minecraft_server\.jar\?v=[0-9]+)/
      data[1]
    end

    def self.command(opts)
      "java -Xmx#{opts[:max_memory] || "1024M"} -Xms#{opts[:min_memory] || "1024M"} -jar minecraft_server.jar nogui"
    end

    def self.toggle_mobs
      content = File.read("server.properties")
      state = content.match(/spawn\-monsters=(true|false)/)[1]
      new_state = state == "true" ? "false" : "true"
      content.gsub! "spawn-monsters=#{state}", "spawn-monsters=#{new_state}"

      File.open("server.properties", "w") { |f| f.print content }
      return new_state
    end
  end
end
