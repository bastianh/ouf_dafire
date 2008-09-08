local height, width, outerborder, innerborder = 34, 170, 1, 1

local function Debug(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99oUF_dafire|r:", ...)) end

local wotlk = select(4, GetBuildInfo()) >= 3e4

local UnitReactionColor = UnitReactionColor

local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
local font = LSM and LSM:Fetch("font","Calibri") or "Interface\\AddOns\\oUF_Dafire\\font.ttf" 
local texture = LSM and LSM:Fetch("statusbar","Smudge") or [[Interface\AddOns\oUF_Dafire\textures\statusbar]]

local playerClass = select(2, UnitClass("player")) -- combopoints for druid/rogue

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

local classification = {
	worldboss = 'B',
	rareelite = 'R',
	elite = '+',
	rare = 'r',
	normal = '',
	trivial = 't',
}

local getDifficultyColor = function(level)
	local levelDiff = level - UnitLevel("player")
	if levelDiff >= 5 then
		return 1.00, 0.10, 0.10
	elseif levelDiff >= 3 then
		return 1.00, 0.50,0.25
	elseif levelDiff >= -2 then
		return 1.00, 1.00, 1.00
	elseif -levelDiff <= GetQuestGreenRange() then
		return 0.25, 0.75, 0.25
	end
	return 0.50, 0.50, 0.50
end

local updateLevelString = function(self, event, unit)
	if(unit ~= self.unit) then return end

	local level = UnitLevel(unit)
	
	if UnitCanAttack("player", unit) then
		self.Level:SetTextColor(getDifficultyColor(level))
	else
		self.Level:SetTextColor(1, 1, 1)
	end
	
	if(level == -1) then
		level = '??'
	end

	self.Level:SetFormattedText("%s%s",classification[UnitClassification(unit)],level)
end

local scaleDebuffs = function(self, unit, aura)
	local debuffs = self.Debuffs
	local newscale = 1
	local debuffcount = debuffs.visibleDebuffs
	if debuffcount == debuffs.debuffcount then return end
	if debuffcount < 2 then newscale = 1.5
	elseif debuffcount > 8 then newscale = 1
	elseif debuffcount < 4 then newscale = 1.4
	else newscale = 1.2
	end
	if newscale == debuffs.scale then return end
	debuffs.scale = newscale
	debuffs:SetScale(newscale)
	--Debug("Debuffs Setscale",tostring(newscale))
end

--[[
local updateInfoString = function(self, event, unit)
	if(unit ~= self.unit) then return end

	local level = UnitLevel(unit)
	if(level == -1) then
		level = '??'
	end

	local class, rclass = UnitClass(unit)
	local color = RAID_CLASS_COLORS[rclass]
	if(not UnitIsPlayer(unit)) then
		class = UnitCreatureFamily(unit) or UnitCreatureType(unit)
	end

	local happiness
	if(unit == 'pet') then
		happiness = GetPetHappiness()
		if(happiness == 1) then
			happiness = ":<"
		elseif(happiness == 2) then
			happiness = ":|"
		elseif(happiness == 3) then
			happiness = ":D"
		end
	end

	self.Info:SetFormattedText(
		"L%s%s |cff%02x%02x%02x%s|r %s",
		level,
		classification[UnitClassification(unit)],
		color.r * 255, color.g * 255, color.b * 255,
		class,
		happiness or ''
	)
end
]]


local siValue = function(val)
	if(val >= 1e4) then
		return ("%.1fk"):format(val / 1e3)
	else
		return val
	end
end

local PostUpdateHealth = function(self, event, unit, bar, min, max)
	if wotlk and self.Threat then
		self.Threat:SetFormattedText("%.1f%%", select(3,UnitDetailedThreatSituation("player", "target")))
	end
	if(UnitIsDead(unit)) then
		bar.value:SetText"Dead"
	elseif(UnitIsGhost(unit)) then
		bar.value:SetText"Ghost"
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText"Offline"
	else
		if unit == "targettarget" then
			bar.value:SetFormattedText("%.1f%%", min/max*100)
		else
			if max == 100 then
				bar.value:SetFormattedText('%s%%', min)
			elseif max == min then
				bar.value:SetFormattedText('%s', max)
			else
				bar.value:SetFormattedText('%s/%s (%.1f%%)', siValue(min), siValue(max), min/max*100)
			end
		end
	end
end

local PostUpdatePower = function(self, event, unit, bar, min, max)
	if(min == 0) then
		bar.value:SetText()
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText()
	else
		bar.value:SetFormattedText('%s/%s', siValue(min), siValue(max))
	end
end

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
	--edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
	--insets = {left = 4, right = 4, top = 4, bottom = 4},
}

local func = function(settings, self, unit)
	local width = settings["initial-width"]
	local height = settings["initial-height"] 	
	
	self.menu = menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(.3, .3, .3, 1)

	-- Health bar
	local hp = CreateFrame"StatusBar"
	hp:SetStatusBarTexture(texture)

	hp:SetParent(self)
	hp.colorTapping = true
	hp.colorClass = true
	hp.colorHappiness = true
	hp.colorReaction = true
	hp.colorSmooth = true
	self.Health = hp

	local hpp = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if unit == "targettarget" then
		hpp:SetPoint("RIGHT",hp, -1*outerborder, 0)
		hpp:SetJustifyH"RIGHT"	
	else
		hpp:SetAllPoints(hp)
		hpp:SetJustifyH"CENTER"
	end
	hpp:SetFont(font, 12)
	hpp:SetTextColor(1, 1, 1)
	hp.value = hpp
	self.PostUpdateHealth = PostUpdateHealth

--[[
	-- Health bar background
	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(texture)
	--hpbg:SetTexture(0, 0, 0, .5)
	hp.bg = hpbg
]]

	-- Threat Display
	if (unit == "targettarget") then
	
		local threat = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	
		threat:SetFont(font, 12)
		threat:SetTextColor(1, 1, 1)
		threat:SetWidth(width-15)
		threat:SetHeight(12)
	
		threat:SetPoint("LEFT",hp, outerborder, 0)
		threat:SetJustifyH"LEFT"	
	
		threat.unit = "target"
		--threat:SetText("XXX%")
	
		self.Threat = threat
	end

	-- Portrait
	if unit == "target" or unit == "player"  or (not unit) then
		local portrait = CreateFrame("PlayerModel", nil, self)
		portrait:SetScript("OnShow",function() this:SetCamera(0) end)
		portrait:SetWidth(height-2*outerborder)
		portrait:SetHeight(height-2*outerborder)
		portrait.type = "3D"
		if unit == "target" then	
			portrait:SetPoint("TOPRIGHT", -1*outerborder, -1*outerborder)
			portrait.side = "right"
		else
			portrait:SetPoint("TOPLEFT", outerborder, -1*outerborder)
			portrait.side = "left"
		end
		self.Portrait = portrait
	end
	
	-- Unit name
	if not settings.noname then
		local name = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		
		if unit == "targettarget" then
			name:SetJustifyH"CENTER"
			name:SetPoint("BOTTOM", hp, "TOP" ,0 ,-5)
		elseif unit == "target" then
			name:SetJustifyH"RIGHT"
			name:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT",0, -6)
		else
			name:SetJustifyH"LEFT"
			name:SetPoint("BOTTOMLEFT", self, "TOPLEFT",0, -6)
		end
		name:SetFont(font, 12, "OUTLINE")
		name:SetTextColor(1, 1, 1)
		name:SetWidth(width-15)
		name:SetHeight(12)
	
		self.Name = name
	end

	if settings.power then
		-- Power bar
		local pp = CreateFrame"StatusBar"
		pp:SetStatusBarTexture(texture)
		pp:SetParent(self)
		pp:SetHeight(10)
		if self.Portrait then
			if self.Portrait.side == "left" then
				pp:SetPoint("BOTTOMRIGHT",-1*outerborder,outerborder)
				pp:SetPoint("LEFT",self.Portrait,"RIGHT",innerborder,0)
			else
				pp:SetPoint("BOTTOMLEFT",outerborder,outerborder)
				pp:SetPoint("RIGHT",self.Portrait,"LEFT",innerborder*-1,0)
			end
		else		
			pp:SetPoint("BOTTOMRIGHT",-1*outerborder,outerborder)
			pp:SetPoint("LEFT",outerborder,0)
		end
		pp.colorPower = true
		self.Power = pp
--[[
		-- Power bar background
		local ppbg = pp:CreateTexture(nil, "BORDER")
		ppbg:SetAllPoints(pp)
		ppbg:SetTexture(texture)
		pp.bg = ppbg
]]

		if settings.power ~= "small" then	
			local ppp = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			ppp:SetAllPoints(pp)
			ppp:SetJustifyH"CENTER"
			ppp:SetFont(font, 10)
			ppp:SetTextColor(1, 1, 1)
			
			pp.value = ppp
			self.PostUpdatePower = PostUpdatePower
		else
			pp:SetHeight(6)
		end
		
		--if(unit == "pet") then
		--	self.UNIT_HAPPINESS = updateInfoString
		--	self:RegisterEvent"UNIT_HAPPINESS"
		--end
	end

		-- Level String
	if not settings.nolevel then
		local level = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		if unit == "target" then
			level:SetJustifyH"LEFT"
			level:SetPoint("BOTTOMLEFT", self, "TOPLEFT",0, -6)				
		else
			level:SetJustifyH"RIGHT"
			level:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT",0, -6)		
		end
		level:SetFont(font, 11, "OUTLINE")
		level:SetTextColor(1, 1, 1)		
		self.Level = level
		self.UNIT_LEVEL = updateLevelString
		self:RegisterEvent"UNIT_LEVEL"
	end
	
	if unit=="target" and playerClass == "ROGUE" or playerClass == "DRUID" then
		local cpoints = self:CreateFontString(nil, "OVERLAY")
		cpoints:SetPoint("CENTER", self, "LEFT", -15, 3)
		cpoints:SetFont(font, 38, "OUTLINE")
		cpoints:SetTextColor(1,1,1)
		cpoints:SetJustifyH("RIGHT")
		self.CPoints = cpoints
	end


	if(unit == 'target') or (unit == 'targettarget') then
		if (unit == 'target') then
			local buffs = CreateFrame("Frame", nil, self)
			buffs:SetPoint("TOPLEFT", self, "TOPRIGHT")
			buffs:SetHeight(18*3)
			buffs:SetWidth(18*8)
			buffs.size = 18
			buffs.num = 8*3
			buffs.initialAnchor = "TOPLEFT"
			buffs['growth-y'] = "DOWN"
			self.Buffs = buffs
		end
		
		-- Debuffs
		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
		debuffs:SetHeight(18*4)
		debuffs:SetWidth(18*10)
		debuffs['growth-y'] = "DOWN"
		debuffs.initialAnchor = "TOPLEFT"
		debuffs.size = 18
		debuffs.showDebuffType = true
		if (unit == 'targettarget') then
			debuffs.num = 10
		else -- target
			debuffs.num = 40
			self.PostUpdateAura = scaleDebuffs
		end
		
		self.Debuffs = debuffs
		
	elseif(unit ~= 'player') then
		-- Buffs
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
		buffs:SetHeight(17)
		buffs:SetWidth(width)

		buffs.size = 17
		buffs.num = math.floor(width / buffs.size + .5)

		self.Buffs = buffs

		-- Debuffs
		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetPoint("BOTTOM", self, "TOP")
		debuffs:SetHeight(20)
		debuffs:SetWidth(width)

		debuffs.initialAnchor = "TOPLEFT"
		debuffs.size = 20
		debuffs.showDebuffType = true
		debuffs.num = math.floor(width / debuffs.size + .5)

		self.Debuffs = debuffs
	elseif (unit == 'player') then
		self:RegisterEvent"PLAYER_UPDATE_RESTING"
		self.PLAYER_UPDATE_RESTING = function(self)
			if(IsResting()) then
				self:SetBackdropBorderColor(.3, .3, .8)
			else
				local color = UnitReactionColor[UnitReaction(unit, 'player')]
				self:SetBackdropBorderColor(color.r, color.g, color.b)
			end
		end
	end

	local leader = self:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(16)
	leader:SetWidth(16)
	leader:SetPoint("BOTTOM", self, "TOP", 0, -5)
	leader:SetTexture[[Interface\GroupFrame\UI-Group-LeaderIcon]]
	self.Leader = leader

	-- Range fading on party
	if(not unit) then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .4
	end
	
	if self.Portrait then
		if self.Portrait.side =='left' then
			hp:SetPoint("TOPLEFT", self.Portrait, "TOPRIGHT",innerborder,0)
			if self.Power then hp:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT",0,innerborder)
			else hp:SetPoint("BOTTOMRIGHT", -1*outerborder, outerborder) end
		else
			hp:SetPoint("TOPRIGHT", self.Portrait, "TOPLEFT",innerborder*-1,0)
			if self.Power then hp:SetPoint("BOTTOMLEFT", self.Power, "TOPLEFT",0,innerborder)
			else hp:SetPoint("BOTTOMLEFT", -1*outerborder, outerborder) end
		end
	else
		hp:SetPoint("TOPLEFT",outerborder,-1*outerborder)
		if self.Power then
			hp:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT", 0, innerborder)
		else
			hp:SetPoint("BOTTOMRIGHT", -1*outerborder, outerborder)
		end
	end
end

------------------------------------------------------------------------------
	
oUF:RegisterStyle("Normal", setmetatable({
	["initial-width"] = width,
	["initial-height"] = height,
	["power"] = 'full'
}, {__call = func}))

oUF:RegisterStyle("Pet", setmetatable({
	["initial-width"] = 80,
	["initial-height"] = height - 12,
	["power"] = 'small',
	["noname"] = true,
	["nolevel"] = true
}, {__call = func}))

oUF:RegisterStyle("Small", setmetatable({
	["initial-width"] = width,
	["initial-height"] = height - 14,
	["nolevel"] = true
}, {__call = func}))

-- hack to get our level information updated.
oUF:RegisterSubTypeMapping"UNIT_LEVEL"

oUF:SetActiveStyle"Normal"
-- :Spawn(unit, frame_name, isPet) --isPet is only used on headers.
local player = oUF:Spawn"player"
player:SetPoint("RIGHT", UIParent, "BOTTOM", -15, 200)

local target = oUF:Spawn"target"
target:SetPoint("LEFT", UIParent, "BOTTOM", 15, 200)

local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("TOPLEFT", 30, -30)
party:SetManyAttributes(
	"showParty", true,
	"yOffset", -40,
	"xOffset", -40,
	'maxColumns', 2,
	'unitsPerColumn', 2,
	'columnAnchorPoint', 'LEFT',
	'columnSpacing', 15
)
party:Show()

oUF:SetActiveStyle"Pet"
local pet = oUF:Spawn"pet"
pet:SetPoint('TOPLEFT', player, 'BOTTOMLEFT',0,-2)

oUF:SetActiveStyle"Small"
local tot = oUF:Spawn"targettarget"
tot:SetPoint("BOTTOM", 0, 250)

tt = tot