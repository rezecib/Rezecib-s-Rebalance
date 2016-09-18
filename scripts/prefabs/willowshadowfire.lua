local function heatfn()
	return 50
end

local function Ignite(inst)
    inst.components.burnable:Ignite(true)
	inst.components.shadowburner.burn_remaining = math.min(TUNING.WILLOW_SHADOWFIRE_BURN_TIME, inst.components.shadowburner.burn_remaining + 0.1)
	inst.components.shadowburner.damage_remaining = math.min(TUNING.WILLOW_SHADOWFIRE_MAX_DAMAGE, inst.components.shadowburner.damage_remaining + 0.1)
	for k,v in pairs(inst.children) do
		k.AnimState:SetMultColour(0,0,0,.5)
		k.Light:Enable(false)
		k.components.heater.heatfn = heatfn
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeLargeBurnable(inst)

    --Remove the default handlers that toggle persists flag
    inst.components.burnable:SetOnIgniteFn(nil)
	inst.components.burnable:SetBurnTime(nil) --don't stop burning, let shadowburner handle that
	inst.components.burnable:SetOnBurntFn(nil) --don't drop ash
    inst.components.burnable:SetOnExtinguishFn(Ignite)
	inst:AddComponent("shadowburner")
	Ignite(inst)

    return inst
end

return Prefab("willowshadowfire", fn)
