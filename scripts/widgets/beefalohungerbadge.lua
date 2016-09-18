local HungerBadge = require "widgets/hungerbadge"

local BeefaloHungerBadge = Class(HungerBadge, function(self, owner)
    HungerBadge._ctor(self, "health", owner)
end)

return BeefaloHungerBadge