--[[
Dependencies:
scripts/tools/upvaluehacker
]]

local require = GLOBAL.require
local TUNING = GLOBAL.TUNING
local TheNet = GLOBAL.TheNet
local orangeamulet_rate = 1/25
local orangestaff_rate = 1/20
local batbat_rate = 1/33

GLOBAL.AllRecipes.nightlight.ingredients[2].amount = 6 --nightmare fuel
GLOBAL.AllRecipes.nightlight.ingredients[3].amount = 3 --gems

GLOBAL.AllRecipes.onemanband.ingredients[1].amount = 4 --gold
GLOBAL.AllRecipes.onemanband.ingredients[2].amount = 6 --nightmare fuel
GLOBAL.AllRecipes.onemanband.ingredients[3].amount = 4 --pig skin

GLOBAL.ACTIONS.BLINK.fn = function(act)
    if act.invobject and act.invobject.components.blinkstaff and not act.invobject.components.fueled:IsEmpty() then
        return act.invobject.components.blinkstaff:Blink(act.pos, act.doer)
    end
end

local function HearPanFlute(inst, musician, instrument)
    if inst ~= musician and
        (TheNet:GetPVPEnabled() or not inst:HasTag("player")) and
        not (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen()) and
        not (inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck()) then
        if inst.components.sleeper ~= nil then
            inst.components.sleeper:AddSleepiness(10, TUNING.PANFLUTE_SLEEPTIME)
        elseif inst.components.grogginess ~= nil then
			local amount = 10
			if inst.components.inventory then
				local hat = inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
				if hat and hat.prefab == "earmuffshat" then
					amount = 2
				end
			end
            inst.components.grogginess:AddGrogginess(amount, TUNING.PANFLUTE_SLEEPTIME)
        else
            inst:PushEvent("knockedout")
        end
    end
end

--I can't believe I have to resort to this for this kind of change, but... 'tis the mod life, I guess
local UpvalueHacker = require("tools/upvaluehacker")
AddPrefabPostInit("world", function(TheWorld)
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.panflute.fn, HearPanFlute, "HearPanFlute")

	--I'm putting this code here to ensure that it runs after component actions are registered,
	-- this condition might NOT be true (gulp)
	
	--Just gotta have it check the fuel first
	local ACTIONS = GLOBAL.ACTIONS
	local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(TheWorld.IsActionValid, "COMPONENT_ACTIONS")
	COMPONENT_ACTIONS.POINT.blinkstaff = function(inst, doer, pos, actions, right)
		if right and TheWorld.Map:IsAboveGroundAtPoint(pos:Get()) and not inst:HasTag("fueldepleted") then
			table.insert(actions, ACTIONS.BLINK)
		end
	end
	
	if not GLOBAL.TheNet:GetIsServer() then return end
	
	local TheSim = GLOBAL.TheSim
	local SpawnPrefab = GLOBAL.SpawnPrefab
	local function pickup(inst, owner)
		if inst.components.fueled:IsEmpty() then return end --#rezecib added
		if owner == nil or owner.components.inventory == nil then
			return
		end
		local x, y, z = owner.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, TUNING.ORANGEAMULET_RANGE, { "_inventoryitem" }, { "INLIMBO", "NOCLICK", "catchable", "fire" })
		for i, v in ipairs(ents) do
			if v.components.inventoryitem ~= nil and
				v.components.inventoryitem.canbepickedup and
				v.components.inventoryitem.cangoincontainer and
				not v.components.inventoryitem:IsHeld() and
				owner.components.inventory:CanAcceptCount(v, 1) > 0 then

				--Amulet will only ever pick up items one at a time. Even from stacks.
				local fx = SpawnPrefab("small_puff")
				fx.Transform:SetPosition(v.Transform:GetWorldPosition())
				fx.Transform:SetScale(.5, .5, .5)

				inst.components.fueled:DoDelta(-TUNING.LARGE_FUEL*orangeamulet_rate) --#rezecib changed

				if v.components.stackable ~= nil then
					v = v.components.stackable:Get()
				end

				if v.components.trap ~= nil and v.components.trap:IsSprung() then
					v.components.trap:Harvest(owner)
				else
					owner.components.inventory:GiveItem(v)
				end
				return
			end
		end
	end
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.orangeamulet.fn, pickup, "onequip_orange", "pickup")
end)

local FUELTYPE = GLOBAL.FUELTYPE
FUELTYPE.BAT = "BAT"
FUELTYPE.ORANGEGEM = "ORANGEGEM"

if not GLOBAL.TheNet:GetIsServer() then return end

local function convert_finiteuses_to_fueled(inst, fueltype, rate, inflation)
	inflation = inflation or 1
	--add the fuel component right away so it can load saved data if it has any
	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = fueltype
	inst.components.fueled:InitializeFuelLevel(inst.components.finiteuses.total*inflation*TUNING.LARGE_FUEL*rate)
	inst.components.fueled.accepting = true
	
	--Set the uses to something impossible so we know if it loads values in
	local impossible_uses = inst.components.finiteuses.total + 1
	inst.components.finiteuses:SetUses(impossible_uses)
	--Delay this so it can load its finiteuses remaining if it has them
	inst:DoTaskInTime(0, function(inst)
		local uses = inst.components.finiteuses:GetUses()
		if uses ~= impossible_uses then --it loaded finiteuses data, transform it to fuel
			inst.components.fueled:InitializeFuelLevel(uses*inflation*TUNING.LARGE_FUEL*rate)
		end
		inst:RemoveComponent("finiteuses")
		inst.components.fueled:DoDelta(0) --make it update the % and whether it can be used
	end)
end

AddPrefabPostInit("orangegem", function(inst)
	inst:AddComponent("fuel")
	inst.components.fuel.fueltype = FUELTYPE.ORANGEGEM
	inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
end)

AddPrefabPostInit("orangestaff", function(inst)
	--update to use fuel instead of finiteuses
	inst.components.blinkstaff.onblinkfn = function(staff, pos, caster)
		if caster.components.sanity ~= nil then
			caster.components.sanity:DoDelta(-TUNING.SANITY_MED)
		end
		staff.components.fueled:DoDelta(-TUNING.LARGE_FUEL*orangestaff_rate)
	end
	
	--Inherit this from cane
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.CANE_DAMAGE)
	
	convert_finiteuses_to_fueled(inst, FUELTYPE.ORANGEGEM, orangestaff_rate) --1 gem per 20 telepoofs
end)

AddPrefabPostInit("orangeamulet", function(inst)
	convert_finiteuses_to_fueled(inst, FUELTYPE.NIGHTMARE, orangeamulet_rate) --1 fuel per 25 items picked up
end)

TUNING.ORANGEAMULET_RANGE = 8

AddPrefabPostInit("yellowamulet", function(inst)
	--stop it from breaking on depleted
	--make it turn off and lose its speed on depleted
	local turnoff_yellow = inst.components.inventoryitem.ondropfn --a bit precarious, but it's something
	inst.components.fueled:SetDepletedFn(function(inst)
		turnoff_yellow(inst)
		inst.components.equippable.walkspeedmult = 1
	end)
	local _onequipfn = inst.components.equippable.onequipfn
	inst.components.equippable:SetOnEquip(function(inst, owner)
		if inst.components.fueled:IsEmpty() then return end
		_onequipfn(inst, owner)
	end)
	local _ontakefuelfn = inst.components.fueled.ontakefuelfn or function() end
	inst.components.fueled.ontakefuelfn = function(inst)
		_ontakefuelfn(inst)
		inst.components.equippable.walkspeedmult = 1.2
		if inst.components.equippable.isequipped then
			inst.components.equippable.onequipfn(inst, inst.components.inventoryitem.owner)
		end
	end
end)

local function onentitydeath(inst, data)
	--gains back 80% of the durability it would use to kill something
	if inst:IsNear(data.inst, 20) then
		local amount = 0.8*data.inst.components.health:GetMaxWithPenalty()/inst.components.weapon.damage
		inst.components.finiteuses:SetUses(math.min(inst.components.finiteuses.total, inst.components.finiteuses:GetUses() + amount))
	end
end
AddPrefabPostInit("multitool_axe_pickaxe", function(inst)
	inst:ListenForEvent("entity_death", function(TheWorld, data) onentitydeath(inst, data) end, GLOBAL.TheWorld)
end)

AddPrefabPostInit("nightlight", function(inst)
    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(5)
    inst.components.childspawner:SetSpawnPeriod(30)
    inst.components.childspawner:SetMaxChildren(0)
    inst.components.childspawner.childname = "crawlingnightmare"
    inst.components.childspawner:SetRareChild("nightmarebeak", 0.35)
	inst.components.childspawner.onchildkilledfn = function(inst, child)
		inst.components.fueled:DoDelta(-TUNING.SMALL_FUEL)
	end
	local _sectionfn = inst.components.fueled.sectionfn
	inst.components.fueled:SetSectionCallback(function(section, ...)
		_sectionfn(section, ...)
		if section > 0 then
			inst.components.childspawner:StartRegen()
			inst.components.childspawner:StartSpawning()
		else
			inst.components.childspawner:StopRegen()
			inst.components.childspawner:StopSpawning()
			for k,child in pairs(inst.components.childspawner.childrenoutside) do
				child.components.combat:SetTarget(nil)
				child.components.lootdropper:SetLoot({})
				child.components.lootdropper:SetChanceLootTable(nil)
				child.components.health:Kill()
			end
		end
		inst.components.childspawner:SetMaxChildren(section)
		inst.components.childspawner:SetSpawnPeriod(50-section*10)
	end)
end)

AddPrefabPostInit("batwing", function(inst)
	inst:AddComponent("fuel")
	inst.components.fuel.fueltype = FUELTYPE.BAT
	inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
end)

AddPrefabPostInit("batbat", function(inst)
	
	local _onattack = inst.components.weapon.onattack
	inst.components.weapon.onattack = function(inst, ...)
		_onattack(inst, ...)
		inst.components.fueled:DoDelta(-TUNING.LARGE_FUEL*batbat_rate)
	end
	
	convert_finiteuses_to_fueled(inst, FUELTYPE.BAT, batbat_rate, 100/75) --1 gem per 20 telepoofs
	inst.components.fueled:SetDepletedFn(inst.Remove)
end)

--Add a hook for followers being added
Leader = require("components/leader")
local _AddFollower = Leader.AddFollower
function Leader:AddFollower(follower, ...)
	if self.followers[follower] == nil and follower.components.follower then
		if self.onaddfollower then
			self.onaddfollower(self.inst, follower)
		end
	end
	_AddFollower(self, follower, ...)
end

--Store a lookup of entities that only walk? not sure how to acquire this information otherwise
local walkers = {
	rocky = true,
}

local function speed_follower(inst, follower)
	local speed = walkers[follower.prefab] and follower.components.locomotor:GetWalkSpeed() or follower.components.locomotor:GetRunSpeed()
	--3x at 2 speed, down to 1.25x at 6 speed
	local speedmult = math.max(0, math.min(1 - (speed - 2)*.25, 1))*1.75 + 1.25
	follower.components.locomotor:SetExternalSpeedMultiplier(inst, "onemanband", speedmult)
	inst:ListenForEvent("stopfollowing", function()
		follower.components.locomotor:RemoveExternalSpeedMultiplier(inst, "onemanband")
	end, follower)
end

local function turnon_onemanband(inst)
	if inst.turnedon then return end --prevent repeat fueling from stacking these listeners
	inst.turnedon = true
	if inst.components.inventoryitem.owner and inst.components.inventoryitem.owner.components.leader then
		local leader = inst.components.inventoryitem.owner.components.leader
		leader.onaddfollower = function(owner, follower) speed_follower(inst, follower) end
		for follower,_ in pairs(leader.followers) do
			speed_follower(inst, follower)
		end
	end
end

local function turnoff_onemanband(inst)
	inst.turnedon = nil
	if inst.components.inventoryitem.owner and inst.components.inventoryitem.owner.components.leader then
		local leader = inst.components.inventoryitem.owner.components.leader
		for follower,_ in pairs(leader.followers) do
			follower.components.locomotor:RemoveExternalSpeedMultiplier(inst, "onemanband")
		end
	end
end

local function onequip_onemanband(inst, owner)
    if owner then
        owner.AnimState:OverrideSymbol("swap_body_tall", "swap_one_man_band", "swap_body_tall")
        inst.components.fueled:StartConsuming()
		if owner:HasTag("monster") then
			inst.hadmonster = true
			inst:RemoveTag("monster")
		end
    end
	if inst.components.fueled:IsEmpty() then return end
	turnon_onemanband(inst)
end

local function onunequip_onemanband(inst, owner)
    if owner then
        owner.AnimState:ClearOverrideSymbol("swap_body_tall") 
        inst.components.fueled:StopConsuming()
		if inst.hadmonster then
			inst:AddTag("monster")
		end
    end
	turnoff_onemanband(inst)
end

AddPrefabPostInit("onemanband", function(inst)
	inst.hadmonster = false
	inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
	inst.components.fueled:InitializeFuelLevel(TUNING.LARGE_FUEL*5) --5 nightmare fuels
	inst.components.fueled:SetDepletedFn(turnoff_onemanband)
	inst.components.fueled.ontakefuelfn = turnon_onemanband
	inst.components.fueled.rate = TUNING.LARGE_FUEL/TUNING.TOTAL_DAY_TIME
	inst.components.fueled.accepting = true
	inst.components.equippable.dapperfn = nil
	inst.components.equippable.dapperness = -TUNING.DAPPERNESS_SMALL
	inst:RemoveComponent("leader")
	inst.components.equippable:SetOnEquip(onequip_onemanband)
	inst.components.equippable:SetOnUnequip(onunequip_onemanband)
end)

AddPrefabPostInit("book_sleep", function(inst)
	inst.components.book.onread = function(inst, reader)
            reader.components.sanity:DoDelta(-TUNING.SANITY_LARGE)

            local x, y, z = reader.Transform:GetWorldPosition()
            local range = 30
            local ents = GLOBAL.TheNet:GetPVPEnabled() and
                        GLOBAL.TheSim:FindEntities(x, y, z, range, nil, { "playerghost" }, { "sleeper", "player" }) or
                        GLOBAL.TheSim:FindEntities(x, y, z, range, { "sleeper" }, { "player" })
            for i, v in ipairs(ents) do
                if v ~= reader and
				not (v.components.freezable ~= nil and v.components.freezable:IsFrozen()) and
				not (v.components.pinnable ~= nil and v.components.pinnable:IsStuck())
				and (not v:HasTag("player") or reader:IsNear(v, 15)) then
                    if v.components.sleeper ~= nil then
                        v.components.sleeper:AddSleepiness(10, 20)
                    elseif v.components.grogginess ~= nil then
						local amount = 10
						if v.components.inventory then
							local hat = v.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
							if hat and hat.prefab == "earmuffshat" then
								amount = 2
							end
						end
                        v.components.grogginess:AddGrogginess(amount, 20)
                    else
                        v:PushEvent("knockedout")
                    end
                end
            end
            return true
        end
end)