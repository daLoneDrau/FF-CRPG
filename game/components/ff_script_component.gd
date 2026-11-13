class_name FFScriptComponent
extends ScriptComponent
## Concrete holder for an entity's scripts. ScriptComponent is abstract in the
## library, so this is the smallest class that can carry a main script.


func _init(p_main_script: EntityScript = null) -> void:
	super()
	main_script = p_main_script


## Saves the script's file path. The script is loaded again from it.
func to_dict() -> Dictionary:
	var path := ""
	if main_script != null:
		path = (main_script.get_script() as Script).resource_path
	return {
		"key": get_class_name(),
		"enabled": enabled,
		"main_script": path,
	}
