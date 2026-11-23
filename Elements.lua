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

-- "Five second rule" spark on the player's mana bar: after mana is spent it runs from
-- left to right in 5 seconds; when it reaches the end, spirit regeneration starts again.
-- Spending is detected from the mana value going down. When that value is secret,
-- successful casts of spells with a mana cost are used instead.
local FSR_DURATION = 5
local MANA = Enum and Enum.PowerType and Enum.PowerType.Mana or 0

local function SpellCostsMana(spellID)
   local GetCost = (C_Spell and C_Spell.GetSpellPowerCost) or GetSpellPowerCost
   local costs = GetCost and spellID and GetCost(spellID)
   if type(costs) ~= "table" then return false end
   for _, c in ipairs(costs) do
      if not U.IsSecret(c.type) and not U.IsSecret(c.cost) and c.type == MANA and c.cost > 0 then
         return true
      end
   end
   return false
end

-- Druids in cat/bear form show energy/rage on the bar: hide the spark there.
local function ManaDisplayed()
   local pType = UnitPowerType("player")
   return U.IsSecret(pType) or pType == MANA
end

-- Needs Power to exist already. Player only.
function E.ManaRegenSpark(self)
   local pp = self.Power
   local spark = pp:CreateTexture(nil, "OVERLAY", nil, 1)
   spark:SetTexture(C.SPARK_TEXTURE)
   spark:SetBlendMode("ADD")
   spark:SetSize(12, pp:GetHeight() * 2)
   spark:Hide()
   pp.RegenSpark = spark

   local driver = CreateFrame("Frame", nil, pp)
   local startTime, lastMana, lastMax

   local function OnUpdate()
      local progress = (GetTime() - startTime) / FSR_DURATION
      if progress >= 1 then
         driver:SetScript("OnUpdate", nil)
         return spark:Hide()
      end
      spark:SetPoint("CENTER", pp, "LEFT", pp:GetWidth() * progress, 0)
      spark:SetShown(ManaDisplayed())
   end

   local function Start()
      startTime = GetTime()
      driver:SetScript("OnUpdate", OnUpdate)
      OnUpdate()
   end

   local function ReadMana()
      local mana, max = UnitPower("player", MANA), UnitPowerMax("player", MANA)
      if U.IsSecret(mana) or U.IsSecret(max) then return nil end
      return mana, max
   end

   driver:SetScript("OnEvent", function(_, event, _, arg2, arg3)
      if event == "UNIT_POWER_FREQUENT" then
         if arg2 ~= "MANA" then return end
         local mana, max = ReadMana()
         -- a lower maximum (lost buff) also lowers mana, but nothing was spent
         if mana and lastMana and mana < lastMana and not (lastMax and max < lastMax) then
            Start()
         end
         lastMana, lastMax = mana, max
      elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
         if not ReadMana() and SpellCostsMana(arg3) then Start() end
      else -- PLAYER_ENTERING_WORLD
         lastMana, lastMax = ReadMana()
      end
   end)
   driver:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
   driver:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
   driver:RegisterEvent("PLAYER_ENTERING_WORLD")
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

-- Hunter pet happiness face (oUF Happiness element, Forever only). Right next to the frame, at its top edge.
local function PetHappiness()
   if C_PetInfo and C_PetInfo.GetPetHappiness then return C_PetInfo.GetPetHappiness() end
   if GetPetHappiness then return GetPetHappiness() end
end

local HAPPINESS_TEXT = { "Unhappy", "Content", "Happy" }
local HAPPINESS_COLOR = { { 1, .2, .2 }, { 1, .82, 0 }, { .2, 1, .2 } }

local function HappinessTooltip(holder)
   local happiness, damage, loyalty = PetHappiness()
   if not happiness then return end
   GameTooltip:SetOwner(holder, "ANCHOR_RIGHT")
   local c = HAPPINESS_COLOR[happiness] or { 1, 1, 1 }
   local text = _G["PET_HAPPINESS" .. happiness] or HAPPINESS_TEXT[happiness] or tostring(happiness)
   GameTooltip:AddLine(text, c[1], c[2], c[3])
   if damage then
      GameTooltip:AddLine(("Damage: %d%%"):format(damage), 1, 1, 1)
   end
   if loyalty then
      if loyalty > 0 then
         GameTooltip:AddLine("Gaining loyalty", .2, 1, .2)
      elseif loyalty < 0 then
         GameTooltip:AddLine("Losing loyalty", 1, .2, .2)
      end
   end
   if GetPetFoodTypes then
      local foods = { GetPetFoodTypes() }
      if #foods > 0 then
         GameTooltip:AddLine(" ")
         GameTooltip:AddLine("Diet: " .. table.concat(foods, ", "), .8, .8, .8, true)
      end
   end
   GameTooltip:Show()
end

function E.Happiness(self)
   -- the oUF element needs a Texture; a small frame around it takes the mouse for the tooltip
   local holder = CreateFrame("Frame", nil, self)
   holder:SetSize(20, 20)
   holder:SetPoint("TOPLEFT", self, "TOPRIGHT", 3, 0)
   holder:EnableMouse(true)
   holder:SetScript("OnEnter", HappinessTooltip)
   holder:SetScript("OnLeave", GameTooltip_Hide)
   holder:Hide()

   local icon = holder:CreateTexture(nil, "OVERLAY")
   icon:SetAllPoints(holder)
   -- only catch the mouse while the face is shown
   icon.PostUpdate = function(_, happiness) holder:SetShown(happiness ~= nil and icon:IsShown()) end
   self.Happiness = icon
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

-- The faction icons are not square (Alliance is tall): keep the height, fit the width.
local function PvPKeepAspect(element)
   local atlas = element.GetAtlas and element:GetAtlas()
   if not atlas or U.IsSecret(atlas) then return end
   local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
   if info and info.height and info.height > 0 then
      element:SetWidth(element:GetHeight() * info.width / info.height)
   end
end

-- Plain true/false for "unit is PvP flagged"; nil when the answer is secret.
local function PvPFlagged(unit)
   local ffa, pvp = UnitIsPVPFreeForAll(unit), UnitIsPVP(unit)
   if U.IsSecret(ffa) or U.IsSecret(pvp) then return nil end
   return (ffa or pvp) and true or false, ffa
end

local function PvPTooltipLines(holder)
   local unit = holder.unit
   local flagged, ffa = PvPFlagged(unit)
   if not flagged then return GameTooltip:Hide() end
   GameTooltip:ClearLines()
   GameTooltip:AddLine(ffa and "Free-for-all PvP" or "PvP flagged", 1, .82, 0)
   if IsPVPTimerRunning and IsPVPTimerRunning() then
      local sec = math.max(0, math.floor((GetPVPTimer() or 0) / 1000))
      GameTooltip:AddLine(("Flag ends in %d:%02d"):format(math.floor(sec / 60), sec % 60), 1, 1, 1)
   elseif GetPVPDesired and GetPVPDesired() then
      GameTooltip:AddLine("Turned on manually (/pvp to turn off)", .8, .8, .8)
   end
   GameTooltip:Show()
end

local function PvPTooltipOnEnter(holder)
   GameTooltip:SetOwner(holder, "ANCHOR_RIGHT")
   PvPTooltipLines(holder)
   holder.elapsed = 0
   holder:SetScript("OnUpdate", function(h, dt) -- count the timer down while hovered
      h.elapsed = h.elapsed + dt
      if h.elapsed < .5 then return end
      h.elapsed = 0
      if GameTooltip:IsOwned(h) then PvPTooltipLines(h) end
   end)
end

local function PvPTooltipOnLeave(holder)
   holder:SetScript("OnUpdate", nil)
   GameTooltip_Hide()
end

-- PvP flag (faction / FFA icon) at the bottom outer corner of the portrait.
-- withTimer: hovering the icon shows the remaining flag time (player only, the timer API
-- only knows the player). Needs Portrait to exist already.
function E.PvP(self, withTimer)
   local pvp = self.Overlay:CreateTexture(nil, "OVERLAY", nil, 1)
   pvp:SetSize(C.PVP_SIZE, C.PVP_SIZE)
   local anchor = self.Portrait or self
   if self.Portrait and self.Portrait.side == "right" then
      pvp:SetPoint("CENTER", anchor, "BOTTOMRIGHT", 0, 2)
   else
      pvp:SetPoint("CENTER", anchor, "BOTTOMLEFT", 0, 2)
   end
   pvp.PostUpdate = PvPKeepAspect
   self.PvPIndicator = pvp

   if withTimer then
      -- hover-only frame over the icon; clicks pass through to the unit frame
      local holder = CreateFrame("Frame", nil, self.Overlay)
      holder:SetAllPoints(pvp)
      holder:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
      holder:EnableMouse(true)
      if holder.SetMouseClickEnabled then holder:SetMouseClickEnabled(false) end
      holder:SetScript("OnEnter", PvPTooltipOnEnter)
      holder:SetScript("OnLeave", PvPTooltipOnLeave)
      holder:Hide()
      pvp.PostUpdate = function(element, unit)
         PvPKeepAspect(element)
         holder.unit = unit
         -- only take the mouse while flagged, so the unit tooltip works there otherwise
         holder:SetShown(PvPFlagged(unit) == true)
      end
   end
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

-- Threat values from UnitDetailedThreatSituation are 100x the threat points addons show.
local THREAT_VALUE_SCALE = 100

-- Threat a unit can still build on the mob before it pulls aggro (110% melee / 130%
-- ranged of the tank, which the scaled percentage already includes). nil when unknown
-- or secret. Second return: the unit's scaled percentage (how close it is to pulling).
local function Headroom(unit, mob)
   local _, _, scaled, _, value = UnitDetailedThreatSituation(unit, mob)
   if U.IsSecret(scaled) or U.IsSecret(value) then return end
   if not scaled or not value or scaled <= 0 then return end
   return value * (100 / scaled - 1), scaled
end

-- The other group member or pet closest to pulling aggro: its headroom, unit and scaled
-- percentage. nil when nobody else is on the threat table.
local function ClosestToPull(mob)
   local best, bestUnit, bestScaled
   local function Check(unit)
      if not U.Exists(unit) then return end
      local isMe = UnitIsUnit(unit, "player")
      if U.IsSecret(isMe) or isMe then return end
      local h, scaled = Headroom(unit, mob)
      if h and (not best or h < best) then
         best, bestUnit, bestScaled = h, unit, scaled
      end
   end
   Check("pet")
   if IsInRaid() then
      for i = 1, 40 do Check("raid" .. i); Check("raidpet" .. i) end
   else
      for i = 1, 4 do Check("party" .. i); Check("partypet" .. i) end
   end
   return best, bestUnit, bestScaled
end

-- Tank view colour by how close the next one is to pulling: green, yellow, red.
local function TankViewColor(self, pct)
   if pct >= 90 then return self.colors.threat[3] end
   if pct >= 70 then return self.colors.threat[1] end
   return C.THREATBAR_LOW
end

-- 1234 threat points -> "1.2k", with the given sign.
local function FormatThreat(sign, raw)
   local v = raw / THREAT_VALUE_SCALE
   if v >= 1000 then
      return ("%s%.1fk"):format(sign, v / 1000)
   end
   return ("%s%d"):format(sign, math.floor(v + .5))
end

-- Thin bar right below the power bar with the player's threat on the current target.
-- Normal view: fill and left text = your threat (0-100%, 100% = you pull), right text =
-- "-1.2k", the threat you can still build before you pull.
-- Tank view, automatically while you hold aggro: fill = how close the group member or pet
-- closest to pulling is (green/yellow/red), left text = their name, right text = "+1.2k",
-- the threat they still need to pull it off you.
-- Uses its own event frame: threat events fire for the mob, not for the player unit.
-- Percentages are secret on bosses; SetValue and formatting accept them, so the normal
-- view still shows the percentage there, colour and threat values need plain numbers.
-- Needs Power to exist already.
function E.ThreatBar(self)
   local bar = CreateFrame("StatusBar", nil, self)
   bar:SetStatusBarTexture(C.TEXTURE)
   bar:SetMinMaxValues(0, 100)
   bar:SetHeight(C.THREATBAR_H)
   local anchor = self.Power or self -- same width as the mana bar, not under the portrait
   bar:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
   bar:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
   U.CreateBackground(bar)
   bar:Hide()
   self.ThreatBar = bar

   local value = CreateText(bar, 10)
   value:SetPoint("LEFT", 3, 0)
   value:SetJustifyH("LEFT")
   bar.value = value

   local delta = CreateText(bar, 10)
   delta:SetPoint("RIGHT", -3, 0)
   delta:SetJustifyH("RIGHT")
   bar.delta = delta

   local function Update()
      if not U.Exists("target") or not UnitCanAttack("player", "target") then
         return bar:Hide()
      end
      local isTanking, status, scaled = UnitDetailedThreatSituation("player", "target")
      if not U.IsSecret(scaled) and scaled == nil then -- not on the threat table
         return bar:Hide()
      end

      if not U.IsSecret(isTanking) and isTanking then
         -- tank view
         local room, unit, pct = ClosestToPull("target")
         pct = pct or 0
         bar:SetStatusBarColor(TankViewColor(self, pct):GetRGB())
         bar:SetValue(pct)
         value:SetText(unit and UnitName(unit) or "")
         delta:SetText(room and FormatThreat("+", room) or "")
      else
         -- normal view
         local color = C.THREATBAR_LOW
         if U.IsSecret(status) then
            color = self.colors.threat[2]
         elseif status and status > 0 then
            color = self.colors.threat[status]
         end
         bar:SetStatusBarColor(color:GetRGB())
         bar:SetValue(scaled)
         value:SetFormattedText("%d%%", scaled) -- formatting a secret number is allowed
         local room = Headroom("player", "target")
         delta:SetText(room and FormatThreat("-", room) or "")
      end
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

-- Gap to leave below player/target for the small frames. Always reserves threat bar and
-- castbar room so pet and targettarget line up even when the player's castbar is provided
-- by another addon.
function E.GapBelow()
   return -(C.THREATBAR_H + C.CASTBAR_H + 7)
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
