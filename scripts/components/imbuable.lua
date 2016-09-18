local Imbuable = Class(function(self, inst)
    self.inst = inst
	self.inst:AddTag("imbuable")
	self.inst:AddTag("imbue_active")
	self.imbue_items = {}
	self.onimbuefn = function(self, item) return true end
end,
nil,
{
})

function Imbuable:OnSave()
	local data = { active = self.inst:HasTag("imbue_active"), imbue_items = {} }-- self.imbue_items }
	for item,has in pairs(self.imbue_items) do
		table.insert(data.imbue_items, item)
	end
	return data
end

function Imbuable:OnLoad(data)
	for _,item in pairs(data.imbue_items) do
		self.imbue_items[item] = true
	end
	if not data.active then self.inst:RemoveTag("imbue_active") end
	self.inst:DoTaskInTime(0, function()
		for item,has in pairs(self.imbue_items) do
			self:Imbue(item)
		end
		if not data.active then self.inst:RemoveTag("imbue_active") end
	end)
end

function Imbuable:OnRemoveFromEntity()
    self.inst:RemoveTag("imbuable")
    self.inst:RemoveTag("imbue_active")
end

function Imbuable:ClearImbueItems(items)
	for _,item in pairs(items) do
		self.imbue_items[item] = nil
	end
end

function Imbuable:Imbue(item)
	local has_item = type(item) == "table"
	local prefab = has_item and item.prefab or item
	if self:onimbuefn(prefab) then
		--note: the onimbuefn is responsible for clearing these out with ClearImbueItems
		self.imbue_items[prefab] = true
		if has_item then item.components.inventoryitem:RemoveFromOwner():Remove() end
		return true
	end
end

function Imbuable:ToggleActive()
	if self.inst:HasTag("imbue_active") then
		self.inst:RemoveTag("imbue_active")
		self.inst.components.locomotor:Stop()
		self.inst.components.combat:DropTarget(true)
	else
		self.inst:AddTag("imbue_active")
	end
end

return Imbuable