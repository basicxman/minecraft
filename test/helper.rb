unless Object.const_defined? 'Minecraft'
  $:.unshift File.expand_path("../../lib", __FILE__)
  require "minecraft"
end

require "minitest/autorun"
require "fileutils"
require "stringio"
require "turn"

module Minecraft
  class Extensions
    attr_accessor :commands, :users, :ops, :hops, :counter, :server, :userkickvotes, :last_kick_vote, :useruptime, :timers, :usershortcuts, :userlog, :userpoints, :vote_threshold, :userdnd, :welcome_message, :memos, :todo_items, :command_history
  end
end

class Test < MiniTest::Unit::TestCase
  # Standard test.
  def self.test(name, &block)
    define_method("test_#{name.gsub(/\W/, '_')}", block)
  end

  # Sandbox test which creates a sandboxed environment for a mocked Minecraft
  # server to run in.
  def self.sandbox_test(name, &block)
    p = Proc.new do
      FileUtils.mkdir("mc") unless File.exists? "mc"
      FileUtils.cd("mc") do
        FileUtils.touch("ops.txt")
        FileUtils.touch("server.properties")
        FileUtils.rm_f("command_history.json")
        instance_eval(&block)
      end
    end
    define_method("test_#{name.gsub(/\W/, '_')}", p)
  end

  def ext(opts = {})
    @ext = Minecraft::Extensions.new(StringIO.new, {})
    @ext.ops  = opts[:ops]  || []
    @ext.hops = opts[:hops] || []
    @ext.users = @ext.ops + @ext.hops + (opts[:users] || [])
    @ext.users.uniq!
  end

  def call(string)
    @ext.call_command(*string.split(" "))
  end

  def output
    @ext.server.string
  end

  def output_lines
    output.split("\n")
  end

  def output_line
    output.gsub("\n", "")
  end

  def clear
    @ext.server.string = ""
  end
end
