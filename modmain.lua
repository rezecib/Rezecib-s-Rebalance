--These will get filled in by the patch files
PrefabFiles = {}
Assets = {}

local require = GLOBAL.require
local TheNet = GLOBAL.TheNet
local KnownModIndex = GLOBAL.KnownModIndex

-- Some mods do things that should override these patches, check for them
local CHECK_MODS = {
	["workshop-741272188"] = "maxwellminions",
	["workshop-1717160740"] = "maxwellminions",
	["workshop-888197520"] = "woodierework",
}
local PATCH_CONFLICT = {}
--If the mod is a]ready loaded at this point
for mod_name, key in pairs(CHECK_MODS) do
	PATCH_CONFLICT[key] = PATCH_CONFLICT[key] or (GLOBAL.KnownModIndex:IsModEnabled(mod_name) and mod_name)
end
--If the mod hasn't loaded yet
for k,v in pairs(GLOBAL.KnownModIndex:GetModsToLoad()) do
	local mod_type = CHECK_MODS[v]
	if mod_type then
		PATCH_CONFLICT[mod_type] = v
	end
end

local function patch(name)
	if (GetModConfigData(name) ~= false) and not PATCH_CONFLICT[name] then
		modimport("scripts/patches/"..name..".lua")
	end
end

patch("maxwellminions")
patch("attackfixes")
patch("beefalodomestication")
patch("willowrework")
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