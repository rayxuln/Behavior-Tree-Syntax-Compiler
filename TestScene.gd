extends Node


var tokenizer_test = preload('res://test/tokenizer_test.gd').new()
var parser_test = preload('res://test/parser_test.gd').new()
var Compiler = preload('res://compiler/Compiler.gd')

func _ready() -> void:
#	tokenizer_test.run_tests()
#	parser_test.run_tests()
	$Control/VSplitContainer/HSplitContainer/Output.text = parser_test.prettify_bt($Control/VSplitContainer/HSplitContainer/Input.text)

#---- Signals -----
func _on_Input_text_changed() -> void:
	$Control/VSplitContainer/HSplitContainer/Output.text = parser_test.prettify_bt($Control/VSplitContainer/HSplitContainer/Input.text)


func _on_CompileButton_pressed() -> void:
	var c = Compiler.new()
	c.init()
	c.compile($Control/VSplitContainer/HSplitContainer/Input.text)
	
	
	
