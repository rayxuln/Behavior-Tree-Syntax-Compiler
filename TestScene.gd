extends Node


var tokenizer_test = preload('res://test/tokenizer_test.gd').new()
var parser_test = preload('res://test/parser_test.gd').new()

func _ready() -> void:
#	tokenizer_test.run_tests()
#	parser_test.run_tests()
	$Control/HSplitContainer/Output.text = parser_test.prettify_bt($Control/HSplitContainer/Input.text)

#---- Signals -----
func _on_Input_text_changed() -> void:
	$Control/HSplitContainer/Output.text = parser_test.prettify_bt($Control/HSplitContainer/Input.text)
