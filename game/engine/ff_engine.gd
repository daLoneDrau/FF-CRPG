class_name FFEngine
extends GameEngine
## Concrete engine for FF-CRPG. Registered as an autoload so it survives the
## scene swaps done by change_scene().

const TITLE_KEY: String = "title"
const TITLE_PATH: String = "res://scenes/title/title.tscn"


func _ready() -> void:
	super._ready()
	# Wait one frame so the boot scene is the current scene before run()
	# asks change_scene() what the current scene is.
	await get_tree().process_frame
	run()


func _initialize_systems() -> void:
	entity_manager = FFEntityManager.new()
	add_child(entity_manager)


func _setup_window() -> void:
	pass


func load_resources() -> void:
	pass


func _start_game() -> void:
	register_scene(TITLE_KEY, TITLE_PATH)
	change_scene(TITLE_KEY)
