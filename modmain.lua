PrefabFiles = {
	-- "shadowwaxwell", --Save this for later after checking for conflicting Maxwell rework mods
	"shadowtorchfire",
	"willowshadowfire",
	"shadowlighter",
	"shadowlighterfire",
	"beefalocollar",
}

Assets = {
	Asset( "IMAGE", "images/inventoryimages/beefalocollar.tex" ),
	Asset( "ATLAS", "images/inventoryimages/beefalocollar.xml" ),
	Asset( "ATLAS", "images/inventoryimages/shadowporter_builder.xml" ),
	Asset( "IMAGE", "images/inventoryimages/shadowporter_builder.tex" ),
	Asset( "ATLAS", "images/inventoryimages/shadowtorchbearer_builder.xml" ),
	Asset( "IMAGE", "images/inventoryimages/shadowtorchbearer_builder.tex" ),
	Asset( "IMAGE", "images/inventoryimages/shadowlighter.tex" ),
	Asset( "ATLAS", "images/inventoryimages/shadowlighter.xml" ),
	Asset( "IMAGE", "minimap/shadowlighter.tex" ),
	Asset( "ATLAS", "minimap/shadowlighter.xml" ),
}
AddMinimapAtlas("minimap/shadowlighter.xml")

local require = GLOBAL.require

local MAXWELLREWORKED = GLOBAL.KnownModIndex:IsModEnabled("workshop-741272188")
for _, moddir in ipairs(GLOBAL.KnownModIndex:GetModsToLoad()) do
	if moddir == "workshop-741272188" then
		MAXWELLREWORKED = true
	end
end

local function patch(name)
	modimport("scripts/patches/"..name..".lua")
end

if not MAXWELLREWORKED then
	table.insert(PrefabFiles, "shadowwaxwell_rebalanced")
	patch("maxwellminions")
end
patch("attackfixes")
patch("beefalodomestication")
patch("willowrework")
patch("ancientguardian")
patch("ancientmagic")
patch("giantitems")

if not GLOBAL.TheNet:GetIsServer() then return end

patch("wx78rework")
patch("wolfgangrework")
patch("woodierework")
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