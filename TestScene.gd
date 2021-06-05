extends Node2D


var tokenizer_test = preload('res://test/tokenizer_test.gd').new()
var parser_test = preload('res://test/parser_test.gd').new()

func _ready() -> void:
#	tokenizer_test.run_tests()
	parser_test.run_tests()
