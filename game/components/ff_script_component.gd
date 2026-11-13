class_name FFScriptComponent
extends ScriptComponent

## Concrete holder for an entity's scripts. ScriptComponent is abstract in the
## library, so this is the smallest class that can carry a main script.


func _init(p_main_script: EntityScript = null) -> void:
	super()
	main_script = p_main_script
