-- major rewrite, inspired by oUF_Lily

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, "oUF not found. This is an unexpected error.")

local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
local FONT = LSM and LSM:Fetch("font","Calibri",true) or [[Interface\AddOns\oUF_Dafire\font.ttf]]
local TEXTURE = LSM and LSM:Fetch("statusbar","Smudge",true) or [[Interface\AddOns\oUF_Dafire\textures\statusbar]]

local backdrop = {
   bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true,
   tileSize = 16, insets ={left = -1, right = -1, top = -1, bottom = -1},
}

local menu = function(self)
   local unit = self.unit:sub(1, -2)
   local cunit = self.unit:gsub("^%l", string.upper)

   if(cunit == 'Vehicle') then
      cunit = 'Pet'
   end

   if(unit == "party" or unit == "partypet") then
      ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
   elseif(_G[cunit.."FrameDropDown"]) then
      ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
   end
end

local siValue = function(val)
   if(val >= 1e4) then
         return ("%.1fk"):format(val / 1e3)
   else
         return val
   end
end

oUF.Tags['dafire:health'] = function(unit)
   if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end
      local min, max = UnitHealth(unit), UnitHealthMax(unit)
   if max == min then
      return max
   else
      return ("%s/%s (%.1f%%)"):format(siValue(min), siValue(max), min/max*100)
   end
end
oUF.TagEvents['dafire:health'] = oUF.TagEvents.missinghp

oUF.Tags['dafire:power'] = function(unit)
   local min, max = UnitPower(unit), UnitPowerMax(unit)
   if(min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end
   return siValue(min)
end
oUF.TagEvents['dafire:power'] = oUF.TagEvents.missingpp

local CreatePortrait = function(self, side)
   local portrait = CreateFrame("PlayerModel", nil, self)
   portrait:SetScript("OnShow", function() this:SetCamera(0) end)
   portrait:SetHeight(self:GetAttribute"initial-height")
   portrait:SetWidth(self:GetAttribute"initial-height")
   portrait.type = "3D"
   portrait:SetPoint"TOP"
   portrait:SetPoint"BOTTOM"
   if side == "right" then
      portrait:SetPoint"RIGHT"
   else
      portrait:SetPoint"LEFT"
   end
   portrait.side = side
   self.Portrait = portrait
end

local CreatePowerBar = function(self, text)
   local pp = CreateFrame("Statusbar", nil, self)
   pp:SetStatusBarTexture(TEXTURE)
   if (text) then
      pp:SetHeight(10)
   else
      pp:SetHeight(8)
   end
   pp.colorPower = true -- CHECKME: alt
   pp:SetPoint"BOTTOM"
   if self.Portrait then
      if self.Portrait.side == "left" then
         pp:SetPoint("LEFT", self.Portrait, "RIGHT", 1, 0)
         pp:SetPoint"RIGHT"
      else
         pp:SetPoint("RIGHT", self.Portrait, "LEFT", -1, 0)
         pp:SetPoint"LEFT"
      end
   else
      pp:SetPoint"LEFT"
      pp:SetPoint"RIGHT"
   end
   self.Power = pp
   
   if (text) then
      local ppp = pp:CreateFontString(nil, "OVERLAY")
      ppp:SetAllPoints(pp)
      ppp:SetJustifyH"CENTER"
      ppp:SetFont(FONT, 10)
      ppp:SetTextColor(1, 1, 1)
      pp.value = ppp
      self:Tag(ppp, "[dafire:power]")
   end
end

local CreateLevelDisplay = function(self,position)
   local level = self.Health:CreateFontString(nil, "OVERLAY")
   if (position == "left") then
      level:SetJustifyH"LEFT"
      level:SetPoint("BOTTOMLEFT", self, "TOPLEFT",0, -6)
   else
      level:SetJustifyH"RIGHT"
      level:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT",0, -6)
   end
   level:SetFont(FONT, 11, "OUTLINE")
   self:Tag(level,"[difficulty][smartlevel][plus][rare]")
end

local UnitSpecific = {
   player = function(self)
      CreatePortrait(self, "left")
      CreatePowerBar(self, true)
      CreateLevelDisplay(self,"right")
   end,
   target = function(self)
      CreatePortrait(self, "right")
      CreatePowerBar(self, true)
      CreateLevelDisplay(self,"left")
      -- TODO: refactor buffs
      local buffs = CreateFrame("Frame", nil, self)
      buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT",0,1)
      buffs:SetHeight(18*3)
      buffs:SetWidth(18*8)
      buffs:SetFrameStrata("LOW")
      buffs.size = 18
      buffs.num = 8*3
      buffs.initialAnchor = "BOTTOMLEFT"
      buffs['growth-x'] = "RIGHT"
      buffs['growth-y'] = "UP"
      self.Buffs = buffs
      -- TODO: refactor Debuffs
      local debuffs = CreateFrame("Frame", nil, self)
      debuffs:SetPoint("TOPLEFT", self, "TOPRIGHT")
      debuffs:SetHeight(18*4)
      debuffs:SetWidth(18*10)
      debuffs['growth-y'] = "DOWN"
      debuffs.initialAnchor = "TOPLEFT"
      debuffs.size = 18
      debuffs.showDebuffType = true
      debuffs.num = 40
      self.PostUpdateAura = scaleDebuffs
      self.Debuffs = debuffs      
   end,
   party = function(self)
      -- FIXME: bugt rum CreatePortrait(self, "left")
      --[[
evtl weil oUF 1.3.28 ist ?
1x oUF-1.3.28\elements\portraits.lua:5: Usage: UnitIsUnit("unit", "otherUnit")
oUF-1.3.28\elements\portraits.lua:5: in function <oUF\elements\portraits.lua:4>
(tail call): ?:

Locals:
self = oUF_DafirePartyUnitButton4 {
 0 = <userdata>
 UNIT_PORTRAIT_UPDATE = <function> @ oUF\elements\portraits.lua:4:
 Portrait = <unnamed> {}
 UNIT_MAXFOCUS = <function> @ oUF\elements\power.lua:11:
 __tags = <table> {}
 PLAYER_ENTERING_WORLD = <function> @ oUF\ouf.lua:315:
 id = "4"
 unit = "party4"
 menu = <function> @ oUF_Dafire\dafire.lua:16:
 UNIT_MAXRAGE = <function> @ oUF\elements\power.lua:11:
 UNIT_ENTERED_VEHICLE = <function> @ oUF\elements\vehicle.lua:4:
 UNIT_MAXRUNIC_POWER = <function> @ oUF\elements\power.lua:11:
 UNIT_DISPLAYPOWER = <function> @ oUF\elements\power.lua:11:
 UNIT_MAXHEALTH = <function> @ oUF\elements\health.lua:6:
 __elements = <table> {}
 UNIT_MAXENERGY = <function> @ oUF\elements\power.lua:11:
 PARTY_MEMBER_ENABLE = <function> @ oUF\elements\portraits.lua:4:
 UNIT_RAGE = <function> @ oUF\elements\power.lua:11:
 Power = <unnamed> {}
 UNIT_ENERGY = <function> @ oUF\elements\power.lua:11:
 UNIT_FOCUS = <function> @ oUF\elements\power.lua:11:
 UNIT_FACTION = <table> {}
 UNIT_HAPPINESS = <table> {}
 UNIT_RUNIC_POWER = <function> @ oUF\elements\power.lua:11:
 UNIT_HEALTH = <function> @ oUF\elements\health.lua:6:
 Health = <unnamed> {}
 UNIT_MAXMANA = <function> @ oUF\elements\power.lua:11:
 UNIT_MANA = <function> @ oUF\elements\power.lua:11:
 style = "Dafire"
 UNIT_EXITED_VEHICLE = <function> @ oUF\elements\vehicle.lua:4:
 UNIT_MODEL_CHANGED = <function> @ oUF\elements\portraits.lua:4:
}
event = "PARTY_MEMBER_ENABLE"
unit = nil

  ---
      ]]
      CreatePowerBar(self, true)
      CreateLevelDisplay(self,"right")
   end,
   targettarget = function(self)
      local tmpheight, tmpwidth = self:GetAttribute"initial-height", self:GetAttribute"initial-width"
      self:SetAttribute('initial-height', tmpheight-12)
      self:SetAttribute('initial-width', tmpwidth-70)
      CreatePowerBar(self, false)
   end,
   pet = function(self)
      local tmpheight, tmpwidth = self:GetAttribute"initial-height", self:GetAttribute"initial-width"
      self:SetAttribute('initial-height', tmpheight-12)
      self:SetAttribute('initial-width', tmpwidth-70)
      CreatePowerBar(self, false)
      CreateLevelDisplay(self,"right")
   end
}

local DafireFrames = function(self, unit)
   self.menu = menu
   
   self:SetScript("OnEnter", UnitFrame_OnEnter)
   self:SetScript("OnLeave", UnitFrame_OnLeave)
   
   self:RegisterForClicks"anyup"
   self:SetAttribute("*type2", "menu")
   
   self:SetBackdrop(backdrop)
   self:SetBackdropColor(0, 0, 0, 1)

   self:SetAttribute('initial-height', 35)
   self:SetAttribute('initial-width', 200)
   
   local hp = CreateFrame("StatusBar", nil, self)
   hp:SetStatusBarTexture(TEXTURE)
   hp.frequentUpdates = true
   hp.colorTapping = true  -- CHECKME: alt
   hp.colorClass = true  -- CHECKME: alt
   hp.colorHappiness = true  -- CHECKME: alt
   hp.colorReaction = true  -- CHECKME: alt
   hp.colorSmooth = true  -- CHECKME: alt
   self.Health = hp
   
   local hpp = hp:CreateFontString(nil, "OVERLAY")
   hpp:SetAllPoints(hp)
   hpp:SetJustifyH"CENTER"
   hpp:SetFont(FONT, 12)
   hpp:SetTextColor(1, 1, 1)
   self:Tag(hpp, '[dead][offline][dafire:health]')
   hp.value = hpp
--[[
   FIXME: cpoints not working!
   local cpoints = self:CreateFontString(nil, "OVERLAY")
   cpoints:SetPoint("CENTER", self, "LEFT", -15, 3)
   cpoints:SetFont(FONT, 38, "OUTLINE")
   cpoints:SetTextColor(1,1,1)
   cpoints:SetJustifyH("RIGHT")
   self.CPoints = cpoints
]]   
   
   if(UnitSpecific[unit]) then
      UnitSpecific[unit](self)
   end

   local name = hp:CreateFontString(nil, "OVERLAY")
   if unit == "target" or unit == "targettarget" then
      name:SetJustifyH"RIGHT"
      name:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT",0, -5)
   else
      name:SetJustifyH"LEFT"
      name:SetPoint("BOTTOMLEFT", self, "TOPLEFT",0, -5)	   
   end
   name:SetFont(FONT, 12, "OUTLINE")
   name:SetTextColor(1, 1, 1)
   name:SetWidth(self:GetAttribute("initial-width") - 15)
   name:SetHeight(12)
   self:Tag(name,"[name]")
   
   hp:SetPoint"TOP"
   if self.Portrait then
      if self.Portrait.side == 'left' then
         hp:SetPoint("LEFT", self.Portrait, "RIGHT", 1, 0)
         hp:SetPoint"RIGHT"
      else
         hp:SetPoint("RIGHT", self.Portrait, "LEFT", -1, 0)
         hp:SetPoint"LEFT"
      end
   else
      hp:SetPoint"RIGHT"
      hp:SetPoint"LEFT"
   end
   if self.Power then
      hp:SetPoint("BOTTOM", self.Power, "TOP", 0, 1)
   else
      hp:SetPoint"BOTTOM"
   end
   
end

oUF:RegisterStyle("Dafire", DafireFrames)

oUF:Factory(function(self)
   self:SetActiveStyle("Dafire")

   local player = self:Spawn("player")
   player:SetPoint("RIGHT", UIParent, "BOTTOM", -15, 170)

   local target = self:Spawn("target")
   target:SetPoint("LEFT", UIParent, "BOTTOM", 15, 170)

   self:Spawn("targettarget"):SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", 0, -8)
   self:Spawn("pet"):SetPoint("TOPLEFT", player, "BOTTOMLEFT", 0, -8)

   -- oUF:SpawnHeader(overrideName, overrideTemplate, visibility, attributes ...)
   local party = self:SpawnHeader(nil, nil, 'raid,party,solo',
      -- http://wowprogramming.com/docs/secure_template/Group_Headers
      -- Set header attributes
      "showParty", true,
      "yOffset", -40,
      "xOffset", -40,
      'maxColumns', 2,
      'unitsPerColumn', 2,
      'columnAnchorPoint', 'LEFT',
      'columnSpacing', 15
   )
   party:SetPoint("TOPLEFT", 30, -30)
end)
