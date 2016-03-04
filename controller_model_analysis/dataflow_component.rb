
class Data_dependency
	def initialize(block, instr, vname)
		@block = block
		@instr = instr
		@vname = vname
		@instr_handler = nil
	end
	def setInstrHandler(h)
		@instr_handler = h
	end
	def getInstrHandler
		@instr_handler
	end
	def getBlock
		@block
	end
	def getInstr
		@instr
	end
	def getVname
		@vname
	end
	def equals(d)
		if d.getBlock == @block and d.getInstr == @instr and d.getVname == @vname
			return true
		else
			return false
		end
	end
end

class Instruction
	def initialize
		@deps = Array.new	
		@resolved = false
		@has_closure = false
		@closure = nil
		@from_user_input = false
		@index = 0
		@f_tag = 0
		@bb = nil
		#TODO: an instruction can match multiple nodes....
		@inode = nil
		@inodes = Array.new
		@defv = nil
		@defv_var = nil
		@args = Array.new
	end
	attr_accessor :defv_var, :args, :inodes, :inode
	def getArgs
		@args
	end
	def setDefv(d)
		@defv = d
	end
	def getDefv
		@defv
	end
	def setFromUserInput
		@from_user_input = true
	end
	def getFromUserInput
		@from_user_input
	end
	def getToUserOutput
		if @bb.getCFG.instance_of?Closure
			@bb.getCFG.getViewCode
		else
			return false
		end
	end
	def setINode(i)
		@inode = i
		@inodes.push(i)
	end
	def getINode
		@inode
	end
	def getINodes
		@inodes
	end
	def getMethodDefCFG
		return @bb.getMethodDefCFG
	end
	def setBB(_bb)
		@bb = _bb
	end
	def getBB
		@bb
	end
	def setFTag(f)
		@f_tag = f
	end
	def getFTag
		@f_tag
	end
	def addClosure(cl)
		@closure = cl
		cl.parent_instr = self
		@has_closure = true
	end
	def hasClosure?
		@has_closure
	end
	def getClosure
		@closure
	end
	def setIndex(ind)
		@index = ind
	end
	def getIndex
		@index
	end
	def addDatadep(dep_string, vname, handler = nil)
		if dep_string == ""
			#no explicit def is found in the closure
			dep = Data_dependency.new(-1, -1, vname)
			if handler != nil
				#puts "#{vname} is defined by #{handler.toString}"
				dep.setInstrHandler(handler)
			end
			@deps.push(dep)
			return
		end
		ary = dep_string.split('.')
		dep = Data_dependency.new(ary[0].to_i, ary[1].to_i, vname)
		#if handler == nil, the dep will be handled in calculate_depinstr_for_cfg in read_dataflow.rb
		if handler != nil
			dep.setInstrHandler(handler)
		end
		exist = false
		@deps.each do |d|
			if d.equals(dep)
				exist = true
			end
		end
		if exist == false
			@deps.push(dep)
		end
	end
	def getDeps
		@deps
	end
	def isResolved?
		@resolved
	end
	def setResolved
		@resolved = true
	end
	def toString
		#s = "[#{self.getBB.getCFG.getMHandler.getName}] (#{@bb.getIndex}.#{@index}) "
		s = "(#{@bb.getIndex}.#{@index}) "
		@deps.each do |dep|
			s = s + "#{dep.getVname}[#{dep.getBlock}.#{dep.getInstr}] "
		end
		return s
	end
	def toString2
		s = ""
		return s
	end 
end

class Call_instr < Instruction
	def initialize(_caller, _funcname)
		@deps = Array.new	
		@resolved = false
		@caller = _caller; #string
		@funcname = _funcname	
		@resolved_caller = ""
		@call_handler = nil #Function_call
		@call_cfg = nil #CFG
		@field = nil
		@hash_fields = Array.new
		@args = Array.new
		@inodes = Array.new
	end
	attr_accessor :field, :hash_fields
	def setCallCFG(c)
		@call_cfg = c
	end
	def getCallCFG
		@call_cfg
	end
	def setCallHandler(h)
		@call_handler = h
	end
	def getCallHandler
		@call_handler
	end
	def getCallerType
		#This is only for method without CFG, for example, scope
		if @call_handler and @call_handler.caller
			return @call_handler.caller.getName
		else
			return type_valid(self, @caller)
		end
	end
	def getTableName
		if @funcname.end_with?("_count") and testTableField(getCallerType, @funcname[0...-6].downcase.singularize)
			return @func_name[0...-6].downcase.singularize.capitalize
		end	
		return self.getCallerType
	end
	def getQueryType
		if @call_handler and @call_handler.getQueryType 
			return @call_handler.getQueryType
		end
		t = type_valid(self, @caller)
		if isActiveRecord(t)
			qtype = check_method_keyword(t, @funcname)
			
			return qtype
		end	
	end
	def isQuery
		if getQueryType
			return true
		else
			return false
		end
	end
	def isReadQuery
		qtype = getQueryType
		if qtype != nil and ["SELECT","GROUP","JOIN","TXN"].include?qtype
			return true
		end
		return false
	end
	def isTableField
		if self.instance_of?AttrAssign_instr 
			return false
		end
		t = type_valid(self, @caller)
		if t != nil
			if testTableField(t, @funcname)
				return true
			else
				return false	
			end
		end
		return false
	end
	def isClassField
		if self.instance_of?AttrAssign_instr
			return false
		else
			t = type_valid(self, @caller)
			if t != nil
				if $class_map[t] != nil
					return $class_map[t].getClassFields.include?(@funcname)
				end
			end
		end
		return false
	end
	def getCaller
		@caller
	end
	def getFuncname
		@funcname
	end
	def setFuncname(f)
		@funcname = f
	end
	def setResolvedCaller(_caller)
		@resolved_caller = _caller
		@resolved = true
	end
	def getResolvedCaller
		@resolved_caller
	end
	def getResolvedString
		s = "#{@resolved_caller}.#{@funcname}"
		return s
	end
	def toString
#		s = "#{@caller}->#{@funcname} "
		s = super
		if @call_handler != nil
			s = s + " #{@call_handler.toString}"
		else
			s = s + " #{@caller} -> #{@funcname}"
		end
		return s
	end
	def toString2
		s = super
		if @call_handler != nil
			s = s + " #{@call_handler.toString}"
		else
			s = s + " #{@caller} -> #{@funcname}"
		end
		return s
		#return s.tr(']', ')').tr('[', '(').tr('<', '(').tr('>', ')')
	end
end

class Const_instr < Instruction
	def initialize(const)
		@const = const
		@deps = Array.new	
		@resolved = true
		@resolved_caller = @const
		@inodes = Array.new
	end
	def getConst
		@const
	end
	def getResolvedString
		@const
	end
	def toString
		s = "(#{@const})"
		return s
	end
end

class InheritConst_instr < Const_instr
	def initialize(const)
		super(const)
	end
end

class Return_instr < Instruction
	def initialize
		super
	end
	def toString
		s = "RETURN "
		s = s + super
		return s
	end
end

class BuildString_instr < Instruction
	def initialize
		super
	end
end

class Branch_instr < Instruction
	def initialize
		super
	end
	def toString
		s = "BRANCH "
		s = s + super
		return s
	end
end

class Copy_instr < Instruction
	def initialize
		super
		@type = nil
	end
	attr_accessor :type
	def toString
		s = "COPY "
		s = s + super
		return s
	end
	def isFromConst
		if @type == nil or @type == "PASS"	
			return false
		else
			return true	
		end
	end
end

class HashField_instr < Instruction
	def initialize
		super
		@hash_fields = Array.new
	end
	attr_accessor :hash_fields
	def addHash(h)
		@hash_fields.push(h)
	end
	def toString
		s = "HashField ["
		@hash_fields.each do |h|
			s += "#{h} "
		end
		s += "] "
		s += super
		return s
	end
end

class ReceiveArg_instr < Instruction
	def initialize
		super
	end
	attr_accessor :var_name
	def toString
		s = "RECEIVEARG "
		s = s + super
		return s
	end
	def setDefv(d)
		@defv = d
		@var_name = d
	end
end

class AttrAssign_instr < Call_instr
	def initialize(_caller, _func_name)
		super(_caller, _func_name)
		@field = _func_name
	end
	def toString
		s = "ATTRASSIGN "
		s = s + super
		return s
	end
end

class GetField_instr < Call_instr
	def initialize(_caller, _func_name)
		super(_caller, _func_name)
		@field = _func_name
	end
	def toString
		s = "GETFIELD "
		s = s + super
		return s
	end
end		

class Basic_block
	def initialize(index)
		@outgoings = Array.new
		@datadeps = Array.new
		@instructions = Array.new
		@calls = Array.new
		@index = index.to_i
		@label_n = 0
		@cfg = nil
		@return_list = Array.new
		@explicit_return = Array.new
	end
	attr_accessor :explicit_return, :return_list
	def addExplicitReturn(r)
		if @explicit_return.include?(r)
		else
			@explicit_return.push(r)
		end
	end
	def getExplicitReturn
		@explicit_return
	end
	def addReturn(r)
		if @return_list.include?(r)
		else
			@return_list.push(r)
		end
	end
	def getReturns
		@return_list
	end
	def includeReturnInstr?
		@instructions.each do |i|
			if i.instance_of?Return_instr
				return true
			end
		end
		return false
	end	
	def getMethodDefCFG
		return @cfg.getMethodDefCFG
	end
	def addCFG(cfg)
		@cfg = cfg
	end
	def getCFG
		@cfg
	end
	def addInstr(instr)
		@instructions.push(instr)
		instr.setBB(self)
	end
	def getInstr
		@instructions
	end
	def getInstrNum
		cnt = 0
		@instructions.each do |i|
			if i.hasClosure?
				cnt = cnt + i.getClosure.getInstrNum
			end
			cnt += 1
		end
		return cnt
	end
	def getLastInstr
		@instructions[-1]
	end
	def addOutgoings(node)
		@outgoings.push(node)
	end
	def getOutgoings
		@outgoings
	end
	def getIndex
		@index
	end
	def addDatadeps(dep)
		@datadeps.push(dep)
	end
	def setLabelN(n)
		@label_n = n
	end
	def getLabelN
		@label_n
	end
	def searchDepLocally(instr, var=nil)
		instr.getDeps.each do |dep|
			if dep.getBlock == @index #locally, blockID matches
				if var != nil
					if var == dep.getVname
						return @instructions[dep.getInstr]
					end
				else
					return @instructions[dep.getInstr]
				end
			end
		end	
		return nil
	end
	def findCalls
=begin
		@instructions.each do |instr|
			if instr.is_a?Call_instr
				#caller = self
				if instr.getCaller=="%self"
					instr.setResolvedCaller("self")
	
				else
					caller_v = instr.getCaller
					dep_instr = searchDepLocally(instr, caller_v)
					if instr.getCaller.include?('%')==false
						instr.setResolvedCaller(instr.getCaller)
					elsif dep_instr != nil and dep_instr.isResolved?
						instr.setResolvedCaller(dep_instr.getResolvedString)
					else
						instr.getDeps.each do |d|
							if d.getVname.include?('%') == false
								instr.setResolvedCaller(d.getVname)
							end
						end
					end
				end
			elsif instr.is_a?Const_instr
				instr.setResolved
			end
			if instr.hasClosure?
				instr.getClosure.getBB.each do |bb|
					bb.findCalls
				end
			end
		end
=end
	end
	def self_print
		puts "BB #{@index}"
		print "  outgoing:"
		s = ""
		@outgoings.each do |og|
			s = s + "#{og} "
		end
		puts "#{s}"
		puts "  instructions:"
		index = 0
		@instructions.each do |instr|
			puts "    #{index}: #{instr.toString}"
			if instr.hasClosure?
				instr.getClosure.self_print
			end
			index = index + 1
		end
	end
end

class CFG
	def initialize
		@bb = Array.new
		#return_list is the return point in control flow, including both "RETURN" instr and exit point in CFG
		@return_list = Array.new
		#explicit_return is the return point in data flow, only include "RETURN" instr
		@explicit_return = Array.new
		@m_handler = nil
		#All nodes that last defines "self", used for validation like "before_save"
		@def_self_nodes = Array.new #INode
		@var_map = Hash.new
		@return_type = nil
		@arg_types = Array.new
	end
	attr_accessor :explicit_return, :return_list, :return_type, :arg_types
	def setReturnType(type)
		if @return_type == nil
			@return_type = type
		#TODO: multiple return types, polymorphic!
		elsif $class_map[type.type] != nil
			@return_type = type
		end
	end
	def getVarMap
		@var_map
	end
	def addToVarMap(v_name, var)
		@var_map[v_name] = var
	end
	def getDefSelf
		@def_self_nodes
	end
	def addDefSelf(s)
		@def_self_nodes.push(s)
	end
	def clear
		@def_self_nodes = Array.new
	end
	def getInstrNum
		cnt = 0
		@bb.each do |b|
			cnt = cnt +  b.getInstrNum
		end
		return cnt
	end
	def getMethodDefCFG
		return self
	end
	def setMHandler(m)
		@m_handler = m
	end
	def getMHandler
		@m_handler
	end
	def addExplicitReturn(r)
		@explicit_return.push(r)
	end
	def getExplicitReturn
		@explicit_return
	end
	def addReturn(r)
		@return_list.push(r)
	end
	def getReturns
		@return_list
	end
	def getBB
		@bb
	end
	def addBB(basicb)
		@bb.push(basicb)
		basicb.addCFG(self)
	end
	def findCalls
		getBB.each do |bb|
			bb.findCalls
		end	
	end
	def getBBByIndex(i)
		@bb.each do |b|
			if b.getIndex == i
				return b
			end
		end
		return nil
	end
end

class Closure < CFG
	def initialize
		r = Random.new
		@rnd = r.rand(1...1048576)
		@view_code = false
		@view_closure = false
		@var_def_table = Array.new
		@closure_def_table = Array.new 
		@parent_instr = nil
		super
	end
	attr_accessor :parent_instr
	def setReturnType(type)
		@return_type = type
		if @parent_instr != nil
			@parent_instr.getBB.getCFG.setReturnType(type)
		end
	end
	def setViewClosure
	  @view_closure = true
	end
	def getMethodDefCFG
		return @parent_instr.getMethodDefCFG	
	end
	def getViewClosure
	   @view_closure
	end
	def addToVarDefTable(vname, dep, handler)	
		ary = dep.split('.')
		dep = Data_dependency.new(ary[0].to_i, ary[1].to_i, vname)
		dep.setInstrHandler(handler)
		@var_def_table.push(dep)
	end
	def addToClosureDefTable(vname, dep, handler)	
		ary = dep.split('.')
		dep = Data_dependency.new(ary[0].to_i, ary[1].to_i, vname)
		dep.setInstrHandler(handler)
		@closure_def_table.push(dep)
	end

	def getVarDefs(vname)
		r = Array.new
		@var_def_table.each do |v|
			if v.getVname == vname
				r.push(v)
			end
		end
		return r
	end
	def getMHandler
		return @parent_instr.getBB.getCFG.getMHandler
	end
	def getRand
		@rnd
	end
	def setViewCode
		@view_code = true
	end
	def getViewCode
		@view_code
	end
	def getLastBB
		return @bb[-1]
	end
	def getFirstBB
		return @bb[0]
	end
	def self_print
		puts "CLOSURE BEGIN"
		getBB.each do |bb|
			bb.self_print
		end
		puts "CLOSURE END"
	end
end
