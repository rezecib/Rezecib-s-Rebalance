local assets =
{
    Asset("ANIM", "anim/shadowlighter.zip"),
    Asset("ANIM", "anim/swap_shadowlighter.zip"),
    --Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "shadowlighterfire",
}

local fuel_rate_multiplier = 1/5

local function onequipfueldelta(inst)
    if inst.components.fueled.currentfuel < inst.components.fueled.maxfuel then
        inst.components.fueled:DoDelta(-inst.components.fueled.maxfuel*.01*fuel_rate_multiplier)
    end
end

local function onequip(inst, owner)
    --owner.components.combat.damage = TUNING.PICK_DAMAGE 
    owner.AnimState:OverrideSymbol("swap_object", "swap_shadowlighter", "swap_shadowlighter")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 
    inst.SoundEmitter:PlaySound("dontstarve/wilson/lighter_LP", "torch")

	if owner:HasTag("pyromaniac") then --this lighter only works for Willow
		inst.components.burnable:Ignite()
		inst.SoundEmitter:PlaySound("dontstarve/wilson/lighter_on")
		inst.SoundEmitter:SetParameter("torch", "intensity", 1)

		if inst.fire == nil then
			inst.fire = SpawnPrefab("shadowlighterfire")
			--inst.fire.Transform:SetScale(.125, .125, .125)
			local follower = inst.fire.entity:AddFollower()
			follower:FollowSymbol(owner.GUID, "swap_object", 56, -40, 0)
		end

		inst:DoTaskInTime(0, onequipfueldelta)
	end
end

local function onunequip(inst,owner)
    if inst.fire ~= nil then
        inst.fire:Remove()
        inst.fire = nil
    end

    inst.components.burnable:Extinguish()
    owner.components.combat.damage = owner.components.combat.defaultdamage 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal")
    inst.SoundEmitter:KillSound("torch")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/lighter_off")        
end

local function onpocket(inst, owner)
    inst.components.burnable:Extinguish()
end

local function onattack(weapon, attacker, target)
    if target ~= nil and target.components.burnable ~= nil and math.random() < TUNING.LIGHTER_ATTACK_IGNITE_PERCENT * target.components.burnable.flammability then
        target.components.burnable:Ignite(nil, attacker)
    end
end

local function onupdatefueled(inst)
    if TheWorld.state.israining then
        inst.components.fueled.rate = fuel_rate_multiplier + TUNING.LIGHTER_RAIN_RATE * TheWorld.state.precipitationrate
    else
        inst.components.fueled.rate = fuel_rate_multiplier
    end
end

local function oncook(inst, product, chef)
    local fuel_delta = 0.01
    if not chef:HasTag("expertchef") then
        --burn
        fuel_delta = 0.05
        if chef.components.health ~= nil then
            chef.components.health:DoFireDamage(5, inst, true)
            chef:PushEvent("burnt")
        end
    end
    inst.components.fueled:DoDelta(-inst.components.fueled.maxfuel * fuel_delta)
end

local function OnHaunt(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_RARE then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 5, { "canlight" }, { "fire", "burnt", "INLIMBO" })
        local didburn = false
        --#HAUNTFIX
        --for i, v in ipairs(ents) do
            --if v:IsValid() and not v:IsInLimbo() and v.components.burnable ~= nil then
                --v.components.burnable:Ignite()
                --didburn = true
            --end
        --end
        if didburn then
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
    end
    return false
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("shadowlighter")
    inst.AnimState:SetBuild("shadowlighter")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("shadowlighter.png")

    inst:AddTag("dangerouscooker")

    --lighter (from lighter component) added to pristine state for optimization
    inst:AddTag("lighter")

    --cooker (from cooker component) added to pristine state for optimization
    inst:AddTag("cooker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.LIGHTER_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    -----------------------------------
    inst:AddComponent("lighter")
    -----------------------------------
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/shadowlighter.xml"
    -----------------------------------
    inst:AddComponent("cooker")
    inst.components.cooker.oncookfn = oncook
    -----------------------------------

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnPocket(onpocket)
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -----------------------------------

    inst:AddComponent("inspectable")

    -----------------------------------

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable.fxprefab = nil
    --inst.components.burnable:AddFXOffset(Vector3(0, 1.5, -.01))

    inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
	inst.components.fueled.accepting = true
    inst.components.fueled:SetUpdateFn(onupdatefueled)
	
    inst.components.fueled:SetSectionCallback(
        function(section)
            if section == 0 then
                --when we burn out
                if inst.components.burnable ~= nil then
                    inst.components.burnable:Extinguish()
                end
                local equippable = inst.components.equippable
                if equippable ~= nil and equippable:IsEquipped() then
                    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
                    if owner ~= nil then
                        local data =
                        {
                            prefab = inst.prefab,
                            equipslot = equippable.equipslot,
                        }
                        inst:Remove()
                        owner:PushEvent("torchranout", data)
                        return
                    end
                end
                inst:Remove()
            end
        end)

    inst.components.fueled:InitializeFuelLevel(TUNING.LIGHTER_FUEL)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, OnHaunt, true, false, true)

    return inst
end

return Prefab("shadowlighter", fn, assets, prefabs)
