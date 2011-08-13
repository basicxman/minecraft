module Minecraft
  class Extensions
    include Commands

    def initialize
      @ops = File.readlines("ops.txt").map { |s| s.chomp }
      @users = []

      # Command set.
      @commands = {}
      add_command(:give, :ops => true,  :all => true, :all_message => "is putting out.")
      add_command(:tp,   :ops => false, :all => true, :all_message => "is teleporting all users to their location.")
      add_command(:kit,  :ops => true,  :all => true, :all_message => "is providing kits to all.")
      add_command(:help, :ops => false, :all => false)
      add_command(:nom,  :ops => true,  :all => true, :all_message => "is providing noms to all.")
    end

    def call_command(user, command, *args)
      is_all = command.to_s.end_with? "all"
      root   = command.to_s.chomp("all").to_sym
      return invalid_command(command) unless @commands.include? root

      # Any `all` suffixed command requires ops.
      if @commands[root][:ops] or (is_all and @commands[root][:all])
        return privilege_error(user, command) unless is_op? user
      end

      if respond_to? "validate_" + root.to_s
        result = send("validate_" + root.to_s, *args)
        return result unless result.nil?
      end

      if is_all
        ret = "say #{user} #{@commands[root][:all_message]}\n"
        if respond_to? command
          ret += send(command, user, *args)
        else
          @users.each { |u| ret += send(root, u, *args) + "\n" }
        end
      else
        ret = send(root, user, *args)
      end
      return ret.chomp
    end

    def add_command(command, opts)
      @commands[command] = opts
    end

    def process(line)
      puts line
      return info_command(line) if line.index "INFO"
    rescue Exception => e
      puts "An error has occurred."
      puts e
    end

    def info_command(line)
      line.gsub! /^.*?\[INFO\]\s+/, ''
      return if meta_check(line)
      match_data = line.match /^\<(.*?)\>\s+!(.*?)$/
      return if match_data.nil?

      user = match_data[1]
      args = match_data[2].split(" ")
      return call_command(user, args.slice!(0).to_sym, *args)
    end

    def meta_check(line)
      return true if check_ops(line)
      return true if check_join_part(line)
    end

    def check_ops(line)
      user = line.split(" ").last
      if line.index "De-opping"
        @ops.reject! { |u| u == user }
        return true
      elsif line.index "Opping"
        @ops << user
        return true
      end
    end

    def check_join_part(line)
      user = line.split(" ").first
      if line.index "lost connection"
        @users.reject! { |u| u == user }
        return true
      elsif line.index "logged in"
        @users << user
        return true
      end
    end

    def method_missing(sym, *args)
      if DATA_VALUE_HASH.has_key? sym.downcase and is_op? args.first
        give(args.first, sym, args.last)
      else
        puts "Invalid command given."
      end
    end

    def is_op?(user)
      @ops.include? user
    end

    def privilege_error(user, command)
      "say #{user} is not an op, cannot use !#{command}."
    end

    def invalid_command(command)
      "say #{command} is invalid."
    end
  end
end
