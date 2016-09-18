--[[
Dependencies:
scripts/components/domesticatable
				   beefalosaver
		prefabs/beefalocollar
			  upvaluehacker
		widgets/beefalowidget
]]

local TheNet = GLOBAL.TheNet
local require = GLOBAL.require
local TUNING = GLOBAL.TUNING

local UpvalueHacker = require("tools/upvaluehacker")
local writeables = require("writeables")
local kinds = UpvalueHacker.GetUpvalue(writeables.makescreen, "kinds")
local beefalo_names = {
	"Fluffy McFlufferton",
	"Boof",
	"Bobby",
	"Scruffy",
	"Harry",
	"Beefchilles",
	"MEATSACK",
	"Floof",
	"Fuzzball",
	"Fluffball",
	"Nibbles",
	"Bloodhoof",
	"Sillyhorns",
	"Bicorn",
	"Salty",
	"Dusty",
	"Bubs",
	"Buck",
	"Beefalonius Maximus",
}
kinds.beefalo = {
    prompt = "What do you want to call your beefalo?",
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = GLOBAL.Vector3(6, -70, 0),

    cancelbtn = { text = "Cancel", cb = nil, control = GLOBAL.CONTROL_CANCEL },
    middlebtn = { text = "Random", cb = function(inst, doer, widget)
            widget:OverrideText( beefalo_names[math.random(#beefalo_names)] )
        end, control = GLOBAL.CONTROL_MENU_MISC_2 },
    acceptbtn = { text = "Name it!", cb = nil, control = GLOBAL.CONTROL_ACCEPT },
}

GLOBAL.STRINGS.NAMES.BEEFALOCOLLAR = "Beefalo Collar"
GLOBAL.STRINGS.RECIPE_DESC.BEEFALOCOLLAR = "If you love it, put a ring on it."
AddRecipe("beefalocollar",
		{Ingredient("silk", 8),
		 Ingredient("moonrocknugget", 2),
		 Ingredient("pigskin", 2)},
		GLOBAL.RECIPETABS.TOOLS,
		GLOBAL.TECH.SCIENCE_TWO,
		nil,
		nil,
		nil,
		nil,
		nil,
		"images/inventoryimages/beefalocollar.xml")

GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BEEFALOCOLLAR = "It may be smelly, but it will be mine."
GLOBAL.STRINGS.CHARACTERS.WX78.DESCRIBE.BEEFALOCOLLAR = "THE MEATBAG WILL BE MY SLAVE FOREVER"
GLOBAL.STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.BEEFALOCOLLAR = "A talisman to bind the beast's soul."
GLOBAL.STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.BEEFALOCOLLAR = "This puts name on hair-cow."
GLOBAL.STRINGS.CHARACTERS.WAXWELL.DESCRIBE.BEEFALOCOLLAR = "This won't make it any less stupid, but it will make it mine."
GLOBAL.STRINGS.CHARACTERS.WENDY.DESCRIBE.BEEFALOCOLLAR = "This will bind the beast to me, as Abigail's flower binds her."
GLOBAL.STRINGS.CHARACTERS.WEBBER.DESCRIBE.BEEFALOCOLLAR = "Does this mean we'll have it all to ourselves?"
GLOBAL.STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.BEEFALOCOLLAR = "This seems like more than a mere collar."
GLOBAL.STRINGS.CHARACTERS.WOODIE.DESCRIBE.BEEFALOCOLLAR = "A beefalo to call my own, eh?"
GLOBAL.STRINGS.CHARACTERS.WILLOW.DESCRIBE.BEEFALOCOLLAR = "This might keep its fire going longer."

GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BEEFALO.NEARDEATH = "It won't live much longer without help."
GLOBAL.STRINGS.CHARACTERS.WX78.DESCRIBE.BEEFALO.NEARDEATH = "THE MEATBAG IS GOING TO DIE. HAH."
GLOBAL.STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.BEEFALO.NEARDEATH = "The beast will be in Valhalla soon..."
GLOBAL.STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.BEEFALO.NEARDEATH = "Hair-cow is dead soon."
GLOBAL.STRINGS.CHARACTERS.WAXWELL.DESCRIBE.BEEFALO.NEARDEATH = "I almost feel sorry for the dying beast."
GLOBAL.STRINGS.CHARACTERS.WENDY.DESCRIBE.BEEFALO.NEARDEATH = "The beast is not long for this world."
GLOBAL.STRINGS.CHARACTERS.WEBBER.DESCRIBE.BEEFALO.NEARDEATH = "We think it needs medicine, soon."
GLOBAL.STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.BEEFALO.NEARDEATH = "It requires immediate medical attention."
GLOBAL.STRINGS.CHARACTERS.WOODIE.DESCRIBE.BEEFALO.NEARDEATH = "The beastie's life is almost a wrap."
GLOBAL.STRINGS.CHARACTERS.WILLOW.DESCRIBE.BEEFALO.NEARDEATH = "Its fire has almost burnt out!"


local ismastersim = TheNet:GetIsServer()

local function OnMounted(parent, data)
	if not data.target then return end
	parent.player_classified.mountwidgetvisible:set(true)
	parent:ListenForEvent("healthdelta", parent.player_classified._OnMountHealthDelta, data.target)
	parent:ListenForEvent("hungerdelta", parent.player_classified._OnMountHungerDelta, data.target)
	parent.player_classified.mountmaxhealth:set(data.target.components.health.maxhealth)
	parent.player_classified.mounthealth:set(data.target.components.health.currenthealth)
	parent.player_classified.mountmaxhunger:set(data.target.components.hunger.max)
end

local function OnDismounted(parent, data)
	parent.player_classified.mountwidgetvisible:set(false)
	parent:RemoveEventCallback("healthdelta", parent.player_classified._OnMountHealthDelta, data.target)
	parent:RemoveEventCallback("hungerdelta", parent.player_classified._OnMountHungerDelta, data.target)
end

local function MountWidgetVisibleDirty(inst)
	if inst.mountwidgetvisible:value() then
		inst._parent.HUD:OpenBeefalo()
	else
		inst._parent.HUD:CloseBeefalo()
	end
end

local function RegisterNetListeners(inst)
	inst._parent = inst._parent or inst.entity:GetParent()
	if ismastersim then
		inst:ListenForEvent("mounted", OnMounted, inst._parent)
		inst:ListenForEvent("dismounted", OnDismounted, inst._parent)
		--I don't think this occurs, but it shouldn't hurt
		if inst._parent.components.rider.mount then
			OnMounted(inst._parent, {target = inst._parent.components.rider.mount})
		end
	end
	if GLOBAL.ThePlayer and GLOBAL.ThePlayer.player_classified == inst then
		inst:ListenForEvent("mountwidgetvisibledirty", MountWidgetVisibleDirty)
		MountWidgetVisibleDirty(inst)
	end
end

AddPrefabPostInit("player_classified", function(inst)
	inst.mounthealth = GLOBAL.net_ushortint(inst.GUID, "mount.health", "mounthealthdirty")
	inst.mountmaxhealth = GLOBAL.net_ushortint(inst.GUID, "mount.maxhealth", "mountmaxhealthdirty")
	inst.mounthunger = GLOBAL.net_ushortint(inst.GUID, "mount.hunger", "mounthungerdirty")
	inst.mountmaxhunger = GLOBAL.net_ushortint(inst.GUID, "mount.maxhunger", "mountmaxhungerdirty")
	inst.mountwidgetvisible = GLOBAL.net_bool(inst.GUID, "mount.widgetvisible", "mountwidgetvisibledirty")
	
	--Set the most likely values for the pristine state
	inst.mounthealth:set(TUNING.BEEFALO_HEALTH)
	inst.mountmaxhealth:set(TUNING.BEEFALO_HEALTH)
	-- inst.mounthunger:set(TUNING.BEEFALO_HUNGER) --most likely is zero, lol
	inst.mountmaxhunger:set(TUNING.BEEFALO_HUNGER)
	inst.mountwidgetvisible:set(false)
	
	inst._OnMountHealthDelta = function(mount, data)
		inst.mounthealth:set(mount.components.health.currenthealth)
	end
	inst._OnMountHungerDelta = function(mount, data)
		inst.mounthunger:set(mount.components.hunger.current)
	end
	
	inst:DoTaskInTime(0, RegisterNetListeners)
end)

local BeefaloWidget = require("widgets/beefalowidget")
local PlayerHud = require("screens/playerhud")
function PlayerHud:OpenBeefalo()
	if not self.beefalowidget then
		self.controls.inv.beefalowidget = self.controls.inv.root:AddChild(BeefaloWidget(self.owner))
		self.beefalowidget = self.controls.inv.beefalowidget
		self.beefalowidget:SetScale(1)
		self.beefalowidget:MoveToBack()
		self.controls.inv:Rebuild()
	end
	
	self.beefalowidget:Open()
end
function PlayerHud:CloseBeefalo()
	if self.beefalowidget then
		self.beefalowidget:Close()
	end
end

local Inv = require("widgets/inventorybar")
local _Rebuild = Inv.Rebuild
function Inv:Rebuild(...)
	_Rebuild(self, ...)
	if self.owner.HUD.beefalowidget then
		self.owner.HUD.beefalowidget.bump_for_controller = self.controller_build 
													   and self.owner.replica.inventory:GetOverflowContainer() 
													   and self.owner.HUD.beefalowidget
		self.owner.HUD.beefalowidget:UpdatePosition()
	end
end

GLOBAL.ACTIONS.MIGRATE.mount_valid = true

if not ismastersim then return end

local Writeable = require("components/writeable")
Writeable.near_dist = 3
local _SetText = Writeable.SetText
function Writeable:SetText(text, ...)
	_SetText(self, text, ...)
	if self.onsettext then self:onsettext(text, ...) end
end
local _Write = Writeable.Write
function Writeable:Write(...)
	_Write(self, ...)
	self.inst.replica.writeable:SetWriter(nil)
end
local CanEntitySeeTarget = GLOBAL.CanEntitySeeTarget
function Writeable:OnUpdate(dt)
    if self.writer == nil then
        self.inst:StopUpdatingComponent(self)
    elseif (self.writer.components.rider ~= nil and
            self.writer.components.rider:IsRiding())
        or not (self.writer:IsNear(self.inst, self.near_dist) and
                CanEntitySeeTarget(self.writer, self.inst)) then
        self:EndWriting()
    end
end

local MaxHealer = require("components/maxhealer")
local _Heal = MaxHealer.Heal
function MaxHealer:Heal(target, ...)
	local ret = _Heal(self, target, ...)
	if target and target.sg and target.prefab == "beefalo" and target.components.domesticatable and target.components.domesticatable.near_death then
		target.components.health:SetPercent(.25)
		target._neardeathtask:Cancel()
		target.components.domesticatable.near_death = false
		target.sg:GoToState("wake")
		return true
	end
	return ret
end

--settled for making them faster on roads instead
-- TUNING.BEEFALO_RUN_SPEED.DEFAULT = 8
-- TUNING.BEEFALO_RUN_SPEED.RIDER = 10
-- TUNING.BEEFALO_RUN_SPEED.ORNERY = 8
-- TUNING.BEEFALO_RUN_SPEED.PUDGY = 7

--Default is 10, which results in about 9 days for full loss; we want to adjust this to 20
TUNING.BEEFALO_DOMESTICATION_MAX_LOSS_DAYS = 10*(20/9)
TUNING.BEEFALO_DOMESTICATION_SLEEP_DIST_SQ = 10*10
local function DomesticationTriggerFn(self, inst)
	local players = {}
	local had_gain = false
	--increase for players that have fed it recently
	if inst.components.hunger:GetPercent() > 0 then
		for k,v in pairs(self.recent_feeders) do
			players[k] = true
			had_gain = true
		end
	end
	--increase for the player riding it
	if inst.components.rideable:IsBeingRidden() then
		players[inst.components.rideable:GetRider().userid] = true
		had_gain = true
	end
	--increase for players nearby while sleeping
	if inst.components.sleeper:IsAsleep() then
		local x,y,z = inst:GetPosition():Get()
		for _,v in pairs(GLOBAL.AllPlayers) do
			if v:GetDistanceSqToPoint(x,y,z) < TUNING.BEEFALO_DOMESTICATION_SLEEP_DIST_SQ then
				players[v.userid] = true
				had_gain = true
			end
		end
	end
	return players, had_gain
end
local function OnBrushed(inst, doer, numprizes)
    if numprizes > 0 and inst.components.domesticatable ~= nil then
        inst.components.domesticatable:DeltaDomestication(TUNING.BEEFALO_DOMESTICATION_BRUSHED_DOMESTICATION, doer.userid)
        inst.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_BRUSHED_OBEDIENCE)
    end
end
local TENDENCY = GLOBAL.TENDENCY
local function OnAttacked(inst, data)
    if inst.components.rideable:IsBeingRidden() then
        if not inst.components.domesticatable:IsDomesticated() or not inst.tendency == TENDENCY.ORNERY then
            inst.components.domesticatable:DeltaDomestication(TUNING.BEEFALO_DOMESTICATION_ATTACKED_DOMESTICATION, inst.components.rideable.rider.userid)
            -- inst.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_ATTACKED_OBEDIENCE)
        end
        -- inst.components.domesticatable:DeltaTendency(TENDENCY.ORNERY, TUNING.BEEFALO_ORNERY_ATTACKED)
    else
        if data.attacker ~= nil and data.attacker:HasTag("player") then
            inst.components.domesticatable:DeltaDomestication(TUNING.BEEFALO_DOMESTICATION_ATTACKED_BY_PLAYER_DOMESTICATION, data.attacker.userid)
            -- inst.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_ATTACKED_BY_PLAYER_OBEDIENCE)
        end
        -- inst.components.combat:SetTarget(data.attacker)
        -- inst.components.combat:ShareTarget(data.attacker, 30, CanShareTarget, 5)
    end
end
local function OnEat(inst, data)
    local full = inst.components.hunger:GetPercent() >= 1
    if not full then
        inst.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_FEED_OBEDIENCE)

        inst.components.domesticatable:TryBecomeDomesticated()
    else
        inst.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_OVERFEED_OBEDIENCE)
		if data.feeder then --just in case. if the feeder has no userid, then this will be ignored anyway
			inst.components.domesticatable:DeltaDomestication(TUNING.BEEFALO_DOMESTICATION_OVERFEED_DOMESTICATION, data.feeder.userid)
		end
        inst.components.domesticatable:DeltaTendency(TENDENCY.PUDGY, TUNING.BEEFALO_PUDGY_OVERFEED)
    end
    inst:PushEvent("eat", { full = full, food = data.food })
    inst.components.knownlocations:RememberLocation("loiteranchor", inst:GetPosition())
end
local TENDENCY_NAMES = {
	[GLOBAL.TENDENCY.DEFAULT] = "Ordinary ",
	[GLOBAL.TENDENCY.ORNERY] = "Ornery ",
	[GLOBAL.TENDENCY.RIDER] = "Speedy ",
	[GLOBAL.TENDENCY.PUDGY] = "Pudgy ",
}
local function UpdateName(inst)
	local name = inst.components.writeable:GetText()
	name = name and inst.owner_name .. name or inst.owner_name .. inst.tendency_name .. GLOBAL.STRINGS.NAMES.BEEFALO
	inst.components.named:SetName(name)
end
AddPrefabPostInit("beefalo", function(inst)
	inst:AddComponent("named")
	inst.UpdateName = UpdateName
	inst:DoTaskInTime(0, inst.UpdateName)
	inst.owner_name = ""
	inst.tendency_name = ""
	local _SetTendency = inst.SetTendency
	function inst.SetTendency(inst, changedomestication, ...)
		_SetTendency(inst, changedomestication, ...)
		if changedomestication == "domestication" then
			inst.tendency_name = TENDENCY_NAMES[inst.tendency]
			inst:UpdateName()
		elseif changedomestication == "feral" then
			inst.tendency_name = ""
			inst:UpdateName()
		end
	end
    inst.components.domesticatable:SetDomesticationTrigger(DomesticationTriggerFn)
    inst.components.brushable:SetOnBrushed(OnBrushed)
	inst:AddComponent("colourtweener") --for the beefalo exit/leave with player animation
	inst.components.locomotor.fasteronroad = true
    inst:ListenForEvent("attacked", OnAttacked)
	inst.components.eater:SetOnEatFn() --clear the normal one, replace with our OnEat
    inst:ListenForEvent("oneat", OnEat)
	local _test = inst.components.trader.test
	inst.components.trader:SetAcceptTest(function(inst, item, giver, ...)
		local _, max_domesticator = inst.components.domesticatable:GetMaxDomestication()
		return _test(inst, item, giver, ...) or (item.prefab == "beefalocollar"
			and inst.components.domesticatable.domesticated and not inst.components.combat:HasTarget()
			and max_domesticator == giver.userid)
	end)
	local _onaccept = inst.components.trader.onaccept
	inst.components.trader.onaccept = function(inst, giver, item, ...)
		inst._pre_eat_hunger = inst.components.hunger.current --need to know the actual delta hunger from eating
		_onaccept(inst, giver, item, ...)
		if item.prefab == "beefalocollar" then
			item:DoTaskInTime(0, item.Remove)
			inst.components.domesticatable:OnCollared(giver)
		end
	end
	inst:AddComponent("writeable")
	inst.components.writeable.near_dist = 10
	inst:RemoveTag("writeable")
	inst.components.writeable.onsettext = function() inst:UpdateName() end
	inst.components.inspectable.getspecialdescription = nil --we don't want the writer to store it here
	local _GetStatus = inst.components.inspectable.getstatus
	function inst.components.inspectable.getstatus(inst)
		if inst.components.domesticatable and inst.components.domesticatable.near_death then
			return "NEARDEATH"
		else
			return _GetStatus(inst)
		end
	end
	inst:ListenForEvent("saddlechanged", function(inst, data)
		if inst.components.domesticatable and inst.components.rideable
		and inst.components.domesticatable.near_death then
			-- Prevent adding the saddle from making it rideable if it's near death
			inst:DoTaskInTime(0, function() inst.components.rideable.canride = false end)
		end
	end)
end)

--I want to avoid screwing up their beefalo stats, and it'd have to be reworked to not crash
-- but unfortunately the component doesn't remove its listeners when it gets removed, so we
-- just have to gut its constructor
BeefaloMetrics = require("components/beefalometrics")
BeefaloMetrics._ctor = function() end

local Brushable = require("components/brushable")
local __ctor = Brushable._ctor
function Brushable:_ctor(inst, ...)
	__ctor(self, inst, ...)
	self:WatchWorldState("cycles", function(self, data)
		if not self.brushable and self.lastbrushcycle < data then
			self.brushable = true --have it renew its brushability every day
		end
	end)
end
local _Brush = Brushable.Brush
function Brushable:Brush(...)
	_Brush(self, ...)
	if self:CalculateNumPrizes() == 0 then
		self.brushable = false --if it's been brushed to completion, don't let them brush more
	end
end

local function ondiscarded(inst)
	inst.components.fueled:DoDelta(-TUNING.SEWINGKIT_REPAIR_VALUE)
end

local function SaddlePostInit(inst)
	local uses = inst.components.finiteuses:GetUses()
	
	--Add the fueled component immediately so it can load any data it has
	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = GLOBAL.FUELTYPE.USAGE
	inst.components.fueled:InitializeFuelLevel(TUNING.SEWINGKIT_REPAIR_VALUE*uses)
	inst.components.fueled:SetDepletedFn(inst.Remove)
	-- inst.components.fueled.rate = 1 --rate of 1 is probably fine, should be 25-40 days of riding
	
	--Set the finiteuses to something impossible so we know if it loads old data
	local impossible_uses = inst.components.finiteuses.total + 1
	inst.components.finiteuses:SetUses(impossible_uses)
	--Delay this so it can load its finiteuses remaining if it has them
	inst:DoTaskInTime(0, function(inst)
		local uses = inst.components.finiteuses:GetUses()
		if uses ~= impossible_uses then --it loaded finiteuses data, transform it to fuel
			inst.components.fueled:InitializeFuelLevel(TUNING.SEWINGKIT_REPAIR_VALUE*uses)
		end
		inst:RemoveComponent("finiteuses")
		inst.components.fueled:DoDelta(0) --make it update the %
	end)
	inst.components.saddler:SetDiscardedCallback(ondiscarded)
end
for _,prefab in pairs({"saddle_basic", "saddle_war", "saddle_race"}) do
	AddPrefabPostInit(prefab, SaddlePostInit)
end
local Rideable = require("components/rideable")
local _SetRider = Rideable.SetRider
function Rideable:SetRider(...)
	local oldrider = self.rider
	_SetRider(self, ...)
	local newrider = self.rider
	if self.saddle == nil then return end -- HAO IS DIS POSSIBRU?!?!
	if newrider == nil then
		self.saddle.components.fueled:StopConsuming()
	elseif oldrider == nil then
		self.saddle.components.fueled:StartConsuming()
	end
end

local Rider = require("components/rider")
local _Mount = Rider.Mount
function Rider:Mount(target, ...)
	if self.riding then return end
	if target.components.domesticatable and TheNet:GetPVPEnabled()
	and target.components.domesticatable.collar_owner
	and not target.components.domesticatable:IsCollarOwner(self.inst) then
		--Tried mounting someone else's beefalo, push refusal events (making the beefalo attack)
		self.inst:PushEvent("refusedmount", {rider=self.inst,rideable=target})
		target:PushEvent("refusedrider", {rider=self.inst,rideable=target})
		return
	end
	return _Mount(self, target, ...)
end

local edible_turfs = {
	[GLOBAL.GROUND.SAVANNA] = true,
	[GLOBAL.GROUND.GRASS] = true,
	[GLOBAL.GROUND.FOREST] = true,
	[GLOBAL.GROUND.DECIDUOUS] = true,
	[GLOBAL.GROUND.SINKHOLE] = true,
}

AddStategraphPostInit("beefalo", function(sg)
	local graze_empty_onenter = sg.states.graze_empty.onenter
	function sg.states.graze_empty.onenter(inst, data)
		if not edible_turfs[GLOBAL.TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition())] then
			inst.sg:SetTimeout(0) --exit immediately because there's no grass to eat!
		else
			graze_empty_onenter(inst, data)
		end
	end
end)

local State = GLOBAL.State
local EventHandler = GLOBAL.EventHandler

AddStategraphState("beefalo", State{
		name = "near_death_pre",
		tags = {"busy", "noattack"},

		onenter = function(inst)
			inst.components.health:SetInvincible(true)
			inst.components.rideable.canride = false
			inst.SoundEmitter:PlaySound(inst.sounds.yell)
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
		end,
		
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("near_death") end),
        },
	})
AddStategraphState("beefalo", State{
		name = "near_death",
		tags = {"busy", "noattack"},

		onenter = function(inst)
			inst.components.health:SetInvincible(true)
			inst.components.rideable.canride = false
			inst.components.rideable:Buck(true)
			inst.AnimState:SetPercent("death", 1)
			inst.Physics:Stop()
		end,
		
		onexit = function(inst)
			inst.components.health:SetInvincible(false)
			if inst.components.rideable and inst.components.rideable.saddle ~= nil then
				inst.components.rideable.canride = true
			end
			GLOBAL.BrainManager:Wake(inst)
		end,
	})

AddPrefabPostInit("world", function(inst)
	local _CanShareTarget = UpvalueHacker.GetUpvalue(GLOBAL.Prefabs.beefalo.fn, "OnAttacked", "CanShareTarget")
	local function CanShareTarget(dude, ...)
		return _CanShareTarget(dude, ...) and (not dude.components.domesticatable or not dude.components.domesticatable.domesticated)
	end
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.beefalo.fn, CanShareTarget, "OnAttacked", "CanShareTarget")
end)

local function PlayerPostInit(inst)
	inst:AddComponent("beefalosaver")
	local _OnDespawn = inst._OnDespawn or function() end
	function inst._OnDespawn(inst, ...)
		_OnDespawn(inst, ...)
		inst.components.beefalosaver:SaveBeefalo()
	end
end

for k,prefabname in ipairs(GLOBAL.DST_CHARACTERLIST) do
	AddPrefabPostInit(prefabname, PlayerPostInit)
end

if GLOBAL.MODCHARACTERLIST then
	for k,prefabname in ipairs(GLOBAL.MODCHARACTERLIST) do
		AddPrefabPostInit(prefabname, PlayerPostInit)
	end
end