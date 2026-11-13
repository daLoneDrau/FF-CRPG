class_name FFEntityManager
extends EntityManager
## Concrete entity manager for FF-CRPG. It creates entities. It does not listen
## to scenes or signals; whoever owns the data model calls the factory methods.

const ADVENTURER_NAME: String = "ADVENTURER"
const INVENTORY_CAPACITY: int = 16
const ITEM_SCRIPT_DIR: String = "res://game/scripts/items/"
const STARTING_ITEMS: Array[String] = ["SWORD", "SHIELD", "LEATHER ARMOUR", "LANTERN"]


# —— Factory —————————————————————————————————————————————————

## Creates the adventurer and its four starting items, and adds them immediately.
## Adventurer components: PlayerComponent, NameComponent, StatsComponent,
## SuppliesComponent (10 Provisions, the potion with 2 measures), InventoryComponent
## (16 empty slots), WalletComponent (0 gold), FFEquipmentComponent (empty) and an
## FFScriptComponent holding a default AdventurerScript.
## Returns {"adventurer": Entity, "items": Array[Entity]}. The items are created but
## not equipped; the caller equips them through the scene's equipment system.
func create_adventurer(skill: int, stamina: int, luck: int, potion: StringName) -> Dictionary:
	var e := Entity.new()
	e.id = uuidv4()
	e.tags.add(EntityTags.Tag.PC)

	e.set_component(PlayerComponent.new(0))
	e.set_component(NameComponent.new(ADVENTURER_NAME))

	var stats := StatsComponent.new()
	stats.setup(skill, stamina, luck)
	e.set_component(stats)

	var supplies := SuppliesComponent.new()
	supplies.setup(potion)
	e.set_component(supplies)

	var inventory := InventoryComponent.new()
	inventory.capacity = INVENTORY_CAPACITY
	inventory.slots.resize(INVENTORY_CAPACITY)
	e.set_component(inventory)

	e.set_component(WalletComponent.new())
	e.set_component(FFEquipmentComponent.new())
	e.set_component(FFScriptComponent.new(AdventurerScript.new()))

	add_entity(e)
	add_entity_immediately(e.id)

	var items: Array[Entity] = []
	for item_name: String in STARTING_ITEMS:
		var item := create_item(item_name)
		if item != null:
			items.append(item)
	return {"adventurer": e, "items": items}


## Creates an item entity from its name, for example "LEATHER ARMOUR". The item's
## script is loaded by name from res://game/scripts/items/ ("leather_armour_script.gd").
## item_name only selects the script. The script names the item and sets the slots
## the item can be equipped in when it receives
## the INITIALIZED event, which add_entity_immediately() emits. That needs a
## ScriptSystem in the scene (FFScriptSystem) to attach the script and dispatch the event.
## Returns null and logs an error if there is no script for the name.
func create_item(item_name: String) -> Entity:
	var path := ITEM_SCRIPT_DIR + item_name.to_lower().replace(" ", "_") + "_script.gd"
	if not ResourceLoader.exists(path):
		push_error("FFEntityManager.create_item: no script for '%s' at %s" % [item_name, path])
		return null
	var script := (load(path) as GDScript).new() as EntityScript
	if script == null or not script.has_method("on_initialized"):
		push_error("FFEntityManager.create_item: '%s' is not an item script." % path)
		return null

	var e := Entity.new()
	e.id = uuidv4()
	e.tags.add(EntityTags.Tag.ITEM)
	e.set_component(NameComponent.new())
	e.set_component(FFItemComponent.new())

	e.set_component(FFScriptComponent.new(script))

	add_entity(e)
	add_entity_immediately(e.id)
	return e


# —— EntityManager abstract API ——————————————————————————————

func is_pc(e: Entity) -> bool:
	return e.tags.has(EntityTags.Tag.PC)


func is_item(e: Entity) -> bool:
	return e.tags.has(EntityTags.Tag.ITEM)


func is_unique(e: Entity) -> bool:
	return e.tags.has(EntityTags.Tag.UNIQUE)


## The game has no spells.
func kill_spells_on(_e_id: String) -> void:
	pass


## Filled in with the equipment in step 3.
func unequip_from_inventory(_player_entity: Entity, _item_entity: Entity) -> bool:
	return false


## The game has no entity scripts.
func send_init_script_event(_entity: Entity) -> void:
	pass
