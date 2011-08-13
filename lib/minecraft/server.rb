require "open3"

module Minecraft
  class Server
    attr_accessor :sin

    def initialize(command)
      @extensions = Extensions.new
      @sin, @sout, @serr = Open3.popen3(command)
      threads = []
      threads << Thread.new { loop { process(@sout.gets) } }
      threads << Thread.new { loop { process(@serr.gets) } }
      threads << Thread.new { loop { mc_exec @extensions.periodic; sleep 1 } }
      threads << Thread.new { loop { @sin.puts gets } }
      threads.each(&:join)
    end

    def process(line)
      result = @extensions.process(line)
      @sin.puts(result) unless result.nil?
    end

    def mc_exec(commands)
      @sin.puts(commands) unless commands == ""
    end
  end
end
