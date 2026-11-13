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
##  - The model has an inverted-hull outline mesh named "border". Its thickness in the
##    .glb is far below one screen pixel at these sizes, so Stage3D rescales it to
##    outline_pixels (see _layout). Without a "border" node the outline is skipped.
##  - For dice, face N is turned toward the camera by FACE_EULER_DEG[N - 1]. The table
##    was measured from dice.glb by counting pips at each rotation. If the model
##    changes, re-measure it.

## Emitted when tumble_to_face() finishes, with or without a model.
signal settled

## Euler rotation (degrees) that turns each face toward the camera (+Z).
## Measured from dice.glb: +Z is 3, +Y is 2, -Y is 5, +X is 1, -X is 6, -Z is 4.
const FACE_EULER_DEG: Array[Vector3] = [
	Vector3(0.0, 90.0, 0.0),    # 1
	Vector3(90.0, 0.0, 0.0),    # 2
	Vector3(0.0, 0.0, 0.0),     # 3
	Vector3(0.0, 180.0, 0.0),   # 4
	Vector3(-90.0, 0.0, 0.0),   # 5
	Vector3(0.0, -90.0, 0.0),   # 6
]

## The .glb (as a PackedScene) to show. Leave empty to show only the size label.
@export var model: PackedScene
## Text shown while there is no model, for example "16" or "40x32".
@export var size_label: String = ""
## Largest model extent as a fraction of the stage's smaller side.
@export_range(0.1, 1.0, 0.05) var fit_fraction: float = 0.75
## Length of a tumble. 0 skips the animation (a future reduce-motion setting).
@export_range(0.0, 2.0, 0.05) var tumble_seconds: float = 0.5
## Outline thickness in screen pixels. The "border" hull is scaled so it reaches this far
## past the model on every side. 0 keeps the hull exactly as modelled.
@export_range(0.0, 4.0, 0.25) var outline_pixels: float = 1.0

@onready var _placeholder: Label = %Placeholder
@onready var _pivot: Node3D = %Pivot
@onready var _camera: Camera3D = %Camera

var _current: Node3D
var _hull: Node3D
var _body_bounds: AABB
var _tumble: Tween


func _ready() -> void:
	_placeholder.text = size_label
	resized.connect(_layout)
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
	_current = node
	_hull = node.find_child("border", true, false) as Node3D
	_body_bounds = _combined_aabb(node, _hull)
	_layout()
	_placeholder.hide()


## Gives every surface of the mesh node called `node_name` this emission colour. The
## surface material is duplicated first, so other stages sharing the .glb are unchanged.
func tint_node(node_name: StringName, color: Color) -> void:
	if _current == null:
		return
	var mesh := _current.find_child(node_name, true, false) as MeshInstance3D
	if mesh == null:
		push_warning("Stage3D: no mesh node named %s." % node_name)
		return
	for i in mesh.get_surface_override_material_count():
		var mesh_material := mesh.get_active_material(i) as StandardMaterial3D
		if mesh_material == null:
			continue
		var copy := mesh_material.duplicate() as StandardMaterial3D
		copy.emission_enabled = true
		copy.emission = color
		mesh.set_surface_override_material(i, copy)


func clear_model() -> void:
	if _current != null:
		_current.queue_free()
		_current = null
	_hull = null
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


## Fits the model body to the stage and centres it on the pivot, so a die turns about its
## own centre. Runs on set_model() and again whenever the stage is resized, because the
## final size is only known after the containers have laid it out.
func _layout() -> void:
	if _current == null:
		return
	var area := size if size.x > 0.0 and size.y > 0.0 else custom_minimum_size
	var body := _body_bounds.size
	var largest := maxf(body.x, maxf(body.y, body.z))
	if area.x <= 0.0 or area.y <= 0.0 or largest <= 0.0:
		return
	var view_height := _camera.size
	var limit := minf(view_height, view_height * area.x / area.y) * fit_fraction
	var centre := _body_bounds.get_center()
	var factor := limit / largest
	if _hull != null and outline_pixels > 0.0:
		# One screen pixel is view_height / area.y world units. Reserve the outline's
		# width on both sides, then grow the hull to reach exactly that far past the body.
		var edge := outline_pixels * view_height / area.y
		factor = maxf((limit - 2.0 * edge) / largest, 0.001)
		var grow := edge / factor
		var hull_scale := Vector3(
				(body.x + 2.0 * grow) / maxf(body.x, 0.001),
				(body.y + 2.0 * grow) / maxf(body.y, 0.001),
				(body.z + 2.0 * grow) / maxf(body.z, 0.001))
		_hull.transform = Transform3D(Basis.from_scale(hull_scale), centre * (Vector3.ONE - hull_scale))
	_current.scale = Vector3.ONE * factor
	_current.position = -centre * factor


## Bounding box of every visual node under root, in root's local space. Nodes under
## `exclude` (the outline hull) are left out.
func _combined_aabb(root: Node3D, exclude: Node3D = null) -> AABB:
	var to_local := root.global_transform.affine_inverse()
	var result := AABB()
	var first := true
	for node in root.find_children("*", "VisualInstance3D", true, false):
		if exclude != null and (node == exclude or exclude.is_ancestor_of(node)):
			continue
		var visual := node as VisualInstance3D
		var box := (to_local * visual.global_transform) * visual.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
