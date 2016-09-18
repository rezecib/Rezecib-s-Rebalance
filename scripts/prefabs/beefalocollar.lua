local assets =
{
    Asset("ANIM", "anim/beefalocollar.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("beefalocollar")
    inst.AnimState:SetBuild("beefalocollar")
    inst.AnimState:PlayAnimation("idle")
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------------------
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/beefalocollar.xml"
    -----------------------------------
    inst:AddComponent("inspectable")
    -----------------------------------
	inst:AddComponent("tradable")
	
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("beefalocollar", fn, assets, prefabs)
