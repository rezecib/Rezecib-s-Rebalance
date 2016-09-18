--[[
Dependencies:
scripts/components/infusable
				   infuser
				   minotaurspawner
]]

local INFUSE = AddAction("INFUSE", "Infuse", function(act)
	if act.invobject and act.invobject.components.infuser
	and act.target and act.target:HasTag("infusable") then
		return act.target.components.infusable:Infuse(act.invobject)
	end
end)

AddComponentAction("USEITEM", "infuser", function(inst, doer, target, actions, right)
	if target:HasTag("infusable") then
		table.insert(actions, INFUSE)
	end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(INFUSE, "give"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(INFUSE, "give"))

if not GLOBAL.TheNet:GetIsServer() then return end

AddPrefabPostInit("meat", function(inst) inst:AddComponent("infuser") end)
AddPrefabPostInit("minotaurhorn", function(inst) inst:AddComponent("infuser") end)

local COLLISION = GLOBAL.COLLISION
AddPrefabPostInit("minotaur", function(inst)
	function inst.OnNightmarePhase(inst, phase)
		if phase ~= "wild" then
			inst.sg:GoToState("taunt")
			inst:DoTaskInTime(1, function() GLOBAL.ErodeAway(inst, 3) end)
			for i = 1, 6 do
				inst:DoTaskInTime(i*.4 + math.random()*.2, function()
					local offset = GLOBAL.Vector3(math.random()*3, 0, math.random()*3)
					local fx = GLOBAL.SpawnPrefab("statue_transition_2")
					if fx ~= nil then
						fx.Transform:SetPosition((inst:GetPosition() + offset):Get())
						fx.Transform:SetScale(2, 2, 2)
					end
					fx = GLOBAL.SpawnPrefab("statue_transition")
					if fx ~= nil then
						fx.Transform:SetPosition((inst:GetPosition() + offset):Get())
						fx.Transform:SetScale(1.5, 1.5, 1.5)
					end
				end)
			end
		end
	end
	function inst.UpdateShadow(inst, percent_infusion)
		inst.components.combat:SetDefaultDamage(0)
		inst.components.health:SetInvincible(true)
		local c = percent_infusion*.1
		local a = percent_infusion*.5 + .5
		inst.AnimState:SetMultColour(c, c, c, a)
		inst.AnimState:SetDeltaTimeMultiplier(a)
		inst.components.locomotor:SetExternalSpeedMultiplier(inst, "shadows become flesh", a)
		inst.Physics:ClearCollisionMask()
		inst.Physics:CollidesWith(COLLISION.WORLD)
		inst.shadowattacks = false
		inst:WatchWorldState("nightmarephase", inst.OnNightmarePhase)
	end
	function inst.BecomeFlesh(inst)
		inst.components.combat:SetDefaultDamage(GLOBAL.TUNING.MINOTAUR_DAMAGE)
		inst.components.health:SetInvincible(false)
		inst.AnimState:SetMultColour(1,1,1,1)
		inst.AnimState:SetDeltaTimeMultiplier(1)
		inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "shadows become flesh")
		inst.Physics:CollidesWith(COLLISION.OBSTACLES)
		inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
		inst.Physics:CollidesWith(COLLISION.CHARACTERS)
		inst.Physics:CollidesWith(COLLISION.GIANTS)
		inst.shadowattacks = true
		inst:StopWatchingWorldState("nightmarephase", inst.OnNightmarePhase)
	end
	
	inst:AddComponent("infusable")
	inst.components.infusable.oninfusefn = inst.UpdateShadow
	inst.components.infusable.oninfusioncompletefn = inst.BecomeFlesh
end)

AddPrefabPostInit("world", function(TheWorld)
	--need to wait for it to load its data
	TheWorld:AddComponent("minotaurspawner")
	TheWorld:DoTaskInTime(0, function(TheWorld)
		if not (TheWorld.topology and TheWorld.topology.nodes) then return end
		for id,node in pairs(TheWorld.topology.nodes) do
			if string.match(TheWorld.topology.ids[id], "RuinedGuarden")
			or string.match(TheWorld.topology.ids[id], "LabyrinthGuarden") then
				--this node is where the ancient guardian spawns
				TheWorld.components.minotaurspawner:RegisterLocation(id, node.x, node.y)
			end
		end
	end)
end)