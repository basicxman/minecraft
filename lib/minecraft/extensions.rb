module Minecraft
  # An Extensions instance is meant to process pipes from a Server instance and
  # manage custom functionality additional to default Notchian Minecraft
  # behaviour.
  class Extensions
    attr_accessor :welcome_message
    include Commands

    # New Extensions instance.
    #
    # @param [IO] server The standard input pipe of the server process.
    # @param [Slop] opts Command line options from Slop.
    def initialize(server, opts)
      @ops = File.readlines("ops.txt").map { |s| s.chomp }
      get_json :hops, []
      get_json :uptime
      get_json :timers
      get_json :shortcuts
      get_json :userlog
      get_json :userpoints
      get_json :userdnd, []
      get_json :memos
      get_json :todo_items, []
      @users = []
      @counter = 0
      @logon_time = {}
      @server = server
      @kickvotes = {}
      @last_kick_vote = nil
      load_server_properties

      opts.to_hash.each { |k, v| instance_variable_set("@#{k}", v) }
      @vote_expiration ||= 300
      @vote_threshold  ||= 5
      @rules           ||= "No rules specified."

      # Initialize the set of commands.
      @commands = {}
      commands = Minecraft::Commands.public_instance_methods
      @command_info = File.read(method(commands.first).source_location.first).split("\n")
      @enums = [ :ops ]
      commands.each do |sym|
        next if sym.to_s.end_with? "all"
        meth  = method(sym)
        src_b, src_e = get_comment_range(meth.source_location.last)

        @commands[sym] = {
          :help => "",
          :ops => :none,
          :params => meth.parameters
        }
        parse_comments(src_b, src_e, sym)
      end
    end

    # Parses the comments for a given command method between the two given line
    # numbers.  Places the results in the commands instance hash.
    #
    # @param [Integer] src_b Beginning comment line.
    # @param [Integer] src_e Ending comment line.
    # @param [Symbol] sym Method symbol.
    # @example
    #   parse_comments(6, 13, :disco)
    def parse_comments(src_b, src_e, sym)
      help_done = false
      (src_b..src_e).each do |n|
        line = @command_info[n].strip[2..-1]
        if line.nil?
          help_done = true
          next
        elsif !help_done
          @commands[sym][:help] += " " unless @commands[sym][:help].empty?
          @commands[sym][:help] += line
        end

        if line.index("@note") == 0
          key, value = line[6..-1].split(": ")
          @commands[sym][key.to_sym] = @enums.include?(key.to_sym) ? value.to_sym : value
        end
      end
    end

    # Gets the line number bounds for the comments corresponding with a method
    # on a given line number.
    def get_comment_range(line_number)
      src_e = line_number - 2
      src_b = (0..src_e - 1).to_a.reverse.detect(src_e - 1) { |n| not @command_info[n] =~ /^\s+#/ } + 1
      [src_b, src_e]
    end

    # Sets an instance variable with it's corresponding data file or a blank hash.
    def get_json(var, blank = {})
      file = "#{var}.json"
      t = if File.exists? file
        JSON.parse(File.read(file))
      else
        blank
      end
      instance_variable_set("@#{var}", t)
    end

    # Save instance variables to their respective JSON files.
    def save
      save_file :timers
      save_file :shortcuts
      save_file :hops
      save_file :userpoints
      save_file :userdnd
      save_file :memos
      save_file :todo_items
    end

    # Save an instance hash to it's associated data file.
    #
    # @param [Symbol] var
    # @example
    #   save_file :timers
    def save_file(var)
      File.open("#{var}.json", "w") { |f| f.print instance_variable_get("@#{var}").to_json }
    end

    # Complicated method to decide the logic of calling a command.  Checks
    # if the command requires op privileges and whether an `all` version is
    # available and has been requested.
    #
    # Figures out the root portion of the command, checks if a validation
    # method is available, if so it will be executed.  Then checks if op
    # privileges are required, any `all` version of the command requires
    # ops as it affects all users.  The corresponding method will be called,
    # if an `all` command is used it will call the corresponding method if
    # available or loop through the base command for each connected user.
    #
    # @param [String] user The requesting user.
    # @param [String] command The requested command.
    # @param args Arguments for the command.
    # @example
    #   call_command("basicxman", "give", "cobblestone", "64")
    def call_command(user, command, *args)
      is_all = command.to_s.end_with? "all"
      root   = command.to_s.chomp("all").to_sym
      return send(root, user, *args) unless @commands.include? root

      # Any `all` suffixed command requires ops.
      if @commands[root][:ops] == :op or (is_all and @commands[root][:all])
        return unless validate_ops(user, command)
      elsif @commands[root][:ops] == :hop
        return unless validate_ops(user, command, false) or validate_hops(user, command)
      end

      if respond_to? "validate_" + root.to_s
        return unless send("validate_" + root.to_s, *args)
      end

      is_all = @commands[root][:all] if is_all
      rest_param = @commands[root][:params].count { |a| a.first == :rest }
      reg_params = @commands[root][:params].count { |a| a.last != :user }

      # Remove excess parameters.
      args = args[0...reg_params] if args.length > reg_params and rest_param == 0

      args = [user] + args unless @commands[root][:params].length == 0
      if is_all
        @server.puts "say #{user} #{@commands[root][:all]}"
        if respond_to? command
          send(command, *args)
        else
          @users.each { |u| send(root, u, *args[1..-1]) unless @userdnd.include? u.downcase }
        end
      else
        send(root, *args)
      end
    rescue Exception => e
      validate_command_entry(rest_param, reg_params, user, command, *args)
      $stderr.puts "An error has occurred during a call command operation.\n#{e}"
      $stderr.puts e.backtrace
    end

    # After an exception is caught this method should be called to find and
    # print errors with the arguments specified to the command.
    #
    # @param [String] user The requesting user.
    # @param [String] command The requested command.
    # @param args Arguments for the command.
    # @example
    #   call_command("basicxman", "give")
    def validate_command_entry(rest_param, reg_params, user, command, *args)
      args.slice! 0 if args.first == user
      params = @commands[command.to_sym][:params][1..-1].map { |a| [a[0], a[1].to_s.gsub("_", " ")] }
      return unless args.length < reg_params

      return @server.puts "say Expected at least one argument." if rest_param == 1
      req_params = params.count { |a| a.first == :req }
      if args.length < req_params
        args.length.times { params.slice! 0 }
        if params.length == 1
          return @server.puts "say Expected the argument '#{params[0][1]}'"
        else
          temp = params.map { |a| "'#{a[1]}'" }
          return @server.pust "say Expected additional arguments, #{temp.join(", ")}"
        end
      end
    end

    # Processes a line from the console.
    def process(line)
      puts colour(line.dup)
      return info_command(line) if line.index "INFO"
    rescue Exception => e
      $stderr.puts "An error has occurred during line processing.\n#{e}"
      $stderr.puts e.backtrace
    end

    # Colours a server side line
    def colour(line)
      return line if @no_colour
      line.gsub!(/^([0-9\-]{10}\s[0-9:]{8})/) { |m| "\033[0;37m#{$1}\033[0m" }
      if line.index "lost connection" or line.index "logged in"
        line.gsub!(/(\[INFO\]\s)(.*)/) { |m| "#{$1}\033[1;30m#{$2}\033[0m" }
      elsif line.index "[INFO] CONSOLE:"
        line.gsub!("CONSOLE:", "\033[1;36mCONSOLE:\033[0m")
      else
        line.gsub!(/(\[INFO\]\s+\<)(.*?)(\>)/) { |m| "#{$1}\033[1;34m#{$2}\033[0m#{$3}" }
        line.gsub!(/(\>\s+)(!.*?)$/) { |m| "#{$1}\033[1;33m#{$2}\033[0m" }
      end
      return line
    end

    # Checks if the server needs to be saved and prints the save-all command if
    # so.
    def check_save
      if @savefreq.nil?
        freq = 30
      elsif @savefreq == "0"
        return
      else
        freq = @savefreq.to_i
      end
      if @counter % freq == 0
        @server.puts "save-all"
        save
      end
    end

    # Increments the counter and checks if any timers are needed to be
    # executed.
    def periodic
      @counter += 1
      check_save
      if @disco
        if @counter % 2 == 0
          @server.puts "time set 0"
        else
          @server.puts "time set 16000"
        end
      end

      if @counter % 10 == 0
        expire_kickvotes
        if @time_change and @time_change != 0
          @server.puts "time add #{@time_change}"
        end
      end

      @users.each do |user|
        next unless @timers.has_key? user
        @timers[user].each do |item, duration|
          next if duration.nil?
          @server.puts "give #{user} #{item} 64" if @counter % duration == 0
        end
      end
    end

    # Checks the available memos for a uesr who has just logged in, prints any
    # that are found.
    #
    # @param [String] user The user to check.
    # @example
    #   check_memos("mike_n_7")
    def check_memos(user)
      user = user.downcase
      return unless @memos.has_key? user

      @memos[user].each do |m|
        @server.puts "say Message from: #{m.first} - #{m.last}"
      end
      @memos[user] = []
    end

    # Removes the meta data (timestamp, INFO) from the line and then executes a
    # series of checks on the line.  Grabs the user and command from the line
    # and then calls the call_command method.
    #
    # @param [String] line The line from the console.
    def info_command(line)
      line.gsub! /^.*?\[INFO\]\s+/, ''
      return if meta_check(line)

      # :foo should use the shortcut 'foo'.
      line.gsub!(/^(\<.*?\>\s+):/) { |m| "#{$1}!s " }

      match_data = line.match /^\<(.*?)\>\s+!(.*?)$/
      return if match_data.nil?

      user = match_data[1]
      args = match_data[2].split(" ")
      call_command(user, args.slice!(0).to_sym, *args)
    end

    # Executes the meta checks (kick/ban, ops, join/disconnect) and returns true
    # if any of them were used (and thus no further processing required).
    #
    # @param [String] line The passed line from the console.
    def meta_check(line)
      return true if check_kick_ban(line)
      return true if check_ops(line)
      return true if check_join_part(line)
    end

    # Removes the specified user as from the connected players array.
    #
    # @param [String] user The specified user.
    # @return [Boolean] Always returns true.
    def remove_user(user)
      @users.reject! { |u| u.downcase == user.downcase }
      return true
    end

    # Check if a console line has informed us about a ban or kick.
    def check_kick_ban(line)
      user = line.split(" ").last
      if line.index "Banning"
        return remove_user(user)
      elsif line.index "Kicking"
        return remove_user(user)
      end
    end

    # Check if a console line has informed us about a [de-]op privilege change.
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

    # Check if a console line has informed us about a player [dis]connecting.
    def check_join_part(line)
      user = line.split(" ").first
      if line.index "lost connection"
        log_time(user)
        return remove_user(user)
      elsif line.index "logged in"
        @users << user
        display_welcome_message(user)
        check_memos(user)
        @logon_time[user] = Time.now
        return true
      end
    end

    # If a command method is called and is not specified, take in the arguments
    # here and attempt to !give the player the item.  Otherwise print an error.
    def method_missing(sym, *args)
      item, quantity = items_arg(1, [sym.to_s.downcase, args.last])
      item = resolve_item(item)
      if item and is_op? args.first
        give(args.first, item, quantity.to_s)
      else
        puts "#{item} is invalid."
      end
    end

    # Calculate and print the time spent by a recently disconnected user.  Save
    # the user uptime log.
    def log_time(user)
      time_spent = calculate_uptime(user)
      @userlog[user] ||= 0
      @userlog[user] += time_spent
      @server.puts "say #{user} spent #{format_uptime(time_spent)} minutes in the server, totalling to #{format_uptime(@userlog[user])}."
      save_file :userlog
    end

    # Format an uptime for printing.  Should not be used for logging.
    #
    # @param [Integer] time Time difference in seconds.
    # @return [Float] Returns the number of minutes rounded to two precision.
    def format_uptime(time)
      (time / 60.0).round(2)
    end

    # Calculate a users current uptime.
    #
    # @param [String] user The specified user.
    # @return [Integer] The uptime in seconds.
    def calculate_uptime(user)
      Time.now - (@logon_time[user] || 0)
    end

    # Check if a user has op privileges.
    #
    # @param [String] user The specified user.
    # @return [Boolean]
    def is_op?(user)
      @ops.include? user.downcase
    end

    # Check if a user has half op privileges.
    #
    # @param [String] user The specified user.
    # @return [Boolean]
    def is_hop?(user)
      @hops.include? user.downcase
    end

    # Check if a user has op privileges and print a privilege error if not.
    #
    # @param [String] user The specified user.
    # @param [String] command The command they tried to use.
    # @return [Boolean] Returns true if the user is an op.
    def validate_ops(user, command, message = true)
      return true if is_op? user.downcase
      @server.puts "say #{user} is not an op, cannot use !#{command}." if message
    end

    # Check if a user has half op privileges and print a privilege error if not.
    #
    # @param [String] user The specified user.
    # @param [String] command The command they tried to use.
    # @return [Boolean] Returns true if the user is an op.
    def validate_hops(user, command, message = true)
      return true if is_hop? user.downcase
      @server.puts "say #{user} is not a half-op, cannot use !#{command}." if message
    end

    # An error message for invalid commands.
    def invalid_command(command)
      @server.puts "say #{command} is invalid."
    end

    # Load the server.properties file into a Ruby hash.
    def load_server_properties
      @server_properties = {}
      File.readlines("server.properties").each do |line|
        next if line[0] == "#"
        key, value = line.split("=")
        @server_properties[key] = value
      end
    end

    # Display a welcome message to a recently connected user.
    def display_welcome_message(user)
      @server.puts "say #{@welcome_message.gsub('%', user)}" unless @welcome_message.nil?
    end
  end
end
