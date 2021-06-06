tool
extends Reference


var source:String = ''

var next:int
var line_cnt:int
var last_line_break:int

var preserved_char_list:String = '#[]()*$%-+={}\'"\\/,.<>:;| \t\r\n'
var digit_char_list:String = '0123456789'
var op_char_list:String = '+-*/%$'
var left_closure_char_list:String = '<[{('
var right_closure_char_list:String = ')}]>'
var indent_char_list:String = '\t '
var blank_char_list:String = ' \t\r'
var escape_char_list:String = 'trn\\\'"'

var ID_trans_table
var ID_fstate_list

var String_trans_table
var String_fstate_list

var Number_trans_table
var Number_fstate_list

var Indent_trans_table
var Indent_fstate_list

var next_token_queue:Array

var has_error:bool
var is_print_error:bool = false
var first_error:String
var last_error:String

enum TransitionConditionType {
	FUNC,
	CHAR,
	NOT_CHAR
}

class StateMachineResult:
	extends Reference
	
	enum {
		FRESH,
		SUCCESS,
		FAIL,
		EOF,
	}
	
	var state:int
	var next:int
	var line_cnt:int
	var last_line_break:int
	var status = FRESH
	var error:String = ''

class Token:
	extends Reference
	
	enum {
		ID,
		STRING,
		NUMBER,
		BOOL,
		INDENT,
		BLANK,
		COMMENT,
		EOF,
		ERROR,
		LEFT_CLOSURE,
		RIGHT_CLOSURE,
		OPERATOR,
		COLON,
		COMMAS,
		LINE_BREAK,
		UNDEFINED
	}
	
	var type = UNDEFINED
	var raw:String
	var value
	var start:int
	var length:int
	var line:int
	var last_line_break:int
	
	func process():
		match type:
			STRING:
				value = raw.substr(1, raw.length()-2).c_unescape()
			NUMBER:
				value = float(raw)
			BOOL:
				value = raw == 'true'
			INDENT:
				value = raw.length() - (1 if raw[0] == '\n' else 0)
			ID, LEFT_CLOSURE, RIGHT_CLOSURE, COLON, COMMAS, OPERATOR:
				value = raw
	
	func _to_string() -> String:
		match type:
			ID:
				return '[ID: %s]' % value
			STRING:
				return '[String: %s]' % value
			NUMBER:
				return '[Number: %f]' % value
			BOOL:
				return '[Bool: %s]' % ('true' if value else 'false')
			INDENT:
				return '[Indent: %d]' % value
			BLANK:
				return '[Blank]'
			COMMENT:
				return '[Comment: %s]' % raw
			EOF:
				return '[EOF]'
			ERROR:
				return '[Error]'
			LEFT_CLOSURE:
				return '[Left Closure: %s]' % value
			RIGHT_CLOSURE:
				return '[Right Closure: %s]' % value
			COLON:
				return '[Colon]'
			COMMAS:
				return '[Commas]'
			OPERATOR:
				return '[Operator: %s]' % value
			LINE_BREAK:
				return '[Line Break]'
		return '[Unknown Token]'
	
#----- Methods -----
func init(_s:String):
	source = _s
	next = 0
	line_cnt = 0
	last_line_break = -1
	next_token_queue = []
	
	has_error = false
	
	ID_trans_table = {
		0: [gen_transition(1, 'is_valid_char_without_digit', '<valid char and not digit>')],
		1: [
			gen_transition(1, 'is_valid_char_without_digit', '<valid char and not digit>'),
			gen_transition(2, 'is_valid_char', '<valid char>')
		],
		2: [gen_transition(2, 'is_valid_char', '<valid char>')]
	}
	ID_fstate_list = [1, 2]
	
	String_trans_table = {
		0: [
			gen_transition_char(1, "'"),
			gen_transition_char(6, '"'),
		],
		1: [
			gen_transition_char(5, "'"),
			gen_transition_char(2, '\\'),
			gen_transition_not_char(3, "'"),
		],
#		2: [
#			gen_transition_char(4, "'"),
#			gen_transition_char(4, '\\'),
#		],
		2: gen_transitions_char_list(4, escape_char_list),
		3: [
			gen_transition_char(2, '\\'),
			gen_transition_char(5, "'"),
			gen_transition_not_char(3, "'"),
		],
		4: [
			gen_transition_char(5, "'"),
			gen_transition_char(2, '\\'),
			gen_transition_not_char(3, "'"),
		],
		5: [],
		6: [
			gen_transition_char(8, '\\'),
			gen_transition_not_char(7, '"'),
		],
		7: [
			gen_transition_char(5, '"'),
			gen_transition_char(8, '\\'),
			gen_transition_not_char(7, '"'),
		],
#		8: [
#			gen_transition_char(9, '"'),
#			gen_transition_char(9, '\\'),
#		],
		8: gen_transitions_char_list(9, escape_char_list),
		9: [
			gen_transition_char(8, '\\'),
			gen_transition_char(5, '"'),
			gen_transition_not_char(7, '"'),
		]
	}
	String_fstate_list = [5]
	
	Number_trans_table = {
		0: [
			gen_transition(1, 'is_digit_char', '<digit>'),
			gen_transition_char(2, '.'),
		],
		1: [
			gen_transition(1, 'is_digit_char', '<digit>'),
			gen_transition_char(2, '.'),
		],
		2: [
			gen_transition(3, 'is_digit_char', '<digit>'),
		],
		3: [
			gen_transition(3, 'is_digit_char', '<digit>'),
		]
	}
	Number_fstate_list = [1, 3]
	
	Indent_trans_table = {
		0: [
			gen_transition(1, 'is_indent_start', '<indent>'),
		],
		1: gen_transitions_char_list(2, indent_char_list),
		2: gen_transitions_char_list(2, indent_char_list),
	}
	Indent_fstate_list = [2]

func preview_next(num:int=1):
	if num <= next_token_queue.size():
		return next_token_queue[num-1]
	while num > next_token_queue.size():
		next_token_queue.push_back(_get_next_token())
	return preview_next(num)

func preview_next_without(exclude:Array, num:int=1):
	var useless_type = [Token.EOF, Token.ERROR, Token.UNDEFINED]
	var cnt = 0
	var pos = 1
	while cnt < num:
		var t = preview_next(pos)
		if t.type in useless_type:
			return t
		if not t.type in exclude:
			cnt += 1
		pos += 1
	return preview_next(pos-1)

func get_next():
	if not next_token_queue.empty():
		return next_token_queue.pop_front()
	return _get_next_token()

func get_next_without_blank(exclude:Array):
	var t = get_next()
	while not t.type in exclude:
		t = get_next()
	return t

func _get_next_token():
	var t = _get_next()
	t.process()
	return t

func _get_next():
	var res:StateMachineResult
	var token = gen_token(Token.UNDEFINED, '', next, 1, line_cnt, last_line_break)
	
	if next >= source.length():
		return gen_token(Token.EOF, '', next, 1, line_cnt, last_line_break)
	
	if source[next] == 't' or source[next] == 'f': # Bool
		var start = next
		if match_char('t') and match_char('r') and match_char('u') and match_char('e') and (next >= source.length() or source[next] in preserved_char_list+digit_char_list):
			return gen_token(Token.BOOL, source.substr(start, next - start), start, next - start, line_cnt, last_line_break)
		elif match_char('f') and match_char('a') and match_char('l') and match_char('s') and match_char('e') and (next >= source.length() or source[next] in preserved_char_list+digit_char_list):
			return gen_token(Token.BOOL, source.substr(start, next - start), start, next - start, line_cnt, last_line_break)
		next = start
	
	if source[next] == ':': # Colon
		next += 1
		return gen_token(Token.COLON, source.substr(next-1, 1), next-1, 1, line_cnt, last_line_break)
	elif source[next] == ',': # Commas
		next += 1
		return gen_token(Token.COMMAS, source.substr(next-1, 1), next-1, 1, line_cnt, last_line_break)
	
	if is_indent_start(next): # Indent
		res = run_state_machine(0, next, Indent_trans_table, Indent_fstate_list)
		token.type = Token.INDENT
	elif source[next] in left_closure_char_list:
		var c = source[next]
		next += 1
		return gen_token(Token.LEFT_CLOSURE, c, next-1, 1, line_cnt, last_line_break)
	elif source[next] in right_closure_char_list:
		var c = source[next]
		next += 1
		return gen_token(Token.RIGHT_CLOSURE, c, next-1, 1, line_cnt, last_line_break)
	elif source[next] == '.' or source[next] in digit_char_list: # Number
		res = run_state_machine(0, next, Number_trans_table, Number_fstate_list)
		token.type = Token.NUMBER
	elif source[next] in op_char_list: # Operator (only has one character)
		var c = source[next]
		next += 1
		return gen_token(Token.OPERATOR, c, next-1, 1, line_cnt, last_line_break)
	elif is_valid_char_without_digit(next): # ID
		res = run_state_machine(0, next, ID_trans_table, ID_fstate_list)
		token.type = Token.ID
	elif source[next] == '"' or source[next] == "'": # String
		res = run_state_machine(0, next, String_trans_table, String_fstate_list)
		token.type = Token.STRING
	elif source[next] == '#': # Comment
		var start = next
		while next < source.length() and source[next] != '\n':
			if source[next] == '\n':
				last_line_break = next
				line_cnt += 1
			next += 1
		var l = next - start
		return gen_token(Token.COMMENT, source.substr(start, l), start, l, line_cnt, last_line_break)
	elif source[next] == '\n': # Line Break
		var old_last_line_break = last_line_break
		last_line_break = next
		line_cnt += 1
		next += 1
		return gen_token(Token.LINE_BREAK, '', next-1, 1, line_cnt-1, old_last_line_break)
	elif source[next] in blank_char_list: # Blank
		var start = next
		while next < source.length() and source[next] in blank_char_list:
			if is_indent_start(next):
				break
			next += 1
		return gen_token(Token.BLANK, '', start, next - start, line_cnt, last_line_break)
	
	if res == null:
		var column = (next - last_line_break) if last_line_break != -1 else next
		var error = 'Cna\'t identify the token! at line: %d, column: %d:\n%s' % [line_cnt+1, column+1, calc_locate_error([
			{
				'line_break': last_line_break if last_line_break != -1 else 0,
				'column': column
			}
		])]
		_error(error)
		return gen_token(Token.ERROR, error, column, 1, line_cnt, last_line_break)
	
	match res.status:
		StateMachineResult.SUCCESS:
			var start = next
			var end = res.next
			next = end
			line_cnt += res.line_cnt
			last_line_break = res.last_line_break
			
			token.raw = source.substr(start, end - start)
			token.start = start
			token.length = end - start
			token.line = line_cnt - res.line_cnt
			token.last_line_break = last_line_break
			return token
		StateMachineResult.FAIL:
			_error(res.error)
			return gen_token(Token.ERROR, res.error, next, 1, line_cnt, last_line_break)
		StateMachineResult.EOF:
			next = res.next
			return gen_token(Token.EOF, '', next, 1, line_cnt, last_line_break)
		_:
			_error('Undefined state machien result status!')

func run_state_machine(state, current_next, state_transition_table, final_state_list):
	var all_condition_fail = false
	var error_list = []
	var l_cnt = 0
	var last_l_break = last_line_break
	while current_next < source.length() and not all_condition_fail:
		all_condition_fail = true
		for e in state_transition_table[state]:
			var cond = false
			match e.type:
				TransitionConditionType.FUNC:
					if e.options:
						cond = call(e.condition, current_next, e.options)
					else:
						cond = call(e.condition, current_next)
				TransitionConditionType.CHAR:
					cond = source[current_next] == e.char
				TransitionConditionType.NOT_CHAR:
					cond = source[current_next] != e.char
			if cond:
				state = e.to
				# advance
				if source[current_next] == '\n':
					l_cnt += 1
					last_l_break = current_next
				current_next += 1
				all_condition_fail = false
				break
			else:
				error_list.append({
					'line': l_cnt + line_cnt,
					'column': (last_l_break - current_next) if last_l_break != -1 else current_next,
					'line_break': last_l_break if last_l_break != -1 else 0,
					'msg': e.error
				})
	
	var res = StateMachineResult.new()
	res.state = state
	res.next = current_next
	res.line_cnt = l_cnt
	res.last_line_break = last_l_break
	res.status = StateMachineResult.SUCCESS
	if not state in final_state_list:
		assert(error_list.size() > 0)
		var error = calc_error(error_list)
		if next < source.length():
			res.error = ('Illegal char \'%s\', expect %s at line: %d, column: %d:\n%s' % [source[next], error, error_list[0].line+1, error_list[0].column+1, calc_locate_error(error_list)])
			res.status = StateMachineResult.FAIL
		else:
#			res.error = ('Expect %s.' % error)
			res.status = StateMachineResult.EOF
	return res

func calc_next_line_break(start):
	while start < source.length():
		if source[start] == '\n':
			return start
		start += 1
	return source.length()

func calc_locate_error(error_list):
	assert(error_list.size() > 0)
	var error = ''
	var start = error_list[0].line_break
	var l = error_list[0].column
	error += source.substr(start, calc_next_line_break(start+1)) + '\n'
	for i in range(l):
		error += ' ' if source.ord_at(start + i) < 128 else '  '
	error += '^'
	return error
	

func calc_error(error_list):
	var error = ''
	var cnt = 0
	for e in error_list:
		error += '\'%s\'' % e.msg
		if cnt < error_list.size() - 1:
			error += ' or '
		cnt += 1
	return error

func is_valid_char(i:int):
	if source[i] in preserved_char_list:
		return false
	return true

func is_valid_char_without_digit(i:int):
	if source[i] in digit_char_list:
		return false
	return is_valid_char(i)

func is_indent_start(i:int):
	if i+1 >= source.length():
		return false
	if (source[i] == '\n' or i == 0):
		if source[i+1] in indent_char_list:
			return true
	return false

func is_digit_char(i:int):
	return source[i] in digit_char_list

func gen_transition(to:int, conditioin, error, options = null):
	return {
		'to': to,
		'type': TransitionConditionType.FUNC,
		'condition': conditioin,
		'options': options,
		'error': error
	}

func gen_transition_char(to:int , c):
	return {
		'to': to,
		'type': TransitionConditionType.CHAR,
		'char': c,
		'error': '\'%s\'' % c
	}
	
func gen_transition_not_char(to:int , c):
	return {
		'to': to,
		'type': TransitionConditionType.NOT_CHAR,
		'char': c,
		'error': 'no \'%s\'' % c
	}

func gen_token(type, raw, start, l, line, last_l_break):
	var t = Token.new()
	t.type = type
	t.raw = raw
	t.start = start
	t.length = l
	t.line = line
	t.last_line_break = last_l_break
	return t

func gen_transitions_char_list(to:int, list):
	var res = []
	for e in list:
		res.append(gen_transition_char(to, e))
	return res

func match_char(c):
	if next >= source.length():
		return false
	if source[next] == c:
		next += 1
		return true
	return false

func _error(error):
	if not has_error:
		first_error = error
	has_error = true
	last_error = error
	if is_print_error:
		printerr(error)
	
