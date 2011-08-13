module Minecraft
  class Extensions
    include Data

    def initialize
      @ops = File.readlines("ops.txt").map { |s| s.chop }
      @users = []
    end

    def process(line)
      puts line
      return info_command(line) if line.index "INFO"
    end

    def info_command(line)
      line.gsub! /^.*?\[INFO\]\s+/, ''
      meta_check(line)
      match_data = line.match /^\<(.*?)\>\s+!(.*?)$/
      return if match_data.nil?

      user = match_data[1]
      args = match_data[2].split(" ")
      return send(args.slice!(0), user, *args)
    end

    def meta_check(line)
      return if check_ops(line)
      return if check_join_part(line)
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
      if DATA_VALUE_HASH.has_key? sym.downcase
        give(args.first, sym, args.last)
      else
        puts "Invalid command given."
      end
    end

    def giveall(user, *args)
      return privilege_error(user, "giveall") unless is_op? user
      ret = "say #{user} is putting out!\n"
      @users.each do |u|
        ret += mc_give(u, *args)
      end

      return ret
    end

    def give(user, *args)
      return privilege_error(user, "give") unless is_op? user
      return mc_give(user, *args)
    end

    def mc_give(user, *args)
      if args.length == 1
        quantity = 1
        item = args.first
      else
        quantity = args.last.to_i || 1
        item = args[0..-2].join(" ")
      end
      item = (item.to_i.to_s == item) ? item.to_i : DATA_VALUE_HASH[item.downcase]

      return quantify(user, item, quantity)
    end

    def kit(user, group)
      return privilege_error(user, "kit") unless is_op? user
      return "say #{group} is not a valid kit." unless KITS.has_key? group.to_sym
      ret = ""

      KITS[group.to_sym].each do |item|
        if item.is_a? Array
          ret += quantify(user, item.first, item.last)
        else
          ret += "give #{user} #{item} 1\n"
        end
      end
      return ret.chop
    end

    def tp(user, target)
      "tp #{user} #{target}"
    end

    def tpall(user)
      return privilege_error(user, "tpall", "Wow, #{user} actually tried to pull that...") unless is_op? user
      ret = "say #{user} is teleporting all users to their location.\n"
      @users.each do |u|
        ret += tp(u, user)
      end
      return ret
    end

    def nom(user)
      return privilege_error(user, "nom", "No noms for you!") unless is_op? user
      "give #{user} 322 1"
    end

    def help(*args)
      <<-eof
say !tp target_user
say !tpall
say !kit kit_name
say !give item quantity
say !giveall item quantity
say !nom
say /help
      eof
    end

    def quantify(user, item, quantity)
      return "give #{user} #{item} #{quantity}" if quantity <= 64

      quantity = 2560 if quantity > 2560
      full_quantity = (quantity / 64.0).floor
      sub_quantity  = quantity % 64
      ret = "give #{user} #{item} 64\n" * full_quantity
      ret += "give #{user} #{item} #{sub_quantity}"
      return ret
    end

    def is_op?(user)
      @ops.include? user
    end

    def privilege_error(user, command, suffix = "S/he must be humiliated!")
      "say #{user} is not an op, cannot use !#{command}.  #{suffix}"
    end
  end
end
