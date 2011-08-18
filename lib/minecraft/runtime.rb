module Minecraft
  class Runtime
    def initialize(opts)
      @opts = opts
      pre_checks

      Minecraft::Tools.check_jarfile
      unless @opts.no_run?
        command = Minecraft::Tools.command(@opts)
        puts "[+] #{command}"
        server = Minecraft::Server.new(command, @opts)
        server.sin.puts("save-on") unless @opts.no_auto_save?
      end
    end

    def pre_checks
      Minecraft::Tools.download_minecraft if @opts.update?
      puts "[+] Temporarily toggling mobs.  Setting to #{Minecraft::Tools.toggle_mobs}." if @opts.tempmobs?
    end
  end
end
