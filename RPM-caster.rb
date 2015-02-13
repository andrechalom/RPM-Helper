require 'yaml'

class Caster
	attr_reader :name, :adept, :magery, :thaumatology, :alchemy, :paths, :kits, :mastery
	@@casters = [] # CLASS attribute
	def self.setup
		YAML.load_file('Casters.yaml').each{ |k| @@casters << Caster.new(k) }
	end
	def self.save_all
		casts = []
		@@casters.each{ |x|	
			casts.push(:name => x.name, :adept => x.adept, :magery => x.magery, 
					   :thaumatology => x.thaumatology, :alchemy => x.alchemy, :paths => x.paths,
					   :kits => x.kits, :mastery => x.mastery)
		}
		File.open('Casters.yaml', 'w') { |f| f.puts casts.to_yaml }
	end
	def self.list; @@casters; end
	def initialize(options = {})
		@name = options[:name]
		@magery = options[:magery] || -1 # convention, no magery
		@adept = options[:adept] || false
		@thaumatology = options[:thaumatology]
		@alchemy = options[:alchemy] || 0
		@paths = options[:paths] || {}
		if @thaumatology - 6 < 12
			@paths.default = @thaumatology - 6
		else
			@paths.default = 12
		end
		@kits = options[:kits] || {}
		@mastery = options[:mastery] || {}
	end
end

Caster.setup
