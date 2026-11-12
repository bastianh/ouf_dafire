-- Frame placement. Player and target sit left and right of the screen's bottom center,
-- pet and targettarget below them, the party as a column at the top left.

local _, ns = ...
local oUF, C, E = ns.oUF, ns.C, ns.E

local function Spawn(self, unit, ...)
   self:SetActiveStyle(ns.StyleFor(unit))
   local object = self:Spawn(unit)
   object:SetScale(C.SCALE)
   object:SetPoint(...)
   return object
end

local function SpawnParty(self)
   self:SetActiveStyle(ns.StyleFor("party"))
   local party = self:SpawnHeader("oUF_DafireParty", nil,
      "showParty", true,
      "showPlayer", false,
      "point", "TOP",
      "yOffset", -30, -- room for the name above each frame
      "oUF-initialConfigFunction", ([[
         self:SetWidth(%d)
         self:SetHeight(%d)
      ]]):format(C.BIG_W, C.BIG_H)
   )
   party:SetScale(C.SCALE)
   party:SetVisibility("party")
   party:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 30, -80)
   return party
end

oUF:Factory(function(self)
   local player = Spawn(self, "player", "RIGHT", UIParent, "BOTTOM", -70, 300)
   local target = Spawn(self, "target", "LEFT", UIParent, "BOTTOM", 70, 300)

   Spawn(self, "targettarget", "TOPRIGHT", target, "BOTTOMRIGHT", 0, E.GapBelow())
   Spawn(self, "pet", "TOPLEFT", player, "BOTTOMLEFT", 0, E.GapBelow())

   if C.SHOW_PARTY then
      SpawnParty(self)
   end
end)
