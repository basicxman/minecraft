unless Object.const_defined? 'Minecraft'
  $:.unshift File.expand_path("../../lib", __FILE__)
  require "minecraft"
end

require "minitest/autorun"
require "stringio"
require "turn"

class Test < MiniTest::Unit::TestCase
  def self.test(name, &block)
    define_method("test_#{name.gsub(/\W/, '_')}", block)
  end
end
