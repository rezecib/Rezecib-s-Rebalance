--[[
Dependencies:
scripts/tools/brainsurgery
]]

-- Not needed, it's imported from below this in the modmain
-- if not GLOBAL.TheNet:GetIsServer() then return end

local TUNING = GLOBAL.TUNING

local function OnStarving() end

AddPrefabPostInit("lavae_pet", function(inst)
	--Prevent it from dying of starvation
	inst.components.hunger:SetOverrideStarveFn(OnStarving)
	--Prevent it from causing fires
	inst:RemoveComponent("propagator")
	--Give it regen
	inst.components.health:StartRegen(250*3/60, 3)
end)

local BrainSurgery = GLOBAL.require("tools/brainsurgery")

AddBrainPostInit("lavaepetbrain", function(brain)
	--Remove the part of the brain that makes it go burn things when hungry
	local node, node_i = BrainSurgery.FindNode(brain.bt.root, "STARVING BABY ALERT!")
	table.remove(brain.bt.root.children, node_i)
end)

AddStategraphPostInit("lavae", function(sg)
	local _frozen_unfreeze_fn = sg.states.frozen.events.unfreeze.fn
	sg.states.frozen.events.unfreeze.fn = function(inst, ...)
		if inst:HasTag("companion") then --this is an Extra-Adorable Lavae, not one of the Dragonfly's adds
			inst.sg:GoToState("hit")
		else
			_frozen_unfreeze_fn(inst, ...)
		end
	end
	local _thaw_unfreeze_fn = sg.states.thaw.events.unfreeze.fn
	sg.states.thaw.events.unfreeze.fn = function(inst, ...)
		if inst:HasTag("companion") then --this is an Extra-Adorable Lavae, not one of the Dragonfly's adds
			inst.sg:GoToState("hit")
		else
			_thaw_unfreeze_fn(inst, ...)
		end
	end
end)