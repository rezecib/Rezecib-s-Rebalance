local Shadowburner = Class(function(self, inst)
    self.inst = inst

    self.dps = TUNING.WILLOW_SHADOWFIRE_DPS
	self.damage_remaining = TUNING.WILLOW_SHADOWFIRE_MAX_DAMAGE
	self.burn_remaining = TUNING.WILLOW_SHADOWFIRE_BURN_TIME
    
    self.damagerange = 3

	self.notags = { "INLIMBO", "pyromaniac" }
	if not TheNet:GetPVPEnabled() then
		table.insert(self.notags, "player")
	end
	
    self:StartUpdating()
end)

function Shadowburner:StopUpdating()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

local function _OnUpdate(inst, self, dt)
    self:OnUpdate(dt)
end

function Shadowburner:StartUpdating()
    if self.task == nil then
        local dt = .5
        self.task = self.inst:DoPeriodicTask(dt, _OnUpdate, dt + math.random() * .67, self, dt)
    end
end

function Shadowburner:OnUpdate(dt)
	local pos = self.inst:GetPosition()
	local dmg_range = TheWorld.state.isspring and self.damagerange * TUNING.SPRING_FIRE_RANGE_MOD or self.damagerange
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, dmg_range, nil, self.notags)
	if #ents > 0 then

		for i, v in ipairs(ents) do
			if v:IsValid() and v.components.propagator ~= nil and
				v.components.health ~= nil and
				v.components.health.vulnerabletoheatdamage then
				--V2C: Confirmed that distance scaling was intentionally removed as a design decision
				--local percent_damage = math.min(.5, 1 - math.min(1, dsq / dmg_range_sq))
				local damage = self.dps * dt
				self.damage_remaining = self.damage_remaining - damage
				v.components.health:DoFireDamage(damage)
				if self.damage_remaining <= 0 then
					self:Extinguish()
				end
			end
		end
	end
	self.burn_remaining = self.burn_remaining - dt
	if self.burn_remaining <= 0 then return self:Extinguish() end
end

function Shadowburner:Extinguish()
	self.inst.components.burnable:SetOnExtinguishFn(self.inst.Remove)
	self.inst.components.burnable:Extinguish()
end

return Shadowburner
