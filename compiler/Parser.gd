extends Reference


var Tokenizer = preload('./Tokenizer.gd')
var AST = preload('./AST/AST.gd')

var tokenizer

var ast

var preserved_id = ['import', 'name', 'subtree', 'tree']

var has_tree

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
	ast = null
	

func parse():
	tokenizer.init(tokenizer.source)
	has_tree = false
	
	ast = AST.new()
	
	_bt_file(ast)
	
	match_blank_or_null()
	match_comment_or_null()
	match_line_break_or_comment_or_indent_with_comment_or_null()
	
	var token = tokenizer.get_next()
	print('End token: ' + str(token))
	
	if token.type != Tokenizer.Token.EOF:
		error(token, 'EOF')
	
	if not has_tree:
		error(token, 'tree')
	

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
	var next_line_break =  tokenizer.calc_next_line_break(token.last_line_break+1)
	var e = 'Expect %s ' % expect if expect != '' else 'Error '
	e += 'at line: %d, column: %d.' % [token.line, token.start - token.last_line_break]
	e += 'Got %s' % str(token)
	
	var e_line = tokenizer.source.substr(token.last_line_break, next_line_break-token.last_line_break)
	
	var e_locate = ''
	for i in range(token.start - token.last_line_break):
		e_locate += ' ' if tokenizer.source.ord_at(token.start+i) < 128 else '  '
	for i in range(token.length-1):
		e_locate += '~'
	e_locate += '^'
	
	printerr('%s\n%s\n%s' % [e, e_line, e_locate])
#----- Top Down Parsers -----
func _bt_file(ast):
	_import_part(ast)
	_tree_part(ast)

func _import_part(ast):
	ast.import_part = AST.ImportPart.new()
	
	var exclude = [Tokenizer.Token.LINE_BREAK, Tokenizer.Token.COMMENT, Tokenizer.Token.INDENT]
	var token = tokenizer.preview_next_without(exclude)
	while token.type == Tokenizer.Token.ID and token.value == 'import':
		match_line_break_or_comment_or_indent_with_comment_or_null()
		_import_statement(ast.import_part)
		token = tokenizer.preview_next_without(exclude)
	

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
	
	print('Found import: [%s -> %s]' % [id_token.value, string_token.value])

func _tree_part(ast):
	ast.tree_part = AST.TreePart.new()
	
	var exclude = [Tokenizer.Token.LINE_BREAK, Tokenizer.Token.COMMENT, Tokenizer.Token.INDENT]
	var token = tokenizer.preview_next_without(exclude)
	while token.type == Tokenizer.Token.ID:
		if token.value == 'tree':
			if not has_tree:
				has_tree = true
				print('Found tree')
				match_line_break_or_comment_or_indent_with_comment_or_null()
				_tree_statement(ast.tree_part)
			else:
				printerr('You can only have one tree in a file.')
				error(token, 'no more than one tree')
				tokenizer.get_next()
		elif token.value == 'subtree':
			print('Found subtree')
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
	print('name: %s' % id_token.value)
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
	if tree_node_cnt == 0:
		printerr('Empty tree.')

func _tree_node_statement():
	var tree_node = AST.TreeNode.new()
	
	print('{')
	var indent_token = match_indent()
	tree_node.indent = indent_token
	var token = tokenizer.preview_next()
	if token.type == Tokenizer.Token.LEFT_CLOSURE and token.value == '(':
		_guard_part(tree_node)
		match_blank_or_null()
	tree_node.task = _task()
	match_blank_or_null()
	match_comment_or_null()
	print('}')
	
	return tree_node

func _guard_part(tree_node):
	var exclude = [Tokenizer.Token.BLANK]
	var token = tokenizer.preview_next_without(exclude)
	while token.type == Tokenizer.Token.LEFT_CLOSURE and token.value == '(':
		match_blank_or_null()
		var task = _guard()
		tree_node.guard_list.append(task)
		token = tokenizer.preview_next_without(exclude)

func _guard():
	match_value('(')
	print('(')
	match_blank_or_null()
	var task = _task()
	match_blank_or_null()
	print(')')
	match_value(')')
	
	return task

func _task():
	var task = AST.Task.new()
	
	var name = _name()
	task.name = name
	
	var exclude = [Tokenizer.Token.BLANK]
	var token = tokenizer.preview_next_without(exclude)
	if token.type == Tokenizer.Token.ID:
		print('-[')
		_parameter_part(task)
		print(']-')
	
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
		print('buit-in name: %s' % id_token.value)
	else:
		var string_token = match_string()
		name.name = string_token
		print('string name: \'%s\'' % string_token.value)
	
	return name

func _subtree_ref(name):
	match_value('$')
	name.is_subtree_ref = true
	var id_token = match_id()
	name.name = id_token
	print('ref name: ' + id_token.value)

func _parameter_part(task):
	var exclude = [Tokenizer.Token.BLANK]
	var token = tokenizer.preview_next_without(exclude)
	while token.type == Tokenizer.Token.ID:
		match_blank()
		var parameter = _parameter()
		task.parameter_list.append(parameter)
		token = tokenizer.preview_next_without(exclude)

func _parameter():
	var parameter = AST.Parameter.new()
	
	var id_token = match_id()
	parameter.id = id_token
	print('param: ' + id_token.value)
	match_blank_or_null()
	match_value(':')
	match_blank_or_null()
	print('exp: [')
	_exp()
	print(']')

func _exp():
	_e1()
	var token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
	while token.type == Tokenizer.Token.OPERATOR and (token.value == '+' or token.value == '-'):
		match_blank_or_null()
		var op_token = match_operator()
		print(op_token.value)
		match_blank_or_null()
		_e1()
		token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])

func _e1():
	_e2()
	var token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
	while token.type == Tokenizer.Token.OPERATOR and (token.value == '*' or token.value == '/'):
		match_blank_or_null()
		var op_token = match_operator()
		print(op_token.value)
		match_blank_or_null()
		_e2()
		token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])

func _e2():
	var token = tokenizer.preview_next()
	if token.type == Tokenizer.Token.OPERATOR and (token.value == '-' or token.value == '+'):
		var op_token = match_operator()
		print(op_token.value)
	_e3()

func _e3():
	var token = tokenizer.preview_next()
	if token.type == Tokenizer.Token.ID:
		token = tokenizer.preview_next(2)
		if token.type == Tokenizer.Token.LEFT_CLOSURE and token.value == '(':
			_func()
		else:
			var id_token = match_id()
			print(id_token)
	elif token.type == Tokenizer.Token.STRING:
		var string_token = match_string()
		print(string_token)
	elif token.type == Tokenizer.Token.NUMBER:
		var number_token = match_number()
		print(number_token)
	elif token.type == Tokenizer.Token.BOOL:
		var bool_token = match_bool()
		print(bool_token)
	elif token.type == Tokenizer.Token.LEFT_CLOSURE and token.value == '(':
		print('(')
		match_value('(')
		match_blank_or_null()
		_exp()
		match_blank_or_null()
		match_value(')')
		print(')')
	elif token.type == Tokenizer.Token.OPERATOR and token.value == '$':
		print('$')
		_name()

func _func():
	var id_token = match_id()
	print('%s|(' % id_token.value)
	match_value('(')
	var token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
	if token.type != Tokenizer.Token.RIGHT_CLOSURE or token.value != ')':
		match_blank_or_null()
		_arg_part()
	match_blank_or_null()
	match_value(')')
	print(')|')

func _arg_part():
	_exp()
	var token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
	while token.type == Tokenizer.Token.COMMAS:
		match_blank_or_null()
		match_value(',')
		print(',')
		match_blank_or_null()
		_exp()
		token = tokenizer.preview_next_without([Tokenizer.Token.BLANK])
	
	
