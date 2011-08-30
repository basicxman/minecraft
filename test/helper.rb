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
    attr_accessor :commands, :users, :ops, :hops, :counter, :server, :kickvotes, :last_kick_vote, :uptime, :timers, :shortcuts, :userlog, :userpoints, :vote_threshold, :userdnd, :welcome_message, :memos, :todo_items
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
        instance_eval(&block)
      end
    end
    define_method("test_#{name.gsub(/\W/, '_')}", p)
  end
end
