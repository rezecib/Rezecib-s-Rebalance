--[[
Dependencies:
scripts/prefabs/willowshadowfire
				shadowlighter
				shadowlighterfire
		components/shadowburner	
]]

table.insert(PrefabFiles, "willowshadowfire")
table.insert(PrefabFiles, "shadowlighter")
table.insert(PrefabFiles, "shadowlighterfire")
table.insert(Assets, Asset( "ATLAS", "images/inventoryimages/shadowlighter.xml" ))
table.insert(Assets, Asset( "IMAGE", "images/inventoryimages/shadowlighter.tex" ))
table.insert(Assets, Asset( "ATLAS", "minimap/shadowlighter.xml" ))
table.insert(Assets, Asset( "IMAGE", "minimap/shadowlighter.tex" ))
AddMinimapAtlas("minimap/shadowlighter.xml")

local require = GLOBAL.require
local TUNING = GLOBAL.TUNING

GLOBAL.STRINGS.CHARACTER_DESCRIPTIONS.willow = ""
	.."*Knows too much about fire for her own good \n"
	.."*Can craft a cuddly bear and some sweet lighters \n"
	.."*Can't keep warm when insane"

GLOBAL.STRINGS.NAMES.SHADOWLIGHTER = "Shadow Lighter"
GLOBAL.STRINGS.RECIPE_DESC.SHADOWLIGHTER = "Burn them! Burn them all!"
AddRecipe("shadowlighter",
		{Ingredient("nightmarefuel", 2),
		 Ingredient("lighter", 1)},
		GLOBAL.RECIPETABS.LIGHT,
		GLOBAL.TECH.MAGIC_THREE,
		nil,
		nil,
		nil,
		nil,
		"pyromaniac", -- required character tag
		"images/inventoryimages/shadowlighter.xml")

GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.SHADOWLIGHTER = "It doesn't seem to work for me..."
GLOBAL.STRINGS.CHARACTERS.WX78.DESCRIBE.SHADOWLIGHTER = "ITS DARK MAGIC IS NONFUNCTIONAL"
GLOBAL.STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.SHADOWLIGHTER = "A warrior draws upon light, not shadow!"
GLOBAL.STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.SHADOWLIGHTER = "Tiny scary firebox not make light for Wolfgang."
GLOBAL.STRINGS.CHARACTERS.WAXWELL.DESCRIBE.SHADOWLIGHTER = "Oh, what has she gotten into..."
GLOBAL.STRINGS.CHARACTERS.WENDY.DESCRIBE.SHADOWLIGHTER = "An even darker death in a box..."
GLOBAL.STRINGS.CHARACTERS.WEBBER.DESCRIBE.SHADOWLIGHTER = "It's a scary lighter. Let's stay away from it."
GLOBAL.STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.SHADOWLIGHTER = "I do not understand or trust its mechanism."
GLOBAL.STRINGS.CHARACTERS.WOODIE.DESCRIBE.SHADOWLIGHTER = "Lighter, but shadow? Guess that's why it's got no light, eh?"
GLOBAL.STRINGS.CHARACTERS.WILLOW.DESCRIBE.SHADOWLIGHTER = "I learned a thing or two while I was on the throne."

local STARTSHADOWFIRE = AddAction("STARTSHADOWFIRE", "Start Shadowfire", function(act)
	if act.doer and act.doer:HasTag("pyromaniac") and act.invobject.prefab == "shadowlighter"
	and act.doer.components.sanity.current > TUNING.WILLOW_SHADOWFIRE_SANITY_COST then
		act.doer._last_firestart = GLOBAL.GetTime()
		act.invobject.components.fueled:DoDelta(-TUNING.WILLOW_SHADOWFIRE_DURABILITY_COST)
		act.doer.components.sanity:DoDelta(-TUNING.WILLOW_SHADOWFIRE_SANITY_COST)
		GLOBAL.SpawnPrefab("willowshadowfire").Transform:SetPosition(act.pos:Get())
		return true
	end
end)

AddComponentAction("POINT", "lighter", function(inst, doer, pos, actions, right)
	if doer:HasTag("pyromaniac") and right and inst.prefab == "shadowlighter" then
		table.insert(actions, STARTSHADOWFIRE)
	end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(STARTSHADOWFIRE, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(STARTSHADOWFIRE, "doshortaction"))

if not GLOBAL.TheNet:GetIsServer() then return end

local _light_fn = GLOBAL.ACTIONS.LIGHT.fn
function GLOBAL.ACTIONS.LIGHT.fn(act)
	if _light_fn(act) then
		if act.doer and act.doer.prefab == "willow" then
			act.doer._last_firestart = GLOBAL.GetTime()
		end
		return true
	end
end

TUNING.WILLOW_LIGHTFIRE_SANITYLOSS_RATE = -TUNING.DAPPERNESS_LARGE
TUNING.WILLOW_LIGHTFIRE_SANITYLOSS_START = TUNING.TOTAL_DAY_TIME*2
TUNING.WILLOW_LIGHTFIRE_SANITYLOSS_MAX = TUNING.TOTAL_DAY_TIME*10 - TUNING.WILLOW_LIGHTFIRE_SANITYLOSS_START
TUNING.WILLOW_SHADOWFIRE_BURN_TIME = 60
TUNING.WILLOW_SHADOWFIRE_MAX_DAMAGE = 200
TUNING.WILLOW_SHADOWFIRE_DPS = 10
TUNING.WILLOW_SHADOWFIRE_DURABILITY_COST = TUNING.LIGHTER_FUEL*0.1
TUNING.WILLOW_SHADOWFIRE_SANITY_COST = 15

GLOBAL.STRINGS.CHARACTERS.WILLOW.ANNOUNCE_WANTFIRE = "I can't remember the last time I burnt something..."
GLOBAL.STRINGS.CHARACTERS.WILLOW.ANNOUNCE_REALLYWANTFIRE = "My fingers are itching to burn something..."

AddPrefabPostInit("willow", function(inst)
	inst._last_firestart = GLOBAL.GetTime()
	local loss_state = 0
	local _custom_rate_fn = inst.components.sanity.custom_rate_fn
	inst.components.sanity.custom_rate_fn = function(inst)
		local delta = _custom_rate_fn(inst)
		local time_since_firestart = GLOBAL.GetTime() - inst._last_firestart - TUNING.WILLOW_LIGHTFIRE_SANITYLOSS_START
		local percent_firestart = math.max(0, math.min(time_since_firestart/TUNING.WILLOW_LIGHTFIRE_SANITYLOSS_MAX, 1))
		if percent_firestart > 0 then
			local loss = math.floor(percent_firestart/.25) + 1
			if loss ~= loss_state then
				inst.components.talker:Say(GLOBAL.GetString(inst, loss == 1 and "ANNOUNCE_WANTFIRE" or "ANNOUNCE_REALLYWANTFIRE"))
				loss_state = loss
			end
		else
			loss_state = 0
		end
		return delta + TUNING.WILLOW_LIGHTFIRE_SANITYLOSS_RATE*percent_firestart
	end
	local _OnSave = inst.OnSave
	inst.OnSave = function(inst, data)
		_OnSave(inst, data)
		data.time_since_last_firestart = GLOBAL.GetTime() - (inst._last_firestart or 0)
	end
	local _OnLoad = inst.OnLoad
	inst.OnLoad = function(inst, data)
		_OnLoad(inst, data)
		inst._last_firestart = GLOBAL.GetTime() - (data.time_since_last_firestart or 0)
	end
end)

--TODO: modify FireOver OnUpdate to do :SetMultColour(0,0,0,self.alpha*.7) if shadowfire damage?