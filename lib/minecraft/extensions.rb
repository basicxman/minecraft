require "json/pure"

module Minecraft
  class Extensions
    include Commands

    def initialize(server, rules = "No rules specified.")
      @ops = File.readlines("ops.txt").map { |s| s.chomp }
      @userlog = get_user_log
      @users = []
      @timers = {}
      @counter = 0
      @logon_time = {}
      @server = server
      @rules = rules
      load_server_properties

      # Command set.
      @commands = {}
      add_command(:give,  :ops => true,  :all => true, :all_message => "is putting out.")
      add_command(:tp,    :ops => false, :all => true, :all_message => "is teleporting all users to their location.")
      add_command(:kit,   :ops => true,  :all => true, :all_message => "is providing kits to all.")
      add_command(:help,  :ops => false, :all => false)
      add_command(:rules, :ops => false, :all => false)
      add_command(:nom,   :ops => true,  :all => true, :all_message => "is providing noms to all.")
      add_command(:list,  :ops => false, :all => false)
      add_command(:uptime,     :ops => false, :all => false)
      add_command(:addtimer,   :ops => true,  :all => false)
      add_command(:deltimer,   :ops => true,  :all => false)
      add_command(:printtimer, :ops => true,  :all => false)
      add_command(:kitlist,    :ops => false, :all => false)
      add_command(:property,   :ops => true,  :all => false)
    end

    def get_user_log
      if File.exists? "user.log"
        JSON.parse(File.read("user.log"))
      else
        {}
      end
    end

    def write_log
      File.open("user.log", "w") { |f| f.print @userlog.to_json }
    end

    def call_command(user, command, *args)
      is_all = command.to_s.end_with? "all"
      root   = command.to_s.chomp("all").to_sym
      return invalid_command(command) unless @commands.include? root

      # Any `all` suffixed command requires ops.
      if @commands[root][:ops] or (is_all and @commands[root][:all])
        return if !validate_ops(user, command)
      end

      if respond_to? "validate_" + root.to_s
        return unless send("validate_" + root.to_s, *args)
      end

      if is_all
        @server.puts "say #{user} #{@commands[root][:all_message]}"
        if respond_to? command
          send(command, user, *args)
        else
          @users.each { |u| send(root, u, *args) }
        end
      else
        send(root, user, *args)
      end
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
      puts e.backtrace
    end

    def periodic
      @counter += 1
      @users.each do |user|
        next unless @timers.has_key? user
        @timers[user].each do |item, duration|
          next if duration.nil?
          @server.puts "give #{user} #{item} 64" if @counter % duration == 0
        end
      end
    end

    def info_command(line)
      line.gsub! /^.*?\[INFO\]\s+/, ''
      return if meta_check(line)
      match_data = line.match /^\<(.*?)\>\s+!(.*?)$/
      return if match_data.nil?

      user = match_data[1]
      args = match_data[2].split(" ")
      call_command(user, args.slice!(0).to_sym, *args)
    end

    def meta_check(line)
      return true if check_kick_ban(line)
      return true if check_ops(line)
      return true if check_join_part(line)
    end

    def remove_user(user)
      @users.reject! { |u| u.downcase == user.downcase }
      return true
    end

    def check_kick_ban(line)
      user = line.split(" ").last
      if line.index "Banning"
        return remove_user(user)
      elsif line.index "Kicking"
        return remove_user(user)
      end
    end

    def check_ops(line)
      user = line.split(" ").last
      if line.index "De-opping"
        @ops.reject! { |u| u == user.downcase }
        return true
      elsif line.index "Opping"
        @ops << user.downcase
        return true
      end
    end

    def check_join_part(line)
      user = line.split(" ").first
      if line.index "lost connection"
        log_time(user)
        return remove_user(user)
      elsif line.index "logged in"
        @users << user
        @logon_time[user] = Time.now
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

    def log_time(user)
      time_spent = calculate_uptime(user)
      @userlog[user] ||= 0
      @userlog[user] += time_spent
      @server.puts "say #{user} spent #{format_uptime(time_spent)} minutes the server, totalling to #{format_uptime(@userlog[user])}."
      write_log
    end

    def format_uptime(time)
      (time / 60.0).round(2)
    end

    def calculate_uptime(user)
      Time.now - @logon_time[user]
    end

    def is_op?(user)
      @ops.include? user.downcase
    end

    def validate_ops(user, command)
      return true if is_op? user
      @server.puts "say #{user} is not an op, cannot use !#{command}."
    end

    def invalid_command(command)
      @server.puts "say #{command} is invalid."
    end

    def load_server_properties
      @server_properties = {}
      File.readlines("server.properties").each do |line|
        next if line[0] == "#"
        key, value = line.split("=")
        @server_properties[key] = value
      end
    end
  end
end
