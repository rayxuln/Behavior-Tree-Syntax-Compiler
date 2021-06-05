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

#----- Classes -----
const Parser = preload('./Parser.gd')
const Tokenizer = preload('./Tokenizer.gd')
const AST = preload('./AST/AST.gd')
const EXPAST = preload('./AST/EXPAST.gd')

class Importer:
	extends Reference
	
	
	func import(path:String):
		pass
	

class BTNodeImporter:
	extends Importer
	
	func import(path:String):
		return BTNodeSymbol.new(path)
	

class Symbol:
	extends Reference
	
	var id # token
	
class SubtreeSymbol:
	extends Symbol
	
	var subtree # a AST Tree ref

class BTNodeSymbol:
	extends Symbol
	
	var script_path
	
	func _init(path:String) -> void:
		script_path = path
	

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
	
	func _init(w, t) -> void:
		what = w
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
#----- Properties -----
var symbol_table

var importer_table

var parser
var tokenizer

var has_error:bool
#----- Methods -----
func init():
	symbol_table = {} # {ID: Symbol}
	importer_table = {} # {sufiix: Importer}
	
	has_error = false
	
	add_importer('.gd', BTNodeImporter.new())

func add_importer(suffix:String, importer:Importer):
	importer_table[suffix] = importer
	

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
	
	return null

func compile_import_part(import_part):
	for i in import_part.import_statement_list:
		var id = i.id
		var path = i.path
		
		if symbol_table.has(id.value):
			error(MultipleIDError.new('\'%s\' is already defined!' % id.value, id))
			continue
		
		var comma = path.value.find_last('.')
		if comma >= 0:
			var suffix = path.value.substr(comma, path.value.length() - comma)
			var importer = importer_table[suffix] if importer_table.has(suffix) else null
			if importer:
				var symbol = importer.import(path.value)
				if symbol:
					symbol.id = id
					symbol_table[id.value] = symbol
				else:
					error(ImportError.new('Can\'t import "%s" with suffix \'%s\'' % [path.value, suffix], path))
			else:
				error(ImportError.new('No importer to import "%s" with suffix \'%s\'' % [path.value, suffix], path))
		else:
			error(ImportError.new('Can\'t import "%s" with no suffix' % path.value, path))
		


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



