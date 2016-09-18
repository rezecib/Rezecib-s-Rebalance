--[[
Dependencies:
none
]]

local require = GLOBAL.require
local TheNet = GLOBAL.TheNet

--Protects player followers from attacks by other players outside of PvP
local Combat = require("components/combat_replica")
local _IsValidTarget = Combat.IsValidTarget
function Combat:IsValidTarget(target, ...)
	local isvalid = _IsValidTarget(self, target, ...)
	if target ~= nil and not TheNet:GetPVPEnabled() and self.inst:HasTag("player")
	and target.replica.follower and target.replica.follower:GetLeader()
	and target.replica.follower:GetLeader():HasTag("player") then
		return isvalid and self.inst == target.replica.follower:GetLeader()
	else
		return isvalid
	end
end

-- Fixes attack commands for clients with movement prediction on
AddModRPCHandler(modname, "SetTarget", function(player, target)
	if player then
		player.components.combat:SetTarget(target)
	end
end)

local LocoMotor = require("components/locomotor")
local _PreviewAction = LocoMotor.PreviewAction
function LocoMotor:PreviewAction(bufferedaction, ...)
	_PreviewAction(self, bufferedaction, ...)
	if bufferedaction and bufferedaction.action == GLOBAL.ACTIONS.ATTACK then
		SendModRPCToServer(MOD_RPC[modname].SetTarget, bufferedaction.target)
	end
end

--Add an action for toggling Abigail
local TOGGLEAGGRO = AddAction("TOGGLEAGGRO", "Disengage", function(act)
	if act.target and act.doer and act.target._playerlink == act.doer then --it's our own minion
		act.target.components.aggrotoggleable:Toggle()
		return true
	end
end)
GLOBAL.STRINGS.ACTIONS.TOGGLEAGGRO = { STOPAGGRO = "Disengage", STARTAGGRO = "Engage" }
TOGGLEAGGRO.strfn = function(act)
	return act.target and (act.target:HasTag("aggro_active") and "STOPAGGRO" or "STARTAGGRO")
end
TOGGLEAGGRO.distance = 15
TOGGLEAGGRO.mount_valid = true

AddComponentAction("SCENE", "aggrotoggleable", function(inst, doer, actions, right)
	if right and inst.replica.follower:GetLeader() and inst.replica.follower:GetLeader() == doer then
		table.insert(actions, TOGGLEAGGRO)
	end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(TOGGLEAGGRO, "give"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(TOGGLEAGGRO, "give"))

if not GLOBAL.TheNet:GetIsServer() then return end

AddPrefabPostInit("abigail", function(inst)
	inst:AddComponent("aggrotoggleable")
end)

-- Fixes attack commands for everyone else
local _PushAction = LocoMotor.PushAction
function LocoMotor:PushAction(bufferedaction, ...)
	_PushAction(self, bufferedaction, ...)
	if bufferedaction and bufferedaction.action == GLOBAL.ACTIONS.ATTACK then
		bufferedaction.doer.components.combat:SetTarget(bufferedaction.target)
	end
end	
