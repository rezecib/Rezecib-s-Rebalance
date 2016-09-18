require "class"
local Widget = require "widgets/widget"
local ItemTile = require "widgets/itemtile"
local ItemSlot = require "widgets/itemslot"
--Use these wrapper classes so other mods can use AddClassPostConstruct
local BeefaloHealthBadge = require "widgets/beefalohealthbadge"
local BeefaloHungerBadge = require "widgets/beefalohungerbadge"

local BeefaloWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "Beefalo")
    self.inv = {}
    self.owner = owner
	self.shown_position = Vector3(580, -60, 0)
	self.hidden_position = Vector3(580, -200, 0)
	self:SetPosition(self.hidden_position)
	self.controller_bump = Vector3(0, 45, 0)
	self.bump_for_controller = false
    self.slotsperrow = 3
   
	self.bg = self:AddChild(Image("images/hud.xml", "craftingsubmenu_fullvertical.tex"))
	self.bg:SetRotation(180)
	
	self.health = self:AddChild(BeefaloHealthBadge(owner))
	self.health:SetScale(1.25, 1.25, 1)
	self.health:SetPosition(80, 155)
	self.health:StopUpdating() -- don't need it to update its fanciness
	local function OnHealthDirty(classified)
		self.health:SetPercent(classified.mounthealth:value()/classified.mountmaxhealth:value(),
			classified.mountmaxhealth:value())
	end
	self.owner.player_classified:ListenForEvent("mounthealthdirty", OnHealthDirty)
	self.owner.player_classified:ListenForEvent("mountmaxhealthdirty", OnHealthDirty)
	OnHealthDirty(self.owner.player_classified)
	
	self.hunger = self:AddChild(BeefaloHungerBadge(owner))
	self.hunger:SetScale(1.25, 1.25, 1)
	self.hunger:SetPosition(-3, 152)
	self.hunger:StopUpdating() -- don't need it to update its fanciness
	local function OnHungerDirty(classified)
		self.hunger:SetPercent(classified.mounthunger:value()/classified.mountmaxhunger:value(),
			classified.mountmaxhunger:value())
	end
	self.owner.player_classified:ListenForEvent("mounthungerdirty", OnHungerDirty)
	self.owner.player_classified:ListenForEvent("mountmaxhungerdirty", OnHungerDirty)
	OnHungerDirty(self.owner.player_classified)
	
	self.saddleslot = self:AddChild(ItemSlot("images/hud.xml", "inv_slot.tex", self.owner))
	self.saddleslot:SetPosition(-84, 154)
	
	self.isopen = false
end)

function BeefaloWidget:GetShownPosition()
	if self.bump_for_controller then
		return self.shown_position + self.controller_bump
	else
		return self.shown_position
	end
end

function BeefaloWidget:GetHiddenPosition()
	if self.bump_for_controller then
		return self.hidden_position + self.controller_bump
	else
		return self.hidden_position
	end
end

function BeefaloWidget:Open()
    self:Close()
    self.isopen = true
	self.saddleslot:SetTile(ItemTile(self.owner.player_classified.ridersaddle:value()))
	self.saddleslot.tile.GetDescriptionString = function(self)
		local str = ""
		if self.item ~= nil and self.item:IsValid() and self.item.replica.inventoryitem ~= nil then
			local adjective = self.item:GetAdjective()
			if adjective ~= nil then
				str = adjective.." "
			end
			str = str..self.item:GetDisplayName()
		end
		return str
	end
    self:Show()
	self:CancelMoveTo()
	self:MoveTo(self:GetPosition(), self:GetShownPosition(), 0.5)
end

function BeefaloWidget:Close()
	if self.isopen then
		self.isopen = false
		self:CancelMoveTo()
		self:MoveTo(self:GetPosition(), self:GetHiddenPosition(), 0.5, function() self:Hide() end)
	end
end

function BeefaloWidget:UpdatePosition()
	local correct_position = self.isopen and self:GetShownPosition() or self:GetHiddenPosition()
	if (self.inst.components.uianim.pos_dest or self:GetPosition()) ~= correct_position then
		self:CancelMoveTo()
		self:MoveTo(self:GetPosition(), self.isopen and self:GetShownPosition() or self:GetHiddenPosition(), 0.2, function() if not self.isopen then self:Hide() end end)
	end
end

return BeefaloWidget