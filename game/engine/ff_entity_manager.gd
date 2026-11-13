class_name FFEntityManager
extends EntityManager
## Concrete entity manager for FF-CRPG. It creates entities. It does not listen
## to scenes or signals; whoever owns the data model calls the factory methods.

const ADVENTURER_NAME: String = "ADVENTURER"
const INVENTORY_CAPACITY: int = 16


# —— Factory —————————————————————————————————————————————————

## Creates the adventurer with the rolled stats and the chosen potion, and adds it
## immediately. Components: PlayerComponent, NameComponent, StatsComponent,
## SuppliesComponent (10 Provisions, the potion with 2 measures), InventoryComponent
## (16 empty slots), WalletComponent (0 gold) and an FFScriptComponent holding a
## default AdventurerScript. The equipment is added to this entity in step 3.
func create_adventurer(skill: int, stamina: int, luck: int, potion: StringName) -> Entity:
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

	e.set_component(FFScriptComponent.new(AdventurerScript.new()))

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
