--[[
Dependencies:
scripts/tools/upvaluehacker
]]

-- Not needed, it's imported from below this in the modmain
-- if not GLOBAL.TheNet:GetIsServer() then return end

local avg_duration = GLOBAL.TUNING.TOTAL_DAY_TIME*0.75
local threshold = 0.5
local k = (1/avg_duration)*math.log(threshold)

AddPrefabPostInit('wx78', function(inst)
	if inst.components.playerlightningtarget then --maybe a mod removed this
		local _onstrikefn = inst.components.playerlightningtarget.onstrikefn
		inst.components.playerlightningtarget.onstrikefn = function(inst, ...)
			local charge_time = inst.charge_time
			_onstrikefn(inst, ...) --let them do the rest of the effects
			if charge_time == inst.charge_time then --they didn't screw with the charge time, we can just exit
				return --this is because wx is either dead or insulated
			end
			if charge_time ~= 0 then --wx had some charge already
				--convert charge time back to the game's linear decay time
				charge_time = avg_duration*(math.exp(k*(0.25*avg_duration - inst.charge_time)) - .75)
			end
			--Add in the old linear amount
			charge_time = charge_time + GLOBAL.TUNING.TOTAL_DAY_TIME * (.5 + .5 * math.random())
			--convert charge time to our exponential decay time
			inst.charge_time = 0.25*avg_duration - math.log(charge_time/avg_duration + .75)/k
		end
	end
end)

local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
AddPrefabPostInit("world", function(inst)
	local applyupgrades = UpvalueHacker.GetUpvalue(GLOBAL.Prefabs.wx78.fn, "master_postinit", "ondeath", "applyupgrades")
	local function ondeath(inst)
		if inst.level > 0 then
			local dropgears = inst.level - 1
			if dropgears > 0 then
				for i = 1, dropgears do
					local gear = GLOBAL.SpawnPrefab("gears")
					if gear ~= nil then
						local x, y, z = inst.Transform:GetWorldPosition()
						if gear.Physics ~= nil then
							local speed = 2 + math.random()
							local angle = math.random() * 2 * GLOBAL.PI
							gear.Transform:SetPosition(x, y + 1, z)
							gear.Physics:SetVel(speed * math.cos(angle), speed * 3, speed * math.sin(angle))
						else
							gear.Transform:SetPosition(x, y, z)
						end
						if gear.components.propagator ~= nil then
							gear.components.propagator:Delay(5)
						end
					end
				end
			end
			inst.level = 0
			applyupgrades(inst)
		end
	end
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.wx78.fn, ondeath, "master_postinit", "ondeath")
end)