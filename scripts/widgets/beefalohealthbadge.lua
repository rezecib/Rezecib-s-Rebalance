local HealthBadge = require "widgets/healthbadge"

local BeefaloHealthBadge = Class(HealthBadge, function(self, owner)
    HealthBadge._ctor(self, owner, "health")
end)

return BeefaloHealthBadge