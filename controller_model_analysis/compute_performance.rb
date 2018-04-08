def compute_performance(output_dir, start_class, start_function, build_node_list_only=false)
	log_filename = "#{$app_dir}/#{start_class}_#{start_function}.log"
	log_file = open(log_filename)
	queries = []
	for l in log_file
		l = l.strip
		#froms,time, table, type, used 
		if l.start_with?('Query Trace')
			fn = l[/app.*rb/].gsub('app/', '')
			loc = l[/:.*:/].gsub(":", '').to_i
			froms = []
			query = []
			# froms << [fn, loc] unless fn.include?("models/")
			if !fn.include?("models/") and froms.length == 0
				froms << [fn, loc]
			end
			query << froms
			next
		end
		if l.start_with?('from')
			fn = l[/app.*rb/].gsub('app/', '') 
			loc = l[/:.*:/].gsub(":", '').to_i
			# froms << [fn, loc] unless fn.include?("models/")
			if !fn.include?("models/") and froms.length == 0
				froms << [fn, loc]
			end
			next
		end
		if l['Load'] or l['COMMIT'] or l['UPDATE'] or l['BEGIN'] or l['SELECT']
			time = l[/\(.*ms\)/]
			tts = l.split(time)[0]
			if tts.strip.split(' ').length == 2
				table = tts.strip.split(' ')[0]
				type = tts.strip.split(' ')[1]
			end
			if l['COMMIT']
				table = ''
				type = 'COMMIT'
			end
			if l['UPDATE']
				table = ''
				type = 'UPDATE'
			end
			if l['BEGIN']
				table = ''
				type = 'BEGIN'
			end
			time = time.gsub('(','').gsub(')','').gsub('ms', '').to_f
			query << time
			query << table
			query << type
			query << 0
			queries << query
			puts "QUERY #{query}"
		end
	end
	if $root == nil
		$cfg = trace_query_flow(start_class, start_function, "", "", 0)
		addAllControlEdges
		compute_source_sink_for_all_nodes
		if $cfg == nil
			return
		end
		if $cfg.getBB[0] == nil or $cfg.getBB[0].getInstr[0] == nil
			exit
		end
		$root = $cfg.getBB[0].getInstr[0].getINode	
	end
	
	
	$node_list.each do |n|
		n.setLabel
		$temp_file.puts "#{n.getIndex}:#{n.getInstr.toString}"
		if n.getValidationStack.length > 0
			str = ""
			n.getValidationStack.each do |v|
				str += "#{v.getIndex}, "
			end
			#$temp_file.puts "\t * \t transaction #{str}"
		end

		if n.getInstr.is_a?Call_instr
			caller_type = type_valid(n.getInstr, n.getInstr.getCaller)
			returnv = ""
			if n.getInstr.getDefv
				returnv = type_valid(n.getInstr, n.getInstr.getDefv)
			end
		end
	end
	cost = {}
	final_cost = {}
	final_dep = {}

	$node_list.each do |n|
		if n.getInstr
	    	re = getInstrLN(n.getInstr)
	    	if re #and re[2] == 1
	    		#puts "Rendered #{re}"
    			if cost[n]
					if final_cost[n]
						final_cost[n] += cost[n]
					else
						final_cost[n] = cost[n]
					end
    			end
	    		tdds = traceback_data_dep(n)
	    		puts "n is #{n.getInstr.toString}"
				n.getInstr.getDeps.each do |dep|
					puts "#{dep.getBlock} #{dep.getInstr}"
				end
	    		tdds.each do |tdd|
	    			ln = getInstrLN(tdd.getInstr)[0..1]
	    			puts "TDD: #{tdd.getInstr. toString}"
					for query in queries
						if !final_dep[n]
							final_dep[n] = []
						end
						if ! final_dep[n].include?query and query[0][0] == ln
							if final_cost[n]
								final_cost[n] += query[1]
							else
								final_cost[n] = query[1]
							end
							# puts "final_cost is : #{tdd.getInstr.toString} #{ln} #{final_cost[n]} tdd_cost: #{cost[tdd]}"
							final_dep[n] << query
						end
						
					end
					# puts "final_dep #{final_dep[n]}"
				
	    		end
	    		
	    	end
    	end
	end
	cost.each do |key, value|
		puts "#{key.getInstr.toString}"
		puts "#{getInstrLN(key.getInstr)}"
		puts value
	end
	
	puts "-------------------"

	final_cost.each do |key, value|
		puts "#{key.getInstr.toString}"
		puts "#{getInstrLN(key.getInstr)}"
		puts value
	end

end
