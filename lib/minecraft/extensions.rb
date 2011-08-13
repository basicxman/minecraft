module Minecraft
	class Extensions
		include Data

		def process(line)
			puts line
			return info_command(line) if line.index "INFO"
		end

		def info_command(line)
			line.gsub! /^.*?\[INFO\]\s+/, ''
			match_data = line.match /^\<(.*?)\>\s+!(.*?)$/
			return if match_data.nil?

			user = match_data[1]
			args = match_data[2].split(" ")
			return send(args.slice!(0), user, *args)
		end

		def method_missing(sym, *args)
			if DATA_VALUE_HASH.has_key? sym.downcase
				give(args.first, sym, args.last)
			else
				puts "Invalid command given."
			end
		end

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

		def kit(user, group)
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

		def nom(user)
			"give #{user} 322 1"
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
