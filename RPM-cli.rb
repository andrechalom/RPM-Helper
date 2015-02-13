#!/usr/bin/env ruby
# Command Line Interface for the RPM helper
# Extends the Caster and Ritual classes with CLI interfaces
require './RPM-core.rb'

class Caster
	def self.cli_select
		# TODO: add tools to update or delete casters
		puts "Select the caster (-1 to enter new):" 
		@@casters.each_with_index { |r, i| 
			puts "[#{i}] Caster: #{r.name}."
		}
		choice = gets.chomp.to_i
		if choice == -1
			c = Caster.cli_create
			@@casters.push(c)
			c.describe
			puts "Do you want to save this caster [y/N]?"; s = gets.chomp;
			if s == "y"; Caster.save_all; end
		else
			c = Caster.list[choice]
			c.describe
		end
		return c
	end
	def describe
		print "Name: #{@name}"
		if @adept 
			print ", adept caster"
		end
		if @magery == -1
			puts ""
		else
			puts ", magery level #{@magery}"
		end
		print "Skills: Thaumatology #{@thaumatology}"
		if @alchemy > 0
			print ", Alchemy #{@alchemy}"
		end
		@paths.each {|x, y| print ", Path of #{x.capitalize} #{y}"}
		puts ""
		@kits.each {|x, y| puts "The caster has a #{y} #{x} kit"}
		puts ""
	end
	def self.cli_create
		#TODO fine-tuning adept?
		#TODO: ritual mastery
		#TODO: work a system for Higher Purpose
		print "Name: "; name = gets.chomp;
		print "Adept [Y/n]: "; a = gets.chomp; if a == "n"; adept = false; else adept = true; end;
		print "Magery (-1 for none): "; magery = gets.chomp.to_i;
		print "Thaumatology: "; thaumatology = gets.chomp.to_i;
		print "Alchemy: "; alchemy = gets.chomp.to_i;
		paths = {}
		while true
			print "Add path? [Y/n] "; cancel = gets.chomp; if cancel == "n"; break; end;
			print "Path: "; p = gets.chomp; print "Level: "; l = gets.chomp;
			paths[p.downcase.to_sym] = l.to_i
		end
		paths.each{ |path, level| 
			puts "WARNING: Path of #{path} is higher than allowed"  if level > thaumatology || level > magery + 12
		}
		kits = {}
		while true
			print "Add kit? [Y/n] "; cancel = gets.chomp; if cancel == "n"; break; end;
			print "Kit (charm or alchemy): "; p = gets.chomp; print "Level (normal, good or fine): "; l = gets.chomp;
			kits[p.downcase.to_sym] = l.downcase.to_sym
		end
		mastery = {}
		while true
			print "Add Ritual Mastery? [Y/n] "; cancel = gets.chomp; if cancel == "n"; break; end;
			ritual = Ritual.cli_select
			mastery[ritual.name.to_sym] = true
		end
		Caster.new(:name => name, :adept => adept, :magery => magery, :thaumatology => thaumatology, 
				   :alchemy => alchemy, :paths => paths, :kits => kits, :mastery => mastery)
	end
end

class Ritual
	def cli_rwd_select
		puts "Add range/weight/duration? [y/N] "; q = gets.chomp;
		if q == "y"
			@@extra_modifiers.each{ |modifier, mod_table|
				puts "#{modifier.to_s.capitalize}: ";
				mod_table.each_with_index{ |d, i| puts "[#{i}] #{d}" }
				choice = gets.chomp.to_i;
				add_modifier({modifier: modifier, level: choice, description: mod_table[choice]}) if choice > 0
			}
		end
	end
	def cli_charm_select(caster)
		time = 0
		print "Conditional, cHarm, Elixir or [none]?"; charm = gets.chomp;
		if charm == "h" 
			puts "Charm: prepare the object (30 minutes)" 
			time = 30*60
		elsif charm =="e"
			puts "Elixir: combine the ingredients (1 hour)" 
			time = 60*60
		end
		if charm=="c" || charm=="h" || charm =="e" 
			puts "Note: this casting includes a Lesser Control Magic effect"
			add_effect({level: :lesser, effect: :control, path: :magic})
		end
		if charm == "h" || charm == "e"
			if charm == "h"; 
				default_kit = caster.kits[:charm].to_s; 
				if default_kit == "" && ! caster.kits[:alchemy].nil?
					default_kit = "improvised"
				end
			end
			if charm == "e"; 
				default_kit = caster.kits[:elixir].to_s; 
				if default_kit == "" && ! caster.kits[:charm].nil?
					default_kit = "improvised"
				end
			end
			default_kit = "none" if default_kit.nil? || default_kit == ""
			print "Kit ";
			r = ["None", "Improvised", "noRmal", "Good", "Fine"]
			r.each {|d|
				if d.downcase == default_kit.downcase
					print "[#{d}]"
				else 
					print d
				end
				print ", " unless d == r.last
			}
			print ": "
			kit = gets.chomp;
			kit = default_kit if kit == ""
			case kit
			when "n", "none"
				b = -5
			when "i", "improvised"
				b = -2
			when "g", "good" 
				b = 1
			when "f", "fine"
				b = 2
			when "r", "normal"
				b = 0
			else
				raise "Kit rating not found: #{kit}"
			end
		else #not charm or elixir
			b = 0
		end

		return [charm, time, b]
	end
	def self.cli_select
		# TODO: add tools to update or delete rituals
		puts "Select the ritual (-1 to enter new):" 
		@@rituals.each_with_index { |r, i| 
			puts "[#{i}] Ritual: #{r.name}. Path(s): #{r.paths}. Cost: #{r.cost}"
		}
		choice = gets.chomp.to_i
		if choice == -1
			c = Ritual.cli_create
			@@rituals.push(c)
			c.describe
			puts "Do you want to save this ritual [y/N]?"; s = gets.chomp;
			if s == "y"; Ritual.save_all; end
		else
			c = @@rituals[choice]
			c.describe
		end
		return c
	end
	def describe
		puts "#{@name} (#{cost} energy)"
		@effects.each { |x| 
			print "#{x[:level].to_s.capitalize} #{x[:effect].to_s.capitalize} #{x[:path].to_s.capitalize} (#{eff_cost(x)})"
			print ", " unless x == @effects.last	
		}
		puts ""
		@modifiers.each { |x| 
			print "#{x[:modifier].to_s.capitalize} (" 
			if x[:modifier] == :bestow; 
				if x[:level] > 0; print "+"; end
				print "#{x[:level]} "; 
			end
			if x[:modifier] == :damage;
				print "#{x[:level]} #{x[:type]} #{x[:class].to_s}; "
			end
			if x[:modifier] == :aoe;
				print "#{x[:level]} meters; "
			end

			unless x[:description].nil?; print "#{x[:description]}; "; end
			print "#{modifier_cost(x)})"
			print ", " unless x == @modifiers.last	
		} unless @modifiers.nil?
		puts ""
		puts @description;
		puts ""
	end
	def self.cli_create
		puts "NOT IMPLEMENTED YET"
		#TODO implement create ritual
	end
end

class Casting
	def cli_gather_loop
		while true
			gather
			puts @new
			if @new[:result] == :crit_fail
				return {result: :crit_fail, gathered: @gathered, time: @time, quirks: @quirks}
			end
			puts "Gathered #{@new[:gathered]} in #{format(@new[:time])} (total #{@gathered}/#{@ritual.cost})"
			break if @gathered >= @ritual.cost;
			print "Continue? [Y/n] "
			cont = gets.chomp; break if cont == "n";
		end
		return {result: :success, gathered: @gathered, time: @time, quirks: @quirks}
	end
	def cli_roll_casting
	end
end

# Interface tosquinha
puts "Hey! I'm the RPM helper!"
caster = Caster.cli_select
# TODO allow non-adept to roll as adepts at -5. ask for connection, consecrated place, etc
ritual = Ritual.cli_select
charm, time, kit_bonus = ritual.cli_charm_select(caster) #selects whether its a charm, conditional or elixir
ritual.cli_rwd_select # adds range/weight/duration modifiers
puts "Total energy cost: #{ritual.cost}"
# TODO declarar grimorios no character file
print "Bonus for grimories: "; grim_bonus = gets.chomp.to_i; grim_bonus = 0 if grim_bonus.nil? 
print "Bonus for ambient energy: "; ambient_bonus = gets.chomp.to_i; ambient_bonus = 0 if ambient_bonus.nil?
print "Time adjustment? "; time_adj = gets.chomp.to_i; time_adj = 0 if time_adj.nil?
casting = Casting.new(ritual, caster, kit_bonus, grim_bonus, ambient_bonus, time_adj)
g = casting.cli_gather_loop

if g[:result] == :success
	puts "Gathered: #{g[:gathered]} in #{format(g[:time])} with #{g[:quirks]} quirks" 
	puts "Total time: #{format(time + g[:time])}"
	keepgoing = true
	while keepgoing
		keepgoing = false
		print "Roll the casting? [Y/n] "
		cont = gets.chomp;
		if cont != "n";
			puts "Skill roll:"
			my_test = test(casting.skill + kit_bonus + grim_bonus); puts my_test
			keepgoing = true if my_test[:result] == :fail
			keepgoing = false if charm == "c" || charm == "e" # IF you fail the cast on a charm, you must start over
		end
	end
	puts "Roll resistance for any subjects? [0...n] "; t = gets.chomp.to_i;
	t.times {
		puts "Best of (HT or Will) + Damage Resistence?"; x= gets.chomp.to_i;
		k = test(x); puts k;
		if k[:by] > my_test[:by]; puts "RESISTED!"; else; puts "Not resisted"; end
	}
else
	puts "CRITICAL FAILURE!"
	puts "The ritual botched with #{g[:gathered]} energy"
	puts "Total time: #{format(time + g[:time])}"
end
