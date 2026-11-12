local _, ns = ...

local C = {}
ns.C = C

-- Toggles
C.SHOW_PARTY = true -- set to false when another addon (e.g. HealBot) handles the party

-- Overall size of all frames incl. texts and auras (1 = original size)
C.SCALE = 1

-- Frame sizes
C.BIG_W, C.BIG_H = 250, 50     -- player, target, party
C.SMALL_W, C.SMALL_H = 120, 40 -- pet, targettarget
C.CASTBAR_H = 14
C.THREATBAR_H = 5 -- threat bar below the player frame
C.THREATBAR_LOW = CreateColor(.3, .8, .3) -- threat bar colour while below 100%

-- Target auras
C.AURA_SIZE, C.AURA_SPACING = 18, 1
C.DEBUFF_SIZE = 27 -- 1.5x the buff size
C.BUFFS_PER_ROW, C.BUFF_ROWS = 8, 3
C.DEBUFFS_PER_ROW, C.MAX_DEBUFFS = 10, 40

-- Media (LibSharedMedia is used when present)
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local PATH = [[Interface\AddOns\oUF_Dafire\]]

C.FONT = LSM and LSM:Fetch("font", "Calibri", true) or PATH .. [[font.ttf]]
C.TEXTURE = LSM and LSM:Fetch("statusbar", "Smudge", true) or PATH .. [[textures\statusbar]]
C.THREAT_TEXTURE = PATH .. [[textures\threat]]
C.SPARK_TEXTURE = [[Interface\CastingBar\UI-CastingBar-Spark]]
