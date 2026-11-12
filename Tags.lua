-- Custom tags. They only do arithmetic when a value is plain and fall back to
-- secret-safe Blizzard helpers otherwise (see Util.lua).

local _, ns = ...
local oUF, U = ns.oUF, ns.U

local Methods, Events = oUF.Tags.Methods, oUF.Tags.Events
local IsSecret, Abbreviate, ShortValue = U.IsSecret, U.Abbreviate, U.ShortValue

-- Full health: "5000". Damaged: "3.2k/5000 (64.0%)".
Methods["dafire:health"] = function(unit)
   if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then return end

   local cur, max = UnitHealth(unit), UnitHealthMax(unit)
   if not IsSecret(cur) and not IsSecret(max) then
      if cur == max then
         return ShortValue(max)
      end
      return ("%s/%s (%.1f%%)"):format(ShortValue(cur), ShortValue(max), cur / max * 100)
   end

   -- secret values: no comparison possible, always show the full form
   return ("%s/%s (%d%%)"):format(Abbreviate(cur), Abbreviate(max),
      UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
end
Events["dafire:health"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"

-- Current power, hidden when empty.
Methods["dafire:power"] = function(unit)
   if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then return end

   local cur, max = UnitPower(unit), UnitPowerMax(unit)
   if IsSecret(cur) or IsSecret(max) then
      return C_StringUtil.TruncateWhenZero(cur)
   end
   if cur == 0 or max == 0 then return end
   return ShortValue(cur)
end
Events["dafire:power"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_CONNECTION"

-- The player's combo points on the current target (they live on the player, not the
-- target). Tag it with the extra unit "player" so player power events update it.
Methods["dafire:cpoints"] = function()
   local cp
   if GetComboPoints then
      cp = GetComboPoints("player", "target")
   else
      cp = UnitPower("player", Enum.PowerType.ComboPoints)
   end
   if IsSecret(cp) then
      return C_StringUtil.TruncateWhenZero(cp)
   end
   if cp and cp > 0 then
      return cp
   end
end
Events["dafire:cpoints"] = "UNIT_POWER_FREQUENT PLAYER_TARGET_CHANGED"

-- Red colour code when the current target is hostile and attacking the player, else "".
-- Pure unit comparison, so it stays usable on bosses where threat values are secret.
-- Use as "[dafire:aggro][name]|r".
Methods["dafire:aggro"] = function()
   local hostile = UnitCanAttack("player", "target")
   local onMe = UnitIsUnit("targettarget", "player")
   if IsSecret(hostile) or IsSecret(onMe) then return end
   if hostile and onMe then
      return "|cffff3030"
   end
end
Events["dafire:aggro"] = "PLAYER_TARGET_CHANGED UNIT_TARGET UNIT_THREAT_SITUATION_UPDATE"

-- The player's threat on the unit as "85%". Percentages are secret on bosses, but a
-- secret number can still be formatted and shown. Nothing when not on the threat table.
Methods["dafire:threat"] = function(unit)
   if not U.Exists(unit) or not UnitCanAttack("player", unit) then return end
   local isTanking, _, scaled = UnitDetailedThreatSituation("player", unit)
   if scaled == nil then return end
   if not IsSecret(isTanking) and isTanking then
      return "100%"
   end
   return ("%d%%"):format(scaled)
end
Events["dafire:threat"] = "UNIT_THREAT_LIST_UPDATE UNIT_THREAT_SITUATION_UPDATE PLAYER_TARGET_CHANGED"
