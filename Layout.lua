-- Styles: which elements each unit gets. Building blocks live in Elements.lua.

local _, ns = ...
local oUF, C, U, E = ns.oUF, ns.C, ns.U, ns.E

-- Common start of every style: click handling, tooltip, size, background, health.
local function Begin(self, isSingle, width, height)
   self:RegisterForClicks("AnyUp")
   -- hook instead of SetScript: group header buttons use OnEnter for secure snippets
   self:HookScript("OnEnter", U.OnEnter)
   self:HookScript("OnLeave", U.OnLeave)

   -- header children get their size from oUF-initialConfigFunction (Spawn.lua)
   if isSingle then
      self:SetSize(width or C.BIG_W, height or C.BIG_H)
   end

   U.CreateBackground(self)
   E.Overlay(self)
   E.Health(self)
end

-- Common end of every style: name and health anchoring (needs portrait and power).
local function Finish(self, nameRight, aggro)
   E.Name(self, nameRight, aggro)
   E.AnchorHealth(self)
end

local styles = {
   player = function(self, unit, isSingle)
      Begin(self, isSingle)
      E.Portrait(self, "left")
      E.RaidIcon(self)
      E.Power(self, true)
      E.Level(self, "right")
      E.Threat(self, 1)
      E.ThreatBar(self)
      -- Quartz and Dominos_Cast bring their own player castbar
      if not (U.IsAddOnLoaded("Quartz") or U.IsAddOnLoaded("Dominos_Cast")) then
         E.Castbar(self, true, -(C.THREATBAR_H + 5)) -- below the threat bar
      end
      Finish(self)
   end,

   target = function(self, unit, isSingle)
      Begin(self, isSingle)
      E.Portrait(self, "right")
      E.RaidIcon(self)
      E.Power(self, true)
      E.Level(self, "left")
      E.Threat(self, 1, "player") -- the player's threat on this target
      E.Castbar(self)
      E.TargetAuras(self)
      E.ComboPoints(self)
      E.ThreatValue(self)
      Finish(self, true, true)
   end,

   targettarget = function(self, unit, isSingle)
      Begin(self, isSingle, C.SMALL_W, C.SMALL_H)
      E.Power(self, false)
      E.Threat(self, 2)
      Finish(self, true, true)
   end,

   pet = function(self, unit, isSingle)
      Begin(self, isSingle, C.SMALL_W, C.SMALL_H)
      E.Power(self, false)
      E.Level(self, "right")
      E.Threat(self, 2)
      Finish(self)
   end,

   party = function(self, unit, isSingle)
      Begin(self, isSingle)
      E.Portrait(self, "left")
      E.RaidIcon(self)
      E.Power(self, true)
      E.Level(self, "right")
      E.Threat(self, 1)
      E.Leader(self)
      E.Range(self)
      Finish(self)
   end,
}

-- Fallback for units without their own style.
local function Default(self, unit, isSingle)
   Begin(self, isSingle)
   Finish(self)
end

local function StyleName(unit)
   return "Dafire - " .. unit:gsub("^%l", string.upper)
end

oUF:RegisterStyle("Dafire", Default)
for unit, style in next, styles do
   oUF:RegisterStyle(StyleName(unit), style)
end

-- Name of the registered style to use for a unit.
function ns.StyleFor(unit)
   return styles[unit] and StyleName(unit) or "Dafire"
end
