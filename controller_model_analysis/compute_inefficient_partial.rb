def compute_inefficient_partial

	puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	puts "compute_inefficient_partial"
	
	view_helpers = ['content_tag', 'tag', 'form_tag']

	@closures = Array.new
	@query_loops = Array.new
	$node_list.each do |n|
			if n.getInClosure
				if n.getNonViewClosureStack.length > 0
						@closures |= n.getNonViewClosureStack
				end
			end
	end
	results = []
	@closures.each do |cl|
		@cl_nodes = Array.new
		if !cl.getInstr.getClosure
			next
		end
		#puts "The #{@closures.index(cl)} th CL"
		# Add realted nodes to the closure
		$node_list.each do |n| 
			if n.getInClosure and n.getNonViewClosureStack.include?cl
				@cl_nodes.push(n)
			end
		end
		@cl_nodes.each do |cn|
			if cn.getInstr.instance_of?Call_instr 
				funcname = cn.getInstr.getFuncname
				puts "funcname #{funcname} #{cn.getInstr.toString} #{cn.cur_class}"
				if view_helpers.include?funcname
					results.push(cn)
				end
			end
		end
	end
	results.each do |re|
		r = getInstrLN(re.getInstr)
		$inefficient_render_file.puts "<inefficientRender>"
		$inefficient_render_file.puts "<statement>"
		$inefficient_render_file.puts "#{r[1]}"
		$inefficient_render_file.puts "</statment>"
		$inefficient_render_file.puts "<filename>"
		$inefficient_render_file.puts "#{r[0]}"
		$inefficient_render_file.puts "</filename>"			
		$inefficient_render_file.puts "</inefficientRender>"
	end
	puts "FINISH"
	puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
end


