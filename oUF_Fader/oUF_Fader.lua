if not oUF then return end
local strmatch, gmatch = string.match, string.gmatch
local objects, addon = {}, CreateFrame("Frame")
-------------------
--Built-in events--
-------------------
local events = setmetatable({
	Combat = "PLAYER_REGEN_ENABLED:PLAYER_REGEN_DISABLED",
	PlayerTarget = "PLAYER_TARGET_CHANGED",
	PlayerHostileTarget = "PLAYER_TARGET_CHANGED",
	UnitTarget = "UNIT_TARGET",
	UnitHostileTarget = "UNIT_TARGET",
	Resting = "PLAYER_UPDATE_RESTING",
	Flying = "UNIT_FLAGS",
	PlayerTaxi = "UNIT_FLAGS",
	UnitTaxi = "UNIT_FLAGS",
	PlayerMaxHealth = "UNIT_HEALTH",
	UnitMaxHealth = "UNIT_HEALTH",
	PlayerMaxMana = "UNIT_MANA",
	UnitMaxMana = "UNIT_MANA",
	Stealth = "UPDATE_STEALTH"
}, {__index = function(events, k)
	local cond = strmatch(k, "not(.+)")
	assert(rawget(events, cond), format("Missing event for condition %s", k))
	events[k] = events[cond]
	return events[cond]
end})

------------------------
--Built-in Conditions--
------------------------
local conditions = setmetatable({
	PlayerHostileTarget = function() return UnitCanAttack("player", "target") end,
	UnitHostileTarget = function(obj, unit) return unit and UnitCanAttack(unit, unit.."target") end,
	PlayerTarget = function() return UnitExists("target") end,
	UnitTarget = function(obj, unit) return unit and UnitExists(unit.."target") end,
	PlayerTaxi = function() return UnitOnTaxi("player") end,
	UnitTaxi = function(obj, unit) return unit and UnitOnTaxi(unit) end,
	UnitMaxHealth = function(obj, unit) return unit and not UnitIsDeadOrGhost(unit) and UnitHealth(unit) == UnitHealthMax(unit) end,
	PlayerMaxHealth = function() return not UnitIsDeadOrGhost("player") and UnitHealth("player") == UnitHealthMax("player") end,
	UnitMaxMana = function(obj, unit) return not UnitIsDeadOrGhost(unit) and UnitMana(unit) == UnitManaMax(unit) end,
	PlayerMaxMana = function() return not UnitIsDeadOrGhost("player") and UnitMana("player") == UnitManaMax("player") end,
	Stealth = IsStealthed,
	Flying = IsFlying,
	Resting = IsResting,
	Combat = InCombatLockdown
}, {__index = function(t, k)
	local cond = strmatch(k, "not(.+)")
	assert(rawget(t, cond), format("Missing condition %s", k))
	t[k] = function(...)
		return not t[cond](...)
	end
	return t[k]
end})

-------------------------------
--Make your own Condition--
-------------------------------
function addon:RegisterCondition(name, func, event)
	assert(type(name) == "string", format("Bad argument #1 to \"RegisterCondition\" (string expected, got %s)", type(name)))
	assert(type(func) == "function", format("Bad argument #2 to \"RegisterCondition\" (function expected, got %s)", type(func)))
	assert(type(event) == "string", format("Bad argument #3 to \"RegisterCondition\" (string expected, got %s)", type(event)))

	conditions[name] = func
	events[name] = event
end

------------------------------
--Update the Alpha or obj--
------------------------------
local function UpdateAlpha(obj)
	local alpha
	for priority, tbl in ipairs(obj.Fader) do
		for cond, condalpha in pairs(tbl) do
			if conditions[cond](obj, obj.unit) then
				alpha = not alpha and condalpha or condalpha > alpha and condalpha or alpha
			end
		end
		if alpha then
			break
		end
	end
	
	alpha = alpha or obj.NormalAlpha
	if obj.Range then
		obj.inRangeAlpha = alpha
		obj.outsideRangeAlpha = alpha * obj.outsideRangeAlphaPerc
	end
	obj:SetAlpha(alpha)
end

local t = 0
local function OnUpdate(addon, el) -- I do this because it's easier than passing events to conditions
	t = t + el
	if t > 0.1 then
		t = 0
		for i, v in ipairs(objects) do
			UpdateAlpha(v)
		end
		addon:Hide()
	end
end

oUF:RegisterInitCallback(
	function(obj)
		local F = obj.Fader
		if F then
			for _, tbl in ipairs(F) do
				for name in pairs(tbl) do
					for event in gmatch(events[name], "[^:]+") do
						addon:RegisterEvent(event)
					end
				end
			end
			
			obj.NormalAlpha = obj.NormalAlpha or obj:GetAlpha()
			obj.outsideRangeAlphaPerc = obj.outsideRangeAlphaPerc or obj.outsideRangeAlpha
			UpdateAlpha(obj)
			objects[#objects + 1] = obj
		end
	end
)
addon:SetScript("OnEvent", addon.Show)
addon:SetScript("OnUpdate", OnUpdate)

addon.Conditions = conditions
addon.Events = events
oUF.Fader = addon
