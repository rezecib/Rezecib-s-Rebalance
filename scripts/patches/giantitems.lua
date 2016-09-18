--[[
Dependencies:
	tools/upvaluehacker
]]

local require = GLOBAL.require
local TheNet = GLOBAL.TheNet
local UpvalueHacker = require("tools/upvaluehacker")

local containers = require("containers")
local _containers_widgetsetup = containers.widgetsetup
function containers.widgetsetup(container, prefab, data, ...)
	prefab = prefab or container.inst.prefab
	if prefab == "icepack" then
		--check how many slots widgetsetup would've made for it
		local test_container = {SetNumSlots = function() end}
		_containers_widgetsetup(test_container, prefab, data, ...)
		if #test_container.widget.slotpos == 6 then --it was default size, use backpack instead
			prefab = "backpack"
		end
	end
	return _containers_widgetsetup(container, prefab, data, ...)
end

GLOBAL.AllRecipes.icepack.ingredients[2].amount = 1

if not GLOBAL.TheNet:GetIsServer() then return end

AddPrefabPostInit("icepack", function(inst)
	inst:RemoveComponent("propagator")
	inst:RemoveComponent("burnable")
end)

local WORK_ACTIONS =
{
    CHOP = 15,
    DIG = 1,
    HAMMER = 1,
    MINE = 6,
}
local TARGET_TAGS = { "_combat" }
for k, v in pairs(WORK_ACTIONS) do
    table.insert(TARGET_TAGS, k.."_workable")
end
local function destroystuff(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = GLOBAL.TheSim:FindEntities(x, y, z, 3, nil, { "INLIMBO" }, TARGET_TAGS)
    for i, v in ipairs(ents) do
        --stuff might become invalid as we work or damage during iteration
        if v ~= inst.WINDSTAFF_CASTER and v:IsValid() then
            if v.components.health ~= nil and
                not v.components.health:IsDead() and
                v.components.combat ~= nil and
                v.components.combat:CanBeAttacked() and
                (TheNet:GetPVPEnabled() or not (inst.WINDSTAFF_CASTER_ISPLAYER and v:HasTag("player"))) then
                local damage =
                    inst.WINDSTAFF_CASTER_ISPLAYER and
                    v:HasTag("player") and
                    TUNING.TORNADO_DAMAGE * TUNING.PVP_DAMAGE_MOD or
                    TUNING.TORNADO_DAMAGE
                v.components.combat:GetAttacked(inst, damage, nil, "wind")
                if inst.WINDSTAFF_CASTER ~= nil and inst.WINDSTAFF_CASTER:IsValid() then
                    v.components.combat:SuggestTarget(inst.WINDSTAFF_CASTER)
                end
            elseif v.components.workable ~= nil and
                v.components.workable:CanBeWorked() and
                v.components.workable:GetWorkAction() and
                WORK_ACTIONS[v.components.workable:GetWorkAction().id] then
                GLOBAL.SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
                v.components.workable:WorkedBy(inst, WORK_ACTIONS[v.components.workable:GetWorkAction().id])
                --v.components.workable:Destroy(inst)
            end
        end
    end
end
AddStategraphPostInit("tornado", function(sg)
	UpvalueHacker.SetUpvalue(sg.states.idle.onenter, destroystuff, "destroystuff")
end)