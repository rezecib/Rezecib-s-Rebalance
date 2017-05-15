--[[
Dependencies:
none
]]

-- Not needed, it's imported from below this in the modmain
-- if not GLOBAL.TheNet:GetIsServer() then return end

AddStategraphPostInit("shadowcreature", function(sg)
	local _idle_onenter = sg.states.idle.onenter
	sg.states.idle.onenter = function(inst, ...)
		--It's been flagged for despawning, cache that flag
		if inst.wantstodespawn then inst._wantstodespawn = inst.wantstodespawn end
		--Otherwise, only make it want to despawn if it's been flagged before and hasn't been attacked recently
		inst.wantstodespawn = inst._wantstodespawn and not inst._recently_attacked
		return _idle_onenter(inst, ...)
	end
end)

local function RemoveRecentlyAttacked(inst)
	inst._recently_attacked = nil
end

local function AddRecentlyAttacked(inst)
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