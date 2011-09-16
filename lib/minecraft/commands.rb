module Minecraft
  # Contains all the methods for console commands executed by a connected
  # player.
  module Commands
    include Data

    # Switch to creative mode.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The target user.
    # @example
    #   creative("basicxman")
    # @return [void]
    # @note ops: op
    def creative(user, target_user = user)
      puts target_user
      @server.puts "gamemode #{target_user} 1"
    end

    # Switch to normal mode.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The targetuser.
    # @example
    #   normal("basicxman")
    # @return [void]
    # @note ops: op
    def normal(user, target_user = user)
      @server.puts "gamemode #{target_user} 0"
    end

    # Allows a user to specify a periodic (once every ten seconds) time change.
    #
    # @param [String] user The requesting user.
    # @param [Integer] time_change Amount of time to add (can be negative or
    # positive) every ten seconds.
    # @example
    #   warptime("basicxman", "5")
    #   warptime("basicxman")
    # @return [void]
    # @note ops: op
    def warptime(user, time_change = nil)
      if time_change.nil?
        return @server.puts "say Current rate: #{@time_change} every ten seconds." if @time_change
        return @server.puts "say No custom rate specified."
      end

      time_change = time_change.to_i
      if time_change < 0
        @time_change = [-1000, time_change].max
      else
        @time_change = [1000, time_change].min
      end

      @server.puts "say New rate: #{@time_change} every ten seconds."
    end

    # Adds a memo for the specified user.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The target user.
    # @param args The memo.
    # @example
    #   memo("basicxman", "mike_n_7", "Hi!")
    # @return [void]
    # @note ops: none
    def memo(user, target_user, *args)
      target_user = target_user.downcase

      if @memos.has_key? target_user and @memos[target_user].length == 5
        return @server.puts "say #{target_user} has too many memos already!"
      end

      @memos[target_user] ||= []
      @memos[target_user] << [user, args.join(" ")]

      say "Memo for #{target_user} added. Will be printed next time s/he logs in."
    end

    # Stops all timers for a user.
    #
    # @param [String] user The requesting user.
    # @example
    #   stop("basicxman")
    # @return [void]
    # @note ops: hop
    def stop(user)
      @timers.delete user
      @server.puts "say #{user} has stopped all his/her timers."
    end

    # Changes or appends to the welcome message.  Use !welcome + foo to add foo.
    #
    # @param [String] user The requesting user.
    # @param args The welcome message.
    # @example
    #   welcome("basicxman", "Welcome", "to", "the", "server")
    #   welcome("basicxman", "+", "%")
    # @return [void]
    # @note ops: op
    def welcome(user, *args)
      if args.first == "+"
        @welcome_message += " " + args[1..-1].join(" ")
        @server.puts "say Appended to welcome message."
      else
        @welcome_message = args.join(" ")
        @server.puts "say Changed welcome message."
      end

      display_welcome_message("basicxman")
    end

    # Changes to dawn.
    #
    # @example
    #   dawn()
    # @note ops: op
    # @return [void]
    def dawn()
      change_time(:dawn)
    end

    # Changes to dusk.
    #
    # @example
    #   dusk()
    # @note ops: op
    # @return [void]
    def dusk()
      change_time(:dusk)
    end

    # Changes to day.
    #
    # @example
    #   day()
    # @note ops: op
    # @return [void]
    def day()
      change_time(:day)
    end

    # Changes to night.
    #
    # @example
    #   night()
    # @note ops: op
    # @return [void]
    def night()
      change_time(:night)
    end

    # Changes to morning.
    #
    # @example
    #   morning()
    # @note ops: op
    # @return [void]
    def morning()
      change_time(:morning)
    end

    # Changes to evening.
    #
    # @example
    #   evening()
    # @note ops: op
    # @return [void]
    def evening()
      change_time(:evening)
    end

    # Toggles disco.
    #
    # @param [String] user The requesting user.
    # @example
    #   disco("basicxman")
    # @note ops: op
    # @return [void]
    def disco(user)
      if @disco
        @server.puts "say Disco ends."
        @disco = false
      else
        say("#{user} has requested disco, s/he likely can't actually dance.")
        @disco = true
      end
    end

    # Stops users from disturbing you.
    #
    # @param [String] user The requesting user.
    # @example
    #   dnd("basicxman")
    # @note ops: none
    # @return [void]
    def dnd(user)
      user = user.downcase

      if @userdnd.include? user
        say("#{user} is ready to be disturbed. *cough*")
        @userdnd.delete user
      else
        say("#{user} does not wish to be disturbed.")
        @userdnd << user
      end
    end

    # Removes somebody from the DND list.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The target user.
    # @example
    #   disturb("basicxman", "mike_n_7")
    # @note ops: op
    # @return [void]
    def disturb(user, target_user)
      say("#{target_user} is being disturbed by #{user}!")
      @userdnd.delete target_user.downcase
    end

    # Prints the users who do not wish to be disturbed.
    #
    # @param [String] user The requesting user.
    # @example
    #   printdnd()
    # @note ops: op
    # @return [void]
    def printdnd()
      @server.puts "say #{@userdnd.join(", ")}"
    end

    # Gives a user a specific amount of points, the quantity is capped
    # depending on the privileges of the user.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The target user to give points to.
    # @param [Integer] points Quantity of points to give.
    # @example
    #   points("basicxman", "mike_n_7")
    #   points("basicxman", "mike_n_7", "50")
    # @note ops: none
    # @return [void]
    def points(user, target_user, num_points = 1)
      target_user = target_user.downcase
      num_points  = num_points.to_i
      @userpoints[target_user] ||= 0

      if user.downcase == target_user
        say("Did you just try to give yourself points? Sure, minus twenty.")
        @userpoints[target_user] -= 20
      elsif num_points < 0
        @server.puts "say Subtracting points? For shame."
        @userpoints[user] -= num_points
      else
        num_points = [num_points, cap_points(user)].min
        @userpoints[target_user] += num_points

        say("#{user} has given #{target_user} #{num_points} points for a total of #{@userpoints[target_user]}.")
      end
    end

    # Checks a users points or displays the leaderboard.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The user to check points of.
    # @example
    #   board("basicxman")
    #   board("basicxman", "mike_n_7")
    # @note ops: none
    # @return [void]
    def board(user, target_user = nil)
      if target_user.nil?
        leaderboard = {}
        @userpoints.each do |u, p|
          leaderboard[p] ||= []
          leaderboard[p] << u
        end
        num_to_display = 5

        leaderboard.sort {|one, other| other <=> one}.each do |points, users|
          users.each do |u|
            return unless num_to_display >= 1
            @server.puts "say #{u}: #{points}"
            num_to_display -= 1
          end
        end
      else
        if @userpoints.has_key? target_user
          @server.puts "say #{u}: #{@userpoints[u]}"
        end
      end
    end

    # Initiates or votes for a specific user to be kicked, since half-ops and
    # regular connected players cannot kick users they can initiate a vote
    # instead.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The target user to be kicked if the vote
    # succeeds.
    # @example
    #   kickvote("basicxman", "blizzard4U")
    #   kickvote("basicxman")
    # @note ops: none
    # @return [void]
    def kickvote(user, target_user = nil)
      return vote(user) if target_user.nil?
      return if submit_vote(user, target_user)

      @userkickvotes[target_user] = {
        :tally => kick_influence(user),
        :votes => [user],
        :start => Time.now
      }
      @last_kick_vote = target_user

      say("A kickvote has been initiated for #{target_user}.")
      say("To vote enter !kickvote #{target_user}.")
    end

    # Votes for the last initiated kickvote.
    #
    # @param [String] user The requesting user.
    # @example
    #   vote("basicxman")
    # @note ops: none
    # @return [void]
    def vote(user)
      unless submit_vote(user, @last_kick_vote)
        @server.puts "say No kickvote was initiated, dummy."
      end
    end

    # Cancels a kickvote initiation for a specific user.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The user which currently has a kickvote.
    # @example
    #   cancelvote("basicxman", "blizzard4U")
    # @note ops: op
    # @return [void]
    def cancelvote(user, target_user)
      if @userkickvotes.has_key? target_user
        @userkickvotes.delete(target_user)
        say("#{user} has cancelled the kickvote on #{target_user}.")
      else
        say("There is no kickvote against #{target_user} dummy.")
      end
    end

    # Displays all current kickvote initiations.
    #
    # @param [String] user The requesting user.
    # @example
    #   kickvotes("basicxman")
    # @note ops: op
    # @return [void]
    def kickvotes(user)
      @userkickvotes.each do |target_user, data|
        say("#{target_user}: #{data[:tally]} #{data[:votes]}")
      end
    end

    # Kicks a random person, the requesting user has a higher chance of being
    # picked.
    #
    # @param [String] user The requesting user.
    # @example
    #   roulette("basicxman")
    # @note ops: op
    # @return [void]
    def roulette(user)
      users       = @users + [user] * 3
      picked_user = users.sample

      say("#{user} has requested a roulette kick, s/he has a higher chance of being kicked.")
      @server.puts "kick #{picked_user}"
    end

    # Gives half-op privileges to the target user.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The target user to be hop'ed.
    # @example
    #   hop("basicxman", "blizzard4U")
    # @note ops: op
    # @return [void]
    def hop(user, target_user)
      @hops << target_user.downcase unless @hops.include? target_user.downcase
      @server.puts "#{target_user} is now a hop, thanks #{user}!"
    end

    # De-half-ops the target user.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The target user to be de-hop'ed.
    # @example
    #   dehop("basicxman", "blizzard4U")
    # @note ops: op
    # @return [void]
    def dehop(user, target_user)
      @hops.delete target_user.downcase
      @server.puts "#{target_user} has been de-hoped, thanks #{user}!"
    end

    # Give command takes an item name or numeric id and a quantifier.  If a
    # quantifier is not specified then the quantity defaults to 1.  Items will
    # try to resolved if they are not an exact match.
    #
    # @param [String] user Target user of the command.
    # @example
    #   give("basicxman", "cobblestone")
    #   give("basicxman", "cobblestone", "9m")
    #   give("basicxman", "flint", "and", "steel", "1")
    #   give("basicxman", "4")
    # @note ops: hop
    # @note all: is putting out.
    # @return [void]
    def give(user, *args)
      item, quantity = items_arg(1, args)
      # For coloured wools/dyes.
      if WOOL_COLOURS.include? item
        (quantity / 64.0).ceil.times { kit(user, item) }
        item = 35
      else
        item = resolve_item(item)
      end

      construct_give(user, item, quantity)
    end

    # Kit command takes a group name and gives the contents of the kit to the
    # target user.
    #
    # @param [String] user Target user of the command.
    # @param [String] group Label of the kit.
    # @example
    #   give("basicxman", "diamond")
    # @note ops: hop
    # @note all: is providing kits to all.
    # @return [void]
    def kit(user, group)
      KITS[group.to_sym].each do |item|
        if item.is_a? Array
          @server.puts construct_give(user, item.first, item.last)
        else
          @server.puts "give #{user} #{item} 1"
        end
      end
    end

    # Teleports the current user to the target user.
    #
    # @param [String] user Current user.
    # @param [String] target User to teleport to.
    # @example
    #   tp("basicxman", "mike_n_7")
    # @note ops: hop
    # @note all: is teleporting all users to their location.
    # @return [void]
    def tp(user, target)
      return if check_dnd(target)
      @server.puts "tp #{user} #{target}"
    end

    # Teleports all users to the target user.  Overrides !tpall.
    #
    # @param [String] user Current (target) user.
    # @example
    #   tpall("basicxman")
    # @return [void]
    def tpall(user)
      @users.each { |u| tp(u, user) unless @userdnd.include? u.downcase }
    end

    # Gives a golden apple to the specified user.
    #
    # @param [String] user Target user.
    # @example
    #   nom("basicxman")
    # @note ops: hop
    # @note all: is providing noms to all.
    # @return [void]
    def nom(user)
      @server.puts "give #{user} 322 1"
    end

    # Gives multiple golden apples to the specified user.
    #
    # @param [String] user Target user.
    # @param args noms!
    # @example
    #   om("basicxman", "nom", "nom", "nom")
    # @note ops: hop
    # @note all: is noming everybody, gross.
    # @return [void]
    def om(user, *args)
      args.length.times { nom(user) }
    end

    # Outputs the current value of a server property.
    #
    # @param [String] user The requesting user.
    # @param [String] key The server property requested.
    # @example
    #   property("basicxman", "spawn-monsters")
    #   property("basicxman")
    # @note ops: op
    # @return [void]
    def property(user, key = nil)
      if key.nil?
        say(@server_properties.keys.join(", "))
      else
        say("#{key} is currently #{@server_properties[key]}") if @server_properties.include? key
      end
    end

    # Checks the current uptime of the current or target user.  Prints their
    # connected uptime and their total uptime.  If no target user is specified
    # it will check the requesting user.
    #
    # @param [String] user The requesting user.
    # @param [String] target_user The user to check.
    # @example
    #   uptime("basicxman")
    #   uptime("basicxman", "mike_n_7")
    # @note ops: none
    # @return [void]
    def uptime(user, target_user = user)
      unless @users.include? target_user
        if @userlog.has_key? target_user
          say("#{target_user} has #{format_uptime(@userlog[target_user])} minutes of logged time.")
        else
          say("#{target_user} Does not exist.")
        end
        return
      end

      time_spent = calculate_uptime(target_user)

      if @userlog.has_key? target_user
        total = "  Out of a total of #{format_uptime(@userlog[target_user] + time_spent)} minutes."
      end

      say("#{target_user} has been online for #{format_uptime(time_spent)} minutes.#{total}")
    end

    # Will print the server rules to all connected players.
    #
    # @example
    #   rules()
    # @note ops: none
    # @return [void]
    def rules()
      say(@rules)
    end

    # Lists the currently connecting players, noting which is the requesting
    # user and which users are ops.
    #
    # @param [String] user The requesting user.
    # @example
    #   list("basicxman")
    # @note ops: none
    # @return [void]
    def list(user)
      l = @users.map { |u|
        pre, suf = "", ""
        if u == user
          pre = "["
          suf = "]"
        end
        pre = pre + "@" if is_op? u
        pre = pre + "%" if is_hop? u

        pre + u + suf
      }.join(", ")

      say(l)
    end

    # Adds a timer to the requesting users timers, the item and frequency in
    # seconds of the timer should be specified.  If the timer already exists
    # for that item, the frequency is re-assigned.  If the frequency is
    # unspecified, it will default to 30.
    #
    # @param [String] user The requesting user.
    # @param args item, frequency
    # @example
    #   addtimer("basicxman", "cobblestone")
    #   addtimer("basicxman", "arrow", "10")
    # @note ops: hop
    # @return [void]
    def addtimer(user, *args)
      item, duration = items_arg(30, args)
      item           = resolve_item(item)

      return @server.puts "say Timer was not added." if item.nil?

      @timers[user]     ||= {}
      @timers[user][item] = duration

      say("Timer added for #{user}.  Giving item id #{item} every #{duration} seconds.")
    end

    # Deletes a timer from the requesting user.
    #
    # @param [String] user The requesting user.
    # @param args item
    # @example
    #   deltimer("basicxman", "cobblestone")
    # @note ops: hop
    # @return [void]
    def deltimer(user, *args)
      item = args.join(" ")
      item = resolve_item(item)

      if @timers.has_key? user
        @timers[user].delete item
        @server.puts "say #{item} timer is deleted."
      else
        @server.puts "say #{item} timer did not exist."
      end
    end

    # Prints the requesting user's current timers.
    #
    # @param [String] user The requesting user.
    # @example
    #   printtimer("basicxman")
    # @note ops: hop
    # @return [void]
    def printtimer(user)
      if not @timers.has_key? user || @timers[user].length == 0
        @server.puts "say No timers have been added for #{user}."
        return
      end

      @timers[user].each do |item, frequency|
        @server.puts "say #{item} every #{frequency} seconds."
      end
    end

    # Prints the current value of the counter (seconds since server
    # initialized).
    #
    # @example
    #   printtimer()
    # @note ops: op
    # @return [void]
    def printtime()
      @server.puts "say Timer is at #{@counter}."
    end

    # Adds a shortcut for the user with a given label.  Shortcuts can only be
    # given for custom commands.  If only a label is given, the shortcut is
    # executed.
    #
    # @param [String] user The requesting user.
    # @param args label, command array
    # @example
    #   s("basicxman", "cobble", "give", "cobblestone", "64")
    #   s("basicxman", "mike", "tp", "mike_n_7")
    # @note ops: hop
    # @return [void]
    def s(user, *args)
      shortcut_name = args.slice! 0

      if args.length == 0
        if !@usershortcuts.has_key?(user) || !@usershortcuts[user].has_key?(shortcut_name)
          return kit(user, shortcut_name) if KITS.include? shortcut_name.to_sym
          return say("#{shortcut_name} is not a valid shortcut for #{user}.")
        end
        return call_command(user, @usershortcuts[user][shortcut_name].first, *@usershortcuts[user][shortcut_name][1..-1]) if args.length == 0
      end

      command_string                      = args
      @usershortcuts[user]              ||= {}
      @usershortcuts[user][shortcut_name] = command_string

      say("Shortcut labelled #{shortcut_name} for #{user} has been added.")
    end

    # Prints the requested users shortcuts.
    #
    # @param [String] user The requesting user.
    # @example
    #   shortcuts("basicxman")
    # @note ops: hop
    # @return [void]
    def shortcuts(user)
      labels = @usershortcuts[user].keys.join(", ") if @usershortcuts.has_key? user
      say("Shortcuts for #{user}: #{labels}.")
    end

    # Prints the available commands for the user.
    #
    # @param [String] user The requesting user.
    # @example
    #   help("basicxman")
    # @note ops: none
    # @return [void]
    def help(user, command = nil)
      unless command.nil?
        return @server.puts "say #{command} does not exist." unless @commands.has_key? command.to_sym

        command_signature(command.to_sym)
        say(@commands[command.to_sym][:help])
        return
      end

      arr = []
      @commands.each do |key, value|
        priv = value[:ops]

        if is_op? user
          arr << key
        elsif is_hop? user
          arr << key unless priv == :op
        else
          arr << key if priv == :none
        end
      end
      commands = arr.sort.map { |s| "!" + s.to_s }
      say(commands.join(", "))
    end

    # Prints the list of available kits to the connected players.
    #
    # @example
    #   kitlist()
    # @note ops: none
    # @return [void]
    def kitlist()
      say("Kits: #{KITS.keys.join(", ")}")
    end

    # Adds or prints the current todo list items.
    #
    # @param [String] user The requesting user.
    # @param args The item.
    # @example
    #   todo("basicxman", "foo")
    #   todo("basicxman")
    # @note ops: none
    # @return [void]
    def todo(user, *args)
      if args.length == 0
        @todo_items.each_with_index do |item, index|
          say("say #{index + 1}. #{item}")
        end
        return
      end

      item = args.join(" ")
      @todo_items << item

      @server.puts "say Added item."
    end

    # Removes an item from the todo list.
    #
    # @param [String] user The requesting user.
    # @param args The item.
    # @example
    #   finished("basicxman", "foo")
    #   finished("basicxman", "2")
    # @note ops: none
    # @return [void]
    def finished(user, *args)
      item = args.join(" ")

      if item.to_i.to_s == item
        index = item.to_i - 1
      else
        index = @todo_items.find_index(item)
      end

      return @server.puts "say Item does not exist." if index.nil? or @todo_items[index].nil?

      @todo_items.slice! index
      @server.puts "say Hurray!"
    end

    # Executes a command from a users history.
    #
    # @param [String] user The requesting user.
    # @param [Integer] history The number of commands to look back.
    # @example
    #   last("basicxman")
    #   last("basicxman", "2")
    # @note ops: none
    # @return [void]
    def last(user, history = 1)
      user, history = user.downcase, history.to_i
      if not @command_history.has_key? user or @command_history[user].length < history
        return say("No command found.")
      end

      command = @command_history[user][-history]
      t       = @command_history[user].length
      call_command(user, command.first, *command[1..-1])

      # process_history_addition() will not add the same command twice in a
      # row, so only slice if the command history length has changed.
      @command_history[user].slice!(-1) unless @command_history[user].length == t
    end

    # Prints the last three commands executed.
    #
    # @param [String] user The requesting user.
    # @example
    #   history("basicxman")
    # @note ops: none
    # @return [void]
    def history(user)
      user = user.downcase
      return say("No command history found.") if not @command_history.has_key? user or @command_history[user].length == 0

      i = [@command_history[user].length, 3].min * -1
      @command_history[user][i, 3].reverse.each_with_index do |command, index|
        say("#{index + 1}. #{command.join(" ")}")
      end
    end

    # Validates a kit group, if the kit cannot be found it executes the
    # !kitlist command.
    #
    # @return [void]
    def validate_kit(group = "")
      return true if KITS.include? group.to_sym
      @server.puts "say #{group} is not a valid kit."
      kitlist
    end

    private

    # Prints the command signature options for a specified command.
    #
    # @param [Symbol] command The command method.
    # @example
    #   command_signature(:give)
    # @return [void]
    def command_signature(command)
      params = method(command).parameters || []
      return if params.length == 0
      params.slice! 0 if params[0][1] == :user

      case params.length
      when 1
        name = params[0][1].to_s.gsub("_", " ")
        type = params[0][0]

        case type
        when :opt
          say("!#{command}")
          say("!#{command} '#{name}'")
        when :rest
          say("!#{command} 'arguments', '...'")
        when :req
          say("!#{command} '#{name}'")
        end
      when 2
        first_name  = params[0][1].to_s.gsub("_", " ")
        second_name = params[1][1].to_s.gsub("_", " ")
        type        = params[1][0]

        case type
        when :rest
          say("!#{command} '#{first_name}', 'arguments', '...'")
        when :opt
          say("!#{command} '#{first_name}'")
          say("!#{command} '#{first_name}', '#{second_name}'")
        end
      end
    end

    # Checks if the user does not wish to be disturbed and prints an error
    # notice if so.
    #
    # @param [String] user The requesting user.
    # @return [Boolean] Returns true if the user does not wish to be disturbed
    # (should cancel action).
    # @example
    #   check_dnd("basicxman")
    def check_dnd(user)
      if @userdnd.include? user.downcase
        say("#{user} does not wish to be disturbed, don't be a jerk!")
        return true
      else
        return false
      end
    end

    # Changes the time of day.
    #
    # @param [String] time The time of day to change it to.
    # @example
    #   change_time("morning")
    # @return [Boolea] True if `time` is a valid time
    def change_time(time)
      return false unless TIME.include? time

      @server.puts "time set #{TIME[time]}"
      @server.puts "say #{TIME_QUOTES[time]}" unless TIME_QUOTES[time] == ""
      return true
    end

    # Checks a kickvote entry to see if the tally number has crossed the
    # threshold, if so, kicks the user.
    #
    # @param [String] user The specified user.
    # @example
    #   check_kickvote("blizzard4U")
    # @return [void]
    def check_kickvote(user)
      if @userkickvotes[user][:tally] >= @vote_threshold
        @server.puts "say Enough votes have been given to kick #{user}."
        @server.puts "kick #{user}"

        @userkickvotes.delete(user)
      end
    end

    # Computes the influence a user has for kickvotes.
    #
    # @param [String] user The specified user.
    # @return [Integer] The influence level.
    # @example
    #   kick_influence("basicxman")
    def kick_influence(user)
      return 3 if is_op? user
      return 2 if is_hop? user
      return 1
    end

    # Checks to see if any kickvotes are expired.
    #
    # @return [void]
    def expire_kickvotes
      @userkickvotes.each do |target_user, data|
        if Time.now > data[:start] + @vote_expiration
          @server.puts "say The kickvote for #{target_user} has expired."
          @userkickvotes.delete(target_user)
        end
      end
    end

    # Submits a kickvote.
    #
    # @param [String] user The requesting user who is voting.
    # @param [String] target_user The user being voted against.
    # @return [Boolean] Returns true if the kickvote has been initiated yet.
    # @example
    #   submit_vote("basicxman", "blizzard4U")
    def submit_vote(user, target_user)
      return unless @users.include? target_user
      if @userkickvotes.has_key? target_user
        if @userkickvotes[target_user][:votes].include? user
          @server.puts "say You have already voted."
        else
          @userkickvotes[target_user][:votes] << user
          @userkickvotes[target_user][:tally] += kick_influence(user)

          check_kickvote(target_user)
        end
        return true
      else
        return false
      end
    end

    # Caps the quantity of points able to be given based on requesting user.
    #
    # @param [String] user The requesting user.
    # @return [Integer] Maximum quantity of points.
    # @example
    #   cap_points("basicxman")
    def cap_points(user)
      return 1000 if is_op? user
      return 500  if is_hop? user
      return 1
    end

    # Helper method for printing the final give statements to the server.  If a
    # quantity is above the default upper bound (64) it will print multiple
    # statements.
    #
    # @param [String] user The requesting user.
    # @param [Integer] item The item id.
    # @param [Integer] quantity The quantity of the item to give.
    # @example
    #   construct_give("basicxman", 4, 64)
    #   construct_give("basicxman", 4, 2560)
    # @return [void]
    def construct_give(user, item, quantity)
      if quantity <= 64
        @server.puts "give #{user} #{item} #{quantity}"
        return
      end

      quantity      = 2560 if quantity > 2560
      full_quantity = (quantity / 64.0).floor
      sub_quantity  = quantity % 64

      @server.puts "give #{user} #{item} 64\n" * full_quantity
      @server.puts "give #{user} #{item} #{sub_quantity}" if sub_quantity > 0
    end

    # Takes an array and decides if a quantifier is specified or not, returns
    # the quantity and full item name.
    #
    # @param [Integer] default The default quantity to give if none is given.
    # @return [Array] full_item_name, quantity
    # @example
    #   items_arg(1, ["flint", "and", "steel"])
    #   items_arg(1, ["4"])
    #   items_arg(1, ["4", "1"])
    #   items_arg(1, ["flint", "and", "steel", "32"])
    def items_arg(default, args)
      if args.length == 1
        second = default
        first  = args.first
      else
        if is_quantifier? args.last
          second = quantify(args.last)
          first  = args[0..-2].join(" ")
        else
          second = default
          first  = args[0..-1].join(" ")
        end
      end
      return [first, second]
    end

    # Resolves a full item name, checks if it is a numeric value and if not
    # attempts an approximate match on the key and gets the value from the
    # data value hash.
    #
    # @param [String] item The full item name.
    # @return [String] The resolved item id.
    # @example
    #   resolve_item("4")
    #   resolve_item("cobb")
    #   resolve_item("cobblestone")
    def resolve_item(item)
      item.to_i.to_s == item ? item : DATA_VALUE_HASH[resolve_key(item.downcase)]
    end

    # Looks for an approximate match of a key, prints an error message to
    # the player if the key does not exist.
    #
    # @param [String] key The approximate item name.
    # @return [String] The proper item id.
    # @example
    #   resolve_key("cobb")
    #   resolve_key("cobblestone")
    #   resolve_key("torches")
    def resolve_key(key)
      bucket        = key[0]
      shortest_diff = nil
      shortest_key  = nil

      return no_key(key) unless ITEM_BUCKETS.include? bucket
      return key if ITEM_BUCKETS[bucket].include? key

      ITEM_BUCKETS[bucket].each do |test_key|
        if test_key.length > key.length
          diff = test_key.length - key.length if test_key.index(key)
        else
          diff = key.length - test_key.length if key.index(test_key)
        end
        next if diff.nil?

        if shortest_diff.nil? or diff < shortest_diff
          shortest_key = test_key
          shortest_diff = diff
        end
      end

      no_key(key) if shortest_key.nil?
      return shortest_key
    end

    # Prints a no key error the server.
    def no_key(key)
      @server.puts "say No item #{key} found."
    end

    # Checks if a value is a valid quantifier or not.
    #
    # @param [String] quantity The potential quantifier.
    # @return [Boolean]
    # @example
    #   is_quantifier? "x"
    #   is_quantifier? "1m"
    #   is_quantifier? "2d"
    #   is_quantifier? "1s"
    #   is_quantifier? "1"
    #   is_quantifier? "steel"
    def is_quantifier?(quantity)
      quantity.index(/[0-9]+[a-z]?/) == 0
    end

    # Compute a final quantity from a quantifier value.
    #
    # @param [String] value The quantifier.
    # @return [Integer] The resulting quantity, upper bounded to 2560.
    # @example
    #   quantify("1m")
    #   quantify("2d")
    #   quantify("34s")
    #   quantify("8m2d")
    #   quantify("64")
    def quantify(value)
      quantity = value.scan(/[0-9]+[a-z]?/).inject(0) do |total, term|
        quantity, flag = term.match(/([0-9]+)([a-z]?)/)[1..2]
        quantity       = quantity.to_i
        return total + quantity if flag.nil?

        total + case flag
                when 'm' then quantity * 64
                when 'd' then (64.0 / [1, quantity].max).round
                when 's' then [1, 64 - quantity].max
                else quantity
                end
      end
      return [2560, quantity].min
    end
  end
end
