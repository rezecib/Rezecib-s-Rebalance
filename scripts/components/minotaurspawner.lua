local MinotaurSpawner = Class(function(self, inst)
    self.inst = inst
	self.days_to_spawn = 20
	self.locations = {}
	self.inst:WatchWorldState("nightmarephase", function(inst, phase) self:OnNightmarePhase(phase) end)
	self.inst:WatchWorldState("issummer", function(inst, issummer) self:OnSummerChanged(issummer) end)
end,
nil,
{
})

function MinotaurSpawner:FindMinotaur(x, z)
	return TheSim:FindEntities(x, 0, z, 64, {"minotaur"})[1]
end

function MinotaurSpawner:OnNightmarePhase(phase)
	if phase == "wild" then
		for _,loc in pairs(self.locations) do
			if not loc.has_minotaur and loc.last_death + self.days_to_spawn <= TheWorld.state.cycles then
				self:SpawnMinotaur(loc, true)
			end
		end
	end
end

function MinotaurSpawner:OnSummerChanged(issummer)
	for _,loc in pairs(self.locations) do
		if issummer and not loc.spawned_this_summer then
			--summer is started; make the minotaur flesh or spawn a flesh one
			local minotaur = nil
			if loc.has_minotaur then
				minotaur = self:FindMinotaur(loc.x, loc.z)
			end
			if minotaur then
				minotaur.components.infusable:Fill()
			else
				self:SpawnMinotaur(loc, false)
			end
			loc.spawned_this_summer = true
		elseif not issummer then
			--summer is over, clear the flag
			loc.spawned_this_summer = false
		end
	end
end

function MinotaurSpawner:SpawnMinotaur(loc, shadow)
	local minotaur = SpawnPrefab("minotaur")
	minotaur.Transform:SetPosition(loc.x, 0, loc.z)
	if shadow then minotaur.components.infusable:Empty() end
	local fx = SpawnPrefab("statue_transition_2")
	if fx ~= nil then
		fx.Transform:SetPosition(loc.x, 0, loc.z)
		fx.Transform:SetScale(2, 2, 2)
	end
	fx = SpawnPrefab("statue_transition")
	if fx ~= nil then
		fx.Transform:SetPosition(loc.x, 0, loc.z)
		fx.Transform:SetScale(1.5, 1.5, 1.5)
	end
	loc.has_minotaur = true
	minotaur:ListenForEvent("onremove", function() loc.has_minotaur = false end)
	minotaur:ListenForEvent("death", function() loc.last_death = TheWorld.state.cycles end)
end

function MinotaurSpawner:RegisterLocation(id, x, z)
	self.locations[id] = {	x = x,
							z = z,
							last_death = TheWorld.state.cycles,
							has_minotaur = self:FindMinotaur(x, z) ~= nil,
							spawned_this_summer = true}
end

function MinotaurSpawner:OnSave()
	local data = { locations = {} }
	for id,location in pairs(self.locations) do
		table.insert(data.locations, {	id = id,
										x = location.x,
										z = location.z,
										last_death = location.last_death,
										has_minotaur = location.has_minotaur,
										spawned_this_summer = location.spawned_this_summer	})
	end
	return data
end

function MinotaurSpawner:OnLoad(data)
	--We have to wait for TheWorld to load its topology, and then for the PostInit to register the locations
	self.inst:DoTaskInTime(1, function()
		if not data or not data.locations then return end
		for _,loc in pairs(data.locations) do
			if self.locations[loc.id] then
				self.locations[loc.id].last_death = loc.last_death
				self.locations[loc.id].spawned_this_summer = loc.spawned_this_summer
			end
		end
		self:OnSummerChanged(TheWorld.state.issummer)
	end)
end

return MinotaurSpawner