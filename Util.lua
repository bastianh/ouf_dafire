-- Helpers shared by tags, elements and styles.
--
-- Forever hands out "secret" values for many unit APIs (health, power, ...). Lua may pass
-- them to widgets and formatting functions but must not compare or calculate with them.

local _, ns = ...
local C = ns.C

local U = {}
ns.U = U

U.IsSecret = issecretvalue or function() return false end
U.Abbreviate = AbbreviateLargeNumbers or AbbreviateNumbers
U.IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded

-- UnitExists that tolerates a secret answer (treated as "exists", callers guard further).
function U.Exists(unit)
   local exists = UnitExists(unit)
   return U.IsSecret(exists) or exists
end

-- 12345 -> "12.3k" for plain numbers; secret numbers go through Blizzard's formatter.
function U.ShortValue(val)
   if U.IsSecret(val) then
      return U.Abbreviate(val)
   elseif val >= 1e4 then
      return ("%.1fk"):format(val / 1e3)
   end
   return val
end

function U.CreateText(parent, size, flags)
   local fs = parent:CreateFontString(nil, "OVERLAY")
   fs:SetFont(C.FONT, size, flags)
   fs:SetTextColor(1, 1, 1)
   fs:SetWordWrap(false)
   return fs
end

-- Solid black background, 1px larger than the parent (replaces the old SetBackdrop).
-- `anchor` optionally moves the top-left corner, e.g. to include a castbar icon.
function U.CreateBackground(parent, anchor)
   local bg = parent:CreateTexture(nil, "BACKGROUND", nil, -7)
   bg:SetPoint("TOPLEFT", anchor or parent, "TOPLEFT", -1, 1)
   bg:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 1, -1)
   bg:SetColorTexture(0, 0, 0, 1)
   return bg
end

-- Unit tooltip on hover. Own handler instead of Blizzard's UnitFrame_OnEnter, which
-- calls GameTooltip:SetUnit(self.unit) unchecked (and again on a timer) and raised
-- "bad argument #1 ... C_TooltipInfo.GetUnit" here. This one only asks for existing units.
function U.OnEnter(self)
   local unit = self.unit
   if type(unit) ~= "string" then return end
   local exists = UnitExists(unit)
   if not U.IsSecret(exists) and not exists then return end

   GameTooltip_SetDefaultAnchor(GameTooltip, self)
   if GameTooltip:SetUnit(unit) then
      GameTooltip:Show()
   end
end

function U.OnLeave(self)
   if GameTooltip:IsOwned(self) then
      GameTooltip:Hide()
   end
end
