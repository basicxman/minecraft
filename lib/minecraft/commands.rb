module Minecraft
  module Commands
    include Data

    def give(user, *args)
      item, quantity = items_arg(1, args)
      item = resolve_item(item)

      return quantify(user, item, quantity)
    end

    def validate_kit(group)
      return "say #{group} is not a valid kit." unless KITS.include? group.to_sym
    end

    def kit(user, group)
      ret = ""
      KITS[group.to_sym].each do |item|
        if item.is_a? Array
          ret += quantify(user, item.first, item.last)
        else
          ret += "give #{user} #{item} 1\n"
        end
      end
      return ret.chomp
    end

    def tp(user, target)
      "tp #{user} #{target}"
    end

    def tpall(user, *args)
      @users.inject("") { |s, u| s + tp(u, user) + "\n" }.chomp
    end

    def nom(user)
      "give #{user} 322 1"
    end

    def list(user)
      l = @users.inject("") do |s, u|
        if u == user
          pre = "["
          suf = "]"
        end
        suf = "*" + suf if is_op? u
        s + ", #{pre}#{u}#{suf}"
      end
      return "say #{l}"
    end

    def addtimer(user, *args)
      item, duration = items_arg(30, args)
      item = resolve_item(item)
      @timers[user] ||= {}
      @timers[user][item] = duration
      return "say Timer added for #{user}.  Giving #{item} every #{duration} seconds."
    end

    def deltimer(user, *args)
      item = args.join(" ")
      item = resolve_item(item)
      @timers[user][item] = nil if @timers.has_key? user
    end

    def printtimer(user)
      return "say Timer is at #{@counter}."
    end

    def help(*args)
      <<-eof
say !tp target_user
say !tpall
say !kit kit_name
say !kitall kit_name
say !give item quantity
say !giveall item quantity
say !nom
say !nomall
say !list
say !addtimer item frequency
say !deltimer item
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

    def items_arg(default, args)
      if args.length == 1
        second = default
        first  = args.first
      else
        second = args.last.to_i || default
        first  = args[0..-2].join(" ")
      end
      return [first, second]
    end

    def resolve_item(item)
      item.to_i.to_s == item ? item.to_i : DATA_VALUE_HASH[item.downcase]
    end
  end
end
