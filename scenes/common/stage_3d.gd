class_name Stage3D
extends Control
## A small self-contained 3D stage for one .glb: its own SubViewport and World3D,
## an orthographic camera, and a pivot holding the model. There is no light: the
## models use emission shaders, so nothing on the stage needs lighting.
##
## Used for the dice and potion bottles. Each instance has its OWN world, so seven
## stages on one screen do not show each other's models.
##
## With no model the stage shows only its size_label (no placeholder art).
## Model assumptions:
##  - The root of the .glb is a Node3D.
##  - For dice, face N is turned toward the camera by FACE_EULER_DEG[N - 1]. That
##    matches a die modelled with 1 on +Z, 2 on +Y, 3 on +X, 4 on -X, 5 on -Y and
##    6 on -Z. If the Blender model differs, edit the table.

## Emitted when tumble_to_face() finishes, with or without a model.
signal settled

## Euler rotation (degrees) that turns each face toward the camera (+Z).
const FACE_EULER_DEG: Array[Vector3] = [
	Vector3(0.0, 0.0, 0.0),     # 1: +Z
	Vector3(90.0, 0.0, 0.0),    # 2: +Y
	Vector3(0.0, -90.0, 0.0),   # 3: +X
	Vector3(0.0, 90.0, 0.0),    # 4: -X
	Vector3(-90.0, 0.0, 0.0),   # 5: -Y
	Vector3(0.0, 180.0, 0.0),   # 6: -Z
]

## The .glb (as a PackedScene) to show. Leave empty to show only the size label.
@export var model: PackedScene
## Text shown while there is no model, for example "16" or "40x32".
@export var size_label: String = ""
## Largest model extent as a fraction of the stage's smaller side.
@export_range(0.1, 1.0, 0.05) var fit_fraction: float = 0.75
## Length of a tumble. 0 skips the animation (a future reduce-motion setting).
@export_range(0.0, 2.0, 0.05) var tumble_seconds: float = 0.5

@onready var _placeholder: Label = %Placeholder
@onready var _pivot: Node3D = %Pivot
@onready var _camera: Camera3D = %Camera

var _current: Node3D
var _tumble: Tween


func _ready() -> void:
	_placeholder.text = size_label
	if model != null:
		set_model(model)


func _exit_tree() -> void:
	if _tumble != null:
		_tumble.kill()


## Replaces whatever is on the stage with an instance of `packed`.
func set_model(packed: PackedScene) -> void:
	clear_model()
	if packed == null:
		return
	var node := packed.instantiate() as Node3D
	if node == null:
		push_warning("Stage3D: model root is not a Node3D.")
		return
	_pivot.add_child(node)
	_fit(node)
	_current = node
	_placeholder.hide()


func clear_model() -> void:
	if _current != null:
		_current.queue_free()
		_current = null
	_pivot.rotation_degrees = Vector3.ZERO
	_placeholder.show()


## Spins the model and settles with `face` (1-6) toward the camera, then emits settled.
## Without a model it just waits tumble_seconds, so callers behave the same.
func tumble_to_face(face: int) -> void:
	var target: Vector3 = FACE_EULER_DEG[clampi(face, 1, 6) - 1]
	if _tumble != null:
		_tumble.kill()
	if tumble_seconds <= 0.0:
		_pivot.rotation_degrees = target
		settled.emit.call_deferred()
		return
	_tumble = create_tween()
	if _current != null:
		# Visual spin only: uses the global RNG so the dice RNG (and the save) are untouched.
		var spin := Vector3(randi_range(1, 2), randi_range(1, 2), randi_range(0, 1)) * 360.0
		_pivot.rotation_degrees = target + spin
		_tumble.tween_property(_pivot, "rotation_degrees", target, tumble_seconds) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_tumble.tween_interval(tumble_seconds)
	_tumble.tween_callback(settled.emit)


## Scales the model so its largest extent fits the stage, and centres it on the pivot
## so a die turns about its own centre.
func _fit(node: Node3D) -> void:
	var bounds := _combined_aabb(node)
	var largest := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if largest <= 0.0:
		return
	var aspect := size.x / size.y if size.y > 0.0 else 1.0
	var view_height := _camera.size
	var limit := minf(view_height, view_height * aspect) * fit_fraction
	var factor := limit / largest
	node.scale = Vector3.ONE * factor
	node.position = -bounds.get_center() * factor


## Bounding box of every visual node under root, in root's local space.
func _combined_aabb(root: Node3D) -> AABB:
	var to_local := root.global_transform.affine_inverse()
	var result := AABB()
	var first := true
	for node in root.find_children("*", "VisualInstance3D", true, false):
		var visual := node as VisualInstance3D
		var box := (to_local * visual.global_transform) * visual.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
