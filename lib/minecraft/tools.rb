require "net/http"

module Minecraft
  # Methods for external manipulation of the current deployment.
  module Tools
    # Checks if minecraft_server.jar exists and calls the download
    # method if not.
    #
    # @return [void]
    def self.check_jarfile
      download_minecraft unless File.exists? "minecraft_server.jar"
    end

    # Downloads the minecraft server jarfile into the current directory.
    #
    # @return [void]
    def self.download_minecraft
      url = get_minecraft_page
      puts "[+] Downloading Minecraft server from #{url}"
      `wget #{url} -O minecraft_server.jar -q`
    end

    # Parses the miencraft.net download page for the current jarfile URL.
    #
    # @return [String] URL to the current Minecraft jar
    def self.get_minecraft_page
      page = Net::HTTP.get("www.minecraft.net", "/download")
      data = page.match(/href=\"([^>]*?minecraft_server\.jar\?.*?)"/)
      data[1]
    end

    # Generates a command for running the server with default settings including memory.
    #
    # @param [Slop] opts Command line options from Slop, used for memory specification.
    # @return [String]
    def self.command(opts)
      "java -Xmx#{opts[:max_memory] || "1024M"} -Xms#{opts[:min_memory] || "1024M"} -jar minecraft_server.jar nogui"
    end

    # Toggles mobs in server.properties and returns the new state.
    #
    # @return [Boolean]
    def self.toggle_mobs
      return unless File.exists? "server.properties"
      content = File.read("server.properties")
      state = content.match(/spawn\-monsters=(true|false)/)[1]
      new_state = state == "true" ? "false" : "true"
      content.gsub! "spawn-monsters=#{state}", "spawn-monsters=#{new_state}"

      File.open("server.properties", "w") { |f| f.print content }
      return new_state
    end

    # Grabs the extension configuration file and parses it.
    #
    # @return [Hash] Configuration hash.
    def self.get_configuration_file
      return {} unless File.exists? "minecraft.properties"
      File.readlines("minecraft.properties").map { |l| l.split(" ") }.inject({}) do |hash, (key, *value)|
        hash.merge({ key.to_sym => config_value(value) })
      end
    end

    # Parses a value (or set of) from a configuration file.
    #
    # @param [String] An array of values.
    # @return [String] The string value joined together.
    # @return [Boolean] Will return a boolean true if the value is blank (meant
    # to be a boolean configuration flag).
    def self.config_value(value)
      return true if value.nil? or value.length == 0
      return value.join(" ")
    end
  end
end
