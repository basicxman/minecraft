require "open3"

module Minecraft
  class Server
    attr_accessor :sin

    def initialize(command)
      @sin, @sout, @serr = Open3.popen3(command)
      @extensions = Extensions.new(@sin)
      threads = []
      threads << Thread.new { loop { @extensions.process(@sout.gets) } }
      threads << Thread.new { loop { @extensions.process(@serr.gets) } }
      threads << Thread.new { loop { @extensions.periodic; sleep 1 } }
      threads << Thread.new { loop { @sin.puts gets } }
      threads.each(&:join)
    end
  end
end
