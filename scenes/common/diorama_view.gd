class_name DioramaView
extends Control
## A framed 3D diorama for one .glb: its own SubViewport and World3D, an orthographic
## camera, and the model exactly as authored. Unlike Stage3D, which fits and recentres a
## small prop (dice, bottles), this view never moves or scales the model. The framing is
## authored in Blender, and the camera is placed from the numbers shown in Blender's
## N panel, so what Blender's camera view shows is what the game shows.
##
## There is no light: the models use emission shaders, so nothing needs lighting.
## With no model the view shows only its size_label (no placeholder art).
##
## Framing dictionary (all Blender values, so they can be copied straight from Blender):
##   "cam_location": Vector3   Camera Location (X, Y, Z) in metres.
##   "cam_rotation": Vector3   Camera Rotation (X, Y, Z) in degrees, XYZ Euler.
##   "cam_size":     float     Visible HEIGHT in metres. Set the Blender camera's Sensor Fit
##                             to Vertical so Ortho Scale is this height. With the default
##                             Auto fit, Ortho Scale is the width: divide by the view's
##                             width/height (306/90 for the Prologue stage).
## The camera is orthographic.

## Text shown while there is no model, for example "306X90".
@export var size_label: String = ""

@onready var _placeholder: Label = %Placeholder
@onready var _anchor: Node3D = %Anchor
@onready var _camera: Camera3D = %Camera

var _current: Node3D
var _current_path: String = ""


func _ready() -> void:
	_placeholder.text = size_label


## Shows the .glb at model_path, framed by `frame`. The model is loaded once and kept while
## the path stays the same, so calling this on every screen is cheap. Returns false and
## shows only the size label when there is no path or the file cannot be loaded.
func show_diorama(model_path: String, frame: Dictionary) -> bool:
	if model_path == "" or not ResourceLoader.exists(model_path):
		clear_diorama()
		return false
	if model_path != _current_path:
		var packed := load(model_path) as PackedScene
		var node: Node3D = null
		if packed != null:
			node = packed.instantiate() as Node3D
		if node == null:
			push_warning("DioramaView: '%s' did not load as a Node3D scene." % model_path)
			clear_diorama()
			return false
		clear_diorama()
		_anchor.add_child(node)
		_current = node
		_current_path = model_path
	_apply_frame(frame)
	_placeholder.hide()
	return true


func clear_diorama() -> void:
	if _current != null:
		_current.queue_free()
		_current = null
	_current_path = ""
	_placeholder.show()


func _apply_frame(frame: Dictionary) -> void:
	var location: Vector3 = frame.get("cam_location", Vector3.ZERO)
	var rotation_deg: Vector3 = frame.get("cam_rotation", Vector3(90.0, 0.0, 0.0))
	var height: float = frame.get("cam_size", 2.0)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = height
	_camera.transform = Transform3D(blender_basis(rotation_deg), blender_to_godot(location))


## Blender is Z-up and a camera at rotation (90, 0, 0) looks along +Y. Godot (and glTF) is
## Y-up and looks along -Z. A point (x, y, z) in Blender is (x, z, -y) in Godot.
static func blender_to_godot(point: Vector3) -> Vector3:
	return Vector3(point.x, point.z, -point.y)


## Orientation of a Blender object with XYZ Euler rotation (degrees), in Godot's axes.
## Blender's XYZ Euler applies X first, then Y, then Z. The axis swap is a -90 degree turn
## about X. For example Blender (85.2, 0, 0) becomes Godot (-4.8, 0, 0): a camera that
## looks along the horizon, tipped 4.8 degrees downward.
static func blender_basis(euler_deg: Vector3) -> Basis:
	var e := euler_deg * (PI / 180.0)
	var blender := Basis(Vector3.BACK, e.z) * Basis(Vector3.UP, e.y) * Basis(Vector3.RIGHT, e.x)
	return Basis(Vector3.RIGHT, -PI / 2.0) * blender
