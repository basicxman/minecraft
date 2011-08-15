module Minecraft
  module Commands
    include Data

    def give(user, *args)
      item, quantity = items_arg(1, args)
      item = resolve_item(item)

      quantify(user, item, quantity)
    end

    def validate_kit(group = "")
      return true if KITS.include? group.to_sym
      @server.puts "say #{group} is not a valid kit."
      kitlist
    end

    def kit(user, group)
      KITS[group.to_sym].each do |item|
        if item.is_a? Array
          @server.puts quantify(user, item.first, item.last)
        else
          @server.puts "give #{user} #{item} 1"
        end
      end
    end

    def tp(user, target)
      @server.puts "tp #{user} #{target}"
    end

    def tpall(user, *args)
      @users.each { |u| tp(u, user) }
    end

    def nom(user)
      @server.puts "give #{user} 322 1"
    end

    def property(user, key)
      @server.puts "say #{key} is currently #{@server_properties[key]}" if @server_properties.include? key
    end

    def uptime(user, target_user = nil)
      target_user ||= user
      time_spent = calculate_uptime(target_user)
      if @userlog.has_key? target_user
        total = "  Out of a total of #{format_uptime(@userlog[target_user] + time_spent)} minutes."
      end
      @server.puts "say #{target_user} has been online for #{format_uptime(time_spent)} minutes.#{total}"
    end

    def rules(*args)
      @server.puts "say #{@rules}"
    end

    def list(user)
      l = @users.inject("") do |s, u|
        if u == user
          pre = "["
          suf = "]"
        end
        suf = "*" + (suf || "") if is_op? u
        s + "#{", " unless s.empty?}#{pre}#{u}#{suf}"
      end
      @server.puts "say #{l}"
    end

    def addtimer(user, *args)
      item, duration = items_arg(30, args)
      item = resolve_item(item)
      @timers[user] ||= {}
      @timers[user][item] = duration
      @server.puts "say Timer added for #{user}.  Giving #{item} every #{duration} seconds."
    end

    def deltimer(user, *args)
      item = args.join(" ")
      item = resolve_item(item)
      @timers[user][item] = nil if @timers.has_key? user
    end

    def printtimer(user)
      @server.puts "say Timer is at #{@counter}."
    end

    def help(*args)
      @server.puts <<-eof
say !tp target_user
say !kit kit_name
say !give item quantity
say !nom
say !list
say !addtimer item frequency
say !deltimer item
      eof
    end

    def kitlist(*args)
      @server.puts "say Kits: #{KITS.keys.join(", ")}"
    end

    def quantify(user, item, quantity)
      if quantity <= 64
        @server.puts "give #{user} #{item} #{quantity}"
        return
      end

      quantity = 2560 if quantity > 2560
      full_quantity = (quantity / 64.0).floor
      sub_quantity  = quantity % 64
      @server.puts "give #{user} #{item} 64\n" * full_quantity
      @server.puts "give #{user} #{item} #{sub_quantity}" if sub_quantity > 0
    end

    def items_arg(default, args)
      if args.length == 1
        second = default
        first  = args.first
      else
        if args.last.to_i.to_s == args.last # Last argument is an integer.
          second = args.last.to_i
          first  = args[0..-2].join(" ")
        else
          second = default
          first = args[0..-1].join(" ")
        end
      end
      return [first, second]
    end

    def resolve_item(item)
      item.to_i.to_s == item ? item.to_i : DATA_VALUE_HASH[resolve_key(item.downcase)]
    end

    def resolve_key(key)
      bucket = key[0]
      return key if ITEM_BUCKETS[bucket].include? key

      puts "Finding #{key} approximate in #{ITEM_BUCKETS[bucket]}"
      shortest_diff = nil
      shortest_key  = nil
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

      return shortest_key
    end
  end
end
