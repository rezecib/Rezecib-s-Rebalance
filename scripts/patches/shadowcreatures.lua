--[[
Dependencies:
none
]]

-- Not needed, it's imported from below this in the modmain
-- if not GLOBAL.TheNet:GetIsServer() then return end

AddStategraphPostInit("shadowcreature", function(sg)
	local disappear_onenter = sg.states.disappear.onenter
	function sg.states.disappear.onenter(inst, ...)
		if inst._recently_attacked then
			inst.sg:GoToState("idle")
			return
		end
		disappear_onenter(inst, ...)
	end
end)

function RemoveRecentlyAttacked(inst)
	inst._recently_attackd = nil
end

function AddRecentlyAttacked(inst)
	inst._recently_attacked = true
	if inst._recently_attacked_task then
		inst._recently_attacked_task:Cancel()
	end
	inst._recently_attacked_task = inst:DoTaskInTime(15, RemoveRecentlyAttacked)
end

for _,prefab in pairs({"crawlinghorror", "terrorbeak"}) do
	AddPrefabPostInit(prefab, function(inst)
		inst:ListenForEvent("attacked", AddRecentlyAttacked)
	end)
end