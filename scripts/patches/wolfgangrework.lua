--[[
Dependencies:
scripts/tools/upvaluehacker
]]

-- Not needed, it's imported from below this in the modmain
-- if not GLOBAL.TheNet:GetIsServer() then return end

local TUNING = GLOBAL.TUNING

AddPrefabPostInit("wolfgang", function(inst)
	inst.components.hunger:SetRate(2*TUNING.WILSON_HUNGER_RATE)
	inst.components.sanity.night_drain_mult = 1.5
	inst.components.sanity.neg_aura_mult = 1.5
end)

local function patch_become(_become, damage_mult, health_max, scale)
	return function(inst, ...)
		_become(inst, ...)
		inst.components.combat.damagemultiplier = damage_mult
		local health_percent = inst.components.health:GetPercent()
		inst.components.health:SetMaxHealth(health_max)
		inst.components.health:SetPercent(health_percent, true)
		inst.Transform:SetScale(scale, scale, scale)
	end
end

local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
AddPrefabPostInit("world", function(inst)
	local onhungerchange = UpvalueHacker.GetUpvalue(GLOBAL.Prefabs.wolfgang.fn,
								"master_postinit", "onload", "onbecamehuman", "onhungerchange")
	UpvalueHacker.SetUpvalue(onhungerchange, function() end, "applymightiness")
	local _becomewimpy = UpvalueHacker.GetUpvalue(onhungerchange, "becomewimpy")
	UpvalueHacker.SetUpvalue(onhungerchange,
		patch_become(_becomewimpy, TUNING.WOLFGANG_ATTACKMULT_WIMPY_MIN, TUNING.WOLFGANG_HEALTH_WIMPY, .9),
		"becomewimpy")
	local _becomenormal = UpvalueHacker.GetUpvalue(onhungerchange, "becomenormal")
	UpvalueHacker.SetUpvalue(onhungerchange,
		patch_become(_becomenormal, TUNING.WOLFGANG_ATTACKMULT_NORMAL, TUNING.WOLFGANG_HEALTH_NORMAL, 1),
		"becomenormal")
	local _becomemighty = UpvalueHacker.GetUpvalue(onhungerchange, "becomemighty")
	UpvalueHacker.SetUpvalue(onhungerchange,
		patch_become(_becomemighty, TUNING.WOLFGANG_ATTACKMULT_MIGHTY_MAX, TUNING.WOLFGANG_HEALTH_MIGHTY, 1.25),
		"becomemighty")
end)

--Prevent the powerup/down states from immobilizing you
AddStategraphPostInit("wilson", function(sg)
	sg.states.powerup.tags.busy = nil
	sg.states.powerup.tags.pausepredict = nil
	sg.states.powerdown.tags.busy = nil
	sg.states.powerdown.tags.pausepredict = nil
end)