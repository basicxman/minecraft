module Minecraft
  # An Extensions instance is meant to process pipes from a Server instance and
  # manage custom functionality additional to default Notchian Minecraft
  # behaviour.
  class Extensions
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
      @users = []
      @counter = 0
      @logon_time = {}
      @server = server
      load_server_properties

      opts = {
        :rules => "No rules specified."
      }.merge(opts)
      opts.each { |k, v| instance_variable_set("@#{k}", v) }

      # Command set.
      @commands = {}
      add_command(:give,       :ops => :hop,  :all => true, :all_message => "is putting out.")
      add_command(:tp,         :ops => :hop,  :all => true, :all_message => "is teleporting all users to their location.")
      add_command(:kit,        :ops => :hop,  :all => true, :all_message => "is providing kits to all.")
      add_command(:kitlist,    :ops => :hop,  :all => false)
      add_command(:help,       :ops => :none, :all => false)
      add_command(:rules,      :ops => :none, :all => false)
      add_command(:nom,        :ops => :hop,  :all => true, :all_message => "is providing noms to all.")
      add_command(:list,       :ops => :none, :all => false)
      add_command(:s,          :ops => :hop,  :all => false)
      add_command(:shortcuts,  :ops => :hop,  :all => false)
      add_command(:hop,        :ops => :op,   :all => false)
      add_command(:dehop,      :ops => :op,   :all => false)
      add_command(:uptime,     :ops => :none, :all => false)
      add_command(:addtimer,   :ops => :hop,  :all => false)
      add_command(:deltimer,   :ops => :hop,  :all => false)
      add_command(:printtimer, :ops => :hop,  :all => false)
      add_command(:printtime,  :ops => :op,   :all => false)
      add_command(:property,   :ops => :op,   :all => false)
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

    # Save the user timers and shortcuts hash to a data file.
    def save
      save_file :timers
      save_file :shortcuts
      save_file :hops
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
      if @commands[root][:ops] == :ops or (is_all and @commands[root][:all])
        return unless validate_ops(user, command)
      elsif @commands[root][:ops] == :hop
        return unless validate_ops(user, command, false) or validate_hops(user, command)
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

    # Add a command to the commands instance hash
    #
    # @param [Symbol] command The command to add.
    # @option opts [Boolean] :all
    #   Whether or not an all version of the command should be made available.
    # @option opts [Boolean] :ops
    #   Whether or not the base command requires ops.
    # @option opts [String] :all_message
    #   The message to print when the all version is used.
    def add_command(command, opts)
      @commands[command] = opts
    end

    # Processes a line from the console.
    def process(line)
      puts line
      return info_command(line) if line.index "INFO"
    rescue Exception => e
      puts "An error has occurred."
      puts e
      puts e.backtrace
    end

    # Checks if the server needs to be saved and prints the save-all command if
    # so.
    def check_save
      if @savefreq.nil?
        freq = 30
      elsif @savefreq == 0
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
      @users.each do |user|
        next unless @timers.has_key? user
        @timers[user].each do |item, duration|
          next if duration.nil?
          @server.puts "give #{user} #{item} 64" if @counter % duration == 0
        end
      end
    end

    # Removes the meta data (timestamp, INFO) from the line and then executes a
    # series of checks on the line.  Grabs the user and command from the line
    # and then calls the call_command method.
    #
    # @param [String] line The line from the console.
    def info_command(line)
      line.gsub! /^.*?\[INFO\]\s+/, ''
      return if meta_check(line)
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
