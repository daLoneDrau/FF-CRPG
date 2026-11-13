class_name SaveSystem
extends GameSystem
## Writes the single save file. There is one slot: user://saves/save.json.
##
## Version 1 holds the dice RNG state, the current location (a placeholder until
## the Adventure scene exists) and every entity. Loading is not built yet.

const SAVE_DIR: String = "user://saves"
const SAVE_PATH: String = "user://saves/save.json"
const VERSION: int = 1
const START_LOCATION: String = "start"


## True when a save file exists.
static func exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Deletes the save file. Returns true when no save exists afterwards.
static func erase() -> bool:
	if not exists():
		return true
	var result := DirAccess.remove_absolute(SAVE_PATH)
	if result != OK:
		push_error("SaveSystem: could not delete %s (error %d)." % [SAVE_PATH, result])
		return false
	return true


## Writes the save. Returns false and logs an error if it could not be written.
func write() -> bool:
	var manager := get_entity_manager() as FFEntityManager
	if manager == null:
		push_error("SaveSystem: no FFEntityManager on the engine.")
		return false

	var data := {
		"version": VERSION,
		# A String, because JSON numbers are doubles and would round a 64-bit state.
		"rng_state": str(DiceTower.get_rng_state()),
		"location": START_LOCATION,
	}
	data.merge(manager.to_dict())

	var made := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if made != OK:
		push_error("SaveSystem: could not create %s (error %d)." % [SAVE_DIR, made])
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open %s (error %d)." % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func _on_ready() -> void:
	pass


func _on_initialize() -> void:
	pass


func handle_event(_event_name: String, _payload: Dictionary = {}) -> bool:
	return true


func _process_system(_delta: float) -> void:
	pass


func _on_cleanup() -> void:
	pass
