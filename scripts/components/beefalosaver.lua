local BeefaloSaver = Class(function(self, inst)
    self.inst = inst
	self.wasriding = false
end,
nil,
{
})

function BeefaloSaver:SaveBeefalo()
	self.wasriding = self.inst.components.rider:IsRiding()
	local beefalo = nil
	if self.wasriding then
		beefalo = self.inst.components.rider:GetMount()
	else
		--look around them for beefalo
		local x,y,z = self.inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 20, {"beefalo"})
		--pick the one that has the largest amount of domestication by this player
		local max_domestication = 0
		for _,ent in pairs(ents) do
			--reject beefalo being ridden by someone else, and 
			--only accept beefalo for which this player is the leading domesticator
			if ent.components.domesticatable and ent.components.rideable and not ent.components.rideable:IsBeingRidden()
			and ent.components.domesticatable:GetDomestication(self.inst.userid) == ent.components.domesticatable:GetMaxDomestication()
			and ent.components.domesticatable:GetDomestication(self.inst.userid) > max_domestication then
				max_domestication = ent.components.domesticatable:GetDomestication(self.inst.userid)
				beefalo = ent
			end
		end	
	end
	if beefalo then
		self.saved_beefalo = beefalo
		self.beefalo_save = beefalo:GetSaveRecord()
		self.saved_beefalo.persists = false
		if not self.wasriding then
			local fx = SpawnPrefab("spawn_fx_medium")
			if fx ~= nil then
				fx.Transform:SetPosition(beefalo.Transform:GetWorldPosition())
			end
		end
		beefalo.components.colourtweener:StartTween({ 0, 0, 0, 1 }, 13 * FRAMES, beefalo.Remove)
	end
end

function BeefaloSaver:OnSave()
	return {beefalo = self.beefalo_save, wasriding = self.wasriding}
end

function BeefaloSaver:OnLoad(data)
	if data.beefalo then
		local beefalo = SpawnSaveRecord(data.beefalo)
		if self.inst.migrationpets ~= nil then
			table.insert(self.inst.migrationpets, beefalo)
		end
		if data.wasriding then
			self.inst:DoTaskInTime(0, function() self.inst.components.rider:Mount(beefalo, true) end)
		else
			self.inst:DoTaskInTime(0, function()
				local fx = SpawnPrefab("spawn_fx_medium")
				if fx ~= nil then
					fx.Transform:SetPosition(beefalo.Transform:GetWorldPosition())
				end
			end)
		end
	end
end

return BeefaloSaver