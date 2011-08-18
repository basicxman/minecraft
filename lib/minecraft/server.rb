require "open3"

module Minecraft
  class Server
    attr_accessor :sin

    def initialize(command, opts)
      @sin, @sout, @serr, @thr = Open3.popen3(command)
      @extensions = Extensions.new(@sin, opts)
      @opts = opts

      trap("SIGINT") { minecraft_exit }

      @threads = []
      @threads << Thread.new { loop { @extensions.process(@sout.gets) } }
      @threads << Thread.new { loop { @extensions.process(@serr.gets) } }
      @threads << Thread.new { loop { @extensions.periodic; sleep 1 } }
      @threads << Thread.new { loop { @sin.puts $stdin.gets } }
      @thr.value
      exit!
    end
    
    def minecraft_exit
      puts "[+] Restoring previous mob state to #{Minecraft::Tools.toggle_mobs}." if @opts.tempmobs?
      puts "\n[+] Saving..."
      @extensions.save
      @threads.each(&:kill)
      @sin.puts("save-all")
      @sin.puts("stop")
    end
  end
end
