require "open3"

module Minecraft
  class Server
    attr_accessor :sin

    def initialize(command, opts)
      @sin, @sout, @serr = Open3.popen3(command)
      @extensions = Extensions.new(@sin, opts)
      @opts = opts

      trap("SIGINT") { minecraft_exit }

      threads = []
      threads << Thread.new { loop { @extensions.process(@sout.gets) } }
      threads << Thread.new { loop { @extensions.process(@serr.gets) } }
      threads << Thread.new { loop { @extensions.periodic; sleep 1 } }
      threads << Thread.new { loop { @sin.puts gets } }
      threads.each(&:join)
    end
    
    def minecraft_exit
      if @opts.tempmobs?
        puts "[+] Restoring previous mob state."
        Minecraft::Tools.toggle_mobs
      end

      puts "\n[+] Saving..."
      @sin.puts("save-all")
      @sin.puts("exit")
      exit!
    end
  end
end
