-- oUF_Dafire v3: port of the 2010 layout (oUF 1.5 / Cataclysm) to oUF 14 on WoW Forever.
-- Originally inspired by oUF_Lily.
--
-- Files (load order, see oUF_Dafire.toc):
--   Init.lua      namespace setup, oUF lookup
--   Config.lua    sizes, toggles, media           -> ns.C
--   Util.lua      secret-safe helpers, widgets    -> ns.U
--   Tags.lua      custom oUF tags (dafire:*)
--   Elements.lua  building blocks per element     -> ns.E
--   Layout.lua    styles per unit, registration   -> ns.StyleFor
--   Spawn.lua     frame placement (oUF:Factory)

local _, ns = ...

local oUF = ns.oUF or _G.oUF
assert(oUF, "oUF_Dafire: oUF not found. Install and enable the oUF addon.")
ns.oUF = oUF
