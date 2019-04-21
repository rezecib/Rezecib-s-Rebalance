--These will get filled in by the patch files
PrefabFiles = {}
Assets = {}

local require = GLOBAL.require
local TheNet = GLOBAL.TheNet
local KnownModIndex = GLOBAL.KnownModIndex

local function IsModLoaded(workshop_name)
	if KnownModIndex:IsModEnabled(workshop_name) then return true end
	for _, moddir in ipairs(KnownModIndex:GetModsToLoad()) do
		if moddir == workshop_name then
			return true
		end
	end
	return false
end

-- Some mods do things that should override these patches
local overrides = {
	maxwellminions = IsModLoaded("workshop-741272188"),
	woodierework = IsModLoaded("workshop-888197520"),
}

local function patch(name)
	if (GetModConfigData(name) ~= false) and not overrides[name] then
		modimport("scripts/patches/"..name..".lua")
	end
end

patch("maxwellminions")
patch("attackfixes")
patch("beefalodomestication")
patch("willowrework")
patch("ancientguardian")
patch("ancientmagic")
patch("giantitems")

if not TheNet:GetIsServer() then return end

patch("woodierework")
patch("wx78rework")
patch("wolfgangrework")
patch("diseaseregrowth")
patch("thermalmeasurer")
patch("shadowcreatures")
patch("lanternhaunt")
patch("lavaebuff")

--Makes deciduous forest spawn the same birds as forest
local UpvalueHacker = require("tools/upvaluehacker")
AddClassPostConstruct("components/birdspawner", function(self)
	local BIRD_TYPES = UpvalueHacker.GetUpvalue(self.SpawnBird, "PickBird", "BIRD_TYPES")
	BIRD_TYPES[GLOBAL.GROUND.DECIDUOUS] = BIRD_TYPES[GLOBAL.GROUND.FOREST]
end)