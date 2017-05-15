local containers = require("containers")
local porter =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(-5, -70, 0),
	},
	type = "chest",
}
for y = 1, 0, -1 do
    for x = 0, 1 do
        table.insert(porter.widget.slotpos, Vector3(80 * x - 80 * 2 + 120, 80 * y - 80 * 2 + 120, 0))
    end
end

local _widgetsetup = containers.widgetsetup
function containers.widgetsetup(container, prefab, data, ...)
	if container.inst.prefab == "shadowwaxwell" or prefab == "shadowwaxwell" then
		data = porter
	end
	return _widgetsetup(container, prefab, data, ...)
end

local assets =
{
    Asset("ANIM", "anim/waxwell_shadow_mod.zip"),
    Asset("SOUND", "sound/maxwell.fsb"),
    Asset("ANIM", "anim/swap_pickaxe.zip"),
    Asset("ANIM", "anim/swap_axe.zip"),
    Asset("ANIM", "anim/swap_nightmaresword.zip"),
}

local prefabs =
{
    "shadow_despawn",
    "statue_transition_2",
}

local brain = require "brains/shadowwaxwellbrain_rebalanced"

local function OnAttacked(inst, data)
    if data.attacker ~= nil then
        if data.attacker.components.petleash ~= nil and
            data.attacker.components.petleash:IsPet(inst) then
            if inst.components.lootdropper == nil then
                inst:AddComponent("lootdropper")
            end
			for i=1,3 do
				inst.components.lootdropper:SpawnLootPrefab("nightmarefuel", inst:GetPosition())
			end
            data.attacker.components.petleash:DespawnPet(inst)
        elseif data.attacker.components.combat ~= nil then
            inst.components.combat:SuggestTarget(data.attacker)
        end
    end
end

local function retargetfn(inst)
    --Find things attacking leader
    local leader = inst.components.follower:GetLeader()
    return leader ~= nil
        and FindEntity(
            leader,
            TUNING.SHADOWWAXWELL_TARGET_DIST,
            function(guy)
                return guy ~= inst
                    and (guy.components.combat:TargetIs(leader) or
                        guy.components.combat:TargetIs(inst))
                    and inst.components.combat:CanTarget(guy)
            end,
            { "_combat" }, -- see entityreplica.lua
            { "playerghost", "INLIMBO" }
        )
        or nil
end

local function keeptargetfn(inst, target)
    --Is your leader nearby and your target not dead? Stay on it.
    --Match KEEP_WORKING_DIST in brain
    return inst.components.follower:IsNearLeader(14)
        and inst.components.combat:CanTarget(target)
end

local imbue_fns = {}
imbue_fns.shadowduelist = {
	imbue = function(inst)
		inst.components.health:StartRegen(TUNING.SHADOWWAXWELL_HEALTH_REGEN, TUNING.SHADOWWAXWELL_HEALTH_REGEN_PERIOD)

		inst.components.combat:SetDefaultDamage(TUNING.SHADOWWAXWELL_DAMAGE)
		inst.components.combat:SetAttackPeriod(TUNING.SHADOWWAXWELL_ATTACK_PERIOD)
		inst.components.combat:SetRetargetFunction(2, retargetfn) --Look for leader's target.
		inst.components.combat:SetKeepTargetFunction(keeptargetfn) --Keep attacking while leader is near.
	end,
	purge = function(inst)
		inst.components.health:StartRegen(TUNING.SHADOWWAXWELL_HEALTH_REGEN*.2, TUNING.SHADOWWAXWELL_HEALTH_REGEN_PERIOD)

		inst.components.combat:SetDefaultDamage(0)
		
		--Clear targeting abilities
		inst.components.combat:SetRetargetFunction() 
		inst.components.combat:SetKeepTargetFunction()
	end
}
imbue_fns.shadowtorchbearer = {
	imbue = function(inst, remaining)
		local fx = SpawnPrefab("shadowtorchfire")
		local follower = fx.entity:AddFollower()
		follower:FollowSymbol(inst.GUID, "swap_object", 0, fx.fx_offset, 0)
		inst._torchfire = fx
		inst._torchtask = inst:DoTaskInTime(remaining or 90, function() imbue_fns.shadowtorchbearer.purge(inst) end)
	end,
	purge = function(inst)
		if inst._torchtask then
			inst._torchtask:Cancel()
			inst._torchtask = nil
		end
		if inst._torchfire then
			inst._torchfire:Remove()
			inst._torchfire = nil
		end
	end
}
imbue_fns.shadowporter = {
	imbue = function(inst)
		inst:AddComponent("inventory")
		inst.components.inventory.maxslots = 0
		inst.components.inventory.GetOverflowContainer = function(self) return self.inst.components.container end
		inst:AddComponent("container")
		inst.components.container:WidgetSetup("shadowwaxwell")
		inst.AnimState:OverrideSymbol("backpack", "swap_backpack", "backpack")
		inst.AnimState:OverrideSymbol("swap_body", "swap_backpack", "swap_body")
	end,
	purge = function(inst)
		if not inst.keep_items then --lets player leave/migrate stop it from dropping duplicates
			inst.components.container:DropEverything()
		end
		inst:DoTaskInTime(0, function(inst)
			inst:RemoveComponent("inventory")
			inst:RemoveComponent("container")
		end)
		inst.AnimState:ClearOverrideSymbol("swap_body")
		inst.AnimState:ClearOverrideSymbol("backpack")
	end
}
imbue_fns.shadowlumber = {
	imbue = function() end,
	purge = function() end,
}
imbue_fns.shadowminer = {
	imbue = function() end,
	purge = function() end,
}
imbue_fns.shadowdigger = {
	imbue = function() end,
	purge = function() end,
}

local item_to_miniontype = {
	axe = 'shadowlumber',
	goldenaxe = 'shadowlumber',
	pickaxe = 'shadowminer',
	goldenpickaxe = 'shadowminer',
	shovel = 'shadowdigger',
	goldenshovel = 'shadowdigger',
	spear = 'shadowduelist',
	spear_wathgrithr = 'shadowduelist',
	torch = 'shadowtorchbearer',
	trap = 'shadowporter',
}

local miniontype_to_items = {}
for item,miniontype in pairs(item_to_miniontype) do
	if not miniontype_to_items[miniontype] then miniontype_to_items[miniontype] = {} end
	table.insert(miniontype_to_items[miniontype], item)
end

local tool_minions = {
	shadowlumber = true,
	shadowminer = true,
	shadowdigger = true,
	shadowtorchbearer = true,
}

local function DoEffects(pet)
    local x, y, z = pet.Transform:GetWorldPosition()
    SpawnPrefab("shadow_despawn").Transform:SetPosition(x, y, z)
    SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
end

local function MatchSpeed(inst)
	local leader = inst.components.follower.leader
	if leader then
		inst.components.locomotor.runspeed = leader.components.locomotor:GetRunSpeed()
	end
end

local hats = { "straw", "top", "beefalo", "feather", "bee", "miner", "spider", "football", "earmuffs",
	"winter", "bush", "flower", "walrus", "slurtle", "ruins", "mole", "wathgrithr", "ice", "rain",
	"catcoon", "watermelon", "eyebrella" }
local accepted_hats = {}
for i,hat in pairs(hats) do
	hats[i] = hat.."hat"
	accepted_hats[hat.."hat"] = "hat_"..hat
end
local helmets = {
	wathgrithrhat = true,
	footballhat = true,
	ruinshat = true,
	slurtlehat = true,
}

local function HealthRedirectDefault(inst, amount, overtime, cause, ignore_invincible, afflicter, ...)
	-- Don't take damage from earthquakes
	return afflicter ~= nil and afflicter:HasTag("quakedebris")
end

local function HealthRedirectArmor(inst, amount, ...)
	-- Carry over the immunity to earthquake damage
	if HealthRedirectDefault(inst, amount, ...) then return true end
	if amount < -60 then
		-- Maximum damage taken in one hit is 60
		inst.components.health:DoDelta(-60, ...)
		return true --don't run the normal DoDelta
	end
	--implicit return nil, which makes the normal DoDelta run
end

local function AddHat(inst, hat)
	inst._hat = hat
	if helmets[hat] then
		inst.components.health:SetAbsorptionAmount(.25)
		inst.components.health.redirect = HealthRedirectArmor
	else
		inst.components.health:SetAbsorptionAmount(0)
		inst.components.health.redirect = HealthRedirectDefault
	end
	inst.AnimState:OverrideSymbol("swap_hat", accepted_hats[hat], "swap_hat")
	inst.AnimState:Hide("HAIR_NOHAT")
	inst.AnimState:Hide("HAIR")
	inst.AnimState:Show("HAT")
	inst.AnimState:Show("HAT_HAIR")
	DoEffects(inst)
end

local function OnImbue(imbuable, item)
	local inst = imbuable.inst
	if accepted_hats[item] then
		if inst._hat == item then
			return false
		else
			imbuable:ClearImbueItems(hats)
			AddHat(inst, item)
			return true
		end
	end
	local miniontype = item_to_miniontype[item] or "shadowwaxwell"
	inst.components.named:SetName(STRINGS.NAMES[miniontype:upper()])
	local penalty = TUNING.SHADOWWAXWELL_SANITY_PENALTY[miniontype:upper()]
	-- Update the sanity penalty for Maxwell, and make sure we have enough
	local leader = inst.components.follower.leader
	local penalty_diff = penalty - (leader.components.sanity.sanity_penalties[inst] or 0)
	if leader.components.builder:HasCharacterIngredient({type=CHARACTER_INGREDIENT.MAX_SANITY, amount=penalty_diff}) then
		leader.components.sanity:AddSanityPenalty(inst, penalty)
	else
		return false
	end
	
	local swap = false
	for mtype,fns in pairs(imbue_fns) do
		if inst.miniontype[mtype] and mtype ~= miniontype then
			--this had mtype previously, and it needs to be removed
			fns.purge(inst)
			imbuable:ClearImbueItems(miniontype_to_items[mtype])
			inst.miniontype[mtype] = nil
		elseif not inst.miniontype[mtype] and mtype == miniontype then
			--it didn't have mtype previously
			fns.imbue(inst)
		end
	end
	if item == "torch" and not inst._torchfire then
		imbue_fns.shadowtorchbearer.imbue(inst)
	end
	
	--handle handslot-equippable display, which is common to most minion types
	if tool_minions[miniontype] then
		swap = "swap_"..item
	elseif miniontype == "shadowduelist" then
		swap = "swap_nightmaresword"
	end
	if swap then --show the new item being held
		inst.AnimState:OverrideSymbol("swap_object", swap, swap)
		inst.AnimState:Hide("ARM_normal")
		inst.AnimState:Show("ARM_carry")
	else --show the default arm state
		inst.AnimState:Hide("ARM_carry")
		inst.AnimState:Show("ARM_normal")
	end
	
	-- Update the minion type for the brain to know how to behave
	inst.miniontype[miniontype] = true
	DoEffects(inst)
	return true
end

local function DeathCleanup(inst)
	inst.match_speed_task:Cancel()
	for mtype,has in pairs(inst.miniontype) do
		if has and imbue_fns[mtype] then --it had this type, and there is cleanup for the type
			imbue_fns[mtype].purge(inst)
			inst.miniontype[mtype] = nil
		end
	end
end

local function OnSave(inst, data)
	if inst.miniontype.shadowtorchbearer then
		data.torch_remaining = inst._torchtask and (inst._torchtask.nexttick - GetTick())*FRAMES or 0
	end
end

local function OnLoad(inst, data)
	if data.torch_remaining then
		inst:DoTaskInTime(FRAMES*5, function()
			imbue_fns.shadowtorchbearer.purge(inst)
			imbue_fns.shadowtorchbearer.imbue(inst, data.torch_remaining)
		end)
	end
end

local function MakeMinion(prefab, tool, hat, master_postinit)
    local assets =
    {
        Asset("ANIM", "anim/waxwell_shadow_mod.zip"),
        Asset("SOUND", "sound/maxwell.fsb"),
        Asset("ANIM", "anim/axe.zip"),
        Asset("ANIM", "anim/pickaxe.zip"),
        Asset("ANIM", "anim/shovel.zip"),
        Asset("ANIM", "anim/spear.zip"),
        Asset("ANIM", "anim/torch.zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeGhostPhysics(inst, 1, 0.5)

        inst.Transform:SetFourFaced(inst)

        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild("waxwell_shadow_mod")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetMultColour(0, 0, 0, .5)

        if tool ~= nil then
            inst.AnimState:OverrideSymbol("swap_object", tool, tool)
            inst.AnimState:Hide("ARM_normal")
        else
            inst.AnimState:Hide("ARM_carry")
        end

        if hat ~= nil then
            inst.AnimState:OverrideSymbol("swap_hat", hat, "swap_hat")
            inst.AnimState:Hide("HAIR_NOHAT")
            inst.AnimState:Hide("HAIR")
        else
            inst.AnimState:Hide("HAT")
            inst.AnimState:Hide("HAT_HAIR")
        end

        inst:AddTag("scarytoprey")
        inst:AddTag("shadowminion")
		inst:AddTag("NOBLOCK")
        inst:SetPrefabNameOverride("shadowwaxwell")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
		
        inst:AddComponent("locomotor")
        -- inst.components.locomotor.runspeed = TUNING.SHADOWWAXWELL_SPEED
        inst.components.locomotor.pathcaps = { ignorecreep = true }
        inst.components.locomotor:SetSlowMultiplier(.6)

        inst:AddComponent("health")
		inst.components.health:SetMaxHealth(TUNING.SHADOWWAXWELL_LIFE)
        inst.components.health.nofadeout = true
		inst.components.health.redirect = HealthRedirectDefault

        inst:AddComponent("combat")
        inst.components.combat.hiteffectsymbol = "torso"
        inst.components.combat:SetRange(2)

        inst:AddComponent("follower")
        inst.components.follower:KeepLeaderOnAttacked()
        inst.components.follower.keepdeadleader = true
        inst:SetBrain(brain)
        inst:SetStateGraph("SGshadowwaxwell")

 		inst.match_speed_task = inst:DoPeriodicTask(1, MatchSpeed)
		inst:ListenForEvent("death", DeathCleanup)
		inst:ListenForEvent("onremove", DeathCleanup)

		inst:ListenForEvent("attacked", OnAttacked)

		inst:AddComponent("imbuable")
		inst.components.imbuable.onimbuefn = OnImbue
		inst.miniontype = {shadowporter = true}
		imbue_fns.shadowporter.imbue(inst)
		--start out with shadowporter to load any saved inventory first
		
		inst:AddComponent("named")
		
        if master_postinit ~= nil then
            master_postinit(inst)
        end
		
		inst.OnSave = OnSave
		inst.OnLoad = OnLoad

        return inst
    end

    return Prefab(prefab, fn, assets, prefabs)
end

--------------------------------------------------------------------------

local function onbuilt(inst, builder)
    local theta = math.random() * 2 * PI
    local pt = builder:GetPosition()
    local radius = math.random(3, 6)
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    if offset ~= nil then
        pt.x = pt.x + offset.x
        pt.z = pt.z + offset.z
    end
	local existing_pets = {}
	for k,v in pairs(builder.components.petleash.pets) do
		existing_pets[k] = v
	end
    builder.components.petleash:SpawnPetAt(pt.x, 0, pt.z, inst.pettype)
	for k,v in pairs(builder.components.petleash.pets) do
		if not existing_pets[k] then --this is the new pet
			k.components.imbuable:Imbue(inst.petimbue)
		end
	end
    inst:Remove()
end

local function MakeBuilder(prefab, imbueitem)
    --These shadows are summoned this way because petleash needs to
    --be the component that summons the pets, not the builder.
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()

        inst:AddTag("CLASSIFIED")

        --[[Non-networked entity]]
        inst.persists = false

        --Auto-remove if not spawned by builder
        inst:DoTaskInTime(0, inst.Remove)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.pettype = "shadowwaxwell"
		inst.petimbue = imbueitem
        inst.OnBuiltFn = onbuilt

        return inst
    end

	--we don't need to add shadowlumber, etc, as dependencies because they all go to shadowwaxwell
    return Prefab(prefab.."_builder", fn, nil)
end

--------------------------------------------------------------------------

return MakeMinion("shadowwaxwell"),
    MakeBuilder("shadowlumber", "axe"),
    MakeBuilder("shadowminer", "pickaxe"),
    MakeBuilder("shadowdigger", "shovel"),
    MakeBuilder("shadowtorchbearer", "torch"),
    MakeBuilder("shadowporter", "trap"),
    MakeBuilder("shadowduelist", "spear")