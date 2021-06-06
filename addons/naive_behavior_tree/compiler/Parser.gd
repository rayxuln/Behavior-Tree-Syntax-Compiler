tool
extends Reference


var Tokenizer = preload('./Tokenizer.gd')
var AST = preload('./AST/AST.gd')
var EXPAST = preload('./AST/EXPAST.gd')

var tokenizer

var preserved_id = ['import', 'name', 'subtree', 'tree']

var has_tree

var has_error
var is_print_error = false
var fist_error:String = ''
var last_error:String = ''

#----- Gramar -----
# bt_file = import_part tree_part
#
# import_part = import_statement
#             | import_part LineBreakOrCommentOrIndentWithCommentOrNull import_statement
#
# import_statement = "import" Blank ID BlankOrNull : BlankOrNull String BlankOrNull CommentOrNull
# 
# tree_part = tree_statement
#           | subtree_statement
#           | tree_part LineBreakOrCommentOrIndentWithCommentOrNull tree_statement
#           | tree_part LineBreakOrCommentOrIndentWithCommentOrNull subtree_statement
#
# tree_statement = "tree" BlankOrNull CommentOrNull LineBreakOrCommentOrIndentWithCommentOrNull tree_node_part
#
# subtree_statement = "subtree" Blank "name" BlankOrNull : BlankOrNull ID BlankOrNull CommentOrNull LineBreakOrCommentOrIndentWithCommentOrNull tree_node_part
#
# tree_node_part = tree_node_statement
#                | tree_node_part LineBreakOrCommentOrIndentWithCommentOrNull tree_node_statement
#
# tree_node_statement = Indent guard_part BlankOrNull task CommentOrNull
#
# guard_part = guard
#            | E
#            | guard_part BlankOrNull guard
#
# guard = "(" BlankOrNull task BlankOrNull ")"
#
# task = name Blank parameter_part
#
# name = subtree_ref | ID | String
#
# subtree_ref = $ ID
#
# parameter_part = parameter
#                | E
#                | parameter_part Blank parameter
#
# parameter = ID BlankOrNull : BlankOrNull exp
#
# exp = e1
#     | exp BlankOrNull + BlankOrNull e1
#     | exp BlankOrNull - BlankOrNull e1
#
# e1 = e2
#    | e1 BlankOrNull * BlankOrNull e2
#    | e1 BlankOrNull / BlankOrNull e2
#
# e2 = e3
#    | -e3
#    | +e3
#
# e3 = func
#    | ( BlankOrNull exp  BlankOrNull)
#    | ID
#    | String
#    | Number
#    | Bool
#    | name
#
# func = ID "(" BlankOrNull arg_part BlankOrNull ")"
#
# arg_part = exp
#          | E
#          | arg_part BlankOrNull , BlankOrNull exp


#----- Methods -----
func init(t):
	tokenizer = t
	

func parse():
	tokenizer.init(tokenizer.source)
	has_tree = false
	has_error = false
	
	var ast = AST.new()
	
	_bt_file(ast)
	
	var token = tokenizer.get_next()
	
	if token.type != Tokenizer.Token.EOF:
		error(token, 'EOF')
	
	if not has_tree:
		error(token, 'tree')
	
	return ast

func match_blank():
	var token = tokenizer.preview_next()
	if token.type == Tokenizer.Token.BLANK:
		tokenizer.get_next()
	else:
		error(token, 'Blank')

# match
# blank
# null
func match_blank_or_null():
	var token = tokenizer.preview_next()
	while token.type == Tokenizer.Token.BLANK:
		tokenizer.get_next()
		token = tokenizer.preview_next()

func match_value(value):
	var token = tokenizer.preview_next()
	if typeof(token.value) == typeof(value) and token.value == value:
		tokenizer.get_next()
	else:
		error(token, '\'%s\'' % value)
	

func match_id():
	var token = tokenizer.preview_next()
	if token.type != Tokenizer.Token.ID:
		error(token, 'ID')
		return null
	else:
		return tokenizer.get_next()

func match_string():
	var token = tokenizer.preview_next()
	if token.type != Tokenizer.Token.STRING:
		error(token, 'String')
		return null
	else:
		return tokenizer.get_next()
	
func match_indent():
	var token = tokenizer.preview_next()
	if token.type != Tokenizer.Token.INDENT:
		error(token, 'Indent')
		return null
	else:
		return tokenizer.get_next()

func match_operator():
	var token = tokenizer.preview_next()
	if token.type != Tokenizer.Token.OPERATOR:
		error(token, 'Operator')
		return null
	else:
		return tokenizer.get_next()

func match_number():
	var token = tokenizer.preview_next()
	if token.type != Tokenizer.Token.NUMBER:
		error(token, 'Number')
		return null
	else:
		return tokenizer.get_next()

func match_bool():
	var token = tokenizer.preview_next()
	if token.type != Tokenizer.Token.BOOL:
		error(token, 'Bool')
		return null
	else:
		return tokenizer.get_next()

# match
# line_break
# line_break comment
# indent comment
# indent indent
# null
func match_line_break_or_comment_or_indent_with_comment_or_null():
	var token = tokenizer.preview_next()
	while true:
		if token.type == Tokenizer.Token.LINE_BREAK:
			if tokenizer.preview_next(2).type == Tokenizer.Token.COMMENT:
				tokenizer.get_next()
				tokenizer.get_next()
			else:
				tokenizer.get_next()
			token = tokenizer.preview_next()
		elif token.type == Tokenizer.Token.INDENT:
			if tokenizer.preview_next(2).type == Tokenizer.Token.COMMENT:
				tokenizer.get_next()
				tokenizer.get_next()
				token = tokenizer.preview_next()
			elif tokenizer.preview_next(2).type == Tokenizer.Token.INDENT:
				tokenizer.get_next()
				token = tokenizer.preview_next()
			elif tokenizer.preview_next(2).type == Tokenizer.Token.LINE_BREAK:
				tokenizer.get_next()
				token = tokenizer.preview_next()
			elif tokenizer.preview_next(2).type == Tokenizer.Token.EOF:
				tokenizer.get_next()
				token = tokenizer.preview_next()
			else:
				break
		else:
			break

func match_comment_or_null():
	var token = tokenizer.preview_next()
	while token.type == Tokenizer.Token.COMMENT:
		tokenizer.get_next()
		token = tokenizer.preview_next()

func get_indent_token_with_ID_followed(): # or with a left braket
	var pos = 1
	var token = tokenizer.preview_next(pos)
	while true:
		if token.type == Tokenizer.Token.LINE_BREAK:
			var next_token = tokenizer.preview_next(pos+1)
			if next_token.type == Tokenizer.Token.COMMENT:
				pos += 1
				pos += 1
			else:
				pos += 1
			token = tokenizer.preview_next(pos)
		elif token.type == Tokenizer.Token.INDENT:
			var next_token = tokenizer.preview_next(pos+1)
			if next_token.type == Tokenizer.Token.COMMENT:
				pos += 1
				pos += 1
			elif next_token.type == Tokenizer.Token.ID:
				pos += 1
				return pos
			elif next_token.type == Tokenizer.Token.STRING:
				pos += 1
				return pos
			elif next_token.type == Tokenizer.Token.OPERATOR and next_token.value == '$':
				pos += 1
				return pos
			elif next_token.type == Tokenizer.Token.LEFT_CLOSURE and next_token.value == '(':
				pos += 1
				return pos
			else:
				pos += 1
			token = tokenizer.preview_next(pos)
		else:
			break
	return -1

func error(token, expect = ''):
	if token == null:
		last_error = expect
		if not has_error:
			fist_error = last_error
		has_error = true
		return
		
	var last_line_break = 0 if token.last_line_break == -1 else token.last_line_break
	
	var next_line_break =  tokenizer.calc_next_line_break(last_line_break+1)
	var e = 'Expect %s ' % expect if expect != '' else 'Error '
	e += 'at line: %d, column: %d.' % [token.line+1, token.start - last_line_break + 1]
	e += 'Got %s' % str(token)
	
	var e_line = tokenizer.source.substr(last_line_break, next_line_break-last_line_break)
	
	var e_locate = ''
	for i in range(token.start - last_line_break):
		e_locate += ' ' if tokenizer.source.ord_at(last_line_break+(1 if token.type != Tokenizer.Token.EOF else 0)+i) < 128 else '  '
	for _i in range(token.length-1):
		e_locate += '~'
	e_locate += '^'
	
	last_error = '%s\n%s\n%s' % [e, e_line, e_locate]
	if is_print_error:
		printerr(last_error)
	if not has_error:
		fist_error = last_error
	has_error = true
#----- Top Down Parsers -----
func _bt_file(ast):
	match_comment_or_null()
	match_line_break_or_comment_or_indent_with_comment_or_null()
	_import_part(ast)
	_tree_part(ast)
	match_blank_or_null()
	match_comment_or_null()
	match_line_break_or_comment_or_indent_with_comment_or_null()

func _import_part(ast):
	ast.import_part = AST.ImportPart.new()
	
	var exclude = [Tokenizer.Token.LINE_BREAK, Tokenizer.Token.COMMENT, Tokenizer.Token.INDENT]
	var token = tokenizer.preview_next_without(exclude)
	while token.type == Tokenizer.Token.ID and token.value == 'import':
		match_line_break_or_comment_or_indent_with_comment_or_null()
		_import_statement(ast.import_part)
		token = tokenizer.preview_next_without(exclude)
		
		if has_error:
			break
	

func _import_statement(import_part):
	match_value('import')
	match_blank()
	var id_token = match_id()
	match_blank_or_null()
	match_value(':')
	match_blank_or_null()
	var string_token = match_string()
	match_blank_or_null()
	match_comment_or_null()
	
	var import_statement = AST.ImportStatement.new(id_token, string_token)
	import_part.import_statement_list.append(import_statement)
	

func _tree_part(ast):
	ast.tree_part = AST.TreePart.new()
	
	var exclude = [Tokenizer.Token.LINE_BREAK, Tokenizer.Token.COMMENT, Tokenizer.Token.INDENT]
	var token = tokenizer.preview_next_without(exclude)
	while token.type == Tokenizer.Token.ID:
		if token.value == 'tree':
			if not has_tree:
				has_tree = true
				match_line_break_or_comment_or_indent_with_comment_or_null()
				_tree_statement(ast.tree_part)
			else:
				error(token, 'no more than one tree')
				tokenizer.get_next()
		elif token.value == 'subtree':
			match_line_break_or_comment_or_indent_with_comment_or_null()
			_subtree_statement(ast.tree_part)
		else:
			break
		token = tokenizer.preview_next_without(exclude)

func _tree_statement(tree_part):
	tree_part.tree = AST.TreeStatement.new()
	
	match_value('tree')
	match_blank_or_null()
	match_comment_or_null()
	match_line_break_or_comment_or_indent_with_comment_or_null()
	_tree_node_part(tree_part.tree)

func _subtree_statement(tree_part):
	var subtree = AST.TreeStatement.new()
	subtree.is_subtree = true
	tree_part.subtree_list.append(subtree)
	
	match_value('subtree')
	match_blank()
	match_value('name')
	match_blank_or_null()
	match_value(':')
	match_blank_or_null()
	var id_token = match_id()
	subtree.name = id_token
	match_blank_or_null()
	match_comment_or_null()
	match_line_break_or_comment_or_indent_with_comment_or_null()
	_tree_node_part(subtree)

func _tree_node_part(tree):
	var tree_node_cnt = 0
	var preview_pos = get_indent_token_with_ID_followed()
	while preview_pos != -1:
		match_line_break_or_comment_or_indent_with_comment_or_null()
		var tree_node = _tree_node_statement()
		tree.tree_node_list.append(tree_node)
		tree_node_cnt += 1
		preview_pos = get_indent_token_with_ID_followed()
		
		if has_error:
			break
	if tree_node_cnt == 0:
		error(null, 'Empty tree.')

func _tree_node_statement():
	var tree_node = AST.TreeNode.new()
	
	var indent_token = match_indent()
	tree_node.indent = indent_token
	var token = tokenizer.preview_next()
	if token.type == Tokenizer.Token.LEFT_CLOSURE and token.value == '(':
		_guard_part(tree_node)
		match_blank_or_null()
	tree_node.task = _task()
	match_blank_or_null()
	match_comment_or_null()
	
	return tree_node

func _guard_part(tree_node):
	var exclude = [Tokenizer.Token.BLANK]
	var token = tokenizer.preview_next_without(exclude)
	while token.type == Tokenizer.Token.LEFT_CLOSURE and token.value == '(':
		match_blank_or_null()
		var task = _guard() # could be null task for no guard
		if task:
			tree_node.guard_list.append(task)
		token = tokenizer.preview_next_without(exclude)
		
		if has_error:
			break

func _guard():
	match_value('(')
	match_blank_or_null()
	var token = tokenizer.preview_next()
	var task = null
	if not (token.type == Tokenizer.Token.RIGHT_CLOSURE and token.value == ')'):
		task = _task()
	match_blank_or_null()
	match_value(')')
	
	return task

func _task():
	var task = AST.Task.new()
	
	var name = _name()
	task.name = name
	
	var exclude = [Tokenizer.Token.BLANK]
	var token = tokenizer.preview_next_without(exclude)
	if token.type == Tokenizer.Token.ID:
		_parameter_part(task)
	
	return task

func _name():
	var name = AST.Name.new()
	name.is_subtree_ref = false
	
	var token = tokenizer.preview_next()
	if token.type == Tokenizer.Token.OPERATOR and token.value == '$':
		_subtree_ref(name)
	elif token.type == Tokenizer.Token.ID:
		var id_token = match_id()
		name.name = id_token
	else:
		var string_token = match_string()
		name.name = string_token
	
	return name

func _subtree_ref(name):
	match_value('$')
	name.is_subtree_ref = true
	var id_token = match_id()
	name.name = id_token

func _parameter_part(task):
	var exclude = [Tokenizer.Token.BLANK]
	var token = tokenizer.preview_next_without(exclude)
	while token.type == Tokenizer.Token.ID:
		match_blank()
		var parameter = _parameter()
		task.parameter_list.append(parameter)
		token = tokenizer.preview_next_without(exclude)
		
		if has_error:
			break

func _parameter():
	var parameter = AST.Parameter.new()
	
	var id_token = match_id()
	parameter.id = id_token
	match_blank_or_null()
	match_value(':')
	match_blank_or_null()
	parameter.exp_node = _exp()
	if parameter.exp_node == null:
		error(tokenizer.preview_next(), 'a expression')
	
	return parameter

func _exp():
	var left_exp_node = _e1()
	var token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
	while token.type == Tokenizer.Token.OPERATOR and (token.value == '+' or token.value == '-'):
		var op_node = EXPAST.OperatorNode.new()
		
		match_blank_or_null()
		var op_token = match_operator()
		op_node.op = op_token
		
		match_blank_or_null()
		var right_exp_node = _e1()
		
		op_node.children = [left_exp_node, right_exp_node]
		left_exp_node = op_node
		
		token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
		
		if has_error:
			break
	return left_exp_node

func _e1():
	var left_exp_node = _e2()
	var token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
	while token.type == Tokenizer.Token.OPERATOR and (token.value == '*' or token.value == '/'):
		var op_node = EXPAST.OperatorNode.new()
		
		match_blank_or_null()
		var op_token = match_operator()
		op_node.op = op_token
		
		
		match_blank_or_null()
		var right_exp_node = _e2()
		
		op_node.children = [left_exp_node, right_exp_node]
		left_exp_node = op_node
		
		token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
		
		if has_error:
			break
	return left_exp_node


func _e2():
	var exp_node = null
	
	var token = tokenizer.preview_next()
	if token.type == Tokenizer.Token.OPERATOR and (token.value == '-' or token.value == '+'):
		exp_node = EXPAST.OperatorNode.new()
		
		var op_token = match_operator()
		exp_node.op = op_token
	
	var e3 = _e3()
	if exp_node:
		exp_node.children.append(e3)
	else:
		exp_node = e3
	
	return exp_node

func _e3():
	var exp_node = null
	
	var token = tokenizer.preview_next()
	if token.type == Tokenizer.Token.ID:
		token = tokenizer.preview_next(2)
		if token.type == Tokenizer.Token.LEFT_CLOSURE and token.value == '(':
			exp_node = _func()
		else:
			var id_token = match_id()
			exp_node = EXPAST.LeafNode.new()
			exp_node.token = id_token
	elif token.type == Tokenizer.Token.STRING:
		var string_token = match_string()
		exp_node = EXPAST.LeafNode.new()
		exp_node.token = string_token
	elif token.type == Tokenizer.Token.NUMBER:
		var number_token = match_number()
		exp_node = EXPAST.LeafNode.new()
		exp_node.token = number_token
	elif token.type == Tokenizer.Token.BOOL:
		var bool_token = match_bool()
		exp_node = EXPAST.LeafNode.new()
		exp_node.token = bool_token
	elif token.type == Tokenizer.Token.LEFT_CLOSURE and token.value == '(':
		match_value('(')
		match_blank_or_null()
		exp_node = _exp()
		match_blank_or_null()
		match_value(')')
	elif token.type == Tokenizer.Token.OPERATOR and token.value == '$':
		exp_node = _name()
	else:
		error(token, 'a valid expression')
	
	return exp_node

func _func():
	var func_node = EXPAST.FuncNode.new()
	
	var id_token = match_id()
	func_node.id = id_token
	
	match_value('(')
	var token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
	if token.type != Tokenizer.Token.RIGHT_CLOSURE or token.value != ')':
		match_blank_or_null()
		_arg_part(func_node)
	match_blank_or_null()
	match_value(')')
	
	return func_node

func _arg_part(func_node):
	var exp_node = _exp()
	func_node.children.append(exp_node)
	
	var token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
	while token.type == Tokenizer.Token.COMMAS:
		match_blank_or_null()
		match_value(',')
		match_blank_or_null()
		exp_node = _exp()
		func_node.children.append(exp_node)
		token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
		if exp_node == null:
			error(token, 'expression')
		
		if has_error:
			break
	
	
