--[[
Dependencies:
none
]]

-- Not needed, it's imported from below this in the modmain
-- if not GLOBAL.TheNet:GetIsServer() then return end

local TUNING = GLOBAL.TUNING

AddPrefabPostInit("world", function(inst)
	inst:DoTaskInTime(0, function(inst) --push it until after the data is loaded
		if inst.prefabswapstatus then
			for _,swap in pairs(inst.prefabswapstatus.twigs) do
				if swap.name == "regular twigs" then
					if not swap.trigger.disease_immunities then
						swap.trigger.disease_immunities = {}
					end
					swap.trigger.disease_immunities.terrain = GLOBAL.GROUND.DECIDUOUS
				end
			end
		else
			print("No prefabswapstatus?")
		end
	end)
end)

local disease_time_increase = 2*TUNING.TOTAL_DAY_TIME

AddComponentPostInit("diseaseable", function(self)
	self.defaultDeathTimeMin = (self.defaultDeathTimeMin or TUNING.SEG_TIME) + disease_time_increase
	self.defaultDeathTimeMax = (self.defaultDeathTimeMax or TUNING.TOTAL_DAY_TIME) + disease_time_increase
end)

AddComponentPostInit("regrowthmanager", function(self)
	local _worldstate = GLOBAL.TheWorld.state
	self:SetRegrowthForType("cave_fern", TUNING.FLOWER_REGROWTH_TIME, "cave_fern", function()
			-- Flowers grow during the day, during not winter, while the ground is still wet after a rain.
			return ((_worldstate.israining or _worldstate.iscavenight or _worldstate.wetness <= 1 or _worldstate.iswinter) and 0)
				or (_worldstate.isspring and 2) -- double speed in spring
				or 1
		end)
	self:SetRegrowthForType("fireflies", TUNING.CARROT_REGROWTH_TIME, "fireflies", function()
			return (not _worldstate.iswinter and not _worldstate.isnight) and 1 or 0
		end)
end)

AddPrefabPostInit("cave_fern", function(inst)
	local _onpickedfn = inst.components.pickable.onpickedfn
	inst.components.pickable.onpickedfn = function(inst, ...)
		GLOBAL.TheWorld:PushEvent("beginregrowth", inst)
		_onpickedfn(inst, ...)
	end
end)

local function FirefliesOnSave(inst, data)
	data.pickedup = inst._pickedup
end

local function FirefliesOnLoad(inst, data)
	if data then
		inst._pickedup = data.pickedup
	end
end

AddPrefabPostInit("fireflies", function(inst)
	local _onpickupfn = inst.components.inventoryitem.onpickupfn
	inst.components.inventoryitem:SetOnPickupFn(function(inst, ...)
		inst._pickedup = true
		_onpickupfn(inst, ...)
	end)
	local _onfinish = inst.components.workable.onfinish
	inst.components.workable:SetOnFinishCallback(function(inst, ...)
		if not inst._pickedup then --don't want exploits where you drop-catch-drop-catch to spawn a ton
			GLOBAL.TheWorld:PushEvent("beginregrowth", inst)
		end
		_onfinish(inst, ...)
	end)
	inst.OnSave = FirefliesOnSave
	inst.OnLoad = FirefliesOnLoad
end)