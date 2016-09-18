local AggroToggleable = Class(function(self, inst)
    self.inst = inst
	self.inst:AddTag("aggro_active")
	--Override these functions to make them check for the tag first
	if not self.inst.components.combat then return end
	local _CanTarget = self.inst.components.combat.CanTarget
	self._CanTarget = _CanTarget
	self.inst.components.combat.CanTarget = function(self, ...)
		if self.inst:HasTag("aggro_active") then
			return _CanTarget(self, ...)
		else
			return false
		end
	end
	local _SetTarget = self.inst.components.combat.SetTarget
	self._SetTarget = _SetTarget
	self.inst.components.combat.SetTarget = function(...)
		if self.inst:HasTag("aggro_active") then
			return _SetTarget(...)
		else
			return false
		end
	end
	if self.inst.components.aura then
		local _auratestfn = self.inst.components.aura.auratestfn
		self._auratestfn = _auratestfn
		self.inst.components.aura.auratestfn = function(inst, ...)
			if self.inst:HasTag("aggro_active") then
				return _auratestfn(inst, ...)
			else
				return false
			end
		end
	end
end,
nil,
{
})

function AggroToggleable:Toggle()
	if self.inst:HasTag("aggro_active") then
		self.inst:RemoveTag("aggro_active")
	else
		self.inst:AddTag("aggro_active")
	end
end

function AggroToggleable:OnSave()
	return { active = self.inst:HasTag("aggro_active") }
end

function AggroToggleable:OnLoad(data)
	if data.active == false then
		self.inst:RemoveTag("aggro_active")
	end
end

--Restore the original functions if the component gets removed
function AggroToggleable:OnRemoveFromEntity()
	if self.inst.components.combat then
		if self._CanTarget then
			self.inst.components.combat.CanTarget = self._CanTarget
		end
		if self._SetTarget then
			self.inst.components.combat.SetTarget = self._SetTarget
		end
	end
	if self.inst.components.aura and self._auratestfn then
		self.inst.components.aura.auratestfn = self._auratestfn
	end
end

return AggroToggleable