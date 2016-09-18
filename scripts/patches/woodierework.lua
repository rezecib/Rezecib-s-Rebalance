--[[
Dependencies:
none
]]

-- Not needed, it's imported from below this in the modmain
-- if not GLOBAL.TheNet:GetIsServer() then return end

local require = GLOBAL.require
local TUNING = GLOBAL.TUNING

TUNING.BEAVER_SANITY_PENALTY = 0 --get rid of beaver sanity drain
TUNING.BEAVER_DAMAGE = TUNING.SPIKE_DAMAGE --restore his damage
--Actually, since being a beaver isn't so bad anymore, maybe this can stay ridiculous
-- TUNING.BEAVER_FULLMOON_DRAIN_MULTIPLIER = 5*4 --100 over 4 segs instead of 2

local function onrespawnedfromghost(inst)
	inst.event_listeners.deployitem = nil --get rid of pinecone sanity gain
end

local function OnBeaverDelta(inst, data)
	if not data.overtime then --overtime is nil when eating, otherwise always true (patches may change this)
		inst.components.health:DoDelta((data.newpercent - data.oldpercent)*20) --works out to 20% of it
	end
end

local function BeaverHealthRedirect(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	if amount >= 0 then return false end --don't intercept positive deltas
	--prevent an infinite loop by "failing" the redirect if there's no log meter to absorb it
	if inst.components.beaverness.current == 0 then return false end
	local armor = (overtime or ignore_absorb) and 1 or TUNING.ARMORGRASS_ABSORPTION
	local log_delta = math.max(-inst.components.beaverness.current/armor, amount)
	inst.components.beaverness:DoDelta(log_delta*armor, true)
	local health_delta = amount - log_delta
	if health_delta < 0 then
		inst.components.health:DoDelta(health_delta, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	end
	return true --prevent it from also carrying out the original delta
end

local function ApplyBeaverChanges(inst)
	inst.components.temperature.inherentinsulation = TUNING.INSULATION_LARGE*2
	inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_LARGE*2
    inst.components.moisture:SetInherentWaterproofness(TUNING.WATERPROOFNESS_HUGE) --90%
	inst.components.health.redirect = BeaverHealthRedirect
	inst.components.combat.pvp_damagemod = TUNING.PVP_DAMAGE_MOD * (TUNING.AXE_DAMAGE / TUNING.BEAVER_DAMAGE)
	inst:ListenForEvent("beavernessdelta", OnBeaverDelta)
end

local function RemoveBeaverChanges(inst)
	--Don't need to revert ALL of the ones above, because some already get stripped by onbecamehuman
	inst.components.health.fire_damage_scale = 1
	inst.components.combat.pvp_damagemod = TUNING.PVP_DAMAGE_MOD
	inst.components.health.redirect = nil
	inst:RemoveEventCallback("beavernessdelta", OnBeaverDelta)
end

AddPrefabPostInit("woodie", function(inst)
	inst:ListenForEvent("ms_respawnedfromghost", onrespawnedfromghost)
	onrespawnedfromghost(inst)
	local _TransformBeaver = inst.TransformBeaver
	function inst.TransformBeaver(inst, isbeaver, ...)
		if inst.isbeavermode:value() then
			--they are transforming back from the werebeaver
			inst.components.sanity:SetPercent(0.25)
			inst.components.health:SetPercent(1/3)
			inst.components.hunger:SetPercent(0.25)
			_TransformBeaver(inst, isbeaver, ...)
			RemoveBeaverChanges(inst)
		else
			--they are transforming back to a human
			_TransformBeaver(inst, isbeaver, ...)
			ApplyBeaverChanges(inst)
		end
	end
	--Push this off to the next tick so the load happens first
	inst:DoTaskInTime(0, function() if inst.isbeavermode:value() then ApplyBeaverChanges(inst) end end)
end)