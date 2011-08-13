# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "minecraft/version"

Gem::Specification.new do |s|
  s.name        = "minecraft"
  s.version     = Minecraft::VERSION
  s.authors     = ["Andrew Horsman"]
  s.email       = ["self@andrewhorsman.net"]
  s.summary     = "Minecraft server wrapper and deployment."
  s.description = "A server console wrapper and other Minecraft deployment tools."

  s.homepage = "http://github.com/basicxman/minecraft"

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'slop'
end
