-- Building blocks. Each function creates one widget on a unit frame and registers it
-- with oUF where applicable. Order matters only where noted.

local _, ns = ...
local C, U = ns.C, ns.U
local CreateText = U.CreateText

local E = {}
ns.E = E

-- Raised layer for icons and texts that must sit above bars and portrait models.
-- Create first: most other elements put their texts on it.
function E.Overlay(self)
   local overlay = CreateFrame("Frame", nil, self)
   overlay:SetAllPoints()
   overlay:SetFrameLevel(self:GetFrameLevel() + 5)
   self.Overlay = overlay
end

-- Anchors a bar between the portrait (if any) and the opposite frame edge.
function E.AnchorBesidePortrait(self, bar)
   local portrait = self.Portrait
   if portrait and portrait.side == "left" then
      bar:SetPoint("LEFT", portrait, "RIGHT", 1, 0)
      bar:SetPoint("RIGHT")
   elseif portrait then
      bar:SetPoint("RIGHT", portrait, "LEFT", -1, 0)
      bar:SetPoint("LEFT")
   else
      bar:SetPoint("LEFT")
      bar:SetPoint("RIGHT")
   end
end

-- Health bar and its text. Vertical anchoring happens later in E.AnchorHealth,
-- once it is known whether there is a portrait and a power bar.
function E.Health(self)
   local hp = CreateFrame("StatusBar", nil, self)
   hp:SetStatusBarTexture(C.TEXTURE)
   hp.colorDisconnected = true
   hp.colorTapping = true
   hp.colorHappiness = true -- hunter pet, Forever only
   hp.colorClass = true
   hp.colorReaction = true
   hp.colorSmooth = true
   hp.colorHealth = true
   self.Health = hp

   local value = CreateText(self.Overlay, 12)
   value:SetAllPoints(hp)
   value:SetJustifyH("CENTER")
   self:Tag(value, "[dead][offline][dafire:health]")
   hp.value = value
end

-- Needs Portrait and Power to exist already.
function E.AnchorHealth(self)
   local hp = self.Health
   hp:SetPoint("TOP")
   E.AnchorBesidePortrait(self, hp)
   if self.Power then
      hp:SetPoint("BOTTOM", self.Power, "TOP", 0, 1)
   else
      hp:SetPoint("BOTTOM")
   end
end

-- Needs Portrait to exist already.
function E.Power(self, withText)
   local pp = CreateFrame("StatusBar", nil, self)
   pp:SetStatusBarTexture(C.TEXTURE)
   pp:SetHeight(withText and 10 or 8)
   pp:SetPoint("BOTTOM")
   E.AnchorBesidePortrait(self, pp)

   pp.frequentUpdates = true
   pp.colorDisconnected = true
   pp.colorTapping = true
   pp.colorPower = true
   self.Power = pp

   if withText then
      local value = CreateText(pp, 10)
      value:SetAllPoints(pp)
      value:SetJustifyH("CENTER")
      self:Tag(value, "[dafire:power]")
      pp.value = value
   end
end

-- 3D model on the given side ("left" or "right"), square with the frame height.
function E.Portrait(self, side)
   local portrait = CreateFrame("PlayerModel", nil, self)
   portrait:SetWidth(self:GetHeight())
   portrait:SetPoint("TOP")
   portrait:SetPoint("BOTTOM")
   portrait:SetPoint(side == "right" and "RIGHT" or "LEFT")
   portrait.side = side
   self.Portrait = portrait
end

-- Name above the frame, right-aligned for target units.
-- aggro: turn the name red while the target is attacking the player.
function E.Name(self, alignRight, aggro)
   local name = CreateText(self.Overlay, 12, "OUTLINE")
   if alignRight then
      name:SetJustifyH("RIGHT")
      name:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -5)
   else
      name:SetJustifyH("LEFT")
      name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -5)
   end
   name:SetSize(self:GetWidth() - 15, 12)
   self:Tag(name, aggro and "[dafire:aggro][name]|r" or "[name]")
end

-- Level above the frame, on the opposite side of the name.
function E.Level(self, side)
   local level = CreateText(self.Overlay, 11, "OUTLINE")
   if side == "left" then
      level:SetJustifyH("LEFT")
      level:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -6)
   else
      level:SetJustifyH("RIGHT")
      level:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -6)
   end
   self:Tag(level, "[difficulty][smartlevel][ $>rare]")
end

-- Covers the portrait if there is one, otherwise a small icon on the right.
function E.RaidIcon(self)
   local icon = self.Overlay:CreateTexture(nil, "OVERLAY")
   if self.Portrait then
      icon:SetAllPoints(self.Portrait)
   else
      icon:SetSize(16, 16)
      icon:SetPoint("RIGHT")
   end
   self.RaidTargetIndicator = icon
end

-- Needs Portrait to exist already.
function E.Leader(self)
   local leader = self.Overlay:CreateTexture(nil, "OVERLAY")
   leader:SetSize(14, 14)
   leader:SetPoint("TOPLEFT", self.Portrait or self, "TOPLEFT", -3, 3)
   self.LeaderIndicator = leader
end

-- Replacement for oUF's threat update: oUF compares the status unguarded, which errors
-- when the status is secret. A secret status only shows the glow (orange) in combat.
local function ThreatUpdate(self, _, unit)
   if unit ~= self.__unit then return end
   local element = self.ThreatIndicator
   unit = self.__unit

   local status
   if U.Exists(unit) then
      local feedback = element.feedbackUnit
      if feedback and feedback ~= unit and U.Exists(feedback) then
         status = UnitThreatSituation(feedback, unit)
      else
         status = UnitThreatSituation(unit)
      end
   end

   local color
   if U.IsSecret(status) then
      if UnitAffectingCombat("player") then
         color = self.colors.threat[2]
      end
   elseif status and status > 0 then
      color = self.colors.threat[status]
   end

   if color then
      element:SetVertexColor(color:GetRGB())
      element:Show()
   else
      element:Hide()
   end
end

-- Glow behind the frame. size 1: big glow (player/target/party), size 2: tight glow
-- for small frames. feedbackUnit: whose threat on this unit to show (nil = the unit's own).
function E.Threat(self, size, feedbackUnit)
   local threat = self:CreateTexture(nil, "BACKGROUND", nil, -8)
   threat:SetTexture(C.THREAT_TEXTURE)
   if size == 1 then
      threat:SetPoint("TOPRIGHT", self, 28, 28)
      threat:SetPoint("BOTTOMLEFT", self, -28, -28)
      threat:SetTexCoord(0, .918, 0, .186)
   else
      threat:SetPoint("TOPRIGHT", self, 8, 8)
      threat:SetPoint("BOTTOMLEFT", self, -8, -8)
      threat:SetTexCoord(.078, .547, .214, .297)
   end
   threat.feedbackUnit = feedbackUnit
   threat.Override = ThreatUpdate
   self.ThreatIndicator = threat
end

-- Small "85%" threat text in the top left corner of the frame (target).
function E.ThreatValue(self)
   local text = CreateText(self.Overlay, 10, "OUTLINE")
   text:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -3)
   self:Tag(text, "[dafire:threat]")
end

-- Thin bar below the frame showing the player's threat (0-100%) on the current target.
-- Uses its own event frame: threat events fire for the mob, not for the player unit.
-- Percentages are secret on bosses; SetValue accepts them, only the colour needs a
-- plain status.
function E.ThreatBar(self)
   local bar = CreateFrame("StatusBar", nil, self)
   bar:SetStatusBarTexture(C.TEXTURE)
   bar:SetMinMaxValues(0, 100)
   bar:SetHeight(C.THREATBAR_H)
   bar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
   bar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -2)
   U.CreateBackground(bar)
   bar:Hide()
   self.ThreatBar = bar

   local function Update()
      if not U.Exists("target") or not UnitCanAttack("player", "target") then
         return bar:Hide()
      end
      local isTanking, status, scaled = UnitDetailedThreatSituation("player", "target")
      if scaled == nil then
         return bar:Hide()
      end

      local color = C.THREATBAR_LOW
      if U.IsSecret(status) then
         color = self.colors.threat[2]
      elseif status and status > 0 then
         color = self.colors.threat[status]
      end
      bar:SetStatusBarColor(color:GetRGB())
      bar:SetValue(scaled)
      bar:Show()
   end

   local events = CreateFrame("Frame")
   events:SetScript("OnEvent", Update)
   events:RegisterEvent("PLAYER_TARGET_CHANGED")
   events:RegisterEvent("PLAYER_ENTERING_WORLD")
   events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
   events:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
end

-- Castbar below the frame with icon, spark, spell name and time.
-- withLatency adds the red latency zone (player only). yOffset: distance below the frame.
function E.Castbar(self, withLatency, yOffset)
   yOffset = yOffset or -5
   local h = C.CASTBAR_H
   local cb = CreateFrame("StatusBar", nil, self)
   cb:SetStatusBarTexture(C.TEXTURE)
   cb:SetStatusBarColor(1, .7, 0)
   cb:SetHeight(h)
   cb:SetPoint("TOPLEFT", self, "BOTTOMLEFT", h + 1, yOffset)
   cb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, yOffset)
   cb.timeToHold = 0.5

   local icon = cb:CreateTexture(nil, "OVERLAY")
   icon:SetSize(h, h)
   icon:SetPoint("RIGHT", cb, "LEFT", -1, 0)
   icon:SetTexCoord(.08, .92, .08, .92)
   cb.Icon = icon

   U.CreateBackground(cb, icon)

   local spark = cb:CreateTexture(nil, "OVERLAY")
   spark:SetTexture(C.SPARK_TEXTURE)
   spark:SetBlendMode("ADD")
   spark:SetSize(12, h * 2)
   spark:SetPoint("CENTER", cb:GetStatusBarTexture(), "RIGHT")
   cb.Spark = spark

   local text = CreateText(cb, 10)
   text:SetPoint("LEFT", 3, 0)
   text:SetPoint("RIGHT", -40, 0)
   text:SetJustifyH("LEFT")
   cb.Text = text

   local time = CreateText(cb, 10)
   time:SetPoint("RIGHT", -3, 0)
   time:SetJustifyH("RIGHT")
   cb.Time = time

   if withLatency then
      local safeZone = cb:CreateTexture(nil, "ARTWORK")
      safeZone:SetColorTexture(1, 0, 0, .4)
      cb.SafeZone = safeZone
   end

   self.Castbar = cb
end

-- Gap to leave below player/target for the small frames. Always reserves castbar room
-- so pet and targettarget line up even when the player's castbar is provided by another addon.
function E.GapBelow()
   return -(C.CASTBAR_H + 12)
end

-- Small fonts for the stack count and the cooldown countdown on the aura icons.
local auraCountdownFont = CreateFont("oUF_DafireAuraCountdown")
auraCountdownFont:SetFont(C.FONT, 9, "OUTLINE")

local function PostCreateAura(_, button)
   if button.Count then
      button.Count:SetFont(C.FONT, 9, "OUTLINE")
   end
   if button.Cooldown then
      button.Cooldown:SetCountdownFont("oUF_DafireAuraCountdown")
   end
end

-- Buffs above the frame (growing up), debuffs to the right (growing down).
function E.TargetAuras(self)
   local step = C.AURA_SIZE + C.AURA_SPACING
   local buffs = self:CreateAuras({
      initialAnchor = "BOTTOMLEFT",
      growthX = "RIGHT",
      growthY = "UP",
      layoutLimit = C.BUFFS_PER_ROW * step,
   })
   buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 14) -- above name/level text
   buffs:SetSize(C.BUFFS_PER_ROW * step, C.AURA_SIZE)
   buffs:SetFrameStrata("LOW")
   buffs.size = C.AURA_SIZE
   buffs.elementSpacing = C.AURA_SPACING
   buffs.lineSpacing = C.AURA_SPACING
   buffs.showCount = true
   buffs.PostCreateButton = PostCreateAura
   buffs:AddGroup("HELPFUL", { maxFrameCount = C.BUFFS_PER_ROW * C.BUFF_ROWS })

   local debuffStep = C.DEBUFF_SIZE + C.AURA_SPACING
   local debuffs = self:CreateAuras({
      initialAnchor = "TOPLEFT",
      growthX = "RIGHT",
      growthY = "DOWN",
      layoutLimit = C.DEBUFFS_PER_ROW * debuffStep,
   })
   debuffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, 0)
   debuffs:SetSize(C.DEBUFFS_PER_ROW * debuffStep, C.DEBUFF_SIZE)
   debuffs.size = C.DEBUFF_SIZE
   debuffs.elementSpacing = C.AURA_SPACING
   debuffs.lineSpacing = C.AURA_SPACING
   debuffs.showCount = true
   debuffs.PostCreateButton = PostCreateAura
   debuffs.showDebuffBorder = true
   debuffs:AddGroup("HARMFUL", { maxFrameCount = C.MAX_DEBUFFS })
end

-- Big combo point number left of the target frame.
function E.ComboPoints(self)
   local cpoints = CreateText(self.Overlay, 38, "OUTLINE")
   cpoints:SetPoint("CENTER", self, "LEFT", -15, 3)
   cpoints:SetJustifyH("RIGHT")
   self:Tag(cpoints, "[dafire:cpoints]", "player")
   self.ComboPointsText = cpoints
end

-- Fades the frame when the unit is out of range (group units).
function E.Range(self)
   self.Range = { insideAlpha = 1, outsideAlpha = .5 }
end
