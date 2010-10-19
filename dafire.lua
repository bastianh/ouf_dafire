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
   portrait:SetScript("OnShow", function(self) self:SetCamera(0) end)
   portrait:SetHeight(self:GetHeight())
   portrait:SetWidth(self:GetHeight())
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

local CreateRuneBar = function(self)
   -- TODO: FIXME: not working, and I don't have a deathknight char to test more yet
   if select(2, UnitClass("player")) ~= "DEATHKNIGHT" then return end
   local runeloadcolors = {
      [1] = {.69,.31,.31},
      [2] = {.69,.31,.31},
      [3] = {.33,.59,.33},
      [4] = {.33,.59,.33},
      [5] = {.31,.45,.63},
      [6] = {.31,.45,.63},
   }

   local width = self:GetAttribute"initial-width"
   runes = CreateFrame('Frame', nil, self)
   runes:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -1)
   self.Runes = runes
   self.Runes:SetHeight(12)
   self.Runes:SetWidth(200)
   self.Runes:SetBackdrop(backdrop)
   self.Runes:SetBackdropColor(0, 0, 0)
   self.Runes.anchor = "TOPLEFT"
   self.Runes.growth = "RIGHT"
   self.Runes.height = 7
   self.Runes.width = 250 / 6 - 0.85
   self.Runes.spacing = 1
   self.Runes.runeMap = {[3] = 3}

   for i = 1, 6 do
      self.Runes[i] = CreateFrame('StatusBar', nil, self.Runes)
      --self.Runes[i]:SetStatusBarTexture(TEXTURE)
      --self.Runes[i]:SetStatusBarColor(unpack(runeloadcolors[i]))
   end

   grunes = self.Runes
end

-- Eclipse Bar function
local function CreateEclipseBar(self)
    local _, class = UnitClass('player')

    if class ~= 'DRUID' then return end

    local eclipseBar = CreateFrame('Frame', nil, self)
    eclipseBar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -1)
    --eclipseBar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -1)
    eclipseBar:SetSize(200, 10)
    eclipseBar:SetBackdrop(backdrop)
    eclipseBar:SetBackdropColor(0, 0, 0)
    
    local lunarBar = CreateFrame('StatusBar', nil, eclipseBar)
    lunarBar:SetPoint('LEFT', eclipseBar, 'LEFT', 0, 0)
    lunarBar:SetSize(200, 10)
    lunarBar:SetStatusBarTexture(TEXTURE)
    lunarBar:SetStatusBarColor(0, 0, 1)
    eclipseBar.LunarBar = lunarBar
    
    local solarBar = CreateFrame('StatusBar', nil, eclipseBar)
    solarBar:SetPoint('LEFT', lunarBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
    solarBar:SetSize(200, 10)
    solarBar:SetStatusBarTexture(TEXTURE)
    solarBar:SetStatusBarColor(1, 3/5, 0)
    eclipseBar.SolarBar = solarBar
    
    local eclipseBarText = solarBar:CreateFontString(nil, 'OVERLAY')
    eclipseBarText:SetPoint('CENTER', eclipseBar, 'CENTER', 0, 0)
    eclipseBarText:SetFont(FONT, 10)
    eclipseBar.Text = eclipseBarText
    
    self.EclipseBar = eclipseBar
end

local CreateRaidIcon = function(self)
   local ricon = self.Health:CreateTexture(nil,"OVERLAY")
   if self.Portrait then
      ricon:SetAllPoints(self.Portrait)
   else
      ricon:SetHeight(16)
      ricon:SetWidth(16)
      ricon:SetPoint"RIGHT"
   end
   self.RaidIcon = ricon
end

local ThreatInfo = function(self, size)
   local threat = self:CreateTexture(nil,"BACKGROUND")
   if size == 1 then
      threat:SetPoint("TOPRIGHT",self,28,28)
      threat:SetPoint("BOTTOMLEFT",self,-28,-28)
      threat:SetTexCoord(0, .918, 0, .186)
   elseif  size == 2 then
      threat:SetPoint("TOPRIGHT",self,8,8)
      threat:SetPoint("BOTTOMLEFT",self,-8,-8)
      threat:SetTexCoord(.078, .547, .214, .297)
   end
   threat:SetTexture[[Interface\AddOns\oUF_Dafire\textures\threat]]
   self.Threat = threat
end

local SharedFirst = function(self,unit,isSingle)
    self.menu = menu

    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)

    self:RegisterForClicks"AnyDown"

    self:SetBackdrop(backdrop)
    self:SetBackdropColor(0, 0, 0, 1)

    if(isSingle) then
        self:SetSize(200, 35)
    end

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

end

local SharedSecond = function(self,unit,isSingle)
    local hp = self.Health
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
    name:SetWidth(self:GetWidth() - 15)
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

local UnitSpecific = {
    player = function(self,...)
        SharedFirst(self,...)
        CreatePortrait(self, "left")
        CreateRaidIcon(self)
        CreatePowerBar(self, true)
        CreateLevelDisplay(self,"right")
        CreateRuneBar(self)
        ThreatInfo(self,1)
        CreateEclipseBar(self)
        SharedSecond(self,...)
    end,
    target = function(self,...)
        SharedFirst(self,...)
        CreatePortrait(self, "right")
        CreateRaidIcon(self)
        CreatePowerBar(self, true)
        CreateLevelDisplay(self,"left")
        ThreatInfo(self,1)
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

        local cpoints = self:CreateFontString(nil, "OVERLAY")
        cpoints:SetPoint("CENTER", self, "LEFT", -15, 3)
        cpoints:SetFont(FONT, 38, "OUTLINE")
        cpoints:SetTextColor(1,1,1)
        cpoints:SetJustifyH("RIGHT")   
        self:Tag(cpoints, '[cpoints]')
        self.ourCPoints = cpoints
        SharedSecond(self,...)
    end,
    pet = function(self,...)
        SharedFirst(self,...)
        local tmpheight, tmpwidth = self:GetHeight(), self:GetWidth()
        self:SetSize(tmpwidth-100,tmpheight-12)
        CreatePowerBar(self, false)
        CreateLevelDisplay(self,"right")
        ThreatInfo(self,2)
        SharedSecond(self,...)
    end,
    targettarget = function(self,...)
        SharedFirst(self,...)
        local tmpheight, tmpwidth = self:GetHeight(), self:GetWidth()
        self:SetSize(tmpwidth-100,tmpheight-12)
        CreatePowerBar(self, false)
        ThreatInfo(self,2)
        SharedSecond(self,...)
    end,
    party = function(self,...)SharedFirst(self,...)
        SharedFirst(self,...)
        CreatePortrait(self, "left")
        CreateRaidIcon(self)
        CreatePowerBar(self, true)
        CreateLevelDisplay(self,"right")
        ThreatInfo(self,1)
        SharedSecond(self,...)
   end
}

local DafireFrames = function(self, unit, isSingle)
    SharedFirst(self,unit,isSingle)
    SharedSecond(self,unit,isSingle);
end

oUF:RegisterStyle("Dafire", DafireFrames)

for unit,layout in next, UnitSpecific do
    -- Capitalize the unit name, so it looks better.
    oUF:RegisterStyle('Dafire - ' .. unit:gsub("^%l", string.upper), layout)
end

local spawnHelper = function(self, unit, ...)
    if(UnitSpecific[unit]) then
        self:SetActiveStyle('Dafire - ' .. unit:gsub("^%l", string.upper))
        local object = self:Spawn(unit)
        object:SetPoint(...)
        return object
    else
        self:SetActiveStyle'Dafire'
        local object = self:Spawn(unit)
        object:SetPoint(...)
        return object
    end
end

oUF:Factory(function(self)
    self:SetActiveStyle("Dafire")
    
    local player = spawnHelper(self, 'player', 'RIGHT', UIParent, "BOTTOM", -15, 170 )
    local target = spawnHelper(self, 'target', 'LEFT', UIParent, "BOTTOM", 15, 170 )

    spawnHelper(self, 'targettarget', 'TOPRIGHT', target, "BOTTOMRIGHT", 0, -8 )
    spawnHelper(self, 'pet', 'TOPLEFT', player, "BOTTOMLEFT", 0, -8 )    
--   local target = self:Spawn("target")
--   target:SetPoint("LEFT", UIParent, "BOTTOM", 15, 170)

--   self:Spawn("targettarget"):SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", 0, -8)
--   self:Spawn("pet"):SetPoint("TOPLEFT", player, "BOTTOMLEFT", 0, -8)
--[[
   -- oUF:SpawnHeader(overrideName, overrideTemplate, visibility, attributes ...)
   local party = self:SpawnHeader(nil, nil, 'party,solo',
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
   ]]
end)
