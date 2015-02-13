require './RPM-ritual.rb'
require './RPM-caster.rb'

# Extendendo a classe Nil para permitir stdin redirect
class NilClass
	def chomp
		nil
	end
end

def format(secs)
	string = ""
	hours = secs / (60*60)
	secs -= hours*60*60
	string += "#{hours} hours, " if hours > 0
	minutes = secs / 60
	secs -= minutes*60
	string += "#{minutes} minutes, " if minutes > 0 
	string += "#{secs} seconds"
	string
end

def roll (d=3)
	x = 0
	d.times { x += rand(6)+1 }
	x
end

def test (level)
	d = roll
	if d == 3 || d == 4 || (level >= 15 && d == 5) || (level >= 16 && d == 6)
		return {roll: d, result: :crit_suc, by: level - d}
	elsif d == 18 || (d == 17 && level <= 15) || d - level >= 10
		return {roll: d, result: :crit_fail, by: level - d}
	elsif d <= level
		return {roll: d, result: :success, by: level - d}
	else
		return {roll: d, result: :fail, by: level - d}
	end
end

class Casting
	attr_reader :ritual, :caster, :skill, :gathered, :time, :quirks
	def find_skill
		skill = 99
		@ritual.paths.each { |p| if @caster.paths[p] < skill; skill = @caster.paths[p]; end}
		if @ritual.paths.size > 2; skill -= @ritual.paths.size - 2; end
		if @caster.mastery.include?(@ritual.name.to_sym); skill += 2; end # Ritual Mastery provides +2 to all rolls
		skill
	end
	def initialize(ritual, caster, kit_bonus, grim_bonus, ambient_bonus, time_adj)
		@ritual = ritual; @caster = caster; @kit_bonus = kit_bonus; 
		@grim_bonus = grim_bonus; @ambient_bonus = ambient_bonus; @time_adj = time_adj;
		@gathered = 0; @time = 0; @count = 0; @quirks = 0; @new = {}; @last_was_crit = false;
		@skill = find_skill
	end
	def gather_roll(skill, timeadj = 0)
		if timeadj < -4 || timeadj > 0
			raise "Time adjustment must be between 0 and -4"
		end
		if timeadj < 0 && !@caster.adept
			raise "Only adepts may use time adjustment"
		end
		time = 5
		skill += timeadj
		time += timeadj
		time *= 60 unless @caster.adept
		g = test(skill)
		if g[:result] == :success 
			gathered = g[:by]; gathered = 1 if gathered == 0
		elsif g[:result] == :crit_suc
			gathered = g[:by]; gathered = 1 if gathered == 0
		elsif g[:result] == :fail 
			gathered = 1
		else
			gathered = 0
		end
		return {eff_skill: skill, roll: g[:roll], result: g[:result], gathered: gathered, time: time}
	end
	def gather
		@new = gather_roll(@skill+@grim_bonus+@kit_bonus+@ambient_bonus, @time_adj)
		@gathered += @new[:gathered]
		@new[:time] *= 2 if @grim_bonus > 0 # double time when using grimories
		if @last_was_crit; @new[:time] =1; end # A critical success makes the NEXT gather last 1 sec only
		@time += @new[:time]
		@count += 1
		if @count == 3 
			@count = 0
			@skill -= 1
		end
		if @new[:result] == :fail
			@quirks +=1
		end
		@last_was_crit = (@new[:result] == :crit_suc) 
	end
end
