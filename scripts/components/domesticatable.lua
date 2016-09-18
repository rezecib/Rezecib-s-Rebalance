local easing = require("easing")

local DECAY_TASK_PERIOD = 10
-- TODO: Make these configurable from the prefab
local OBEDIENCE_DECAY_RATE = -1/(TUNING.TOTAL_DAY_TIME * 2)
local FEEDBACK_DECAY_RATE = -1/(TUNING.TOTAL_DAY_TIME * 45)

local Domesticatable = Class(function(self, inst)
    self.inst = inst

    -- I feel like it would be much cleaner to break domestication and obedience into two components, but they
    -- use a lot of the same hooks so I'm keeping them together for now.
    self.domesticated = false
	
	self.collar_owner = nil
	self.near_death = false

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("domesticatable")

    self.domestication = {}
	self.max_domesticator = nil
	self.num_domesticators = 0
    self.domestication_latch = false
    self.lastdomesticationgain = 0
	self.recent_feeders = {}
	self.num_recent_feeders = 0
    self.domestication_triggerfn = nil
    self.inst:ListenForEvent("oneat", function(inst, data) self:OnEat(inst, data) end)

    self.obedience = 0
    self.minobedience = 0
    self.maxobedience = 1

    self.domesticationdecaypaused = false

    self.tendencies = {}

    self.decaytask = nil
end
)

local function NearDeathDismount(oldrider)
	oldrider:RemoveEventCallback("dismounted", oldrider.oldmount.NearDeathDismount)
	BrainManager:Hibernate(oldrider.oldmount)
	oldrider.oldmount.sg:GoToState("near_death_pre")
	oldrider.oldmount.NearDeathDismount = nil
	oldrider.oldmount.olderider = nil
	oldrider.oldmount = nil
end

local function HealthRedirect(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	if ignore_absorb then return false end --allow Kill to still work
	if inst.components.domesticatable.near_death then return true end
	if inst.components.health.currenthealth + amount <= 0 then
		inst.components.domesticatable.near_death = GetTime() + TUNING.TOTAL_DAY_TIME
		inst._neardeathtask = inst:DoTaskInTime(TUNING.TOTAL_DAY_TIME, function() inst.components.health:SetPercent(0) end)
		inst.NearDeathDismount = NearDeathDismount
		if inst.components.rideable.rider then
			inst.oldrider = inst.components.rideable.rider
			inst.oldrider.oldmount = inst
			inst.oldrider:ListenForEvent("dismounted", NearDeathDismount)
			inst.components.rideable:Buck(true)
		else
			BrainManager:Hibernate(inst)
			inst:DoTaskInTime(FRAMES*5, function() inst.sg:GoToState("near_death_pre") end)
		end
		return true
	end
end

function Domesticatable:OnCollared(doer)
	if doer ~= nil then
		self.collar_owner = doer.userid
		self.inst.components.writeable:BeginWriting(doer)
	end
	self.inst.components.health.redirect = HealthRedirect
end

function Domesticatable:IsCollarOwner(dude)
	if dude and dude.userid then
		return dude.userid == self.collar_owner
	end
end

function Domesticatable:OnEat(inst, data)
	--eliminates the case where overfeeding shouldn't actually give it more domestication time
	local hunger_delta = self.inst.components.hunger.current - (self.inst._pre_eat_hunger or 0)
	if data.feeder ~= nil then
		if not self.recent_feeders[data.feeder.userid] then
			self.num_recent_feeders = self.num_recent_feeders + 1
		end
		--for the duration of digesting this food, this feeder will be credited
		self.recent_feeders[data.feeder.userid] = (self.recent_feeders[data.feeder.userid] or 0) 
			+ hunger_delta/TUNING.BEEFALO_HUNGER_RATE
	end
end

function Domesticatable:SetDomesticationTrigger(fn)
    self.domestication_triggerfn = fn
end

function Domesticatable:GetObedience()
    return self.obedience
end

function Domesticatable:GetMaxDomestication()
	local max_domestication = self.cached_domestication or 0
	local max_domesticator = nil
	for k,v in pairs(self.domestication) do
		if v > max_domestication then
			max_domestication = v
			max_domesticator = k
		end
	end
	return max_domestication, max_domesticator
end

function Domesticatable:GetDomestication(userid)
	--this gets called by beefalobrain to see if it has anything
    return userid and (self.domestication[userid] or 0) or self:GetMaxDomestication()
end

function Domesticatable:Validate()
    if self.obedience <= self.minobedience
        and self.inst.components.hunger:GetPercent() <= 0
        and self.num_domesticators == 0 then
        self:CancelTask()
        return false
    end

    return true
end

function Domesticatable:CheckForChanges()
	local max_domestication, max_domesticator = self:GetMaxDomestication()
	if max_domesticator ~= self.max_domesticator then
		--teeeechnically this can cause a failure case if someone feeds the beefalo, then leaves
		-- THEN becomes the max_domesticator (so we can't get their name because they left)
		-- if they then come back and continue being the max domesticator, the name will never update
		-- ...but I think that's rare enough and it won't crash or anything that I'll just leave it
		-- because really fixing it would require something fancy like caching player names
		self.max_domesticator = max_domesticator
		local client = max_domesticator and TheNet:GetClientTableForUser(max_domesticator)
		self.inst.owner_name = client and client.name.."'s " or self.inst.owner_name
		self.inst:UpdateName()
	end
    if not self.domesticated and max_domestication >= 1.0 then
        self.domestication_latch = true
		-- this really shouldn't be necessary because DeltaDomestication clamps it
		-- for userid,domestication in pairs(self.domestication) do
			-- self.domestication[userid] = math.min(1.0, domestication)
		-- end
    elseif max_domestication < 0.95 then
        self.domestication_latch = false
    end

    if self.inst.components.hunger:GetPercent() <= 0 and max_domestication <= 0 then
        self.tendencies = {}
		self.inst.owner_name = ""
		self.inst.tendency_name = ""
        self.inst:PushEvent("goneferal", {domesticated = self.domesticated})
        if self.domesticated then
            self:SetDomesticated(false)
        end
    end
end

function Domesticatable:BecomeDomesticated()
    self.domestication_latch = false
    self:SetDomesticated(true)
    self.inst:PushEvent("domesticated", {tendencies=self.tendencies})
end

local function CalculateLoss(currenttime, lastgaintime)
    -- you don't lose full domestication right away, only after ignoring the critter for a while
    local delta = currenttime-lastgaintime
    local ratio = math.min(delta/(TUNING.BEEFALO_DOMESTICATION_MAX_LOSS_DAYS*TUNING.TOTAL_DAY_TIME), 1.0)
    return TUNING.BEEFALO_DOMESTICATION_LOSE_DOMESTICATION * ratio
end

local function UpdateDomestication(inst)
    local self = inst.components.domesticatable
	if not self.domesticationdecaypaused then
		for k,v in pairs(self.tendencies) do
			self.tendencies[k] = math.max(v + FEEDBACK_DECAY_RATE * DECAY_TASK_PERIOD, 0)
		end
	end

    self:DeltaObedience(OBEDIENCE_DECAY_RATE * DECAY_TASK_PERIOD)

	local players, had_players = self:domestication_triggerfn(inst)
	if had_players then
        self.lastdomesticationgain = GetTime()
	end
	for userid,_ in pairs(players) do
		self:DeltaDomestication(TUNING.BEEFALO_DOMESTICATION_GAIN_DOMESTICATION * DECAY_TASK_PERIOD, userid)
	end
	--Something that's not obvious: if it's not starving, then it will have at least one recent feeder
	-- having a recent feeder means had_players will be true,
	-- which means self.lastdomesticationgain == GetTime(),
	-- which in turn means no loss on this tick
	if not self.domesticationdecaypaused then
		for userid,_ in pairs(self.domestication) do
			if not players[userid] then
				self:DeltaDomestication(CalculateLoss(GetTime(), self.lastdomesticationgain) * DECAY_TASK_PERIOD, userid)
			end
		end
	end
	--Ensures that whoever had the most time in it as of the last feeding will keep getting credited
	-- after their time (so that there isn't domestication loss while it's not starving)
	local can_remove = self.num_recent_feeders > 1 or self.inst.components.hunger:GetPercent() <= 0
	for userid,remaining in pairs(self.recent_feeders) do
		self.recent_feeders[userid] = remaining - DECAY_TASK_PERIOD
		if can_remove and self.recent_feeders[userid] <= 0 then
			self.recent_feeders[userid] = nil
			self.num_recent_feeders = self.num_recent_feeders - 1
		end
	end

    self:CheckForChanges()
    self:Validate()
end

function Domesticatable:DeltaObedience(delta)
    local old = self.obedience
    self.obedience = math.max(math.min(self.obedience + delta, self.maxobedience), self.minobedience)
    if old ~= self.obedience then
        self.inst:PushEvent("obediencedelta", {old=old, new=self.obedience})
    end
    self:CheckAndStartTask()
end

function Domesticatable:DeltaDomestication(delta, userid)
	if not userid then
		-- The two places this gets called normally:
		-- beefalo.components.eater.oneatfn, beefalo "attack" listener
		-- We can replace the first one with an "oneat" listener that does the right thing
		-- but the "attack" listener cannot be unhooked neatly, so we'll just ignore it
		-- (we also provide another listener to direct it to the correct character)
		return
	end
	if self.cached_domestication and delta > 0 then
		--if we loaded from a save without the mod, apply the base game domestication
		-- to the first player to increase it with the mod
		self.domestication[userid] = self.cached_domestication
		self.cached_domestication = nil
	end
    local old = self.domestication[userid] or 0
	local new = math.max(math.min(old + delta, 1), 0)
	if not self.domestication[userid] then
		self.num_domesticators = self.num_domesticators + 1
	end
    self.domestication[userid] = new
	if self.domestication[userid] == 0 then
		self.num_domesticators = self.num_domesticators - 1
		self.domestication[userid] = nil
	end

    if old ~= self.domestication[userid] then
        self.inst:PushEvent("domesticationdelta", {old=old, new=self.domestication[userid], userid=userid})
        self:CheckAndStartTask()
    end
end

function Domesticatable:DeltaTendency(tendency, delta)
    if self.tendencies[tendency] == nil then
        self.tendencies[tendency] = delta
    else
        self.tendencies[tendency] = self.tendencies[tendency] + delta
    end
end

function Domesticatable:PauseDomesticationDecay(pause)
    self.domesticationdecaypaused = pause
end

function Domesticatable:TryBecomeDomesticated()
    if self.domestication_latch then
        self:BecomeDomesticated()
    end
end

function Domesticatable:CancelTask()
    if self.decaytask ~= nil then
        self.decaytask:Cancel()
        self.decaytask = nil
    end
end

function Domesticatable:CheckAndStartTask()
    if not self:Validate() then
        return
    end
    if self.decaytask ~= nil then
        return
    end
    self.decaytask = self.inst:DoPeriodicTask(DECAY_TASK_PERIOD, UpdateDomestication, 0)
end

function Domesticatable:SetDomesticated(domesticated)
    self.domesticated = domesticated
	if not domesticated then
		self.collar_owner = nil
		self.inst.components.writeable:SetText(nil) --this adds the "writeable" tag
		self.inst:RemoveTag("writeable")
	end
    self:Validate()
end

function Domesticatable:IsDomesticated()
    return self.domesticated
end

function Domesticatable:SetMinObedience(min)
    self.minobedience = min
    if self.obedience < min then
        self:DeltaObedience(min - self.obedience)
    end
    self:CheckAndStartTask()
end

function Domesticatable:OnSave()
    return {
		owner_name = self.inst.owner_name,
        domestication = self:GetMaxDomestication(),
		domestication_per_player = self.domestication,
		collar_owner = self.collar_owner,
		near_death = self.near_death and self.near_death - GetTime(),
		recent_feeders = self.recent_feeders,
        tendencies = self.tendencies,
        domestication_latch = self.domestication_latch,
        domesticated = self.domesticated,
        obedience = self.obedience,
        minobedience = self.minobedience,
        lastdomesticationgaindelta = GetTime() - self.lastdomesticationgain,
        --V2C: domesticatable MUST load b4 rideable, and we
        --     aren't using the usual OnLoadPostPass method
        --     so... we did this! lol...
        rideable = self.inst.components.rideable ~= nil and self.inst.components.rideable:OnSaveDomesticatable() or nil,
    }
end

function Domesticatable:OnLoad(data)
    if data ~= nil then
		if type(data.domestication) == "table" then --need for backwards compatibility with myself
			self.domestication = data.domestication
		elseif data.domestication_per_player then --the last OnSave was with this mod
			self.domestication = data.domestication_per_player
		else --store to apply to the first player to interact
			self.cached_domestication = data.domestication
		end
        self.domestication = type(data.domestication) == "table" and data.domestication or self.domestication
		for k,v in pairs(self.domestication) do
			self.num_domesticators = self.num_domesticators + 1
		end
		if data.collar_owner then self:OnCollared() end
		self.collar_owner = data.collar_owner
		if data.near_death then	
			self.inst._neardeathtask = self.inst:DoTaskInTime(data.near_death, function(inst) inst.components.health:SetPercent(0) end)
			self.near_death = data.near_death + GetTime()
			BrainManager:Hibernate(self.inst)
			self.inst.sg:GoToState("near_death")
		end
		self.inst.owner_name = data.owner_name or ""
		self.recent_feeders = type(data.recent_feeders) == "table" and data.recent_feeders or self.recent_feeders
		for k,v in pairs(self.recent_feeders) do
			self.num_recent_feeders = self.num_recent_feeders + 1
		end
        self.tendencies = data.tendencies or self.tendencies
        self.domestication_latch = data.domestication_latch or false
        self:SetDomesticated(data.domesticated or false)
        self.obedience = 0
        self.lastdomesticationgain = GetTime() - (data.lastdomesticationgaindelta or 0)
        self:DeltaObedience(data.obedience or 0)
        self:SetMinObedience(data.minobedience or 0)
        --V2C: see above comment in OnSave
        if self.inst.components.rideable ~= nil then
            self.inst.components.rideable:OnLoadDomesticatable(data.rideable)
        end
    end
    self:CheckAndStartTask()
end

function Domesticatable:GetDebugString()
    local s = string.format("%s%s %.3f%% %s obedience: %.2f/%.3f/%.2f ",
        self.domesticated and "DOMO" or "NORMAL",
        self.domesticationdecaypaused and "(nodecay)" or "",
        self:GetMaxDomestication() * 100, self.decaytask ~= nil and (GetTime() % 2 < 1 and " ." or ". ") or "..",
        self.minobedience, self.obedience, self.maxobedience
        )
    for k,v in pairs(self.tendencies) do
        s = s .. string.format(" %s:%.2f", k, v)
    end
    s = s .. string.format(" latch: %s", self.domestication_latch and "true" or "false")
    return s
end

return Domesticatable
