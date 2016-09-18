local function onnuminfusions(self, num_infusions)
	if num_infusions < self.max_infusions or not self.has_key then
		self.inst:AddTag("infusable")
		self.oninfusefn(self.inst, (self.has_key and .5 or 0) + .5*num_infusions/self.max_infusions)
	else
		self.inst:RemoveTag("infusable")
		self.oninfusioncompletefn(self.inst)
	end
end

local Infusable = Class(function(self, inst)
    self.inst = inst
	self.oninfusefn = function(inst) return end
	self.oninfusioncompletefn = function(inst) return end
	self.key_infuser = "minotaurhorn"
	self.has_key = true
	self.max_infusions = 8
	self.num_infusions = self.max_infusions
end,
nil,
{
	num_infusions = onnuminfusions
})

function Infusable:Empty()
	self.has_key = false
	self.num_infusions = 0
end

function Infusable:Fill()
	self.has_key = true
	self.num_infusions = self.max_infusions
end

function Infusable:Infuse(item)
	if item.prefab == self.key_infuser then
		item.components.inventoryitem:RemoveFromOwner()
		self.has_key = true
		onnuminfusions(self, self.num_infusions)
		local fx = SpawnPrefab("statue_transition_2")
		if fx ~= nil then
			fx.Transform:SetPosition(self.inst:GetPosition():Get())
			fx.Transform:SetScale(2, 2, 2)
		end
		fx = SpawnPrefab("statue_transition")
		if fx ~= nil then
			fx.Transform:SetPosition(self.inst:GetPosition():Get())
			fx.Transform:SetScale(1.5, 1.5, 1.5)
		end
		return true
	elseif self.num_infusions < self.max_infusions then
		item.components.inventoryitem:RemoveFromOwner()
		self.num_infusions = self.num_infusions + 1
		local fx = SpawnPrefab("statue_transition_2")
		if fx ~= nil then
			fx.Transform:SetPosition(self.inst:GetPosition():Get())
			fx.Transform:SetScale(2, 2, 2)
		end
		fx = SpawnPrefab("statue_transition")
		if fx ~= nil then
			fx.Transform:SetPosition(self.inst:GetPosition():Get())
			fx.Transform:SetScale(1.5, 1.5, 1.5)
		end
		return true
	end
end

function Infusable:OnSave()
	return { num_infusions = self.num_infusions, has_key = self.has_key }
end

function Infusable:OnLoad(data)
	self.num_infusions = data.num_infusions or self.num_infusions
	self.has_key = data.has_key or false
end

function Infusable:OnRemoveFromEntity()
    self.inst:RemoveTag("infusable")
end

return Infusable