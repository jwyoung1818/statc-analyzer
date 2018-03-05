def solve_all_renders
	$actions.each do |k, a|
		puts "@@@@@ #{a.name} #{a.is_entrance} #{a.has_non_default_or_layout_render}"
		if a.is_entrance or a.has_non_default_or_layout_render or (a.render_stmts.length > 0 and a.render_stmts[0].is_default)
			con = solve_render_for_action(a)
			a.replaced_code = con 
			# if $only_generate_nextcall == false
			# 	puts "Action: #{a.controller.name}.#{a.name} renders:"
			# 	str = ""
			# 	a.render_stack.each do |r|
			# 		puts "\t#{r.render_file}"
			# 		str += "\n"
			# 		str += r.get_content
			# 	end
			# 	str += "\n"
			# 	a.replaced_code = con 
			# end
		end
	end
end


def replace_files
	#TODO: mkdir
	$controllers.each do |k, v|
		fp = File.open("#{v.file_name}","r")
		content = fp.read
		puts "CONTENT #{content}"
		dic = create_dic(v.file_name, content)
		fp.close
		sorted_actions = v.actions.sort_by {|a| -a.astnode.line}
		sorted_actions.each do |a|
			if a.render_stack.length > 0 and  a.replaced_code.length > 0
				puts "Replace #{a.controller.name}.#{a.name}"
				#content = content.gsub(a.astnode.source[0...-1], "#{a.astnode.source[0...-1]}#{a.replaced_code}")
				#key = a.astnode.source[0...-1]
				k = a.astnode.parent.source
				content[k] = "#{a.replaced_code[0]}"
				# deal with move of the class controller 
				start = a.astnode.parent.line
				puts "START #{start}"
				l = k.lines.count
				dic2 = a.replaced_code[1]
				dic = insert2(dic, dic2, start, l)
				#content, dic = deleteComments(content, dic)
			end
		end
		# delete the comments and space
		content, dic = deleteComments(content, dic)
		puts "FINAL #{dic.length} #{dic.sort}"
		new_file_name = v.file_name.gsub($controller_folder_name, $new_controller_folder_name)
		puts "Rewriting #{new_file_name}"
		file_path = new_file_name.gsub(File.basename(new_file_name),'')
		run_command("mkdir -p #{file_path}")
		File.write("#{new_file_name}", content)
		
		line_file_name = new_file_name + ".line"
		puts line_file_name
		File.write("#{line_file_name}", dic.sort.to_h)
		# #### MAKE THE LINE NUMBER CORRESPONDS TO THE INSTRUCTION
		# # if a line starts with space, delete the space
		# run_command("sed -e 's/^[ \t]*//' #{new_file_name} > tmp.rb")
		# run_command("mv tmp.rb #{new_file_name}")
		# # remove empty line
		# run_command("sed '/^$/d' #{new_file_name} > tmp.rb")
		# run_command("mv tmp.rb #{new_file_name}")
		# # remove comments line e.g. starts with #
		# run_command("sed '/#.*/d' #{new_file_name} > tmp.rb")
		# run_command("mv tmp.rb #{new_file_name}")
		#make sure the replaced file parses
		ast = YARD::Parser::Ruby::RubyParser.parse(File.open(new_file_name, "r").read)
	end
	
	if $has_helper
		$helpers.each do |k, v|
			fp = File.open("#{v.file_name}","r")
			content = fp.read
			fp.close
			dic = create_dic(v.file_name, content)
			v.actions.each do |a|
				if a.render_stack.length > 0 and  a.replaced_code.length > 0
					puts "Replace #{a.controller.name}.#{a.name}"
					#content = content.gsub(a.astnode.source[0...-1], "#{a.astnode.source[0...-1]}#{a.replaced_code}")
					#content[a.astnode.source[0...-1]] = "#{a.astnode.source[0...-1]}#{a.replaced_code}" 
					k = a.astnode.parent.source
					content[k] = "#{a.replaced_code[0]}"
					# deal with move of the class controller 
					start = a.astnode.parent.line
					l = k.lines.count
					dic2 = a.replaced_code[1]
					dic = insert2(dic, dic2, start, l)			
				end
			end
			content, dic = deleteComments(content, dic)	
			new_file_name = v.file_name.gsub($helper_folder_name, $new_helper_folder_name)
			puts "Rewriting #{new_file_name}"
        	file_path = new_file_name.gsub(File.basename(new_file_name),'')
        	run_command("mkdir -p #{file_path}")
			File.write("#{new_file_name}", content)
			
			line_file_name = new_file_name + ".line"
			puts line_file_name
			File.write("#{line_file_name}", dic)

			ast = YARD::Parser::Ruby::RubyParser.parse(File.open(new_file_name, "r").read)

		end
	end
end

def solve_render_for_action(action)
	#first, check layout
	if action.use_layout and action.controller.exist_layout
		action.push_to_render_stack(action.controller.get_layout)
	end	
	#then check render stmt
	exist_render = false
	# put the whole action's code as the source
	ast_node = action.astnode.parent
	str = ast_node.source
	# start position of this action inside the controllers
	sp = ast_node.line
	puts "action ssss #{sp} #{ast_node.source}"
	dic = create_dic(action.controller.file_name, str, sp)
	ar = action.render_stmts
	# sort the action buy it's line_range, so that the order will not change
	valid_stmts = action.render_stmts.select {|rs| rs.valid_file_path && rs.astnode}
	rss = valid_stmts.sort_by {|rs| -rs.astnode.line_range.to_a.last}
	rss.each do |r|
		if r.valid_file_path
			if(r.astnode)
				action.push_to_render_stack(r)
				exist_render = true
				s, dic2 = solve_render_for_view(action, r.render_file)
				start = r.astnode.line_range.to_a.last - sp + 1
				dic = insert(dic, dic2, start)
				str = insertString(str, start, s)
				# str = str.gsub(r.astnode.source, r.astnode.source + "\n"+ s.chop)
				puts "***************"
				puts str
				puts "----------------"
				puts s 
				#action.astnode = YARD::Parser::Ruby::RubyParser.parse(str).root
			end
		end
	end
	#if no exist render, check default render
	if exist_render == false
		if action.exist_template
			action.push_to_render_stack(action.get_template)
			start = action.astnode.line_range.to_a.last - 1
			puts "BEFORE END"
			s, dic2 = solve_render_for_view(action, action.get_template.render_file)
			str = str + "\n"  +  s
			dic = insert(dic, dic2, start)
		end
	end
	#puts dic.sort_by { |k,v| k.to_s }
	return str, dic
end

#recursively...
def solve_render_for_view(action, view_file)
	viewf = find_view_file(view_file)
	if viewf
		str = viewf.get_content
		dic = {}
		code = viewf.get_content
		# .gsub($new_view_folder_name, $view_folder_name)
		dic = create_dic(view_file, code)
		if viewf.render_stmts.length == 0
			return viewf.get_content, dic
		end
		rss = viewf.render_stmts.sort_by {|rs| -rs.astnode.line_range.to_a.last}
		rss.each do |r|
			#puts "#{view_file}: #{r.astnode.source}"
			# recursively rendering
			puts "#{r.render_file} #{view_file}"
			if r.valid_file_path && r.render_file != view_file
				#exist = viewf.push_to_render_stack(r)
				#exist = action.push_to_render_stack(r)
				#if exist == true
					s, dic2 = solve_render_for_view(viewf, r.render_file)
					puts "RRR #{r.astnode.line_range.to_a.last} #{r.astnode.source}"
					start = r.astnode.line_range.to_a.last
					dic = insert(dic, dic2, start)
					# chop here since the new line will included by the gsub
					# str = str.gsub(r.astnode.source, r.astnode.source + "\n" + s.chop)
					str = insertString(str, start, s)
				#end
			end 
		end
		puts "STTTTTTR IS #{str}"
		return str, dic
	end
	return '', dic
end

def insert(dic, dic2, start)
	length = dic2.length
	dic_dup = dic.clone
	for key in dic.keys()
		puts "KEY IS : #{key}"
		if key > start
			dic[key + length] = dic_dup[key]
			puts "#### #{key + length} #{dic_dup[key]}"
		end
	end
	for key in dic2.keys()
		dic[start + key] = dic2[key]
		puts "**** #{start + key} #{dic2[key]}"
	end
	
	puts "HASH #{dic.length} #{dic.sort}"

	return dic
end

def insert2(dic, dic2, start, l)
	length = dic2.length
	dic_dup = dic.clone
	for key in dic.keys()
		puts "KEY2 IS : #{key}"
		if key > start
			dic[key + length - l] = dic_dup[key]
			puts "####2 #{key + length} #{dic_dup[key]}"
		end
	end
	for key in dic2.keys()
		dic[start + key - 1] = dic2[key]
		puts "****2 #{start + key} #{dic2[key]}"
	end
	
	puts "HASH2 #{dic.length} #{dic.sort}"

	return dic
end

def deleteLine(dic, l)
	# sort the key so that they can be moved up by 1
	puts "Delete #{dic[l]}"
	for key in dic.keys().sort
		if key > l
			dic[key - 1] = dic[key]
		end
	end
	# delete the last key
	dic.delete(key)
	return dic
end

def deleteComments(str, dic)
	re = ""
	ls = str.lines
	length = ls.length
	for i in 1..length
		index = length - i
		line = ls[length - i]
		if !line.strip.start_with?("#") && line.strip != ''
			re = line + re
		else
			puts "DELETE"
			puts "#{line}, #{index}"
			dic = deleteLine(dic, index + 1 )
		end
	end

	return re, dic
end
def create_dic(view_file, code, start = 1, ss = 1)
	dic = {}
	l = code.lines.count
	puts "VIEW FILE #{view_file} #{l}"
	puts "#{code}"
	for i in start..(start + l - 1)
		dic[i - start + 1] = [view_file, i]
		puts "III #{i}"
	end
	return dic
end

def insertString(str, ln, content)
	ls = str.lines
	re = ""
	for i in 1..ln
	
		con = ls[i - 1]
		
		re = re + con
		re = re 
		
	end
	
	re += content
	
	for i in (ln + 1)..ls.length
	
		con = ls[i - 1]
		re = re + con
		re = re 
	end
	
	re
end 