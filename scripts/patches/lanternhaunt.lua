--[[
Dependencies:
none
]]

-- Not needed, it's imported from below this in the modmain
-- if not GLOBAL.TheNet:GetIsServer() then return end

AddPrefabPostInit("lantern", function(inst)
	GLOBAL.AddHauntableCustomReaction(inst, function()
		if not inst.components.machine or math.random() < .5 then return true end
		if inst.components.machine:IsOn() then
			inst.components.machine:TurnOff()
		else
			inst.components.machine:TurnOn()
		end
		return false
	end)
end)