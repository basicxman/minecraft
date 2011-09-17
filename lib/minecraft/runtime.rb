module Minecraft
  # An instance of the Runtime class will spool up the server and do any
  # preliminary work.
  class Runtime
    # New Runtime instance.
    #
    # @param [Slop] opts Command line options from slop.
    # @example
    #   opts = Slop.parse do
    #     ...
    #   end
    #   runtime = Runtime.new(opts)
    def initialize(opts)
      @opts = opts
      pre_checks

      Minecraft::Tools.check_jarfile
      unless @opts[:no_run]
        command = Minecraft::Tools.command(@opts)
        puts "[+] #{command}"
        server = Minecraft::Server.new(command, @opts)
        server.sin.puts("save-on") unless @opts[:no_auto_save]
      end
    end

    # Checks if Minecraft needs to be updated, checks if mobs are to be
    # toggled.
    #
    # @return [void]
    def pre_checks
      Minecraft::Tools.download_minecraft if @opts[:update]
      puts "[+] Temporarily toggling mobs.  Setting to #{Minecraft::Tools.toggle_mobs}." if @opts[:tempmobs]
    end
  end
end
