tool
extends GraphNode

signal request_open_script(path)

enum {
	PARENT_SLOT = 0,
	CHILDREN_SLOT = 0,
	GUARD_SLOT = 1,
}

const PARENT_SLOT_COLOR = Color.rebeccapurple
const CHILDREN_SLOT_COLOR = Color.royalblue
const GUARD_SLOT_COLOR = Color.goldenrod

enum {
	NONE_TYPE = 0,
	BT_NODE_TYPE = 0,
}

var source_data
enum BTNStatus {
	Fresh = BTNode.FRESH,
	Running = BTNode.RUNNING,
	Failed = BTNode.FAILED,
	Succeeded = BTNode.SUCCEEDED,
	Cancelled = BTNode.CANCELLED,
}
export(BTNStatus) var status = BTNode.FRESH setget _on_set_status
func _on_set_status(v):
	if v == BTNStatus.Succeeded:
		highlight_color.a = 1.0
	status = v
	update()

onready var script_button = $ScriptButton
onready var param_container = $ParameterContainer

var highlight_color := Color(1, 1, 1, 0)

var builtin_node_name_map := {
	'BTActionFail': 'Fail',
	'BTActionSuccess': 'Success',
	'BTActionTimer': 'Timer',
	'BTActionRandomTimer': 'Random Timer',
	'BTCompositeDynamicGuardSelector': 'Dynamic Guard Selector',
	'BTCompositeParallel': 'Parallel',
	'BTCompositeRandomSelector': 'Random Selector',
	'BTCompositeRandomSequence': 'Random Sequence',
	'BTCompositeSelector': 'Selector',
	'BTCompositeSequence': 'Sequence',
	'BTDecoratorAlwaysFail': 'Always Fail',
	'BTDecoratorAlwaysSucceed': 'Always Succeed',
	'BTDecoratorInvert': 'Invert',
	'BTDecoratorRandom': 'Random',
	'BTDecoratorRepeat': 'Repeat',
	'BTDecoratorUntilFail': 'Until Fail',
	'BTDecoratorUntilSuccess': 'Until Success',
}

func _ready() -> void:
	set_slot(PARENT_SLOT, true, BT_NODE_TYPE, PARENT_SLOT_COLOR, true, BT_NODE_TYPE, CHILDREN_SLOT_COLOR)
	set_slot(GUARD_SLOT, false, NONE_TYPE, Color.white, true, BT_NODE_TYPE, GUARD_SLOT_COLOR)
	
	rect_size = Vector2.ZERO

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAW:
			match status:
				BTNode.RUNNING:
					draw_style_box(get_stylebox('running'), Rect2(Vector2.ZERO, rect_size))
				BTNode.FAILED:
					draw_style_box(get_stylebox('failed'), Rect2(Vector2.ZERO, rect_size))
				BTNode.SUCCEEDED:
					draw_style_box(get_stylebox('succeeded'), Rect2(Vector2.ZERO, rect_size))
				BTNode.CANCELLED:
					draw_style_box(get_stylebox('cancelled'), Rect2(Vector2.ZERO, rect_size))
			draw_rect(Rect2(Vector2.ZERO, rect_size), highlight_color, false, 3)

func _process(delta: float) -> void:
	if highlight_color.a > 0:
		highlight_color.a = lerp(highlight_color.a, 0, 0.03)
		update()
#----- Methods -----
func set_data(node_data):
	source_data = node_data
	title = source_data.name
	self.status = source_data.status
	update_script_button()
	if node_data.has('params'):
		param_container.set_data(node_data.params)
	update()

func update_data(node_data:Dictionary):
	for k in node_data.keys():
		if source_data.has(k):
			source_data[k] = node_data[k]
			if k == 'params':
				param_container.update_data(node_data.params)
	title = source_data.name
	self.status = source_data.status
	update_script_button()
	update()

func update_script_button():
	var script_path:String = source_data.script
	var type = script_path.get_file().get_basename()
	if builtin_node_name_map.has(type):
		script_button.text = builtin_node_name_map[type]
	else:
		script_button.text = type
	

#----- Signals -----
func _on_ScriptButton_pressed() -> void:
	emit_signal('request_open_script', source_data.script)
