class_name PrologueData
extends RefCounted
## The Prologue's content: five beats, twelve screens (see docs/prologue.md in the project).
##
## A beat is one vignette (or one carousel highlight) with one to three screens of text.
## The text is uppercase and wrapped at about 42 characters. The stage text panel holds a
## caption line and 4 body lines, and the carousel text panel holds 5 body lines.

const STAGE := "stage"
const CAROUSEL := "carousel"

## Captions under the three carousel panels, left to right.
const CAROUSEL_CAPTIONS: Array[String] = ["THE PLEA", "ANVIL", "RUMOURS"]

## layout:  STAGE (one large diorama) or CAROUSEL (three small ones).
## caption: red line at the top of the text panel. Stage beats only.
## panel:   index of the highlighted carousel panel. Carousel beats only.
## screens: the text, one entry per screen.
## diorama: optional. The .glb and its camera, with the numbers copied from Blender's N panel
##          (see DioramaView). Beats without one show the art area's size label.
const BEATS: Array[Dictionary] = [
	{
		"layout": STAGE,
		"caption": "THE OLD MAN",
		"diorama": {
			"model": "res://assets/art/models/dioramas/pagan_plain.glb",
			"cam_location": Vector3(0.0, -6.8151, 1.1805),
			"cam_rotation": Vector3(85.2, 0.0, 0.0),
			# Visible height in metres. Estimated from the 306x90 Blender test render (the
			# cart spans about 63 px per metre), not read from the camera. Check it against
			# the camera's Ortho Scale.
			"cam_size": 1.42,
		},
		"screens": [
			"WANDERING THE PAGAN PLAIN, YOU MEET AN OLD MAN PUSHING A LADEN HANDCART. YOU TELL HIM YOU ARE AN ADVENTURER, NOT A ROBBER.",
			"HE SMILES. \"THEN PERHAPS YOU OUGHT TO VISIT MY VILLAGE. WE ARE WORRIED BY STRANGE TALES FROM FIRETOP MOUNTAIN, TWO DAYS' WALK EAST.\"",
		],
	},
	{
		"layout": CAROUSEL,
		"panel": 0,
		"screens": [
			"VILE CREATURES ENTER THE MOUNTAIN THROUGH A CAVE. A MIGHTY SORCERER, A WARLOCK, RULES IT FROM BELOW. OUR CROPS FAIL, AND WE KNOW HIS EVIL IS THE CAUSE.",
			"WE SENT OUR BRAVEST MEN INTO THE MOUNTAIN. ONLY ONE RETURNED, A SHADOW OF HIMSELF, MUMBLING OF HIS TERROR. NOW WE LIVE WITHOUT HOPE, WAITING FOR DOOM.",
			"WE HAVE NO MONEY TO PAY YOU. BUT IT IS SAID THE WARLOCK KEEPS GREAT RICHES LOCKED IN A MAGNIFICENT CHEST INSIDE THE MOUNTAIN.",
		],
	},
	{
		"layout": CAROUSEL,
		"panel": 1,
		"screens": [
			"YOU TAKE THE CHALLENGE AND FOLLOW HIM TO THE VILLAGE OF ANVIL. ANXIOUS VILLAGERS CROWD ROUND, EAGER WITH ADVICE AND WARNINGS ABOUT THE WARLOCK.",
			"NEXT DAY YOU PRACTISE YOUR SWORDPLAY AND EAT TO BUILD YOUR STRENGTH. THE WHOLE VILLAGE SEES YOU OFF, MANY IN TEARS. WILL THEY EVER SEE YOU ALIVE AGAIN?",
		],
	},
	{
		"layout": CAROUSEL,
		"panel": 2,
		"screens": [
			"THE VILLAGERS' STORIES CONFLICT. THE WARLOCK IS OLD, OR YOUNG. HIS POWER COMES FROM AN ENCHANTED DECK OF CARDS, OR FROM BLACK SILK GLOVES.",
			"ONE RUMOUR SEEMS TRUE: THE WARLOCK'S TREASURE LIES IN A CHEST WITH TWO LOCKS, AND CREATURES IN THE TUNNELS GUARD THE KEYS. A FARMER SWEARS GOBLINS GUARD THE ENTRANCE.",
			"THE HEAD VILLAGER ADVISES: KEEP A GOOD MAP, OR YOU WILL BE LOST. THE WORST CREATURES LIE BEYOND AN UNDERGROUND RIVER. BEWARE THE FERRYMAN, WHO CHARGES GOLD PIECES.",
		],
	},
	{
		"layout": STAGE,
		"caption": "THE MOUNTAIN",
		"screens": [
			"THE TWO-DAY WALK ENDS. YOU REST AND LOOK UP AT FIRETOP MOUNTAIN, ITS FACE CLAWED BY SOME GREAT BEAST, ITS SUMMIT RED WITH STRANGE GROWTH.",
			"ACROSS THE CLEARING, A DARK CAVE MOUTH WAITS. YOU TAKE UP YOUR SWORD AND WALK IN.",
		],
	},
]


## Flattens the beats into one entry per screen:
## {"layout": String, "beat": int, "caption": String, "panel": int, "text": String,
##  "diorama": Dictionary}.
## `panel` is -1 for stage screens. `diorama` is empty when the beat has none.
static func build_screens() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for beat_index in BEATS.size():
		var beat: Dictionary = BEATS[beat_index]
		for text: String in beat["screens"]:
			result.append({
				"layout": beat["layout"],
				"beat": beat_index,
				"caption": beat.get("caption", ""),
				"panel": beat.get("panel", -1),
				"diorama": beat.get("diorama", {}),
				"text": text,
			})
	return result
