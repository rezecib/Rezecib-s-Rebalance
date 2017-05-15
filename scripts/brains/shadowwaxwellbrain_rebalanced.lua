require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"
require "behaviours/standstill"
require "behaviours/leash"
require "behaviours/runaway"

local ShadowWaxwellBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

--Images will help chop, mine and fight.

local MIN_FOLLOW_DIST = 0
local TARGET_FOLLOW_DIST = 6
local CLOSE_TARGET_FOLLOW_DIST = 2
local CLOSE_MAX_FOLLOW_DIST = 3
local MAX_FOLLOW_DIST = 8

local START_FACE_DIST = 6
local KEEP_FACE_DIST = 8

local KEEP_WORKING_DIST = 14
local SEE_WORK_DIST = 10

local KEEP_DANCING_DIST = 2

local KITING_DIST = 3
local STOP_KITING_DIST = 5

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8

local AVOID_EXPLOSIVE_DIST = 5

local DIG_TAGS = { "stump", "grave" }

local IGNORE_ITEMS = { waxwelljournal = true, trap = true }

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetLeaderPos(inst)
    return inst.components.follower.leader:GetPosition()
end

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function IsNearLeader(inst, dist)
    local leader = GetLeader(inst)
    return leader ~= nil and inst:IsNear(leader, dist)
end

local function FindEntityToWorkAction(inst, action, addtltags)
    local leader = GetLeader(inst)
    if leader ~= nil then
        --Keep existing target?
        local target = inst.sg.statemem.target
        if target ~= nil and
            target:IsValid() and
            not (target:IsInLimbo() or
                target:HasTag("NOCLICK") or
                target:HasTag("event_trigger")) and
            target.components.workable ~= nil and
            target.components.workable:CanBeWorked() and
            target.components.workable:GetWorkAction() == action and
            not (target.components.burnable ~= nil
                and (target.components.burnable:IsBurning() or
                    target.components.burnable:IsSmoldering())) and
            target.entity:IsVisible() and
            target:IsNear(leader, KEEP_WORKING_DIST) then
                
            if addtltags ~= nil then
                for i, v in ipairs(addtltags) do
                    if target:HasTag(v) then
                        return BufferedAction(inst, target, action)
                    end
                end
            else
                return BufferedAction(inst, target, action)
            end
        end

        --Find new target
        target = FindEntity(leader, SEE_WORK_DIST, nil, { action.id.."_workable" }, { "fire", "smolder", "event_trigger", "INLIMBO", "NOCLICK" }, addtltags)
        return target ~= nil and BufferedAction(inst, target, action) or nil
    end
end

local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local function DanceParty(inst)
    inst:PushEvent("dance")
end

local function ShouldDanceParty(inst)
    local leader = GetLeader(inst)
    return leader ~= nil and leader.sg:HasStateTag("dancing")
end

local function ShouldAvoidExplosive(target)
    return target.components.explosive == nil
        or target.components.burnable == nil
        or target.components.burnable:IsBurning()
end

local function ShouldRunAway(inst, target)
    return not (target.components.health ~= nil and target.components.health:IsDead())
        -- and (not target:HasTag("shadowcreature") or (target.components.combat ~= nil and target.components.combat:HasTarget()))
		and not (inst.miniontype == "shadowlumber" and target.monster) --#rezecib choppers don't fear poison birchnuts
end

local function UpdateForTarget(inst, target)
	if target ~= nil and target.components.combat and target.components.combat.target then
		if target ~= inst._brain_last_target then
			-- Previously used the line below for range, but it causes problems with the Ewecus snotbomb
			-- local range = target.components.combat:GetAttackRange()
			local range = target.components.combat.attackrange
			inst._brain_DuelistRunAwayNode.see_dist = math.max(range*1.25, KITING_DIST)
			inst._brain_DuelistRunAwayNode.safe_dist = math.max(range*1.5, STOP_KITING_DIST)
			inst._brain_cooldown_threshold = range/inst.components.locomotor.runspeed + .25
			inst._brain_last_target = target
		end
	end
end

local function ShouldKite(target, inst)
	if target ~= nil and target.components.health ~= nil and not target.components.health:IsDead() then
		if target.components.combat.target ~= nil and (target:HasTag("attack") or target.components.combat:GetCooldown() < (inst._brain_cooldown_threshold)) then 
			--target is fighting, and either in the process of doing an attack or just about to
			local leader = GetLeader(inst)
			if target == leader then return false end --don't run from our leader
			if TheNet:GetPVPEnabled() then
				--another leader's follower is to be feared
				return target.components.follower == nil or GetLeader(target) ~= leader
			else
				--run away from non-player-leader's followers, but don't be afraid of fellow player minions
				return target.components.follower == nil or GetLeader(target) == nil or not GetLeader(target):HasTag("player")
			end
		end
	end
end

local function IsMinionType(inst, miniontype)
	return function() return inst.miniontype[miniontype] and inst:HasTag("imbue_active") end
end

local function FindItemToPickupAction(inst)
	if inst.components.container:IsOpen() then return end
    local pt = inst:GetPosition()
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, SEE_WORK_DIST, nil, {"INLIMBO", "FX"})
	for k,item in pairs(ents) do
		if item:IsOnValidGround() and item.components.inventoryitem
		and item.components.inventoryitem.canbepickedup
		and not item.components.inventoryitem:IsHeld()
		and not IGNORE_ITEMS[item.prefab]
		and not item:HasTag("fire") and not item:HasTag("smolder") then
			local has_free_slot = not inst.components.container:IsFull()
			if not has_free_slot and item.components.stackable then
				for i = 1, inst.components.container:GetNumSlots() do
					local slot_item = inst.components.container:GetItemInSlot(i)
					if slot_item.prefab == item.prefab and not slot_item.components.stackable:IsFull() then
						has_free_slot = true
					end
				end
			end
			if has_free_slot then
				return BufferedAction(inst, item, ACTIONS.PICKUP)
			end
		end
	end
end

function ShadowWaxwellBrain:OnStart()
	self.inst._brain_last_target = nil
	self.inst._brain_cooldown_threshold = .5
	self.inst._brain_DuelistRunAwayNode = RunAway(self.inst, { fn = function(target) return ShouldKite(target, self.inst) end, tags = { "_combat", "_health" }, notags = { "shadowcreature", "INLIMBO" } }, KITING_DIST, STOP_KITING_DIST)
	local _Visit = self.inst._brain_DuelistRunAwayNode.Visit
	function self.inst._brain_DuelistRunAwayNode:Visit()
		UpdateForTarget(self.inst, self.inst.components.combat.target)
		_Visit(self)
	end
	local _GetRunAngle = self.inst._brain_DuelistRunAwayNode.GetRunAngle
	function self.inst._brain_DuelistRunAwayNode:GetRunAngle(pt, hp)
		--kite in the direction of your leader so you don't get too far from him
		local leader = GetLeader(self.inst)
		local fake_self = {inst = leader, avoid_time = self.avoid_time, avoid_angle = self.avoid_angle}
		local ret = _GetRunAngle(fake_self, pt, hp)
		self.avoid_time = fake_self.avoid_time
		self.avoid_angle = fake_self.avoid_angle
		return ret
	end
    local root = PriorityNode(
    {
        --#1 priority is dancing beside your leader. Obviously.
        WhileNode(function() return ShouldDanceParty(self.inst) end, "Dance Party",
            PriorityNode({
                Leash(self.inst, GetLeaderPos, KEEP_DANCING_DIST, KEEP_DANCING_DIST),
                ActionNode(function() DanceParty(self.inst) end),
        }, .25)),
		
        WhileNode(function() return IsNearLeader(self.inst, KEEP_WORKING_DIST) end, "Leader In Range",
            PriorityNode({
                --All shadows will avoid explosives
                RunAway(self.inst, { fn = ShouldAvoidExplosive, tags = { "explosive" }, notags = { "INLIMBO" } }, AVOID_EXPLOSIVE_DIST, AVOID_EXPLOSIVE_DIST),
                --Duelists will try to fight before fleeing
                IfNode(IsMinionType(self.inst, "shadowduelist"), "Is Duelist",
                    PriorityNode({
                        WhileNode(function()
								UpdateForTarget(self.inst, self.inst.components.combat.target)
								return ShouldKite(self.inst.components.combat.target, self.inst)
							end,
							"Dodge",
                            self.inst._brain_DuelistRunAwayNode),
                        ChaseAndAttack(self.inst),
                }, .25)),
                --All shadows will flee from danger at this point
				--#rezecib wrapped ShouldRunAway to pass inst
                RunAway(self.inst, { fn = function(target) return ShouldRunAway(self.inst, target) end, oneoftags = { "monster", "hostile" }, notags = { "shadowcreature", "player", "INLIMBO" } }, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
                --Workiers will try to work if not fleeing
                IfNode(IsMinionType(self.inst, "shadowlumber"), "Keep Chopping",
                    DoAction(self.inst, function() return FindEntityToWorkAction(self.inst, ACTIONS.CHOP) end)),
                IfNode(IsMinionType(self.inst, "shadowminer"), "Keep Mining",
                    DoAction(self.inst, function() return FindEntityToWorkAction(self.inst, ACTIONS.MINE) end)),
                IfNode(IsMinionType(self.inst, "shadowdigger"), "Keep Digging",
                    DoAction(self.inst, function() return FindEntityToWorkAction(self.inst, ACTIONS.DIG, DIG_TAGS) end)),
                IfNode(IsMinionType(self.inst, "shadowtorchbearer"), "Keep Torch Close",
					Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, CLOSE_TARGET_FOLLOW_DIST, CLOSE_MAX_FOLLOW_DIST)),
                IfNode(IsMinionType(self.inst, "shadowporter"), "Keep Picking Stuff Up",
					DoAction(self.inst, FindItemToPickupAction)),
        }, .25)),

        Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),

        WhileNode(function() return GetLeader(self.inst) ~= nil end, "Has Leader",
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),
    }, .25)

    self.bt = BT(self.inst, root)
end

return ShadowWaxwellBrain