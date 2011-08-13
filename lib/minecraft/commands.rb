module Minecraft
  module Commands
    include Data

    def give(user, *args)
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

    def help(*args)
      <<-eof
say !tp target_user
say !tpall
say !kit kit_name
say !give item quantity
say !giveall item quantity
say !nom
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
  end
end
