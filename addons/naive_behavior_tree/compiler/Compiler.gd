tool
extends Reference

#
# BehaviorTree Script Compiler
#
# Compile *.bt to PackedScene
#
# Every BTNode is unique without sharing
#

# BehaviorTree
#   |
#   --- Guards
#   |      |
#   |      ----- BTNode
#   |              ...
#   --- BTNode
#         |
#         ----- Guards
#         |
#         ----- BTNode
#            ....
#

#----- Lib -----
func lib_add(a, b):
	return a + b

func lib_sub(a, b):
	return a - b

func lib_mult(a, b):
	return a * b

func lib_divide(a, b):
	return a / b
#----- Classes -----
const Parser = preload('./Parser.gd')
const Tokenizer = preload('./Tokenizer.gd')
const AST = preload('./AST/AST.gd')
const EXPAST = preload('./AST/EXPAST.gd')

class Importer:
	extends Reference
	
	func import(compiler, path_token):
		return null

class BTNodeImporter:
	extends Importer
	
	func import(compiler, path_token):
		return CustomBTNodeSymbol.new(compiler, path_token)
	

class Symbol:
	extends Reference
	
	var id # token
	
class SubtreeSymbol:
	extends Symbol
	
	var subtree # a AST Tree ref
	
	func get_class():
		return 'SubtreeSymbol'

class FuncSymbol:
	extends Symbol
	
	var func_ref:FuncRef
	var expected_arg_num:int
	var is_op:bool
	
	func _init(f:FuncRef, n:int, op:bool=false) -> void:
		func_ref = f
		expected_arg_num = n
		is_op = op
	
	func get_class():
		return 'FuncSymbol'

class ConstValueSymbol:
	extends Symbol
	
	var value
	
	func _init(v) -> void:
		value = v
	
	func get_class():
		return 'ConstValueSymbol'

class BTNodeSymbol:
	extends Symbol
	
	var the_script
	var the_property_list:Array
	
	var preserved_property_list = [
		'status',
		'parent',
		'tree',
		'guard_path',
		'guard',
		'running_child',
		'current_child_index',
		'random_children'
	]
	
	func _Class_Type_BTNodeSymbol_():
		pass
	
	func gen_property_list():
		var n:BTNode = the_script.new()
		for p in n.get_property_list():
			if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				if not p.name in preserved_property_list:
					the_property_list.append(p.name)
		n.free()
	
	func create_node(compiler, relative_id, args):
		var n = the_script.new()
		
		for a in args:
			if a.key in the_property_list:
				n.set(a.key, a.value)
			else:
				compiler.error(UndefinedParameterError.new(relative_id.value, a.key, relative_id))
		
		return n
	
	func get_class():
		return 'BTNodeSymbol'

class CustomBTNodeSymbol:
	extends BTNodeSymbol
	
	var script_path
	
	func _init(compiler, path_token) -> void:
		script_path = path_token.value
		the_script = load(script_path)
		if not the_script:
			compiler.error(ScriptNotFoundError.new(path_token))
			return
		gen_property_list()
	
	func get_class():
		return 'CustomBTNodeSymbol'

class BuiltInBTNodeSymbol:
	extends BTNodeSymbol
	
	func _init(s) -> void:
		the_script = s
		gen_property_list()
		
	
	func get_class():
		return 'BuiltInBTNodeSymbol'

class Error:
	extends Reference
	
	var what
	var relative_token
	
	func get_class():
		return 'UnkownError'

class ImportError:
	extends Error
	
	
	func _init(w, t) -> void:
		what = w
		relative_token = t
	
	func get_class():
		return 'ImportError'

class MultipleIDError:
	extends Error
	
	func _init(t) -> void:
		what = '\'%s\' is already defined!' % t.value
		relative_token = t
	
	func get_class():
		return 'MultipleIDError'

class TokenizerError:
	extends Error
	
	func _init(w) -> void:
		what = w
		relative_token = null
	
	func get_class():
		return 'TokenizerError'

class ParserError:
	extends Error
	
	func _init(w) -> void:
		what = w
		relative_token = null
	
	func get_class():
		return 'ParserError'

class EmptyTreeError:
	extends Error
	
	func _init() -> void:
		what = 'The tree can\'t be empty!'
		relative_token = null
	
	func get_class():
		return 'EmptyTreeError'
	

class UndefinedParameterError:
	extends Error
	
	func _init(id, param, t) -> void:
		what = '\'%s\' does not have parameter \'%s\'' % [id, param]
		relative_token = t
	
	func get_class():
		return 'UndefinedParameterError'

class ScriptNotFoundError:
	extends Error
	
	func _init(path_token) -> void:
		what = 'Can\'t load script "%s"' % path_token.value
		relative_token = path_token
	
	func get_class():
		return 'ScriptNotFoundError'

class IncompatibleIDError:
	extends Error
	
	func _init(id) -> void:
		what = 'Incompatible ID \'%s\'' % id.value
		relative_token = id
	
	func get_class():
		return 'IncompatibleIDError'
	

class UndefinedIDError:
	extends Error
	
	func _init(id) -> void:
		what = 'Undefined ID \'%s\'' % id.value
		relative_token = id
	
	func get_class():
		return 'UndefinedIDError'
	

class IncompatibleIndentError:
	extends Error
	
	func _init(t) -> void:
		what = 'The indent is chaos!'
		relative_token = t
	
	func get_class():
		return 'IncompatibleIndentError'
	

class BrokenExpressionError:
	extends Error
	
	func _init(t) -> void:
		what = 'The expression is proken?'
		relative_token = t
	
	func get_class():
		return 'BrokenExpressionError'

class UndefinedFunctionError:
	extends Error
	
	func _init(f) -> void:
		what = 'Function \'%s\' is undefined!' % f.value
		relative_token = f
	
	func get_class():
		return 'UndefinedFunctionError'
	

class UndefinedOperatorError:
	extends Error
	
	func _init(f) -> void:
		what = 'Operator \'%s\' is undefined!' % f.value
		relative_token = f
	
	func get_class():
		return 'UndefinedOperatorError'
	

class UnexpectedArgumentNumError:
	extends Error
	
	func _init(id, expected, provided) -> void:
		what = 'Function \'%s\' need %d arguments, but you\'ve provided %d.' % [id.value, expected, provided]
		relative_token = id
	
	func get_class():
		return 'UnexpectedArgumentNumError'
	
#----- Properties -----
var symbol_table

var importer_table

var lib_list

var parser
var tokenizer

var has_error:bool
#----- Methods -----
func init():
	symbol_table = {} # {ID: Symbol}
	importer_table = {} # {sufiix: Importer}
	lib_list = [] # [LibBase]
	
	has_error = false
	
	add_importer('.gd', BTNodeImporter.new())
	
	add_const_symbol('fail', BuiltInBTNodeSymbol.new(BTActionFail))
	add_const_symbol('success', BuiltInBTNodeSymbol.new(BTActionSuccess))
	add_const_symbol('timer', BuiltInBTNodeSymbol.new(BTActionTimer))
	
	add_const_symbol('dynamic_guard_selector', BuiltInBTNodeSymbol.new(BTCompositeDynamicGuardSelector))
	add_const_symbol('parallel', BuiltInBTNodeSymbol.new(BTCompositeParallel))
	add_const_symbol('random_selector', BuiltInBTNodeSymbol.new(BTCompositeRandomSelector))
	add_const_symbol('random_sequence', BuiltInBTNodeSymbol.new(BTCompositeRandomSequence))
	add_const_symbol('selector', BuiltInBTNodeSymbol.new(BTCompositeSelector))
	add_const_symbol('sequence', BuiltInBTNodeSymbol.new(BTCompositeSequence))
	
	add_const_symbol('always_fail', BuiltInBTNodeSymbol.new(BTDecoratorAlwaysFail))
	add_const_symbol('always_succeed', BuiltInBTNodeSymbol.new(BTDecoratorAlwaysSucceed))
	add_const_symbol('invert', BuiltInBTNodeSymbol.new(BTDecoratorInvert))
	add_const_symbol('random', BuiltInBTNodeSymbol.new(BTDecoratorRandom))
	add_const_symbol('repeat', BuiltInBTNodeSymbol.new(BTDecoratorRepeat))
	add_const_symbol('until_fail', BuiltInBTNodeSymbol.new(BTDecoratorUntilFail))
	add_const_symbol('until_success', BuiltInBTNodeSymbol.new(BTDecoratorUntilSuccess))
	
	add_const_symbol('SEQUENCE', ConstValueSymbol.new(BTCompositeParallel.Policy.SEQUENCE))
	add_const_symbol('SELECTOR', ConstValueSymbol.new(BTCompositeParallel.Policy.SELECTOR))
	add_const_symbol('RESUME', ConstValueSymbol.new(BTCompositeParallel.Orchestrator.Resume))
	add_const_symbol('JOIN', ConstValueSymbol.new(BTCompositeParallel.Orchestrator.Join))
	
	add_const_symbol('+', FuncSymbol.new(funcref(self, 'lib_add'), 2))
	add_const_symbol('-', FuncSymbol.new(funcref(self, 'lib_sub'), 2))
	add_const_symbol('*', FuncSymbol.new(funcref(self, 'lib_mult'), 2))
	add_const_symbol('/', FuncSymbol.new(funcref(self, 'lib_divide'), 2))
	
	add_lib(preload('./lib/BasicLib.gd'))

func add_importer(suffix:String, importer:Importer):
	importer_table[suffix] = importer
	
func add_const_symbol(id, s):
	if symbol_table.has(id):
		printerr('%s already exist.' % id)
		return
	symbol_table[id] = s

func add_lib(s:Script):
	var lib = s.new()
	lib_list.append(lib)
	if not lib.has_method('_Class_Type_LibBase_'):
		printerr('"%s" is not a libary.' % s.path)
		return
	var prefix = lib.get_func_prefix()
	
	for m in lib.get_method_list():
		if m.name.find(prefix) == 0:
			var id = m.name.substr(prefix.length(), m.name.length() - prefix.length())
			var arg = m.args.size()
			add_func_symbol(id, lib, m.name, arg)
	

func add_func_symbol(id:String, obj:Object, func_name:String, expect_arg_num:int):
	add_const_symbol(id, FuncSymbol.new(funcref(obj, func_name), expect_arg_num))

func compile(source:String):
	parser = Parser.new()
	tokenizer = Tokenizer.new()
	tokenizer.init(source)
	parser.init(tokenizer)
	
	var ast:AST = parser.parse()
	
	if tokenizer.has_error:
		error(TokenizerError.new(tokenizer.first_error))
		ast = null
	if parser.has_error:
		error(ParserError.new(parser.fist_error))
		ast = null
	if has_error:
		return null
	
	compile_import_part(ast.import_part)
	if has_error:
		return null
	
	compile_subtree_part(ast.tree_part)
	if has_error:
		return null
	
	var root = compile_tree(ast.tree_part.tree)
	if has_error:
		return null
		
	
	assert(root != null)
	
	var bt = BehaviorTree.new()
	bt.name = 'BehaviorTreeTest'
	
	bt.add_child(root)
	bt.root_path = bt.get_path_to(root)
	
	return bt

func compile_import_part(import_part):
	for i in import_part.import_statement_list:
		var id = i.id
		var path = i.path
		
		if symbol_table.has(id.value):
			error(MultipleIDError.new(id))
			continue
		
		var comma = path.value.find_last('.')
		if comma >= 0:
			var suffix = path.value.substr(comma, path.value.length() - comma)
			var importer = importer_table[suffix] if importer_table.has(suffix) else null
			if importer:
				var symbol = importer.import(self, path)
				if symbol:
					symbol.id = id
					symbol_table[id.value] = symbol
				else:
					error(ImportError.new('Can\'t import "%s" with suffix \'%s\'' % [path.value, suffix], path))
			else:
				error(ImportError.new('No importer to import "%s" with suffix \'%s\'' % [path.value, suffix], path))
		else:
			error(ImportError.new('Can\'t import "%s" with no suffix' % path.value, path))
		

func compile_subtree_part(tree_part):
	# Add subtree to symbol table
	for tree in tree_part.subtree_list:
		
		if symbol_table.has(tree.name.value):
			error(MultipleIDError.new(tree.name))
			continue
		
		var symbol = SubtreeSymbol.new()
		symbol.id = tree.name
		symbol.subtree = tree
		symbol_table[symbol.id.value] = symbol
		

func compile_tree(tree_statement):
	var tree_node_list:Array = tree_statement.tree_node_list
	var tree_node_stack = [] # {indent, BTNode}
	var created_node_list = [] # BTNode
	
	if tree_node_list.empty():
		error(EmptyTreeError.new())
		return null
	
		
	var i = 0
	while i < tree_node_list.size():
		var tree_node = tree_node_list[i]
		
		# gen bt node
		var n = gen_bt_node(tree_node)
		created_node_list.append(n)
		if has_error:
			break
		
		# add to parent
		if not tree_node_stack.empty():
			if tree_node_stack.back().indent + 1 == tree_node.indent.value:
				tree_node_stack.back().node.add_child(n)
			else:
				error(IncompatibleIndentError.new(tree_node.indent))
				break
		else: # root
			tree_node_stack.push_back(gen_tree_node_stack_element(tree_node.indent.value, n))
		
		# decide to be pushed into stack
		if i < tree_node_list.size() - 1:
			var next_tree_node = tree_node_list[i+1]
			if next_tree_node.indent.value > tree_node.indent.value:
				tree_node_stack.push_back(gen_tree_node_stack_element(tree_node.indent.value, n))
			elif next_tree_node.indent.value < tree_node.indent.value:
				# pop to correct indent
				var target_indent = next_tree_node.indent.value - 1
				while tree_node_stack.back().indent > target_indent:
					tree_node_stack.pop_back()
					if tree_node_stack.empty():
						error(IncompatibleIndentError.new(tree_node.indent))
						break
		
		i += 1
		
	
	# clean up
	if has_error:
		for n in created_node_list:
			if is_instance_valid(n):
				n.queue_free()
		return null
	
	if tree_node_stack.empty():
		error(EmptyTreeError.new())
		return null
	
	return tree_node_stack[0].node

func gen_bt_node(tree_node):
	var created_node_list = []
	
	var task = gen_bt_node_from_task(tree_node.task)
	created_node_list.append(task)
	
	# gen guards
	var guard_node_list = []
	for guard in tree_node.guard_list:
		var g = gen_bt_node_from_task(guard)
		created_node_list.append(g)
		
		if has_error:
			break
		
		guard_node_list.append(g)
	
	# add guards
	if not has_error:
		if not guard_node_list.empty():
			var n = task.get_node_or_null('Guards')
			if n == null:
				n = Node.new()
				n.name = 'Guards'
				task.add_child(n)
			
			for g in guard_node_list:
				n.add_child(g)
				task.guard_path = task.get_path_to(g)
	
	if has_error:
		for n in created_node_list:
			if is_instance_valid(n):
				n.queue_free()
		return null
	
	return task

func gen_tree_node_stack_element(i, n):
	return {
		'indent': i,
		'node': n
	}

func gen_bt_node_from_task(task):
	# gen args
	var args = []
	for param in task.parameter_list:
		var key = param.id.value
		var value = calc_exp_node(param.id, param.exp_node)
		args.append({
			'key': key,
			'value': value
		})
		if has_error:
			break
	
	if has_error:
		return null
	
	# gen task node
	if task.name.is_subtree_ref:
		if symbol_table.has(task.name.name.value):
			var symbol = symbol_table[task.name.name.value]
			if symbol.get_class() == 'SubtreeSymbol':
				var bt = compile_tree(symbol.subtree)
				if has_error:
					if is_instance_valid(bt):
						bt.queue_free()
					return null
				return bt
			else:
				error(IncompatibleIDError.new(task.name.name))
		else:
			error(UndefinedIDError.new(task.name.name))
		return null
	if task.name.name.type == Tokenizer.Token.ID:
		if symbol_table.has(task.name.name.value):
			var symbol = symbol_table[task.name.name.value]
			if symbol.has_method('_Class_Type_BTNodeSymbol_'):
				var n = symbol.create_node(self, task.name.name, args)
				n.name = task.name.name.value
				return n
			else:
				error(IncompatibleIDError.new(task.name.name))
		else:
			error(UndefinedIDError.new(task.name.name))
	elif task.name.name.type == Tokenizer.Token.STRING:
		var symbol = CustomBTNodeSymbol.new(self, task.name.name)
		if symbol:
			var n = symbol.create_node(self, task.name.name, args)
			n.name = task.name.name.value
			return n
	return null

func calc_exp_node(relative_token, exp_node):
	match exp_node.get_class():
		'OperatorNode':
			if symbol_table.has(exp_node.op.value):
				var symbol = symbol_table[exp_node.op.value]
				if symbol.get_class() == 'FuncSymbol':
					var l = calc_exp_node(relative_token, exp_node.children[0])
					if has_error:
						return null
					var r = calc_exp_node(relative_token, exp_node.children[1])
					if has_error:
						return null
					return symbol.func_ref.call_func(l, r)
				else:
					error(IncompatibleIDError.new(exp_node.op))
			else:
				error(UndefinedOperatorError.new(exp_node.op))
		'FuncNode':
			if symbol_table.has(exp_node.id.value):
				var symbol = symbol_table[exp_node.id.value]
				if symbol.get_class() == 'FuncSymbol':
					var args = []
					for c in exp_node.children:
						var a = calc_exp_node(relative_token, c)
						if has_error:
							return null
						args.append(a)
					if args.size() != symbol.expected_arg_num:
						error(UnexpectedArgumentNumError.new(exp_node.id, symbol.expected_arg_num, args.size()))
						return null
					return symbol.func_ref.call_funcv(args)
				else:
					error(IncompatibleIDError.new(exp_node.id))
			else:
				error(UndefinedFunctionError.new(exp_node.id))
		'LeafNode':
			match exp_node.token.type:
				Tokenizer.Token.ID:
					if symbol_table.has(exp_node.token.value):
						var symbol = symbol_table[exp_node.token.value]
						if symbol.get_class() == 'ConstValueSymbol':
							return symbol.value
						else:
							error(IncompatibleIDError.new(exp_node.token))
					else:
						error(UndefinedIDError.new(exp_node.token))
			return exp_node.token.value
	error(BrokenExpressionError.new(relative_token))

func error(e:Error):
	has_error = true
	
	printerr('[%s]:' % str(e.get_class()))
	printerr(e.what)
	printerr(error_token_str(e.relative_token))


func error_token_str(token):
	if token == null:
		return ''
		
	var last_line_break = 0 if token.last_line_break == -1 else token.last_line_break
	
	var next_line_break =  tokenizer.calc_next_line_break(last_line_break+1)
	var e = 'Error '
	e += 'at line: %d, column: %d.' % [token.line+1, token.start - last_line_break + 1]
	
	var e_line = tokenizer.source.substr(last_line_break, next_line_break-last_line_break)
	
	var e_locate = ''
	for i in range(token.start - last_line_break):
		e_locate += ' ' if tokenizer.source.ord_at(last_line_break+(1 if token.type != Tokenizer.Token.EOF else 0)+i) < 128 else '  '
	for _i in range(token.length-1):
		e_locate += '~'
	e_locate += '^'
	
	return '%s\n%s\n%s' % [e, e_line, e_locate]



