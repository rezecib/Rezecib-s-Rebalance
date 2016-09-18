--[[
Dependencies:
scripts/prefabs/shadowwaxwell
				shadowtorchfire
		brains/shadowwaxwellbrain
		
Potential changes:
	Increase duelist cost to 40%
	Remove armor imbuing, or make it add 5%
	Change duelist cost to dark sword
]]

local require = GLOBAL.require

local new_minions = {
	{
		name = "shadowtorchbearer",
		displayname = "Shadow Torchbearer",
		recipedesc = "Keep Charlie at bay.",
		item = "torch",
		penalty = GLOBAL.TUNING.SHADOWWAXWELL_SANITY_PENALTY.SHADOWLUMBER
	},
	{
		name = "shadowporter",
		displayname = "Shadow Porter",
		recipedesc = "Would you like me to carry that, sir?",
		item = "trap",
		penalty = GLOBAL.TUNING.SHADOWWAXWELL_SANITY_PENALTY.SHADOWDUELIST
	}
}

for _,data in ipairs(new_minions) do
	local builderprefab = data.name.."_builder"
	AddRecipe(builderprefab,
			{Ingredient("nightmarefuel", 2),
			 Ingredient(data.item, 1),
			 Ingredient(GLOBAL.CHARACTER_INGREDIENT.MAX_SANITY,
						data.penalty)},
			GLOBAL.CUSTOM_RECIPETABS.SHADOW,
			GLOBAL.TECH.SHADOW_TWO,
			nil,
			nil,
			true, -- cannot be prototyped, always needs the crafting station
			nil,
			"shadowmagic", -- required character tag
			"images/inventoryimages/"..data.name.."_builder.xml")
	GLOBAL.TUNING.SHADOWWAXWELL_SANITY_PENALTY[data.name:upper()] = data.penalty
	GLOBAL.STRINGS.NAMES[builderprefab:upper()] = data.displayname
	GLOBAL.STRINGS.RECIPE_DESC[builderprefab:upper()] = data.recipedesc
end
GLOBAL.STRINGS.NAMES.SHADOWWAXWELL = nil
GLOBAL.STRINGS.NAMES.SHADOWLUMBER = "Shadow Logger"
GLOBAL.STRINGS.NAMES.SHADOWMINER = "Shadow Miner"
GLOBAL.STRINGS.NAMES.SHADOWDIGGER = "Shadow Digger"
GLOBAL.STRINGS.NAMES.SHADOWDUELIST = "Shadow Duelist"
GLOBAL.STRINGS.NAMES.SHADOWTORCHBEARER = "Shadow Torchbearer"
GLOBAL.STRINGS.NAMES.SHADOWPORTER = "Shadow Porter"

local imbuers = {
	'axe', 'goldenaxe',
	'pickaxe', 'goldenpickaxe',
	'shovel', 'goldenshovel',
	'spear', 'spear_wathgrithr',
	'torch',
	'trap',
	"strawhat", "tophat", "beefalohat", "featherhat",
	"beehat", "minerhat", "spiderhat", "footballhat",
	"earmuffshat", "winterhat", "bushhat", "flowerhat",
	"walrushat", "slurtlehat", "ruinshat", "molehat",
	"wathgrithrhat", "icehat", "rainhat", "catcoonhat",
	"watermelonhat", "eyebrellahat",
}
local add_imbuer = function(inst) inst:AddComponent('imbuer') end
for _,prefab in ipairs(imbuers) do
	AddPrefabPostInit(prefab, add_imbuer)
end

local IMBUE = AddAction("IMBUE", "Imbue", function(act)
	if act.invobject and act.invobject.components.imbuer --it's something we can give to a minion
	and act.target and act.target:HasTag("imbuable") --we're targeting a minion
	and act.doer and act.doer.components.petleash and act.doer.components.petleash:IsPet(act.target) then --it's our own minion
		return act.target.components.imbuable:Imbue(act.invobject)
	end
end)
IMBUE.priority = 1

local IMBUETOGGLEACTIVE = AddAction("IMBUETOGGLEACTIVE", "Disengage", function(act)
	if act.target and act.target:HasTag("imbuable") --we're targeting a minion
	and act.doer and act.doer.components.petleash and act.doer.components.petleash:IsPet(act.target) then --it's our own minion
		act.target.components.imbuable:ToggleActive()
		return true
	end
end)
GLOBAL.STRINGS.ACTIONS.IMBUETOGGLEACTIVE = { STOPWORKING = "Disengage", STARTWORKING = "Engage" }
IMBUETOGGLEACTIVE.strfn = function(act)
	return act.target and (act.target:HasTag("imbue_active") and "STOPWORKING" or "STARTWORKING")
end
IMBUETOGGLEACTIVE.distance = 15
IMBUETOGGLEACTIVE.mount_valid = true

AddComponentAction("USEITEM", "imbuer", function(inst, doer, target, actions, right)
	if right and target:HasTag("imbuable") and target.replica.follower:GetLeader() and target.replica.follower:GetLeader() == doer then
		table.insert(actions, IMBUE)
	end
end)

AddComponentAction("SCENE", "imbuable", function(inst, doer, actions, right)
	if right and inst.replica.follower:GetLeader() and inst.replica.follower:GetLeader() == doer then
		table.insert(actions, IMBUETOGGLEACTIVE)
	end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(IMBUE, "give"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(IMBUE, "give"))
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(IMBUETOGGLEACTIVE, "give"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(IMBUETOGGLEACTIVE, "give"))

-- Prevent the imbue action from automatically putting the object in the hand equip slot
-- (this is both annoying and it messes up clients with action prediction)
local PlayerController = require("components/playercontroller")
local _DoActionAutoEquip = PlayerController.DoActionAutoEquip
function PlayerController:DoActionAutoEquip(buffaction, ...)
	if buffaction.invobject ~= nil and
		buffaction.invobject.replica.equippable ~= nil and
		buffaction.invobject.replica.equippable:EquipSlot() == GLOBAL.EQUIPSLOTS.HANDS and
		buffaction.action == IMBUE then
		return
	end
	return _DoActionAutoEquip(self, buffaction, ...)
end

-- Scales the container widget for the porter minion properly
local ContainerWidget = require("widgets/containerwidget")
local _Open = ContainerWidget.Open
function ContainerWidget:Open(container, doer, ...)
	_Open(self, container, doer, ...)
	if container.prefab == "shadowwaxwell" then
		self.bganim:SetScale(2/3)
	end
end

local TimeEvent = GLOBAL.TimeEvent
local FRAMES = GLOBAL.FRAMES
AddStategraphState("shadowmaxwell", GLOBAL.State{
	name = "doshortaction",
	tags = { "doing", "busy" },

	onenter = function(inst)
		inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("pickup")
		inst.AnimState:PushAnimation("pickup_pst", false)

		inst.sg.statemem.action = inst.bufferedaction
		inst.sg:SetTimeout(10 * FRAMES)
	end,

	timeline =
	{
		TimeEvent(4 * FRAMES, function(inst)
			inst.sg:RemoveStateTag("busy")
		end),
		TimeEvent(6 * FRAMES, function(inst)
			inst:PerformBufferedAction()
		end),
	},

	ontimeout = function(inst)
		--pickup_pst should still be playing
		inst.sg:GoToState("idle", true)
	end,

	onexit = function(inst)
		if inst.bufferedaction == inst.sg.statemem.action then
			inst:ClearBufferedAction()
		end
	end,
})
AddStategraphActionHandler("shadowmaxwell", GLOBAL.ActionHandler(GLOBAL.ACTIONS.PICKUP, "doshortaction"))

if not GLOBAL.TheNet:GetIsServer() then return end

AddPrefabPostInit("waxwell", function(inst)
	--reduce his spawning nightmare fuel to 4 to remove easy farming from the start
	local _OnNewSpawn = inst.OnNewSpawn
	inst.OnNewSpawn = function(inst, ...)
		_OnNewSpawn(inst, ...)
		inst.components.inventory:ConsumeByName("nightmarefuel", 2)
	end
	local _OnDespawn = inst.OnDespawn or function() end
	inst.OnDespawn = function(inst, ...)
		for _,pet in pairs(inst.components.petleash.pets) do
			if pet.components.container then
				pet.components.container:DropEverythingWithTag("irreplaceable")
				pet.keep_items = true
			end
		end
		_OnDespawn(inst, ...)
	end
end)