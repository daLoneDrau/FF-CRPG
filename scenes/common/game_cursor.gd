extends CanvasLayer
## Software mouse cursor in the Apple II style: a blinking inverse-video block.
##
## The OS cursor is hidden and this block is drawn inside the 320x180 viewport, so it
## scales with the integer scaling (a hardware cursor would not). The block inverts
## whatever is under it to ink or paper, so it shows on cream, on ink fills and on
## hovered buttons.
##
## Registered as an autoload (see game_cursor.tscn). It blinks while the mouse rests,
## stays solid right after the mouse moves, hides while keys are being used, and
## returns on the next mouse movement.

## Size of the block in viewport pixels. 6x8 is one character cell.
@export var cell_size: Vector2i = Vector2i(6, 8)
## Seconds for one full blink (on, then off).
@export_range(0.2, 2.0, 0.05) var blink_seconds: float = 1.0
## Seconds the block stays solid after the mouse moves.
@export_range(0.0, 2.0, 0.05) var solid_seconds: float = 0.4

@onready var _block: ColorRect = %Block

var _clock: float = 0.0
var _solid_until: float = 0.0
var _keyboard_mode: bool = false
var _inside: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_block.size = Vector2(cell_size)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_keyboard_mode = false
		_solid_until = _clock + solid_seconds
	elif event is InputEventKey and (event as InputEventKey).pressed:
		_keyboard_mode = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		_inside = false
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		_inside = true


func _process(delta: float) -> void:
	_clock += delta
	_block.position = get_viewport().get_mouse_position().floor()
	var blink_on := _clock < _solid_until or fmod(_clock, blink_seconds) < blink_seconds * 0.5
	_block.visible = _inside and not _keyboard_mode and blink_on
