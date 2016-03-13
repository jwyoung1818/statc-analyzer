require 'yard'
require 'logger'
require 'optparse'
require 'date'

#Global variables:
load 'global_variables.rb'

#Helpers:
load 'helper.rb'
load 'check_is_query.rb'
load 'check_validation.rb'
load 'util.rb'

#App ruby code parser:
load 'traverse_ast.rb'
load 'parse_node.rb'

#Data structure for classes/modules and functions:
load 'func_call.rb'
load 'class_method.rb'

#Data structure for dataflow:
load 'dataflow_component.rb'
load 'graph_component.rb'
load 'type_inference.rb'

#Read files:
load 'read_app_files.rb'
load 'read_dataflow_log.rb'
load 'read_schema.rb'

#Trace a controller action and build dataflow graph:
load 'trace_flow.rb'
load 'build_dataflow_graph.rb'

#Compute stats:
load 'compute_stats.rb'
load 'compute_functional_dependency_stat.rb'
load 'compare_consequent_actions.rb'
load 'compute_branch_stat.rb'
load 'compute_dataflow_chain_stat.rb'

PATH_ORDER = [
  'lib/yard/autoload.rb',
  'lib/yard/code_objects/base.rb',
  'lib/yard/code_objects/namespace_object.rb',
  'lib/yard/handlers/base.rb',
  'lib/yard/generators/helpers/*.rb',
  'lib/yard/generators/base.rb',
  'lib/yard/generators/method_listing_generator.rb',
  'lib/yard/serializers/base.rb',
  'lib/**/*.rb'
]

#iterate over all controllers

def print_classes(class_name=nil)
	if class_name == nil
		$class_map.each do |keyc, valuec|
			valuec.print_calls
		end	
	else
		$class_map[class_name].print_calls
	end
end

def print_types(class_name=nil)
	if class_name == nil
		$class_map.each do |keyc, valuec|
			valuec.print_var_types
		end	
	else
		$class_map[class_name].print_var_types
	end
end

def print_instructions(class_name=nil)
	if class_name == nil
		$class_map.each do |keyc, valuec|
			valuec.print_instructions
		end	
	else
		$class_map[class_name].print_instructions
	end
end


options = {}

pgr = Random.new((DateTime.now.strftime('%Q')).to_i)
$fast_random = Fast_random.new(pgr.rand(1...104829910))

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: ruby parsing.rb [OPTIONS]"

  opt.on("-p","--print [CLASS_NAME]",String,"print out variable and function call names of class specified; or type all to print out all classes","example: --print CommentsController or --print all") do |class_name|
		options[:class_name] = class_name
  end

	opt.on("-r","--trace CLASS_NAME,FUNCTION_NAME",Array,"needs two arguments, class_name function_name; will print out call graph of the function specified","example: --trace CommentsController,create") do |trace_input|
		options[:trace_input] = trace_input
  end

	opt.on("-c","--consequent CLASS_NAME,FUNCTION_NAME",Array,"calculate the overlap between two controller functions","example: --consequent CommentsController,create") do |cons_input|
		options[:consequent] = cons_input
  end


	opt.on("-d","--dir DIR",String,"the application directory, for example, -d /home/congy/lobsters/app, by default it is ./losters,","where the controllers/models/logs of lobsters application is located") do |dir|
   	options[:dir] = dir
  end

	opt.on("-a","--run-all","Run all entrance") do |run_all|
		options[:run_all] = true
	end

	opt.on("-i", "--only-type-inference","Only do type inference, and search method by name upon function call.","Using this option the script may not be able to resolve every function call, but no need for dynamic type logs.") do |inference|
		options[:inference] = true
	end

	opt.on("-v", "--print-validation",String,"Print queries in validation") do |print_validation|
		options[:print_validation] = true
	end


	opt.on("-n", "--print-instr [CLASS_NAME]",String,"Print instructions and CFG of all methods in the specified class") do |class_name|
		options[:printinstr] = class_name
	end

	opt.on("-t", "--trace-dataflow CLASS_NAME,FUNCTION_NAME",Array,"needs two arguments, class_name,function_name; print call graph and data flow to a file, use graphviz to visualize") do |trace_input|
		options[:trace_flow] = true
		if options[:trace] == nil
			options[:trace]  = trace_input
		end
	end

	#opt.on("-r", "--random-path","instead of calculate the complete control flow graph, select random path at each branch") do |random_path|
	#	options[:random_path] = true
	#end

	opt.on("-g", "--query-graph CLASS_NAME,FUNCTION_NAME",Array,"print out flow graph only containing queries") do |q_input|
		options[:query_graph] = true
		if options[:trace] == nil
			options[:trace] = q_input
		end
	end

	opt.on("-s", "--stats CLASS_NAME,FUNCTION_NAME",Array,"print some stats, including query_num, dataflow grap from user input to user output, etc. Needs two argument") do |stats|
			options[:stats] = true
			options[:trace] = stats
	end

	opt.on("-o", "--output-dir DIR",String,"Output directory for graphviz files") do |output_dir|
		options[:output] = output_dir
	end
	
	opt.on("-b", "--print-all","Print all calls, only for debug") do |print_all|
		options[:print_all] = true
	end

  opt.on("-h","--help","help") do
		options[:help] = true
    puts opt_parser
		puts "=================="
		puts "Example: ruby main.rb -a -d ../applications/boxroom"
  end
end

opt_parser.parse!

if options[:help]
	exit
end

if options[:inference] == true
	$type_inference = true
end

if options[:dir] != nil
	puts "dir = #{options[:dir]}"
	if options[:template] != nil
		read_ruby_files_with_template(options[:dir], options[:template])
	else
		$app_dir = options[:dir]
		read_ruby_files(options[:dir])
		#puts "Finish reading files"
	
		#$class_map.each do |k, v|
		#	v.getMethods.each do |k1, v1|
		#		puts "#{k} . #{k1}:"
		#		#if v1.getCFG == nil
		#			v1.getCalls.each do |c|
		#				puts "\t#{c.getObjName} . #{c.getFuncName}"
		#			end
		#		#end
		#	end
		#end

		read_dataflow(options[:dir])
		
		do_type_inference
	end
else
	read_ruby_files
	read_dataflow
	do_type_inference
end

if options[:class_name] != nil
	if options[:class_name] == "all"
		print_classes
	else
		print_classes(options[:class_name])
	end
end

if options[:class_name_for_type] != nil
	if options[:class_name_for_type] == "all"
		print_types
	else
		print_types(options[:class_name_for_type])
	end
end

if options[:printinstr] != nil
	if options[:printinstr] == "all"
		print_instructions
	else
		print_instructions(options[:printinstr])
	end
end

if options[:trace_input] != nil
	start_class = options[:trace_input][0]
	start_function = options[:trace_input][1]
	level = 0
end


if options[:output] != nil
	$output_dir = options[:output]
end


if options[:trace_flow] or options[:random_path] or options[:stats] or options[:query_graph]
	start_class = options[:trace][0]
	start_function = options[:trace][1]
	level = 0

	if options[:trace_flow] or options[:random_path]
		graph_fname = "#{$output_dir}/#{start_class}_#{start_function}_graph.log"
		$graph_file = File.open(graph_fname, "w");

		$graph_file.write("digraph #{remove_special_chars(start_class)}_#{start_function} {\n")
		if options[:random_path]
			#print_random_trace(start_class, start_function)
		else
			trace_flow(start_class, start_function, "", "", level)
		end
		$graph_file.write("}")
	end

	if options[:query_graph]
		print_query_graph($output_dir, start_class, start_function)
	end

	if options[:stats]
		if options[:random_path]
			compute_dataflow_stat($output_dir, start_class, start_function, true)
		else
			compute_dataflow_stat($output_dir, start_class, start_function)
		end
	end
end

if options[:run_all]
	system("rm -rf #{$app_dir}/results/")
	system("mkdir #{$app_dir}/results/")
	call_file = "#{$app_dir}/calls.txt"
	File.open(call_file, "r").each do |line|
		line = line.gsub("\n","")
		chs = line.split(',')
		start_function = chs[1]
		start_class = getControllerNameCap(chs[0])
		puts "Handling #{start_class}, #{start_function}"
		level = 0
	
		#start print query trace
		$output_dir = "#{$app_dir}/results/#{start_class}_#{start_function}"
		system("mkdir #{$output_dir}")
		graph_fname = "#{$output_dir}/#{start_class}_#{start_function}_graph.log"
		$graph_file = File.open(graph_fname, "w");

		#$trace_output_file = File.open("#{$output_dir}/trace.temp", "w")
		#trace_flow(start_class, start_function, "", "", level)
		#$trace_output_file.close

		puts "Trace output finish"

	#start compute stat
		$cur_node = nil
		$root = nil
		$non_repeat_list = Array.new
		$global_check = Hash.new
		$node_list = Array.new
		$cur_query_stack = Array.new
		$query_edges = Array.new

		compute_dataflow_stat($output_dir, start_class, start_function)
		puts "\t..Finish computing stats"
	#start print overlap between current and next controller actions
		next_file = nil
		if start_class.include?("::")
			l = start_class.gsub("\n","")
			chs = l.split('::')
 			chs[0] = chs[0].downcase
			next_file = "#{$app_dir}/next_calls/#{chs[0]}/#{chs[1]}_#{start_function}.txt"
		else	
			next_file = "#{$app_dir}/next_calls/#{start_class}_#{start_function}.txt"
		end
		if File.exist?(next_file)

			graph_fname = "#{$output_dir}/next_action.xml"
			$graph_file = File.open(graph_fname, "w")
			$graph_file.puts("<NEXTACTION>")

			@next_action = Array.new
			@prev_list = Array.new 
			$node_list.each do |n|
				@prev_list.push(n)
			end
			
			clear_data_structure
			File.open(next_file, "r").each do |line|
				if line.length > 1
					line = line.gsub("\n","")
					if @next_action.include?line
					else
						@next_action.push(line)
					end
				end
			end
				
			@next_action.each do |line|

				line = line.gsub("\n","")
				chs = line.split(',')
				next_function = chs[1]
				next_class = getControllerNameCap(chs[0])

				compute_dataflow_stat($output_dir, next_class, next_function, true)
			
				puts "Compare with: #{next_class}.#{next_function}"
				compare_consequent_actions("#{next_class}_#{next_function}", @prev_list, $node_list)
				clear_data_structure
			end

			$graph_file.puts("<\/NEXTACTION>")
			$graph_file.close
		end

		clear_data_structure
	end
end

if options[:consequent] != nil
	start_class = options[:consequent][0]
	start_function = options[:consequent][1]
	
	level = 0
	$trace_output_file = File.open("#{$output_dir}/trace.temp", "w")
	compute_dataflow_stat($output_dir, start_class, start_function, true)


	@prev_list = Array.new 
	$node_list.each do |n|
		@prev_list.push(n)
	end

	view_by_controllers_dir = "../zewei/view_controller_analysis/links_by_controllers/lobsters/#{start_class}_#{start_function}.txt"
	@next_action = Array.new
	File.open(view_by_controllers_dir, "r").each do |line|
		if line.length > 1
			line = line.gsub("\n","")
			if @next_action.include?line
			else
				@next_action.push(line)
			end
		end
	end
			
#	next_file = "#{$app_dir}/next_calls/#{start_class}_#{start_function}.txt"
#	File.open(next_file, "r").each do |line|
	@next_action.each do |line|
		clear_data_structure

		line = line.gsub("\n","")
		chs = line.split(',')
		next_function = chs[1]
		chs[0] = chs[0].capitalize
		next_class = "#{chs[0]}Controller"
		compute_dataflow_stat($output_dir, next_class, next_function, true)
	
		puts "Compare with: #{next_class}.#{next_function}"
		compare_consequent_actions("#{next_class}_#{next_function}", @prev_list, $node_list)
	end
end

if options[:print_validation] == true
	call_file = "#{$app_dir}/calls.txt"
	File.open(call_file, "r").each do |line|
		line = line.gsub("\n","")
		chs = line.split(',')
		start_function = chs[1]
		chs[0] = chs[0].capitalize
		start_class = "#{chs[0]}Controller"
		puts "Handling #{start_class}, #{start_function}"
		level = 0

		$output_dir = "#{$app_dir}/results/#{start_class}_#{start_function}"
		system("mkdir #{$output_dir}")
		graph_fname = "#{$output_dir}/validation.log"
		puts "Graph_name = #{graph_fname}"
		$graph_file = File.open(graph_fname, "w");
		clear_data_structure

		$cfg = trace_query_flow(start_class, start_function, "", "", 0)
		addAllControlEdges
		compute_source_sink_for_all_nodes
		check_validations

	end
end

if options[:xml] == true
	generate_xml_files
end

if options[:print_all] == true
	#$class_map.each do |keyc, valuec|
		#puts "class #{keyc} < #{valuec.getUpperClass} #{isActiveRecord(keyc)}"
		#valuec.getMethod("before_save").getCalls.each do |s|
		#	puts "\t#{s.getFuncName}"
		#end
		#puts "class #{keyc}"
		#if $table_names.find(keyc) != nil
		#	valuec.getFields.each do |f|
		#		puts "\t#{f.field_name} | #{f.type}"
		#	end
		#end
		#valuec.getMethods.each do |keym, valuem|
		#	puts "\tdef #{keym}"
		#end
		#print "#{keyc}: "
		#valuec.getCreate.each do |c|
		#	print "#{c.getFuncName}, "
		#end
		#puts ""
	#end
	_file = File.open("#{$app_dir}/table_name.txt", "w")
	f2 = File.open("#{$app_dir}/tablefields.txt","w")
	$table_names.each do |t|
		_file.write("#{t}\n")
	end
	$table_names.each do |t|
		if $class_map[t] != nil
			$class_map[t].getTableFields.each do |f|
				f2.puts("#{t}.#{f.field_name}")
			end
		else
			puts "Table #{t} doesn't have a class!"
		end
	end
=begin
		valuec.getMethods.each do |keym, valuem|
			cfg = valuem.getCFG
			if cfg!= nil
				cfg.getBB.each do |bb|
					bb.getInstr.each do |instr|
						if instr.instance_of?Call_instr and instr.isReadQuery and instr.hash_fields.length > 0
							puts "#{keyc}.#{keym}: Read QUERY #{instr.toString} fields:"
							s = ""
							instr.hash_fields.each do |h|
								s = s + "#{h} "
							end
							puts "\t\t#{s}"
						end
					end
				end
			end
		end
=end
	#end
end