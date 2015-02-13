require 'yaml'

class Ritual
	attr_reader :name, :description
	@@rituals = [] # CLASS attribute
	@@extra_modifiers = { # Used to add extra modifiers "on the run"
		:duration => ["Momentary", "10 min", "30 min", "1 h", "3 h", "6 h", "12 h", "1 day", "3 day", "7 day", "14 day", "1 month"],
		:weight => ["5 kg", "10 kg", "50 kg", "100 kg", "500 kg", "1000 kg", "5 ton", "15 ton", "50 ton", "150 ton"],
		:range => ["2 m", "4 m", "7 m", "10 m", "15 m", "20 m", "30 m", "50 m", "70 m", "100 m", "150 m"]
	}
	def self.setup
		YAML.load_file('Rituals.yaml').each{ |k| @@rituals << Ritual.new(k) }
	end
	def self.save_all
		rits = []
		@@rituals.each{ |x|	
			rits.push(:name => x.name, :effects => x.effects, :modifiers => x.modifiers, 
					  :description => x.description)
		}
		File.open('Rituals.yaml', 'w') { |f| f.puts rits.to_yaml }
	end
	def self.list; @@rituals; end
	def cost
		cost = 0
		@effects.each { |x| cost += eff_cost(x)	}
		@modifiers.each { |x| m = modifier_cost(x); cost +=m unless m.nil?	} unless @modifiers.nil?
		cost * g_mult
	end
	def initialize(options = {})
		@name = options[:name]
		@effects = options[:effects]
		@modifiers = options[:modifiers]
		@description = options[:description]
	end
	def add_effect(new); @effects << new; end
	def add_modifier(new); @modifiers << new; end
	def paths
		p = []
		@effects.each{ |x| p << x[:path] unless p.include?(x[:path])}
		return p
	end
	def greater
		g = 0
		@effects.each { |x| g+= 1 if x[:level] == :greater}
		return g
	end
	def g_mult
		greater * 2 + 1
	end
	def eff_cost(x)
		case x[:effect]
		when :sense; 2
		when :strengthen; 3
		when :restore; 4
		when :control, :destroy; 5
		when :create; 6
		when :transform; 8
		end
	end
	def modifier_cost (x)
		# TODO METAMAGIC
		# TODO HEALING
		# TODO SPEED
		case x[:modifier]
		when :affliction;  x[:level] / 5
		when :altered_trait
			if x[:level] > 0
				x[:level]
			else 
				-x[:level]/5
			end
		when :bestow
			case x[:class]
			when :broad; b = 5
			when :moderate; b = 2
			when :narrow; b = 1
			end
			l = x[:level]
			b * (2 ** (l.abs - 1))
		when :aoe
			(x[:exclude]+1) / 2 unless x[:exclude].nil?
			if x[:level] <= 3;  2
			elsif x[:level] <= 4;  4
			elsif x[:level] <= 6;  6
			elsif x[:level] <= 9;  8
			elsif x[:level] <= 13;  10
			elsif x[:level] <= 18;  12
			elsif x[:level] <= 27;  14
			elsif x[:level] <= 45;  16
			elsif x[:level] <= 64;  18
			elsif x[:level] <= 91;  20
			elsif x[:level] <= 137;  22
			else; puts "WARNING. AOE too large" 
			end
		when :damage
			d = x[:level] =~ /d/
			dice = x[:level][0..d-1].to_i
			plus = x[:level] =~ /[+-]/ 
			mod = 0; mod = x[:level][plus..plus+1].to_i unless plus.nil?
			case x[:type]
			when "pi-"
				mult = 0.5
			when "burn", "cr", "pi", "tox"
				mult = 1
			when "cut", "pi+"
				mult = 1.5
			when "cor", "fat", "imp", "pi++" 
				mult = 2
			end
			(4*dice + mod) * mult
		when :duration, :weight, :range
			x[:level]
		else; puts "ERROR: #{x[:modifier].to_s} modifier not implemented"
		end
	end
end

Ritual.setup
