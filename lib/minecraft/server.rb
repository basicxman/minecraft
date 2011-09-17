require "open3"

module Minecraft
  # An instance of the server class will start a Java subprocess running the
  # Minecraft server jarfile.  The interrupt signal will be trapped to run an
  # exit hook and threads will be created to process all pipes.
  class Server
    # @return [IO]
    attr_accessor :sin

    # New Server instance.
    #
    # @param [String] command The command for the subprocess.
    # @param [Slop] opts Command line options from Slop.
    # @example
    #   opts = Slop.new do
    #     ...
    #   end
    #   server = Server.new("java -jar minecraft_server.jar", opts)
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

    # An exit hook, checks if mobs need to be untoggled and saves the server.
    # Server is stopped gracefully.
    #
    # @return [void]
    def minecraft_exit
      puts "[+] Restoring previous mob state to #{Minecraft::Tools.toggle_mobs}." if @opts[:tempmobs]
      puts "[~] The current welcome message is:"
      puts @extensions.welcome_message
      puts "\n[+] Saving..."
      @extensions.save
      @threads.each(&:kill)
      @sin.puts("save-all")
      @sin.puts("stop")
    end
  end
end
