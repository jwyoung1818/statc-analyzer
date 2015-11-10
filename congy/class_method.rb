#load "func_call.rb"

class Method_class
	def initialize(name)
		@variables = Hash.new
		@name = name
		@calls = Array.new
	end
	def getVars
		@variables
	end
	def getName
		@name
	end
	def getCalls
		@calls
	end
end

class Class_class
	def initialize(name)
		@methods = Hash.new
		@name = name
		@belongs_to = Array.new
		@variable = Array.new
		@upper_class = ""
		@upper_class_instance = nil
		@func_var_map = Hash.new
		@before_filter = Array.new
		#@after_create = Array.new
		#@after_destroy = Array.new
	end
	def getName
		@name
	end
	def setUpperClass(up_name)
		@upper_class = up_name
	end
	def setUpperClassInstance(upper_class)
		@upper_class_instance = upper_class
	end
	def getUpperClass
		@upper_class
	end
	def getUpperClassInstance
		@upper_class_instance
	end
	def getMethods
		@methods
	end
	def addMethod(meth)
		@methods[meth.getName] = meth
	end
	def getMethod(meth_name)
		@methods[meth_name]
	end
	def addBelongsTo(belong_name)
		@belongs_to.push(belong_name)
	end
	def addVariable(var_name)
		@variable.push(var_name)
	end
	#def addBeforeValidation(valid_name)
	#	@before_validation.push(valid_name)
	#end
	
	#mappings of function name ane variable type list
	def addFuncVar(func_name, var_name, class_name)
		if @func_var_map.has_key?(func_name)
			@func_var_map[func_name].insert_var(var_name, class_name)
		else
			temp_f = Function_vars.new(func_name)
			temp_f.insert_var(var_name, class_name)
			@func_var_map[func_name] = temp_f
		end
	end
	def getFuncVarMap
		@func_var_map
	end
		
	def addBeforeFilter(filter_name)
		@before_filter.push(filter_name)
	end
	def getBeforeFilter
		@before_filter
	end
	def print_var_types
		puts "######## BEGIN ########"
		puts "Class: #{@name}"
		@func_var_map.each do |key2, value2|
			print "function #{value2.get_name} : "
			value2.get_var_map.each do |key3, value3|
				print "#{key3}(#{value3}), "
			end
			puts ""
			puts "----"
		end
		puts "###### END #######"
		puts ""
	end
	def print_calls
		puts "######## BEGIN ########"
		puts "Class: #{@name}"
		
		@methods.each do |key, array|
			puts "Method #{key}:\n"
			print "\t ** variables: {"
			array.getVars.each do |key2, array2|
				print "#{key2}, "
			end
			puts "}"
			array.getCalls.each do |each_call|
				print "\t "
				each_call.print
			end
		end
	end
end

class Model_class < Class_class
	def initialize(name)
		super(name)
		@has_one = Array.new
		@has_many = Array.new
	end
	def addHasOne(hasone_name)
		@has_one.push(hasone_name)
	end
	def addHasMany(hasmany_name)
		@has_many.push(hasmany_name)
	end
end

class Controller_class < Class_class
	def initialize(name)
		super(name)
	end
end
