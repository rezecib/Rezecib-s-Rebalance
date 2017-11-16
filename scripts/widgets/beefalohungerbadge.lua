local HungerBadge = require "widgets/hungerbadge"

local BeefaloHungerBadge = Class(HungerBadge, function(self, owner)
    HungerBadge._ctor(self, owner, "hunger")
end)

return BeefaloHungerBadge