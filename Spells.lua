local addonName, CombatTracker = ...

if not CombatTracker then return end
if CombatTracker.profile then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
local debug = CT.debug
local hasteCD = CT.hasteCD
--------------------------------------------------------------------------------
-- Power Tables
--------------------------------------------------------------------------------
CT.spells = {}

CT.powerTypes = {
  [0] = "SPELL_POWER_MANA",
  [1] = "SPELL_POWER_RAGE",
  [2] = "SPELL_POWER_FOCUS",
  [3] = "SPELL_POWER_ENERGY",
  [4] = "SPELL_POWER_COMBO_POINTS",
  [5] = "SPELL_POWER_RUNES",
  [6] = "SPELL_POWER_RUNIC_POWER",
  [7] = "SPELL_POWER_SOUL_SHARDS",
  [8] = "SPELL_POWER_ECLIPSE",
  [9] = "SPELL_POWER_HOLY_POWER",
  [10] = "SPELL_POWER_ALTERNATE_POWER",
  [11] = "SPELL_POWER_DARK_FORCE",
  [12] = "SPELL_POWER_CHI",
  [13] = "SPELL_POWER_SHADOW_ORBS",
  [14] = "SPELL_POWER_BURNING_EMBERS",
  [15] = "SPELL_POWER_DEMONIC_FURY",
  ["SPELL_POWER_MANA"] = 0,
  ["SPELL_POWER_RAGE"] = 1,
  ["SPELL_POWER_FOCUS"] = 2,
  ["SPELL_POWER_ENERGY"] = 3,
  ["SPELL_POWER_COMBO_POINTS"] = 4,
  ["SPELL_POWER_RUNES"] = 5,
  ["SPELL_POWER_RUNIC_POWER"] = 6,
  ["SPELL_POWER_SOUL_SHARDS"] = 7,
  ["SPELL_POWER_ECLIPSE"] = 8,
  ["SPELL_POWER_HOLY_POWER"] = 9,
  ["SPELL_POWER_ALTERNATE_POWER"] = 10,
  ["SPELL_POWER_DARK_FORCE"] = 11,
  ["SPELL_POWER_CHI"] = 12,
  ["SPELL_POWER_SHADOW_ORBS"] = 13,
  ["SPELL_POWER_BURNING_EMBERS"] = 14,
  ["SPELL_POWER_DEMONIC_FURY"] = 15,
}

CT.powerTypesFormatted = {
  [0] = "Mana",
  [1] = "Rage",
  [2] = "Focus",
  [3] = "Energy",
  [4] = "Combo Points",
  [5] = "Runes",
  [6] = "Runic Power",
  [7] = "Soul Shards",
  [8] = "Eclipse",
  [9] = "Holy Power",
  [10] = "Alternate Power",
  [11] = "Dark Force",
  [12] = "Chi",
  [13] = "Shadow Orbs",
  [14] = "Burning Embers",
  [15] = "Demonic Fury",
}
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
-- This amazing list was completely done by the developer/developers of the addon Details!, which can be found at http://www.curse.com/addons/wow/details
-- This must have taken a lot of time to put together... Thank you very much for doing all this work!

-- RE.ClassColors = {
-- 	["HUNTER"] = "AAD372",
-- 	["WARLOCK"] = "9482C9",
-- 	["PRIEST"] = "FFFFFF",
-- 	["PALADIN"] = "F48CBA",
-- 	["MAGE"] = "68CCEF",
-- 	["ROGUE"] = "FFF468",
-- 	["DRUID"] = "FF7C0A",
-- 	["SHAMAN"] = "0070DD",
-- 	["WARRIOR"] = "C69B6D",
-- 	["DEATHKNIGHT"] = "C41E3A",
-- 	["MONK"] = "00FF96",
-- };

-- RE.RaceIconCoords = {
-- 	["HUMAN_MALE"] = {0, 0.125, 0, 0.25},
-- 	["DWARF_MALE"] = {0.125, 0.25, 0, 0.25},
-- 	["GNOME_MALE"] = {0.25, 0.375, 0, 0.25},
-- 	["NIGHT ELF_MALE"] = {0.375, 0.5, 0, 0.25},
-- 	["NIGHTELF_MALE"] = {0.375, 0.5, 0, 0.25},
-- 	["TAUREN_MALE"] = {0, 0.125, 0.25, 0.5},
-- 	["UNDEAD_MALE"] = {0.125, 0.25, 0.25, 0.5},
-- 	["SCOURGE_MALE"] = {0.125, 0.25, 0.25, 0.5},
-- 	["TROLL_MALE"] = {0.25, 0.375, 0.25, 0.5},
-- 	["ORC_MALE"] = {0.375, 0.5, 0.25, 0.5},
-- 	["BLOOD ELF_MALE"] = {0.5, 0.625, 0.25, 0.5},
-- 	["BLOODELF_MALE"] = {0.5, 0.625, 0.25, 0.5},
-- 	["DRAENEI_MALE"] = {0.5, 0.625, 0, 0.25},
-- 	["GOBLIN_MALE"] = {0.625, 0.750, 0.25, 0.5},
-- 	["WORGEN_MALE"] = {0.625, 0.750, 0, 0.25},
-- 	["PANDAREN_MALE"] = {0.750, 0.875, 0, 0.25},
-- };

-- RE.ClassIconCoords = {
-- 	["WARRIOR"] = {0, 0.25, 0, 0.25},
-- 	["MAGE"] = {0.25, 0.49609375, 0, 0.25},
-- 	["ROGUE"] = {0.49609375, 0.7421875, 0, 0.25},
-- 	["DRUID"] = {0.7421875, 0.98828125, 0, 0.25},
-- 	["HUNTER"] = {0, 0.25, 0.25, 0.5},
-- 	["SHAMAN"] = {0.25, 0.49609375, 0.25, 0.5},
-- 	["PRIEST"] = {0.49609375, 0.7421875, 0.25, 0.5},
-- 	["WARLOCK"] = {0.7421875, 0.98828125, 0.25, 0.5},
-- 	["PALADIN"] = {0, 0.25, 0.5, 0.75},
-- 	["DEATHKNIGHT"] = {0.25, 0.49609375, 0.5, 0.75},
-- 	["MONK"] = {0.49609375, 0.7421875, 0.5, 0.75},
-- };

CT.spellBlacklist = {
  [82327] = "Holy Power",
}

CT.uptimeBlacklist = {
  [186403] = true, -- Sign of Battle (Honor bonus event)
  [77769] = true, -- Trap Launcher
  [155347] = true, -- Shamanstone: Spirit of the Wolf
  [93828] = true, -- Silvermoon Champion (Blood Elf tabard)
  [186404] = true, -- Sign of the Emissary (Reputation bonus event)
  [186406] = true, -- Sign of the Critter (Pet battle bonus event)
  [186400] = true, -- Sign of Apexis (Apexis bonus event)
}

if ignore then
  local others = {
    "Healing increased by",
    "Absorbing up to 75 magic damage", -- NOTE
    "granting an additional",
    "increases healing",
    "absorbing up to",
    "healing received increased",
    "maximum health increased",
    "immune to stun effects",
    "Leech increased by",
    "Armor increased by",
    "Deflecting all attacks",
    "Avoiding all attacks",
    "Attacks that deal damage equal to 15% or more of your total health are reduced by half",
    "All damage and healing caused increased by",
    "Abilities that generate Holy Power deal 30% additional damage and healing",
    "Haste, Critical Strike, Mastery, Multistrike, Versatility, and Bonus Armor increased by",
    "Healing done increased by",
    "Damage done increased by",
    "Healing increased by",
    "mana cost of spells reduced by",
    "Haste increased by",
    "Dodge chance increased by",
    "Damage taken from area-of-effect attacks reduced by", -- Feint
    "Resisting all harmful spells", -- Cloak
    "Able to move while casting all",
    "Absorbed 0 damage", -- 110913 dark-bargain, 50% DR
    "Mastery increased by",
    "Critical strike chance increased by",
    "Healing received increased by",
    "Absorbs 400 damage",
    "Able to move while casting",
    "Stunned",
    "Parry chance increased by",
    "Maximum health increased by",
    "Healing received increased by",
    "Maximum health increased by",
  }
end

CT.spells.schoolColors = {
  [1] = {name = "Physical", formated = "|cFFFFFF00Physical|r", hex = "FFFFFF00", rgb = {255, 255, 0}, decimals = {1.00, 1.00, 0.00}},
  [2] = {name = "Holy", formated = "|cFFFFE680Holy|r", hex = "FFFFE680", rgb = {255, 230, 128}, decimals = {1.00, 0.90, 0.50}},
  [4] = {name = "Fire", formated = "|cFFFF8000Fire|r", hex = "FFFF8000", rgb = {255, 128, 0}, decimals = {1.00, 0.50, 0.00}},
  [8] = {name = "Nature", formated = "|cFFbeffbeNature|r", hex = "FFbeffbe", rgb = {190, 190, 190}, decimals = {0.7451, 1.0000, 0.7451}},
  [16] = {name = "Frost", formated = "|cFF80FFFFFrost|r", hex = "FF80FFFF", rgb = {128, 255, 255}, decimals = {0.50, 1.00, 1.00}},
  [32] = {name = "Shadow", formated = "|cFF8080FFShadow|r", hex = "FF8080FF", rgb = {128, 128, 255}, decimals = {0.50, 0.50, 1.00}},
  [64] = {name = "Arcane", formated = "|cFFFF80FFArcane|r", hex = "FFFF80FF", rgb = {255, 128, 255}, decimals = {1.00, 0.50, 1.00}},
  [3] = {name = "Holystrike", formated = "|cFFFFF240Holystrike|r", hex = "FFFFF240", rgb = {255, 64, 64}, decimals = {1.0000, 0.9490, 0.2510}}, --#FFF240
  [5] = {name = "Flamestrike", formated = "|cFFFFB900Flamestrike|r", hex = "FFFFB900", rgb = {255, 0, 0}, decimals = {1.0000, 0.7255, 0.0000}}, --#FFB900
  [6] = {name = "Holyfire", formated = "|cFFFFD266Holyfire|r", hex = "FFFFD266", rgb = {255, 102, 102}, decimals = {1.0000, 0.8235, 0.4000}}, --#FFD266
  [9] = {name = "Stormstrike", formated = "|cFFAFFF23Stormstrike|r", hex = "FFAFFF23", rgb = {175, 35, 35}, decimals = {0.6863, 1.0000, 0.1373}}, --#AFFF23
  [10] = {name = "Holystorm", formated = "|cFFC1EF6EHolystorm|r", hex = "FFC1EF6E", rgb = {193, 110, 110}, decimals = {0.7569, 0.9373, 0.4314}}, --#C1EF6E
  [12] = {name = "Firestorm", formated = "|cFFAFB923Firestorm|r", hex = "FFAFB923", rgb = {175, 35, 35}, decimals = {0.6863, 0.7255, 0.1373}}, --#AFB923
  [17] = {name = "Froststrike", formated = "|cFFB3FF99Froststrike|r", hex = "FFB3FF99", rgb = {179, 153, 153}, decimals = {0.7020, 1.0000, 0.6000}},--#B3FF99
  [18] = {name = "Holyfrost", formated = "|cFFCCF0B3Holyfrost|r", hex = "FFCCF0B3", rgb = {204, 179, 179}, decimals = {0.8000, 0.9412, 0.7020}},--#CCF0B3
  [20] = {name = "Frostfire", formated = "|cFFC0C080Frostfire|r", hex = "FFC0C080", rgb = {192, 128, 128}, decimals = {0.7529, 0.7529, 0.5020}}, --#C0C080
  [24] = {name = "Froststorm", formated = "|cFF69FFAFFroststorm|r", hex = "FF69FFAF", rgb = {105, 175, 175}, decimals = {0.4118, 1.0000, 0.6863}}, --#69FFAF
  [33] = {name = "Shadowstrike", formated = "|cFFC6C673Shadowstrike|r", hex = "FFC6C673", rgb = {198, 115, 115}, decimals = {0.7765, 0.7765, 0.4510}},--#C6C673
  [34] = {name = "Shadowlight (Twilight)", formated = "|cFFD3C2ACShadowlight (Twilight)|r", hex = "FFD3C2AC", rgb = {211, 172, 172}, decimals = {0.8275, 0.7608, 0.6745}},--#D3C2AC
  [36] = {name = "Shadowflame", formated = "|cFFB38099Shadowflame|r", hex = "FFB38099", rgb = {179, 153, 153}, decimals = {0.7020, 0.5020, 0.6000}}, -- #B38099
  [40] = {name = "Shadowstorm (Plague)", formated = "|cFF6CB3B8Shadowstorm (Plague)|r", hex = "FF6CB3B8", rgb = {108, 184, 184}, decimals = {0.4235, 0.7020, 0.7216}}, --#6CB3B8
  [48] = {name = "Shadowfrost", formated = "|cFF80C6FFShadowfrost|r", hex = "FF80C6FF", rgb = {128, 255, 255}, decimals = {0.5020, 0.7765, 1.0000}},--#80C6FF
  [65] = {name = "Spellstrike", formated = "|cFFFFCC66Spellstrike|r", hex = "FFFFCC66", rgb = {255, 102, 102}, decimals = {1.0000, 0.8000, 0.4000}},--#FFCC66
  [66] = {name = "Divine", formated = "|cFFFFBDB3Divine|r", hex = "FFFFBDB3", rgb = {255, 179, 179}, decimals = {1.0000, 0.7412, 0.7020}},--#FFBDB3
  [68] = {name = "Spellfire", formated = "|cFFFF808CSpellfire|r", hex = "FFFF808C", rgb = {255, 140, 140}, decimals = {1.0000, 0.5020, 0.5490}}, --#FF808C
  [72] = {name = "Spellstorm", formated = "|cFFAFB9AFSpellstorm|r", hex = "FFAFB9AF", rgb = {175, 175, 175}, decimals = {0.6863, 0.7255, 0.6863}}, --#AFB9AF
  [80] = {name = "Spellfrost", formated = "|cFFC0C0FFSpellfrost|r", hex = "FFC0C0FF", rgb = {192, 255, 255}, decimals = {0.7529, 0.7529, 1.0000}},--#C0C0FF
  [96] = {name = "Spellshadow", formated = "|cFFB980FFSpellshadow|r", hex = "FFB980FF", rgb = {185, 255, 255}, decimals = {0.7255, 0.5020, 1.0000}},--#B980FF

  [28] = {name = "Elemental", formated = "|cFF0070DEElemental|r", hex = "FF0070DE", rgb = {0, 222, 222}, decimals = {0.0000, 0.4392, 0.8706}},
  [124] = {name = "Chromatic", formated = "|cFFC0C0C0Chromatic|r", hex = "FFC0C0C0", rgb = {192, 192, 192}, decimals = {0.7529, 0.7529, 0.7529}},
  [126] = {name = "Magic", formated = "|cFF1111FFMagic|r", hex = "FF1111FF", rgb = {17, 255, 255}, decimals = {0.0667, 0.0667, 1.0000}},
  [127] = {name = "Chaos", formated = "|cFFFF1111Chaos|r", hex = "FFFF1111", rgb = {255, 17, 17}, decimals = {1.0000, 0.0667, 0.0667}},
}

do
  CT.resetCasts = {
  	[108285] = { -- Call of the Elements
  		[108269] = 1, -- Capacitor Totem
  		[8177] = 1, -- Grounding Totem
  		[51485] = 1, -- Earthgrab Totem
  		[8143] = 1, -- Tremor Totem
  		[5394] = 1, -- Healing Stream Totem
  	},
  	[11129] = { -- Combustion
  		[108853] = 1, -- Inferno Blast
  	},
  	[11958] = { -- coldsnap
  		[45438] = 1, -- iceblock
  		[31661] = 1, -- dragon's breath
  		[12043] = 1, -- presence of mind
  		[120] = 1, -- cone of cold
  		[122] = 1, -- frost nova
  	},
  	[14185] = { --prep
  		[5277] = 1, -- Evasion
  		[2983] = 1, -- Sprint
  		[1856] = 1, -- Vanish
  	},
  	[50334] = { --druid berserk or something
  		[33878] = 1,
  		[33917] = 1,
  	},

    -- 124495 -- Devouring Plague reset?
  }

  CT.resetAuras = {
  	[81162] = { -- Will of the Necropolis
  		48982, -- Rune Tap
  	},
  	[93622] = { -- Mangle! (from lacerate and thrash)
  		33878, -- Mangle
  	},
  	[48518] = { -- lunar eclipse
  		48505, -- Starfall
  	},
  	[50227] = { -- Sword and Board
  		23922, -- Shield Slam
  	},
  	[59578] = { -- The Art of War
  		879, -- Exorcism
  	},
  	[52437] = { -- Sudden Death
  		86346, -- Colossus Smash
  	},
  	[124430] = { -- Divine Insight (Shadow version)
  		8092, -- Mind Blast
  	},
  	[77762] = { -- Lava Surge
  		51505, -- Lava Burst
  	},
  	[93400] = { -- Shooting Stars
  		78674, -- Starsurge
  	},
  	[32216] = { -- Victorious
  		103840, -- Impending Victory
  	},
    [160002] = { -- Enhanced Holy Shock
      20473, -- Holy Shock
    },
    [168980] = { -- Lock and Load
      53301, -- Explosive Shot
    },
    [121152] = { -- Blindside
      111240, -- Dispatch
    },
  }

  local spellBlacklist = {
  	[50288] = 1, -- Starfall damage effect, causes the cooldown to be off by 10 seconds and prevents proper resets when tracking by name.
  }

  CT.spells.potion = {}
  do
    local t = CT.spells.potion
		t[105702] = true -- Jade Serpent
		t[105706] = true -- Mogu Power
		t[105697] = true -- Virmen's Bite
		t[105698] = true -- Montains

		t[156426] = true -- Draenic Intellect Potion
		t[156430] = true -- Draenic Armor Potion
		t[156423] = true -- Draenic Agility Potion
		t[156428] = true -- Draenic Strength Potion
		t[175821] = true -- Draenic Oure Rage Potion
	end

  -- CT.spells.SpecSpellList = {
  --
	-- 	-- Unholy Death Knight:
	-- 	[165395] = 252, -- Necrosis
	-- 	[49206] = 252, -- Summon Gargoyle
	-- 	[63560] = 252, -- Dark Transformation
	-- 	[85948] = 252, -- Festering Strike
	-- 	[49572] = 252, -- Shadow Infusion
	-- 	[55090] = 252, -- Scourge Strike
	-- 	[46584] = 252, -- Raise Dead
	-- 	[51160] = 252, -- Ebon Plaguebringer
  --
	-- 	-- Frost Death Knight:
	-- 	[130735] = 251, -- Soul Reaper
	-- 	[51271] = 251, -- Pillar of Frost
	-- 	[49020] = 251, -- Obliterate
	-- 	[49143] = 251, -- Frost Strike
	-- 	[49184] = 251, -- Howling Blast
  --
	-- 	-- Blood Death Knight:
	-- 	[165394] = 250, -- Runic Strikes
	-- 	[114866] = 250, -- Soul Reaper
	-- 	[49222] = 250, -- Bone Shield
	-- 	[55233] = 250, -- Vampiric Blood
	-- 	[49028] = 250, -- Dancing Rune Weapon
	-- 	[48982] = 250, -- Rune Tap
	-- 	[56222] = 250, -- Dark Command
  --
	-- 	-- Balance Druid:
	-- 	[152221] = 102, -- Stellar Flare
	-- 	[88747] = 102, -- Wild Mushroom
	-- 	[33605] = 102, -- Astral Showers
	-- 	[48505] = 102, -- Starfall
	-- 	[112071] = 102, -- Celestial Alignment
	-- 	[78675] = 102, -- Solar Beam
	-- 	[93399] = 102, -- Shooting Stars
	-- 	[78674] = 102, -- Starsurge
	-- 	[2912] = 102, -- Starfire
  --
	-- 	-- Feral Druid:
	-- 	[171746] = 103, -- Claws of Shirvallah
	-- 	[22570] = 103, -- Maim
	-- 	[16974] = 103, -- Predatory Swiftness
	-- 	[106785] = 103, -- Swipe
	-- 	[1079] = 103, -- Rip
	-- 	[52610] = 103, -- Savage Roar
	-- 	[5217] = 103, -- Tiger's Fury
	-- 	[1822] = 103, -- Rake
  --
	-- 	-- Guardian Druid:
	-- 	[155835] = 104, -- Bristling Fur
	-- 	[155578] = 104, -- Guardian of Elune
	-- 	[80313] = 104, -- Pulverize
	-- 	[159232] = 104, -- Ursa Major
	-- 	[33745] = 104, -- Lacerate
	-- 	[135288] = 104, -- Tooth and Claw
	-- 	[6807] = 104, -- Maul
	-- 	[62606] = 104, -- Savage Defense
  --
	-- 	-- Restoration Druid:
  --
	-- 	[145518] = 105, -- Genesis
	-- 	[145205] = 105, -- Wild Mushroom
	-- 	[48438] = 105, -- Wild Growth
	-- 	[740] = 105, -- Tranquility
	-- 	[102342] = 105, -- Ironbark
	-- 	[33763] = 105, -- Lifebloom
	-- 	[88423] = 105, -- Nature's Cure
	-- 	[8936] = 105, -- Regrowth
	-- 	[18562] = 105, -- Swiftmend
  --
	-- 	-- Beast Mastery Hunter:
	-- 	[19574] = 253, -- Bestial Wrath
	-- 	[82692] = 253, -- Focus Fire
	-- 	[53257] = 253, -- Cobra Strikes
	-- 	[19574] = 253, -- Bestial Wrath
	-- 	--[34026] = 253, -- Kill Command
	-- 	--[83381] = 253, -- Kill Command
  --
	-- 	-- Marksmanship Hunter:
	-- 	[53209] = 254, -- Chimaera Shot
	-- 	[3045] = 254, -- Rapid Fire
	-- 	[19434] = 254, -- Aimed Shot
  --
	-- 	-- Survival Hunter:
	-- 	[3674] = 255, -- Black Arrow
	-- 	[53301] = 255, -- Explosive Shot
	-- 	[87935] = 255, -- Serpent Sting
  --
	-- 	-- Arcane Mage:
	-- 	[153626] = 62, -- Arcane Orb
	-- 	[114923] = 62, -- Nether Tempest
	-- 	[157980] = 62, -- Supernova
	-- 	[12042] = 62, -- Arcane Power
	-- 	[12051] = 62, -- Evocation
	-- 	[31589] = 62, -- Slow
	-- 	[5143] = 62, -- Arcane Missiles
	-- 	[1449] = 62, -- Arcane Explosion
	-- 	[44425] = 62, -- Arcane Barrage
	-- 	[30451] = 62, -- Arcane Blast
  --
	-- 	-- Fire Mage:
	-- 	[153561] = 63, -- Meteor
	-- 	[11129] = 63, -- Combustion
	-- 	[157981] = 63, -- Blast Wave
	-- 	[44457] = 63, -- Living Bomb
	-- 	[31661] = 63, -- Dragon's Breath
	-- 	[2120] = 63, -- Flamestrike
	-- 	[108853] = 63, -- Inferno Blast
	-- 	[2948] = 63, -- Scorch
	-- 	[133] = 63, -- Fireball
	-- 	[11366] = 63, -- Pyroblast
  --
	-- 	-- Frost Mage:
	-- 	[153595] = 64, -- Comet Storm
	-- 	[112948] = 64, -- Frost Bomb
	-- 	[157997] = 64, -- Ice Nova
	-- 	[84714] = 64, -- Frozen Orb
	-- 	[10] = 64, -- Blizzard
	-- 	[30455] = 64, -- Ice Lance
	-- 	[116] = 64, -- Frostbolt
  --
	-- 	-- Brewmaster Monk:
	-- 	[157676] = 268, -- Chi Explosion
	-- 	[119582] = 268, -- Purifying Brew
	-- 	[115308] = 268, -- Elusive Brew
	-- 	[115295] = 268, -- Guard
	-- 	[115181] = 268, -- Breath of Fire
	-- 	[121253] = 268, -- Keg Smash
	-- 	[115180] = 268, -- Dizzying Haze
  --
	-- 	-- Mistweaver Monk:
	-- 	[115310] = 269, -- Revival
	-- 	[116680] = 269, -- Thunder Focus Tea
	-- 	[115460] = 269, -- Detonate Chi
	-- 	[116670] = 269, -- Uplift
	-- 	[115294] = 269, -- Mana Tea
	-- 	[116849] = 269, -- Life Cocoon
	-- 	[115151] = 269, -- Renewing Mist
	-- 	[124682] = 269, -- Enveloping Mist
	-- 	[115175] = 269, -- Soothing Mist
  --
	-- 	-- Windwalker Monk:
	-- 	[152175] = 270, -- Hurricane Strike
	-- 	[116095] = 270, -- Disable
	-- 	[122470] = 270, -- Touch of Karma
	-- 	[124280] = 270, -- Touch of Karma
	-- 	[128595] = 270, -- Combat Conditioning
	-- 	[101545] = 270, -- Flying Serpent Kick
	-- 	[113656] = 270, -- Fists of Fury
	-- 	[117418] = 270, -- Fists of Fury
  --
	-- 	-- Holy Paladin:
	-- 	[156910] = 65, -- Beacon of Faith
	-- 	[157007] = 65, -- Beacon of Insight
	-- 	[85222] = 65, -- Light of Dawn
	-- 	[31821] = 65, -- Devotion Aura
	-- 	[82326] = 65, -- Holy Light
	-- 	[148039] = 65, -- Sacred Shield
	-- 	[53563] = 65, -- Beacon of Light
	-- 	[82327] = 65, -- Holy Radiance
	-- 	[2812] = 65, -- Denounce
	-- 	[20473] = 65, -- Holy Shock
  --
	-- 	-- Protection Paladin:
	-- 	[53600] = 66, -- Shield of the Righteous
	-- 	[26573] = 66, -- Consecration
	-- 	[119072] = 66, -- Holy Wrath
	-- 	[31935] = 66, -- Avenger's Shield
  --
	-- 	-- Retribution Paladin:
	-- 	[157048] = 70, -- Final Verdict
	-- 	[20164] = 70, -- Seal of Justice
	-- 	[879] = 70, -- Exorcism
	-- 	[53385] = 70, -- Divine Storm
	-- 	[85256] = 70, -- Templar's Verdict
  --
	-- 	-- Discipline Priest:
	-- 	[152118] = 256, -- Clarity of Will
	-- 	[109964] = 256, -- Spirit Shell
	-- 	[62618] = 256, -- Power Word: Barrier
	-- 	[33206] = 256, -- Pain Suppression
	-- 	[81751] = 256, -- Atonement
	-- 	[94472] = 256, -- Atonement (crit)
	-- 	[47753] = 256, -- Divine Aegis
	-- 	[132157] = 256, -- Holy Nova
	-- 	[47750] = 256, -- Penance
  --
	-- 	-- Holy Priest:
	-- 	[155245] = 257, -- Clarity of Purpose
	-- 	[64843] = 257, -- Divine Hymn
	-- 	[34861] = 257, -- Circle of Healing
	-- 	[32546] = 257, -- Binding Heal
	-- 	--[596] = 257, -- Prayer of Healing
	-- 	[126135] = 257, -- Lightwell
	-- 	[139] = 257, -- Renew
	-- 	--[88625] = 257, -- Holy Word: Chastise
  --
	-- 	-- Shadow Priest:
	-- 	--[127632] = 258, -- Cascade
	-- 	--[122121] = 258, -- Divine Star
	-- 	--[120644] = 258, -- Halo
	-- 	[15286] = 258, -- Vampiric Embrace
	-- 	[32379] = 258, -- Shadow Word: Death
	-- 	[73510] = 258, -- Mind Spike
	-- 	[78203] = 258, -- Shadowy Apparitions
	-- 	[34914] = 258, -- Vampiric Touch
	-- 	[2944] = 258, -- Devouring Plague
	-- 	[8092] = 258, -- Mind Blast
	-- 	[15407] = 258, -- Mind Flay
  --
	-- 	-- Assassination Rogue:
	-- 	[79140] = 259, -- Vendetta
	-- 	[111240] = 259, -- Dispatch
	-- 	[32645] = 259, -- Envenom
	-- 	[1329] = 259, -- Mutilate
	-- 	[79134] = 259, -- Venomous Wounds
  --
	-- 	-- Combat Rogue:
	-- 	[51690] = 260, -- Killing Spree
	-- 	[84617] = 260, -- Revealing Strike
  --
	-- 	-- Subtlety Rogue:
	-- 	[53] = 261, -- Backstab
	-- 	[16511] = 261, -- Hemorrhage
  --
	-- 	-- Elemental Shaman:
	-- 	[165399] = 262, -- Elemental Overload
	-- 	[165477] = 262, -- Unleashed Fury
	-- 	[165339] = 262, -- Ascendance
	-- 	[165462] = 262, -- Unleash Flame
	-- 	[170374] = 262, -- Mastery: Molten Earth
	-- 	[61882] = 262, -- Earthquake
	-- 	[77756] = 262, -- Lava Surge
	-- 	[86108] = 262, -- Mail Specialization
	-- 	[88766] = 262, -- Fulmination
	-- 	[60188] = 262, -- Elemental Fury
	-- 	[29000] = 262, -- Elemental Reach
	-- 	[62099] = 262, -- Shamanism
	-- 	[123099] = 262, -- Spiritual Insight
	-- 	[51490] = 262, -- Thunderstorm
	-- 	[8042] = 262, -- Earth Shock
  --
	-- 	-- Enhancement Shaman:
	-- 	[165368] = 263, -- Lightning Strikes
	-- 	[117012] = 263, -- Unleashed Fury
	-- 	[165341] = 263, -- Ascendance
	-- 	[73680] = 263, -- Unleash Elements
	-- 	[77223] = 263, -- Mastery: Enhanced Elements
	-- 	[51533] = 263, -- Feral Spirit
	-- 	[58875] = 263, -- Spirit Walk
	-- 	[51530] = 263, -- Maelstrom Weapon
	-- 	[86099] = 263, -- Mail Specialization
	-- 	[1535] = 263, -- Fire Nova
	-- 	[8190] = 263, -- Magma Totem
	-- 	[166221] = 263, -- Enhanced Weapons
	-- 	[33757] = 263, -- Windfury
	-- 	[17364] = 263, -- Stormstrike
	-- 	[16282] = 263, -- Flurry
	-- 	[86629] = 263, -- Dual Wield
	-- 	[10400] = 263, -- Flametongue
	-- 	[60103] = 263, -- Lava Lash
	-- 	[30814] = 263, -- Mental Quickness
	-- 	[51522] = 263, -- Primal Wisdom
  --
	-- 	-- Restoration Shaman:
	-- 	[157153] = 264, -- Cloudburst Totem
	-- 	[157154] = 264, -- High Tide
	-- 	[165391] = 264, -- Purification
	-- 	[165479] = 264, -- Unleashed Fury
	-- 	[165344] = 264, -- Ascendance
	-- 	[77226] = 264, -- Mastery: Deep Healing
	-- 	[98008] = 264, -- Spirit Link Totem
	-- 	[108280] = 264, -- Healing Tide Totem
	-- 	[77472] = 264, -- Healing Wave
	-- 	[86100] = 264, -- Mail Specialization
	-- 	[51564] = 264, -- Tidal Waves
	-- 	[1064] = 264, -- Chain Heal
	-- 	[16196] = 264, -- Resurgence
	-- 	[974] = 264, -- Earth Shield
	-- 	[52127] = 264, -- Water Shield
	-- 	[77130] = 264, -- Purify Spirit
	-- 	[55453] = 264, -- Telluric Currents
	-- 	[95862] = 264, -- Meditation
	-- 	[16213] = 264, -- Restorative Waves
	-- 	[61295] = 264, -- Riptide
	-- 	[112858] = 264, -- Spiritual Insight
  --
	-- 	-- Affliction Warlock:
	-- 	[152109] = 265, -- Soulburn: Haunt
	-- 	[165367] = 265, -- Eradication
	-- 	[113860] = 265, -- Dark Soul: Misery
	-- 	[77215] = 265, -- Mastery: Potent Afflictions
	-- 	[86121] = 265, -- Soul Swap
	-- 	[48181] = 265, -- Haunt
	-- 	[980] = 265, -- Agony
	-- 	[103103] = 265, -- Drain Soul
	-- 	[27243] = 265, -- Seed of Corruption
	-- 	[117198] = 265, -- Soul Shards
	-- 	[74434] = 265, -- Soulburn
	-- 	[108558] = 265, -- Nightfall
	-- 	[30108] = 265, -- Unstable Affliction
  --
	-- 	--  Demonology Warlock:
	-- 	[157695] = 266, -- Demonbolt
	-- 	[165392] = 266, -- Demonic Tactics
	-- 	[113861] = 266, -- Dark Soul: Knowledge
	-- 	[77219] = 266, -- Mastery: Master Demonologist
	-- 	[171975] = 266, -- Grimoire of Synergy
	-- 	[30146] = 266, -- Summon Felguard
	-- 	[114592] = 266, -- Wild Imps
	-- 	[1949] = 266, -- Hellfire
	-- 	[105174] = 266, -- Hand of Gul'dan
	-- 	[6353] = 266, -- Soul Fire
	-- 	[109151] = 266, -- Demonic Leap
	-- 	[108869] = 266, -- Decimation
	-- 	[104315] = 266, -- Demonic Fury
	-- 	[124913] = 266, -- Doom
	-- 	[103958] = 266, -- Metamorphosis
	-- 	[122351] = 266, -- Molten Core
  --
	-- 	--  Destruction Warlock:
	-- 	[157696] = 267, -- Charred Remains
	-- 	[165363] = 267, -- Devastation
	-- 	[113858] = 267, -- Dark Soul: Instability
	-- 	[77220] = 267, -- Mastery: Emberstorm
	-- 	[120451] = 267, -- Flames of Xoroth
	-- 	[117896] = 267, -- Backdraft
	-- 	[109784] = 267, -- Aftermath
	-- 	[108683] = 267, -- Fire and Brimstone
	-- 	[17877] = 267, -- Shadowburn
	-- 	[80240] = 267, -- Havoc
	-- 	[5740] = 267, -- Rain of Fire
	-- 	[114635] = 267, -- Ember Tap
	-- 	[174848] = 267, -- Searing Flames
	-- 	[348] = 267, -- Immolate
	-- 	[108647] = 267, -- Burning Embers
	-- 	[116858] = 267, -- Chaos Bolt
	-- 	[111546] = 267, -- Chaotic Energy
	-- 	[17962] = 267, -- Conflagrate
	-- 	[29722] = 267, -- Incinerate
  --
	-- 	--  Arms Warrior:
	-- 	[165365] = 71, -- Weapon Mastery
	-- 	[167105] = 71, -- Colossus Smash
	-- 	[12328] = 71, -- Sweeping Strikes
	-- 	[86101] = 71, -- Plate Specialization
	-- 	[1464] = 71, -- Slam
	-- 	[56636] = 71, -- Taste for Blood
	-- 	[12294] = 71, -- Mortal Strike
	-- 	[12712] = 71, -- Seasoned Soldier
	-- 	[772] = 71, -- Rend
	-- 	[174737] = 71, -- Enhanced Rend
  --
	-- 	--  Fury Warrior:
	-- 	[165383] = 72, -- Cruelty
	-- 	[12950] = 72, -- Meat Cleaver
	-- 	[46915] = 72, -- Bloodsurge
	-- 	[86110] = 72, -- Plate Specialization
	-- 	[169679] = 72, -- Furious Strikes
	-- 	[169683] = 72, -- Unquenchable Thirst
	-- 	[81099] = 72, -- Single-Minded Fury
	-- 	[85288] = 72, -- Raging Blow
	-- 	[12323] = 72, -- Piercing Howl
	-- 	[100130] = 72, -- Wild Strike
	-- 	[23881] = 72, -- Bloodthirst
	-- 	[23588] = 72, -- Crazed Berserker
	-- 	[46917] = 72, -- Titan's Grip
  --
	-- 	--  Protection Warrior:
	-- 	[152276] = 73, -- Gladiator's Resolve
	-- 	[159362] = 73, -- Blood Craze
	-- 	[165393] = 73, -- Shield Mastery
	-- 	[114192] = 73, -- Mocking Banner
	-- 	[76857] = 73, -- Mastery: Critical Block
	-- 	[161798] = 73, -- Riposte
	-- 	[84608] = 73, -- Bastion of Defense
	-- 	[1160] = 73, -- Demoralizing Shout
	-- 	[86535] = 73, -- Plate Specialization
	-- 	[871] = 73, -- Shield Wall
	-- 	[169680] = 73, -- Heavy Repercussions
	-- 	[169685] = 73, -- Unyielding Strikes
	-- 	[12975] = 73, -- Last Stand
	-- 	[6572] = 73, -- Revenge
	-- 	[20243] = 73, -- Devastate
	-- 	[2565] = 73, -- Shield Block
	-- 	[161608] = 73, -- Bladed Armor
	-- 	[23922] = 73, -- Shield Slam
	-- 	[46953] = 73, -- Sword and Board
	-- 	[122509] = 73, -- Ultimatum
	-- 	[29144] = 73, -- Unwavering Sentinel
	-- 	[157497] = 73, -- Improved Block
	-- 	[6343] = 73, -- Thunder Clap
	-- 	[71] = 73, -- Defensive Stance
	-- 	[157494] = 73, -- Improved Defensive Stance
	-- 	[57755] = 73, -- Heroic Throw
  --
	-- }

	-- updated on 25/04/2015 (@Tonyleila - WoWInterface)
  CT.spells.CC = {

		--Racials
			[28730]	= true, -- Arcane Torrent (be)
			[47779]	= true, -- Arcane Torrent (be)
			[50613]	= true, -- Arcane Torrent (be)
      [155145] = true, -- Arcane Torrent (be)
			[107079]	= true, -- Quaking Palm (pandaren)
			[20549]	= true, -- War Stomp (tauren)

		-- Death Knight
			[108194]	= true, -- Asphyxiate
			[96294]	= true, -- Chains of ice
			[47481]	= true, -- Gnaw
			[47528]	= true, -- Mind Freeze
			[91797]	= true, -- Monstrous Blow
			[115001]	= true, -- Remorseless Winter (Stunned)
			[47476]	= true, -- Strangulate

		-- Druid
			[33786] 	= true, -- Cyclone
			[339]		= true, -- Entangling Toots
			[45334] 	= true, -- Immobilized (from Wild Charge)
			[99]		= true, -- Incapacitating Roar
			[22570] 	= true, -- Maim
			[102359] 	= true, -- Mass Entanglement
			[5211] 	= true, -- Mighty Bash (talent)
			[163505] 	= true, -- Rake (stealth)
			[106839]	= true, -- Skull Bash
			[81261] 	= true, -- Solar Beam
			[107566] 	= true, -- Staggering Shout
			[16979]	= true, -- Wild Charge (talent)

		-- Hunter
			[117405]	= true, -- Binding Shot
			[64803]	= true, -- Entrapment
			[3355]	= true, -- Freezing trap
			[24394]	= true, -- Intimidation (pet)
			[128405]	= true, -- Narrow Escape
			[136634]	= true, -- Narrow Wscape
			[24335]	= true, -- Wyvern sting
			[19386]	= true, -- Wyvern sting

		-- Mage
			[2139]	= true, -- Counterspell
			[44572]	= true, -- Deep Freeze
			[58534]	= true, -- Deep Freeze
			[31661]	= true, -- Dragon's Breath
			[33395]	= true, -- Freeze (pet)
			[122]		= true, -- Frost Nova
			[102051]	= true, -- Frostjaw
			[157997]	= true, -- Ice Nova
			[111340]	= true, -- Ice Ward
			[118]		= true, -- Polymorph sheep
			[28272]	= true, -- Polymorph pig
			[126819]	= true, -- Polymorph pig 2
			[61305]	= true, -- Polymorph black cat
			[61721]	= true, -- Polymorph rabbit
			[61780]	= true, -- Polymorph turkey
			[28271]	= true, -- Polymorph turtle
			[161354]	= true, -- Polymorph Monkey
			[161353]	= true, -- Polymorph Polar Bear Cub
			[161355]	= true, -- Polymorph Penguin
			[82691]	= true, -- Ring of frost

		-- Monk
			[123393]	= true, -- Breath of Fire
			[119392]	= true, -- Charging Ox Wave
			[116706]	= true, -- Disable
			[120086]	= true, -- Fists of Fury
			[117418]	= true, -- Fists of Fury
			[119381]	= true, -- Leg Sweep
			[115078]	= true, -- Paralysis
			[116705]	= true, -- Spear Hand Strike
			[142895]	= true, -- Incapacitated (ring of peace)

		-- Paladin
			[31935]	= true, -- Avenger's Shield
			[105421]	= true, -- Blinding light
			[105593]	= true, -- Fist of Justice
			[853]		= true, -- Hammer of Justice
			[96231] 	= true, -- Rebuke
			[20066]	= true, -- Repentance
			[145067]	= true, -- Turn Evil

		-- Priest
			[605]		= true, -- Dominate Mind
			[87194]	= true, -- Glyph of Mind Blast
			[88625]	= true, -- Holy Word: Chastise
			[64044]	= true, -- Psychic Horror
			[8122]	= true, -- Psychic scream
			[9484]	= true, -- Shackle undead
			[15487]	= true, -- Silence
			[131556]	= true, -- Sin and Punishment
			[114404]	= true, -- Void Tendril's Grasp

		-- Rogue
			[2094]	= true, -- Blind
			[1833]	= true, -- Cheap shot
			[1330]	= true, -- Garrote
			[1776]	= true, -- Gouge
			[1766]	= true, -- Kick
			[408]		= true, -- Kidney shot
			[6770]	= true, -- Sap
			[76577]	= true, -- Smoke Bomb

		-- Shaman
			[64695]	= true, -- Earthgrab (earthgrab totem)
			[77505]	= true, -- Earthquake
			[51514]	= true, -- Hex
			[118905]	= true, -- Static Charge
			[51490]	= true, -- Thunderstorm
			[57994]	= true, -- Wind Shear

		-- Warlock
			[89766]	= true, -- Axe Toss (Felguard)
			[111397]	= true, -- Blood Horror
			[170996]	= true, -- Debilitate (terrorguard)
			[5782] 	= true, -- Fear
			[118699]	= true, -- Fear
			[5484]	= true, -- Howl of terror
			[115268]	= true, -- Mesmerize (shivarra)
			[6789] 	= true, -- Mortal Coil
			[115781]	= true, -- Optical Blast (improved spell lock from Grimoire of Supremacy)
			[6358]	= true, -- Seduction (succubus)
			[30283]	= true, -- Shadowfury
			[19647]	= true, -- Spell Lock (Felhunters)
			[31117]	= true, -- Unstable Affliction

		-- Warrior
			[100]		= true, -- Charge
			[105771]	= true, -- Charge
			[102060]	= true, -- Disrupting Shout
			[118895]	= true, -- Dragon Roar
			[5246]	= true, -- Intimidating shout
			[6552]	= true, -- Pummel
			[132168]	= true, -- Shockwave
			[107566]	= true, -- Staggering shout
			[132169]	= true, -- Storm Bolt
			[7922]	= true, -- Warbringer
	}

  CT.spells.absorb = {
		-- Priest
			[47753]	=	true,  --Divine Aegis (discipline)
			[17]		=	true,  --Power Word: Shield (discipline)
			[114908]	=	true,  --Spirit Shell (discipline)
			[114214]	=	true,  --Angelic Bulwark (talent)
			[152118]	=	true,  --Clarity of Will (talent)

		-- Death Knight
			[48707]	=	true, --Anti-Magic Shell
			[116888]	=	true, --Shroud of Purgatory (talent)
			[51052]	=	true, --Anti-Magic Zone (talent)
			[77535]	=	true, --Blood Shield
			[115635]	=	true, --death barrier

		-- Shaman
			[114893]	=	true, --Stone Bulwark (stone bulwark totem)
			[145379]	=	true, --Barreira da Natureza
			[145378]	=	true, --2P T16

		-- Paladin
			[86273]	=	true, --Illuminated Healing (holy)
			[65148]	=	true, --Sacred Shield (talent)

		-- Monk
			[116849]	=	true, --Life Cocoon (mistweaver)
			[115295]	=	true, --Guard (brewmaster)
			--[118604]	=	true, --Guard (brewmaster)
			[145051]	=	true, -- Protection of Niuzao
			[145056]	=	true, --
			[145441]	=	true, --2P T16
			[145439]	=	true, --2P T16

		-- Warlock
			--[6229]	=	true, --Twilight Ward
			[108366]	=	true, --Soul Leech (talent)
			[108416]	=	true, --Sacrificial Pact (talent)
			[110913]	=	true, --Dark Bargain (talent)
			[7812]	=	true, --Voidwalker's Sacrifice

		-- Mage
			[11426]	=	true, --Ice Barrier (talent)
			[1463]	=	true, --Incanter's Ward (talent)

		-- Warrior
			[112048]	=	true, -- Shield Barrier (protection)

		--others
			[116631]	=	true, -- enchant "Enchant Weapon - Colossus"
			[140380]	=	true, -- trinket "Inscribed Bag of Hydra-Spawn"
			[138925]	=	true, -- trinket "Stolen Relic of Zuldazar"
	}

  CT.spells.defensives = {
		--> spellid = {cooldown, duration}
    [20594] = 120, --racial stoneform

		--[6262] = {120, 1, 1}, --healthstone

		-- Death Knigh
		[55233] = 60, -- Vampiric Blood
		[49222] = 60, -- Bone Shield
		[48792] = 180, -- Icebound Fortitude
		[48743] = 120, -- Death Pact
		[49039] = 12, -- Lichborne
    [48707] = 45, -- Anti-Magic Shell
    [48743] = 120, --Death Pact
    [51052] = 120, --Anti-Magic Zone
    [152279] = 120, -- Breath of Sindragosa
    [48982] = 30, -- Rune Tap
    [152279] = 120, -- "Breath of Sindragosa"
		["DEATHKNIGHT"] = {55233, 49222, 48707, 48792, 48743, 49039, 48743, 51052, 152279},

		-- Druid
		[62606] = 1.5, -- Savage Defense
		--[106922] = {180, 20}, -- Might of Ursoc
		[102342] = 60, -- Ironbark
		[61336] = 180, -- Survival Instincts
		[22812] = 60, -- Barkskin
		[155835] = 60, -- Bristling Fur
    [740] = 480, -- Tranquility
    [22842] = 0, -- Frenzied Regeneration
    --[124988] = 90, -- Nature's Vigil
    [124974] = 90, -- Nature's Vigil
		["DRUID"] = {62606, 102342, 61336, 22812, 740, 22842, 155835}, --106922

		-- Hunter
		[19263] = 120, -- Deterrence
    [172106] = 180, -- "Aspect of the Fox"
		["HUNTER"] = {19263, 172106},

		-- Mage
		[45438] = 300, -- Ice Block
    [159916]	= 120, -- "Amplify Magic"
    [157913]	= 45, -- "Evanesce"
    [110960] = 90, -- greater invisibility - 110959 too
		["MAGE"] = {45438, 159916, 157913, 110960},

		-- Monk
		[122470] = 90, -- Touch of Karma
		--[115213] = 180, -- Avert Harm
    [115295] = 30, -- Guard
    [116849] = {120, 100}, -- NOTE: Life Cocoon (a)
    [115310] = 180, -- Revival
    [119582] = 0, -- NOTE: Purifying Brew
    [116844] = 45, -- Ring of Peace
    [115308] = 0, -- Elusive Brew
    [122783] = 90, -- Diffuse Magic
    [122278] = 90, -- Dampen Harm
    [115176] = 180, -- Zen Meditation
    [115203] = 18, -- Fortifying Brew
    [157535] = 90, -- "Breath of the Serpent"
		["MONK"] = {122470, 115295, 115203, 115176, 116849, 122278, 122783, 115310, 119582, 116844, 115308, 157535}, --115213

		-- Paladin
    [633]	=	{600, 720, 360}, -- NOTE: Lay on Hands
    [31821]	=	180,-- Devotion Aura
		[86659] = 180, -- Guardian of Ancient Kings
		[31850] = 180, -- Ardent Defender
		[498] = {60, 30}, -- NOTE: Divine Protection
		[642] = {300, 160}, -- NOTE: Divine Shield
		[6940] = 120, -- Hand of Sacrifice
		[1022] = 300, -- Hand of Protection
		[1038] = 120, -- Hand of Salvation
		["PALADIN"] = {86659, 31850, 498, 642, 6940, 1022, 1038, 633, 31821},

		-- Priest
		[15286] = 180, -- Vampiric Embrace
		[47788] = 180, -- Guardian Spirit
		[47585] = 120, -- Dispersion
		[33206] = 180, -- Pain Suppression
    [62618] = 180, --Power Word: Barrier
    [109964] = 60, --Spirit Shell
    [64843] = 180, --Divine Hymn
    --[108968] = {300, 0, 0}, --Void Shift holy disc
    --[142723] = {600, 0, 0}, --Void Shift shadow
		["PRIEST"] = {15286, 47788, 47585, 33206, 62618, 109964, 64843}, --108968 142723

		-- Rogue
		[1966] = 1.5, -- Feint
		[31224] = 60, -- Cloak of Shadows
		[5277] = 180, -- Evasion
    [76577] = 180, -- Smoke Bomb
		["ROGUE"] = {1966, 31224, 5277, 76577},

		-- Shaman
		[30823] = {120, 60}, -- Shamanistic Rage
		[108271] = 120, -- Astral Shift
    [108270] = 60, -- Stone Bulwark Totem
    [108280]	=	180, -- Healing Tide Totem
    [98008]	=	180, -- Spirit Link Totem
    [108281]	=	120, -- Ancestral Guidance
    [165344]	=	180, -- "Ascendance"
    [152256]	=	300, -- "Storm Elemental Totem"
		["SHAMAN"] = {30823, 108271, 108270, 108280, 98008, 108281, 165344, 152256},

		-- Warlock
		[104773] = {180, 120, 240}, -- Unending Resolve
		[108359] = {120, 12}, -- Dark Regeneration
		[110913] = {180, 8}, -- Dark Bargain
    [108416] = 60, -- Sacrificial Pact  1 = self
    --[6229] = {30, 30, 1}, -- Twilight Ward  1 = self
		["WARLOCK"] = {104773, 108359, 108416, 110913}, --6229

		-- Warrior
		[12975] = {180, 20}, -- Last Stand
		[23920] = 25, -- Spell Reflection
		[114030] = 120, -- Vigilance
		[118038] = 120, -- Die by the Sword
		[112048]	= 90, -- Shield Barrier
    --[114203]	= {180, 15}, -- Demoralizing Banner
    [114028]	= 60, -- Mass Spell Reflection
    [97462]	= 180, -- Rallying Cry
    [2565] 	= 12, -- Shield Block
    [871] = {180, 300}, -- NOTE: Shield Wall
    [12975] = 180, -- Last Stand
    [23920] = 25, -- Spell Reflection
    [114030] = 120, -- Vigilance
    [118038] = 120, -- Die by the Sword
    [112048]	= 90, -- Shield Barrier
		["WARRIOR"] = {871, 12975, 23920, 114030, 118038, 114028, 97462, 2565} --114203

	}

  CT.spells.DualSideSpells = {
		[114165] = 20,-- Holy Prism (paladin)
		[47750]	=	true, -- Penance (priest)
	}

  CT.spells.offensives = {
		-- Death Knight
		--[49016]	=	true, -- Unholy Frenzy (attack cd)
		[49206]	=	true, -- Summon Gargoyle (attack cd)
		[49028]	=	true, -- Dancing Rune Weapon (attack cd)
		[51271]	=	true, -- Pillar of Frost (attack cd)
		[63560]	=	true, -- Dark Transformation (pet)

		-- Druid
		[106951] =	true, -- Berserk (attack cd)
		[124974] =	true, -- Nature's Vigil (attack cd)
		[102543] =	true, -- Incarnation: King of the Jungle
		[50334]	=	true, -- Berserk
		[102558] =	true, -- Incarnation: Son of Ursoc
		[102560] =	true, -- Incarnation: Chosen of Elune
		[112071] =	true, -- Celestial Alignment
		[127663] =	true, -- Astral Communion
		[108293] =	true, --  Heart of the Wild (attack cd)
		[108291] =	true, --  Heart of the Wild

		-- Hunter
		[131894]	=	true,-- A Murder of Crows (attack cd)
		[121818]	=	true,-- Stampede (attack cd)
		[82692]	=	true,-- Focus Fire
		[120360]	=	true,-- Barrage

		-- Mage
		[80353]	=	true,-- Time Warp
		--[131078]	=	true,-- Icy Veins
		[12472]	=	true,-- Icy Veins
		[12043]	=	true,-- Presence of Mind
		[108978]	=	true,-- Alter Time
		[127140]	=	true,-- Alter Time
		[12042]	=	true,-- Arcane Power

		-- Monk
		[116740]	=	true, -- Tigereye Brew (attack cd?)
		[123904]	=	true, -- Invoke Xuen, the White Tiger
		[115288]	=	true, -- Energizing Brew

		-- Paladin
		[31884]	=	true,-- Avenging Wrath
		[105809] =	true,-- Holy Avenger
		[31842] = true, -- Divine Favor

		-- Priest
		[34433]	=	true, -- Shadowfiend
		[123040]	=	true, -- Mindbender
		[10060]	=	true, -- Power Infusion

		-- Rogue
		[13750]	=	true, -- Adrenaline Rush (attack cd)
		--[121471]	=	true, -- Shadow Blades
		[137619]	=	true, -- Marked for Death
		[79140]	=	true, -- Vendetta
		[51690]	=	true, -- Killing Spree
		[51713]	=	true, -- Shadow Dance
		[152151]	=	true, -- "Shadow Reflection"

		-- Shaman
		--[120668]	=	true, --Stormlash Totem (attack cd)
		[2894]	=	true, -- Fire Elemental Totem
		[2825]	=	true, -- Bloodlust
		[114049]	=	true, -- Ascendance
		[16166]	=	true, -- Elemental Mastery
		[51533]	=	true, -- Feral Spirit
		[16188]	=	true, -- Ancestral Swiftness
		[2062]	=	true, -- Earth Elemental Totem

		-- Warlock
		[113860] = true, -- Dark Soul: Misery (attack cd)
		[113858] = true, -- Dark Soul: Instability
		[113861] = true, -- Dark Soul: Knowledge

		-- Warrior
		[1719]	=	true, -- Recklessness (attack cd)
		--[114207]	=	true, -- Skull Banner
		[107574]	=	true, -- Avatar
		[12292]	=	true, -- Bloodbath
	}

  CT.spells.dispel = {
    [115450] = true, -- Detox (Monk)
    [77130]	=	true, -- Purify Spirit (Shaman)
    [51886] = true, -- Cleanse Spirit (Shaman)
    [32375] = true, -- Mass Dispel (Priest)
    [4987] = true, -- Cleanse (Paladin)
  }

  local interrupts = {
    [96231] = true, -- Rebuke (Paladin)
  }

  -- for container = 0, NUM_BAG_SLOTS do
  --   for slot = 1, GetContainerNumSlots(container) do
  --     local id = GetContainerItemID(container, slot)
  --     if id then
  --       local name = GetItemInfo(id)
  --       name = name and strlower(name)
  --
  --       CurrentItems[id] = name
  --       cacheItem(id, name)
  --     end
  --   end
  -- end
  --
  -- -- Cache equipped items
  -- for slot = 1, 19 do
  --   local id = GetInventoryItemID("player", slot)
  --   if id then
  --     local name = GetItemInfo(id)
  --     name = name and strlower(name)
  --
  --     CurrentItems[id] = name
  --     cacheItem(id, name)
  --   end
  -- end

	-- local Loc = LibStub ("AceLocale-3.0"):GetLocale ( "Details" )
	-- CT.SpellOverwrite = {
	-- 	--[124464] = {name = GetSpellInfo (124464) .. " (" .. Loc ["STRING_MASTERY"] .. ")"}, --> shadow word: pain mastery proc (priest)
	-- }

end

if load then
  CT:Print("LOADING EXTRA SPELLS!")
  CT.spells.harmful = {

    -- Death Knight
    [49020] 	= 	true, -- obliterate
    [49143] 	=	true, -- frost strike
    [55095] 	= 	true, -- frost fever
    [55078] 	= 	true, -- blood plague
    [49184] 	= 	true, -- howling blast
    [49998] 	= 	true, -- death strike
    [55090] 	= 	true, -- scourge strike
    [47632] 	= 	true, -- death coil
    [108196]	=	true, --Death Siphon
    [47541]	=	true, -- Death Coil
    --[48721]	=	true, -- Blood Boil
    [42650]	=	true, -- Army of the Dead
    [130736]	=	true, -- Soul Reaper
    [45524]	=	true, -- Chains of Ice
    [45462]	=	true, -- Plague Strike
    [85948]	=	true, -- Festering Strike
    --[56815]	=	true, -- Rune Strike
    [108200]	=	true, -- Remorseless Winter
    [45477]	=	true, -- Icy Touch
    [43265]	=	true, -- Death and Decay
    [77575]	=	true, -- Outbreak
    [115989]	=	true, -- Unholy Blight
    --[55050]	=	true, -- Heart Strike
    [114866]	=	true, -- Soul Reaper
    --[73975]	=	true, -- Necrotic Strike
    [130735]	=	true, -- Soul Reaper
    [50842]	=	true, -- Pestilence
    --[45902]	=	true, -- Blood Strike
    [108194]	=	true, --  Asphyxiate
    [77606]	=	true, --  Dark Simulacrum

    -- Druid
    --[80965]	=	 true, --  Skull Bashs
    [78675]	=	 true, --  Solar Beam
    [22570]	=	 true, --  Maim
    [33831]	=	 true, --  Force of Nature
    [102706]	=	 true, --  Force of Nature
    [102355]	=	 true, --  Faerie Swarm
    [16914]	=	 true, --  Hurricane
    [2908]	=	 true, --  Soothe
    --[62078]	=	 true, --  Swipe
    [106996]	=	 true, --  Astral Storm
    --[6785]	=	 true, --  Ravage
    [33891]	=	 true, --  Incarnation: Tree of Life
    [102359]	=	 true, --  Mass Entanglement
    [5211]	=	 true, --  Mighty Bash
    --[102795]	=	 true, --  Bear Hug
    [1822] 	= 	true, --rake
    [1079] 	= 	true, --rip
    [5221] 	= 	true, --shred
    --[33876] 	=	true, --mangle
    --[102545] 	= 	true, --ravage!
    [5176]	=	true, --wrath
    [93402]	=	true, --sunfire
    [2912]	=	true, --starfire
    [8921]	=	true, --moonfire
    [6807]	=	 true, -- Maul
    [33745]	=	 true, -- Lacerate
    [770]	=	 true, -- Faerie Fire
    [22568]	=	 true, -- Ferocious Bite
    --[779]	=	 true, -- Swipe
    [77758]	=	 true, -- Thrash
    [106830]	=	 true, -- Thrash
    --[114236]	=	 true, -- Shred!
    [48505]	=	 true, -- Starfall
    [78674]	=	 true, -- Starsurge
    --[80964]	=	 true, -- Skull Bash

    -- Hunter
    --[19503]	=	true,--  Scatter Shot
    [109259]	=	true,--  Powershot
    [20736]	=	true,--  Distracting Shot
    [131900]	=	true, --a murder of crows
    [118253]	=	true, --serpent sting
    [77767]	=	true, --cobra shot
    [3044]	=	true, --arcane shot
    [53301]	=	true, --explosive shot
    [120361]	=	true, --barrage
    [53351]	=	true, --kill shot
    [3674]	=	true,-- Black Arrow
    [117050]	=	true,-- Glaive Toss
    --[1978]	=	true,-- Serpent Sting
    [34026]	=	true,-- Kill Command
    [2643]	=	true,-- Multi-Shot
    [109248]	=	true,-- Binding Shot
    [149365]	=	true,-- Dire Beast
    [120679]	=	true,-- Dire Beast
    [3045]	=	true,-- Rapid Fire
    [19574]	=	true,-- Bestial Wrath
    [19386]	=	true,-- Wyvern Sting
    [19434]	=	true,-- Aimed Shot
    [120697]	=	true,-- Lynx Rush
    [56641]	=	true,-- Steady Shot
    --[34490]	=	true,-- Silencing Shot
    [53209]	=	true,-- Chimera Shot
    --[82928]	=	true,-- Aimed Shot!
    [5116]	=	true,-- Concussive Shot
    [147362]	=	true,-- Counter Shot
    [19801]	=	true,-- Tranquilizing Shot
    --[82654]	=	true,-- Widow Venom

    -- Mage
    [116]	=	true, --frost bolt
    [30455]	=	true, --ice lance
    [84721]	=	true, --frozen orb
    [1449]	=	true, --arcane explosion
    [113092]	=	true, --frost bomb
    [115757]	=	true, --frost nova
    [44614]	=	true, --forstfire bolt
    [42208]	=	true, --blizzard
    [11366]	=	true, --pyroblast
    [133]	=	true, --fireball
    [108853]	=	true, --infernoblast
    [2948]	=	true, --scorch
    [30451]	=	true, --arcane blase
    [44457]	=	true,-- Living Bomb
    [84714]	=	true,-- Frozen Orb
    [11129]	=	true,-- Combustion
    [112948]	=	true,-- Frost Bomb
    [2139]	=	true,-- Counterspell
    [2136]	=	true,-- Fire Blast
    [7268]	=	true,-- Arcane Missiles
    [114923]	=	true,-- Nether Tempest
    [2120]	=	true,-- Flamestrike
    [44425]	=	true,-- Arcane Barrage
    [44572]	=	true,-- Deep Freeze
    [113724]	=	true,-- Ring of Frost
    [31661]	=	true,--  Dragon's Breath

    -- Monk
    [107428]	=	true, --rising sun kick
    [100784]	=	true, --blackout kick
    [132467]	=	true, --Chi wave
    [107270]	=	true, --spinning crane kick
    [100787]	=	true, --tiger palm
    [132463]	=	true, -- shi wave
    [100780]	=	true, -- Jab
    [115698]	=	true, -- Jab
    [108557]	=	true, -- Jab
    [115693]	=	true, -- Jab
    [101545]	=	true, -- Flying Serpent Kick
    [122470]	=	true, -- Touch of Karma
    [117418]	=	true, -- Fists of Fury
    [113656]	=	true, -- Fists of Fury
    [115098]	=	true, -- Chi Wave
    [117952]	=	true, -- Crackling Jade Lightning
    [115078]	=	true, -- Paralysis
    [116705]	=	true, -- Spear Hand Strike
    --[116709]	=	true, -- Spear Hand Strike
    [101546]	=	true, -- Spinning Crane Kick
    [116847]	=	true, -- Rushing Jade Wind
    [115181]	=	true, -- Breath of Fire
    [121253]	=	true, -- Keg Smash
    [124506]	=	true, -- Gift of the Ox
    [124503]	=	true, -- Gift of the Ox
    [124507]	=	true, -- Gift of the Ox
    [115080]	=	true, -- Touch of Death
    [119381]	=	true, -- Leg Sweep
    [115695]	=	true, -- Jab
    [137639]	=	true, -- Storm, Earth, and Fire
    --[115073]	=	true, -- Spinning Fire Blossom
    [115008]	=	true, -- Chi Torpedo
    [121828]	=	true, -- --Chi Torpedo
    [115180]	=	true, -- Dizzying Haze
    [123986]	=	true, -- Chi Burst
    [130654]	=	true, -- Chi Burst
    [148135]	=	true, -- Chi Burst
    [119392]	=	true, -- Charging Ox Wave
    [116095]	=	true, -- Disable
    [115687]	=	true, -- Jab
    [117993]	=	true, -- Chi Torpedo

    -- Paladin
    [35395]	=	hasteCD, -- crusader strike
    [879]	=	hasteCD, -- exorcism
    [85256]	=	true, -- templar's verdict
    [31935]	=	hasteCD, -- avenger's shield
    [20271]	=	hasteCD, -- judgment
    [81297]	=	hasteCD, -- Consecration
    [26573]	=	hasteCD,-- Consecration
    [116467] = hasteCD, -- Consecration
    [31803]	=	true, -- censure
    [20473]	=	hasteCD, -- Holy Shock
    [114158]	=	true,-- Light's Hammer
    [24275]	=	true,-- Hammer of Wrath
    [88263]	=	hasteCD,-- Hammer of the Righteous
    [53595]	=	hasteCD,-- Hammer of the Righteous
    [53600]	=	true,-- Shield of the Righteous
    [119072]	=	hasteCD,-- Holy Wrath
    [105593]	=	true,-- Fist of Justice
    [122032]	=	hasteCD,-- Exorcism
    [96231]	=	true,-- Rebuke
    [115750]	=	true,-- Blinding Light
    [53385]	=	true,-- Divine Storm
    [31801] 	= 	true, -- Seal of Truth
    [20165] 	= 	true, -- Seal of Insight

    -- Priest
    [589]	=	true, --shadow word: pain
    [34914]	=	true, --vampiric touch
    [15407]	=	true, --mind flay
    [8092]	=	true, --mind blast
    [15290]	=	true,-- Vampiric Embrace
    [2944]	=	true,--devouring plague (damage)
    [585]	=	true, --smite
    [47666]	=	true, --penance
    [14914]	=	true, --holy fire
    [48045]	=	true, -- Mind Sear
    [49821]	=	true, -- Mind Sear
    [32379]	=	true, -- Shadow Word: Death
    [129176]	=	true, -- Shadow Word: Death
    [120517]	=	true, -- Halo
    [120644]	=	true, -- Halo
    [15487]	=	true, -- Silence
    [129197]	=	true, -- Mind Flay (Insanity)
    [108920]	=	true, -- Void Tendrils
    [73510] 	= 	true, -- Mind Spike
    [127632] 	= 	true, -- Cascade
    --[108921] 	= 	true, -- Psyfiend
    [88625] 	= 	true, -- Holy Word: Chastise

    -- Rogue
    [53]		= 	true, --backstab
    [2098]	= 	true, --eviscerate
    [51723]	=	true, --fan of knifes
    [111240]	=	true, --dispatch
    [703]	=	true, --garrote
    [1943]	=	true, --rupture
    [114014]	=	true, --shuriken toss
    [16511]	=	true, --hemorrhage
    [89775]	=	true, --hemorrhage
    [8676]	=	true, --amcush
    [5374]	=	true, --mutilate
    [32645]	=	true, --envenom
    [1943]	=	true, --rupture
    [27576]	=	true, -- Mutilate Off-Hand
    [1329]	=	true, -- Mutilate
    [84617]	=	true, -- Revealing Strike
    [1752]	=	true, -- Sinister Strike
    --[121473]	=	true, -- Shadow Blade
    --[121474]	=	true, -- Shadow Blade Off-hand
    [1766]	=	true, -- Kick
    --[8647]	=	true, -- Expose Armor
    [2094]	=	true, -- Blind
    [121411]	=	true, -- Crimson Tempest
    [137584] 	= 	true, -- Shuriken Toss
    [137585] 	= 	true, -- Shuriken Toss Off-hand
    [1833] 	= 	true, -- Cheap Shot
    [121733] 	= 	true, -- Throw
    [1776] 	= 	true, -- Gouge

    -- Shaman
    [51505]	=	true, --lava burst
    [8050]	=	true, --flame shock
    [117014]	=	true, --elemental blast
    [403]	=	true, --lightning bolt
    --[45284]	=	true, --lightning bolt
    [421]	=	true, --chain lightining
    [32175]	=	true, --stormstrike
    [25504]	=	true, --windfury
    [8042]	=	true, --earthshock
    [26364]	=	true, --lightning shield
    [117014]	=	true, --elemental blast
    [73683]	=	true, --unleash flame
    [115356]	=	true, -- Stormblast
    [60103]	=	true, -- Lava Lash
    [17364]	=	true, -- Stormstrike
    [61882]	=	true, -- Earthquake
    [57994]	=	true, -- Wind Shear
    [8056]	=	true, -- Frost Shock
    [114074] 	= 	true, -- Lava Beam

    -- Warlock
    --[77799]	=	true, --fel flame
    [63106]	=	true, --siphon life
    [103103]	=	true, --malefic grasp
    [980]	=	true, --agony
    [30108]	=	true, --unstable affliction
    [172]	=	true, --corruption
    [48181]	=	true, --haunt
    [29722]	=	true, --incenerate
    [348]	=	true, --Immolate
    [116858]	=	true, --Chaos Bolt
    [114654]	=	true, --incinerate
    [108686]	=	true, --immolate
    [108685]	=	true, --conflagrate
    [104233]	=	true, --rain of fire
    [103964]	=	true, --touch os chaos
    [686]	=	true, --shadow bolt
    --[114328]	=	true, --shadow bolt glyph
    [140719]	=	true, --hellfire
    [104027]	=	true, --soul fire
    [603]	=	true, --doom
    [108371]	=	true, --Harvest life
    [17962]	=	true, -- Conflagrate
    [105174]	=	true, -- Hand of Gul'dan
    [146739]	=	true, -- Corruption
    [30283]	=	true, -- Shadowfury
    [104232]	=	true, -- Rain of Fire
    [6353]	=	true, -- Soul Fire
    [689]	=	true, -- Drain Life
    [17877]	=	true, -- Shadowburn
    --[1490]	=	true, -- Curse of the Elements
    [27243]	=	true, -- Seed of Corruption
    [6789]	=	true, -- Mortal Coil
    [124916]	=	true, -- Chaos Wave
    --[1120]	=	true, -- Drain Soul
    [5484]	=	true, -- Howl of Terror
    --[89420]	=	true, -- Drain Life
    --[109466]	=	true, -- Curse of Enfeeblement
    --[112092] 	= 	true, -- Shadow Bolt
    --[103967] 	= 	true, -- Carrion Swarm

    -- Warrior
    [100130]	=	true, --wild strike
    [96103]	=	true, --raging blow
    [12294]	=	true, --mortal strike
    [1464]	=	true, --Slam
    [23922]	=	true, --shield slam
    [20243]	=	true, --devastate
    --[11800]	=	true, --dragon roar
    [115767]	=	true, --deep wounds
    [109128]	=	true, --charge
    --[11294]	=	true, --mortal strike
    --[29842]	=	true, --undribled wrath
    [86346]	=	true, -- Colossus Smash
    [107570]	=	true, -- Storm Bolt
    [1680]	=	true, -- Whirlwind
    [85384]	=	true, -- Raging Blow Off-Hand
    [85288]	=	true, -- Raging Blow
    --[7384]	=	true, -- Overpower
    [23881]	=	true, -- Bloodthirst
    [118000]	=	true, -- Dragon Roar
    [50622]	=	true, -- Bladestorm
    [46924]	=	true, -- Bladestorm
    [103840]	=	true, -- Impending Victory
    [5308]	=	true, -- Execute
    [57755]	=	true, -- Heroic Throw
    [1715]	=	true, -- Hamstring
    [46968]	=	true, -- Shockwave
    [6343]	=	true, -- Thunder Clap
    [64382]	=	true, -- Shattering Throw
    [6552]	=	true, -- Pummel
    [6572]	=	true, -- Revenge
    [102060]	=	true, -- Disrupting Shout
    [12323] 	= 	true, -- Piercing Howl
    --[122475] 	= 	true, -- Throw
    --[845] 	= 	true, -- Cleave
    [5246] 	= 	true, -- Intimidating Shout
    --[7386] 	= 	true, -- Sunder Armor
    [107566] 	= 	true, -- Staggering Shout
  }
  CT.spells.helpful = {
    -- Death Knight
    [45470] = true, -- Death Strike (heal)
    [77535] = true, -- Blood Shield (heal)
    [53365] = true, -- Unholy Strength (heal)
    [48707] = true, -- Anti-Magic Shell (heal)
    [48982] = true, -- rune tap
    [119975]	=	true, -- Conversion (heal)
    [48743]	=	true, -- Death Pact (heal)

    -- Druid
    --[33878] =	true, --mangle (energy gain)
    [17057] =	true, --bear form (energy gain)
    [16959] =	true, --primal fury (energy gain)
    [5217] = true, --tiger's fury (energy gain)
    [68285] =	true, --leader of the pack (mana)
    [774]	=	true, --rejuvenation
    --[44203]	=	true, --tranquility
    [48438]	=	true, --wild growth
    [81269]	=	true, --shiftmend
    --[102792]	=	true, -- Wild Mushroom: Bloom
    [5185]	=	true, --healing touch
    [8936]	=	true, --regrowth
    [33778]	=	true, --lifebloom
    [48503]	=	true, --living seed
    --[50464]	=	true, --nourish
    [18562]	=	 true, --Swiftmend (heal)
    [145205]	=	 true, -- Wild Mushroom (heal)
    [33763]	=	 true, -- Lifebloom (heal)
    --[102791]	=	 true, -- Wild Mushroom: Bloom
    [147349]	=	 true, -- Wild Mushroom
    [108238]	=	 true, -- Renewal
    [102351]	=	 true, --  Cenarion Ward


    -- Hunter
    [109304]	=	true,-- Exhilaration (heal)

    -- Mage
    [11426]	=	true, --Ice Barrier (heal)
    [115610]	=	true,-- Temporal Shield
    [111264]	=	true,-- Ice Ward

    -- Monk
    [124682]	=	true, -- Enveloping Mist (helpful)
    [115460]	=	true, -- Healing Sphere
    --[115464]	=	true, -- Healing Sphere
    [115151]	=	true, -- Renewing Mist
    [122783]	=	true, -- Diffuse Magic
    [147489]	=	true, -- Expel Harm
    [135920]	=	true, -- Gift of the Serpent
    [116841]	=	true, -- Tiger's Lust
    [116694]	=	true, -- Surging Mist
    [115308]	=	true, -- Elusive Brew
    --[135914]	=	true, -- Healing Sphere
    [116844]	=	true, -- Ring of Peace
    [123761]	=	true, --mana tea
    [119611]	=	true, --renewing mist
    [115310]	=	true, --revival
    [116670]	=	true, --uplift
    [115175]	=	true, --soothing mist
    [124041]	=	true, --gift of the serpent
    [124040]	=	true, -- chi torpedo
    [132120]	=	true, -- enveloping mist
    [115295]	=	true, --guard
    [115072]	=	true, --expel harm
    [117895]	=	true, --eminence (statue)
    [115176]	=	true, -- Zen Meditation cooldown
    [115203]	=	true, -- Fortifying Brew
    --[115213]	=	true, -- Avert Harm
    [124081]	=	true, -- Zen Sphere
    [125355]	=	true, -- Healing Sphere
    [122278]	=	true, -- Dampen Harm

    -- Paladin
    [85673]	=	true,-- Word of Glory (heal)
    [20925]	=	true,-- Sacred Shield
    [53563]	=	true,-- Beacon of Light
    [633]	=	true,-- Lay on Hands
    [114163]	=	true,-- Eternal Flame
    [642]	=	true,-- Divine Shield
    [31821]	=	true,-- Devotion Aura
    [148039]	=	true,-- Sacred Shield
    [82326]	=	true,-- Divine Light
    [20167]	=	true,--seal of insight (mana)
    [65148]	=	true, --Sacred Shield
    [20167]	=	true, --Seal of Insight
    [86273]	=	true, --illuminated healing
    [85222]	=	true, --light of dawn
    [53652]	=	true, --beacon of light
    [82327]	=	true, --holy radiance
    [119952]	=	true, --arcing light
    [25914]	=	true, --holy shock
    [19750]	=	true, --flash of light
    [31850] 	= 	true, -- Ardent Defender --defensive cd
    [1044] 	= 	true, -- Hand of Freedom --helpful
    [114039] 	= 	true, -- Hand of Purity
    [136494] 	= 	true, -- Word of Glory

    -- Priest
    [19236] 	= 	true, -- Desperate Prayer
    [47788] 	= 	true, -- Guardian Spirit
    [81206] 	= 	true, -- Chakra: Sanctuary
    [62618] 	= 	true, -- Power Word: Barrier
    [32546] 	= 	true, -- Binding Heal
    [33110]	=	true, --prayer of mending
    [596]	=	true, --prayer of healing
    [34861]	=	true, --circle of healing
    [139]	=	true, --renew
    [120692]	=	true, --halo
    [2060]	=	true, --greater heal
    [110745]	=	true, --divine star
    [2061]	=	true, --flash heal
    [88686]	=	true, --santuary
    [17]		=	true, --power word: shield
    --[64904]	=	true, --hymn of hope
    [129250]	=	true, --power word: solace
    [121135]	=	true, -- Cascade
    [122121]	=	true, -- Divine Star
    [110744]	=	true, -- Divine Star
    [123258]	=	true, -- Power Word: Shield
    [88685]	=	true, -- Holy Word: Sanctuary
    [88684]	=	true, -- Holy Word: Serenity
    [33076]	=	true, -- Prayer of Mending
    [15286]	=	true, -- Vampiric Embrace
    --[2050]	=	true, -- Heal
    [123259]	=	true, -- Prayer of Mending

    -- Rogue
    [73651]	=	true, --Recuperate (heal)
    [35546]	=	true, --combat potency (energy)
    [98440]	=	true, --relentless strikes (energy)
    [51637]	=	true, --venomous vim (energy)
    [31224]	=	true, -- Cloak of Shadows (cooldown)
    [1966]	=	true, -- Feint (helpful)
    [76577]	=	true, -- Smoke Bomb
    [5277]	=	true, -- Evasion

    -- Shaman
    --[88765]	=	true, --rolling thunder (mana)
    [51490]	=	true, --thunderstorm (mana)
    --[82987]	=	true, --telluric currents glyph (mana)
    [101033]	=	true, --resurgence (mana)
    [51522]	=	true, --primal wisdom (mana)
    --[63375]	=	true, --primal wisdom (mana)
    [114942]	=	true, --healing tide
    [73921]	=	true, --healing rain
    [1064]	=	true, --chain heal
    [52042]	=	true, --healing stream totem
    [61295]	=	true, --riptide
    --[51945]	=	true, --earthliving
    [114083]	=	true, --restorative mists
    [8004]	=	true, --healing surge
    [5394]	=	true, -- Healing Stream Totem (heal)
    [73920]	=	true, -- Healing Rain
    [108270]	=	true, -- Stone Bulwark Totem
    --[331]	=	true, -- Healing Wave
    [52127]	=	true, -- Water Shield
    [77472]	=	true, -- Greater Healing Wave
    [108271]	=	true, -- Astral Shift
    [30823]	=	true, -- Shamanistic Rage
    [98008] 	= 	true, -- Spirit Link Totem

    -- Warlock
    [108359]	=	true, -- Dark Regeneration (helpful)
    [110913]	=	true, -- Dark Bargain
    -- [104773]	=	true, -- Unending Resolve
    --[6229]	=	true, -- Twilight Ward
    [114635]	=	true, -- Ember Tap
    --[131623]	=	true, -- Twilight Ward
    [108416]	=	true, -- Sacrificial Pact
    [132413]	=	true, -- Shadow Bulwark
    [114189] 	= 	true, -- Health Funnel

    -- Warrior
    [871]	=	true, -- Shield Wall
    [97462]	=	true, -- Rallying Cry
    [118038]	=	true, -- Die by the Sword
    --[114203]	=	true, -- Demoralizing Banner
    [114028]	=	true, -- Mass Spell Reflection
    [55694]	=	true, -- Enraged Regeneration
    [112048]	=	true, -- Shield Barrier
    [23920]	=	true, -- Spell Reflection
    [12975]	=	true, -- Last Stand
    [2565] 	= 	true, -- Shield Block
  }
  CT.spells.misc = {
    -- Death Knight
    [49576]	=	true, -- Death Grip
    [56222]	=	true, -- Dark Command
    [47528]	=	true, -- Mind Freeze (interrupt)
    [123693]	=	true, -- Plague Leech (consume plegue, get 2 deathrunes)
    [3714]	=	true, -- Path of Frost
    [48263]	=	true, -- Blood Presence
    [47568]	=	true, -- Empower Rune Weapon
    [57330]	=	true, -- Horn of Winter (buff)
    [45529]	=	true, -- Blood Tap
    [96268]	=	true, -- Death's Advance (walk faster)
    [48266]	=	true, -- Frost Presence
    [50977]	=	true, --  Death Gate
    [108199]	=	true, --  Gorefiend's Grasp
    [108201]	=	true, --  Desecrated Ground
    [48265]	=	true, --  Unholy Presence
    [61999]	=	true, --  Raise Ally

    -- Druid
    --[16689]	=	 true, --  Nature's Grasp
    [102417]	=	 true, --  Wild Charge
    --[5229]	=	 true, --  Enrage
    --[9005]	=	 true, --  Pounce
    [114282]	=	 true, --  Treant Form
    [5215]	=	 true, --  Prowl
    [52610]	=	 true, --  Savage Roar
    [102401]	=	 true, --  Wild Charge
    [102793]	=	 true, --  Ursol's Vortex
    [106898]	=	 true, --  Stampeding Roar
    [132158]	=	 true, -- Nature's Swiftness (misc)
    [1126]	=	 true, -- Mark of the Wild (buff)
    [77761]	=	 true, -- Stampeding Roar
    [77764]	=	 true, -- Stampeding Roar
    [16953]	=	 true, -- Primal Fury
    [102693]	=	 true, -- Force of Nature
    [145518]	=	 true, -- Genesis
    [5225]	=	 true, -- Track Humanoids
    [102280]	=	 true, -- Displacer Beast
    [1850]	=	 true, -- Dash
    [108294]	=	 true, -- Heart of the Wild
    [108292]	=	 true, -- Heart of the Wild
    [768]	=	 true, -- Cat Form
    --[127538]	=	 true, -- Savage Roar
    [16979]	=	 true, -- Wild Charge
    [49376]	=	 true, -- Wild Charge
    [6795]	=	 true, -- Growl
    [61391]	=	 true, -- Typhoon
    [24858]	=	 true, -- Moonkin Form
    --[81070]	=	true, --eclipse
    --[29166]	=	true, --innervate

    -- Hunter
    [781]	=	true,-- Disengage
    [82948]	=	true,-- Snake Trap
    [82939]	=	true,-- Explosive Trap
    [82941]	=	true,-- Ice Trap
    [883]	=	true,-- Call Pet 1
    [83242]	=	true,-- Call Pet 2
    [83243]	=	true,-- Call Pet 3
    [83244]	=	true,-- Call Pet 4
    [2641]	=	true,-- Dismiss Pet
    [82726]	=	true,-- Fervor
    [13159]	=	true,-- Aspect of the Pack
    [109260]	=	true,-- Aspect of the Iron Hawk
    [1130]	=	true,--'s Mark
    [5118]	=	true,-- Aspect of the Cheetah
    [34477]	=	true,-- Misdirection
    [19577]	=	true,-- Intimidation
    [83245]	=	true,--  Call Pet 5
    [51753]	=	true,--  Camouflage
    --[13165]	=	true,--  Aspect of the Hawk
    [53271]	=	true,--  Master's Call
    [1543]	=	true,--  Flare

    -- Mage
    [1953]	=	true,-- Blink
    [108843]	=	true,-- Blazing Speed
    [55342]	=	true,-- Mirror Image
    [110960]	=	true,-- Greater Invisibility
    [110959]	=	true,-- Greater Invisibility
    [11958]	=	true,-- Cold Snap
    [61316]	=	true,-- Dalaran Brilliance
    [1459]	=	true,-- Arcane Brilliance
    [116011]	=	true,-- Rune of Power
    [116014]	=	true,-- Rune of Power
    [132627]	=	true,-- Teleport: Vale of Eternal Blossoms
    [31687]	=	true,-- Summon Water Elemental
    [3567]	=	true,-- Teleport: Orgrimmar
    [30449]	=	true,-- Spellsteal
    [132626]	=	true,-- Portal: Vale of Eternal Blossoms
    [12051]	=	true, --evocation
    [108839]	=	true,--  Ice Floes
    [7302]	=	true,--  Frost Armor
    [53140]	=	true,--  Teleport: Dalaran
    [11417]	=	true,--  Portal: Orgrimmar
    [42955]	=	true,--  Conjure Refreshment

    -- Monk
    [109132]	=	true, -- Roll (neutral)
    [115313]	=	true, -- Summon Jade Serpent Statue
    [116781]	=	true, -- Legacy of the White Tiger
    [115921]	=	true, -- Legacy of the Emperor
    [119582]	=	true, -- Purifying Brew
    [126892]	=	true, -- Zen Pilgrimage
    [121827]	=	true, -- Roll
    [115315]	=	true, -- Summon Black Ox Statue
    [115399]	=	true, -- Chi Brew
    [101643]	=	true, -- Transcendence
    [115546]	=	true, -- Provoke
    [115294]	=	true, -- Mana Tea
    [116680]	=	true, -- Thunder Focus Tea
    [115070]	=	true, -- Stance of the Wise Serpent
    [115069]	=	true, -- Stance of the Sturdy Ox

    -- Paladin
    [85499]	=	true,-- Speed of Light
    --[84963]	=	true,-- Inquisition
    [62124]	=	true,-- Reckoning
    [121783]	=	true,-- Emancipate
    [98057]	=	true,-- Grand Crusader
    [20217]	=	true,-- Blessing of Kings
    [25780]	=	true,-- Righteous Fury
    [20154]	=	true,-- Seal of Righteousness
    [19740]	=	true,-- Blessing of Might
    --[54428] 	= 	true, -- Divine Plea --misc
    [7328] 	= 	true, -- Redemption

    -- Priest
    [8122]	=	true, -- Psychic Scream
    [81700]	=	true, -- Archangel
    [586]	=	true, -- Fade
    [121536]	=	true, -- Angelic Feather
    [121557]	=	true, -- Angelic Feather
    --[64901]	=	true, -- Hymn of Hope
    --[89485]	=	true, -- Inner Focus
    [112833]	=	true, -- Spectral Guise
    --[588]	=	true, -- Inner Fire
    [21562]	=	true, -- Power Word: Fortitude
    --[73413]	=	true, -- Inner Will
    [15473]	=	true, -- Shadowform
    [126135] 	= 	true, -- Lightwell
    [81209] 	= 	true, -- Chakra: Chastise
    [81208] 	= 	true, -- Chakra: Serenity
    [2006] 	= 	true, -- Resurrection
    [1706] 	= 	true, -- Levitate

    -- Rogue
    [108212]	=	true, -- Burst of Speed (misc)
    [5171]	=	true, -- Slice and Dice
    [2983]	=	true, -- Sprint
    [36554]	=	true, -- Shadowstep
    [1784]	=	true, -- Stealth
    [115191]	=	true, -- Stealth
    [2823]	=	true, -- Deadly Poison
    --[108215]	=	true, -- Paralytic Poison
    [14185]	=	true, -- Preparation
    [74001] 	= 	true, -- Combat Readiness
    [14183] 	= 	true, -- Premeditation
    [108211] 	= 	true, -- Leeching Poison
    --[5761] 	= 	true, -- Mind-numbing Poison
    [8679] 	= 	true, -- Wound Poison

    -- Shaman
    [73680]	=	true, -- Unleash Elements (misc)
    [3599]	=	true, -- Searing Totem
    [2645]	=	true, -- Ghost Wolf
    [108285]	=	true, -- Call of the Elements
    --[8024]	=	true, -- Flametongue Weapon
    --[51730]	=	true, -- Earthliving Weapon
    [51485]	=	true, -- Earthgrab Totem
    [108269]	=	true, -- Capacitor Totem
    [79206]	=	true, -- Spiritwalker's Grace
    [58875]	=	true, -- Spirit Walk
    [36936]	=	true, -- Totemic Recall
    [8177] 	= 	true, -- Grounding Totem
    [8143] 	= 	true, -- Tremor Totem
    [108273] 	= 	true, -- Windwalk Totem
    [51514] 	= 	true, -- Hex
    --[73682] 	= 	true, -- Unleash Frost
    --[8033] 	= 	true, -- Frostbrand Weapon

    -- Warlock
    [697]	=	true, -- Summon Voidwalker
    [6201]	=	true, -- Create Healthstone
    [109151]	=	true, -- Demonic Leap
    [103958]	=	true, -- Metamorphosis
    [119678]	=	true, -- Soul Swap
    [74434]	=	true, -- Soulburn
    [108503]	=	true, -- Grimoire of Sacrifice
    [111400]	=	true, -- Burning Rush
    [109773]	=	true, -- Dark Intent
    [112927]	=	true, -- Summon Terrorguard
    [1122]	=	true, -- Summon Infernal
    [18540]	=	true, -- Summon Doomguard
    [29858]	=	true, -- Soulshatter
    [20707]	=	true, -- Soulstone
    [48018]	=	true, -- Demonic Circle: Summon
    [80240] 	= 	true, -- Havoc
    [112921] 	= 	true, -- Summon Abyssal
    [48020] 	= 	true, -- Demonic Circle: Teleport
    [111397] 	= 	true, -- Blood Horror
    [112869] 	= 	true, -- Summon Observer
    [1454] 	= 	true, -- Life Tap
    [112868] 	= 	true, -- Summon Shivarra
    [112869] 	= 	true, -- Summon Observer
    [120451] 	= 	true, -- Flames of Xoroth
    [29893] 	= 	true, -- Create Soulwell
    [112866] 	= 	true, -- Summon Fel Imp
    [108683] 	= 	true, -- Fire and Brimstone
    [688] 	= 	true, -- Summon Imp
    [112870] 	= 	true, -- Summon Wrathguard
    [104316] 	= 	true, -- Imp Swarm

    -- Warrior
    [18499]	=	true, -- Berserker Rage (class)
    [100]	=	true, -- Charge
    [6673]	=	true, -- Battle Shout
    [52174]	=	true, -- Heroic Leap
    [355]	=	true, -- Taunt
    [2457] 	= 	true, -- Battle Stance
    [12328] 	= 	true, -- Sweeping Strikes
    [114192] 	= 	true, -- Mocking Banner
  }
  -- CT.spells.ClassSpellList = {
  --
  -- 	-- Death Knight
  -- 		[152280]	=	"DEATHKNIGHT", -- "Defile"
  -- 		[152279]	=	"DEATHKNIGHT", -- "Breath of Sindragosa"
  -- 		[165569]	=	"DEATHKNIGHT", -- "Frozen Runeblade"
  -- 		[156000]	=	"DEATHKNIGHT", -- "Defile"
  -- 		[50401]	=	"DEATHKNIGHT", -- "Razorice"
  -- 		[155166]	=	"DEATHKNIGHT", -- "Mark of Sindragosa"
  -- 		[66198]	=	"DEATHKNIGHT", -- "Obliterate Off-Hand"
  -- 		[52212]	=	"DEATHKNIGHT", -- "Death and Decay"
  -- 		[168828]	=	"DEATHKNIGHT", -- "Necrosis"
  -- 		[66196]	=	"DEATHKNIGHT", -- "Frost Strike Off-Hand"
  -- 		[66216]	=	"DEATHKNIGHT", -- "Plague Strike Off-Hand"
  -- 		[108194]	=	"DEATHKNIGHT", --  Asphyxiate
  -- 		[50977]	=	"DEATHKNIGHT", --  Death Gate
  -- 		[108199]	=	"DEATHKNIGHT", --  Gorefiend's Grasp
  -- 		[108201]	=	"DEATHKNIGHT", --  Desecrated Ground
  -- 		[48265]	=	"DEATHKNIGHT", --  Unholy Presence
  -- 		[77606]	=	"DEATHKNIGHT", --  Dark Simulacrum
  -- 		[61999]	=	"DEATHKNIGHT", --  Raise Ally
  -- 		[108196]	=	"DEATHKNIGHT", --Death Siphon
  -- 		[47541]	=	"DEATHKNIGHT", -- Death Coil
  -- 		--[48721]	=	"DEATHKNIGHT", -- Blood Boil
  -- 		[42650]	=	"DEATHKNIGHT", -- Army of the Dead
  -- 		[130736]	=	"DEATHKNIGHT", -- Soul Reaper
  -- 		[45524]	=	"DEATHKNIGHT", -- Chains of Ice
  -- 		[57330]	=	"DEATHKNIGHT", -- Horn of Winter
  -- 		[45462]	=	"DEATHKNIGHT", -- Plague Strike
  -- 		[85948]	=	"DEATHKNIGHT", -- Festering Strike
  -- 		--[56815]	=	"DEATHKNIGHT", -- Rune Strike
  -- 		[63560]	=	"DEATHKNIGHT", -- Dark Transformation
  -- 		[108200]	=	"DEATHKNIGHT", -- Remorseless Winter
  -- 		[49222]	=	"DEATHKNIGHT", -- Bone Shield
  -- 		[45477]	=	"DEATHKNIGHT", -- Icy Touch
  -- 		[43265]	=	"DEATHKNIGHT", -- Death and Decay
  -- 		[77575]	=	"DEATHKNIGHT", -- Outbreak
  -- 		[51271]	=	"DEATHKNIGHT", -- Pillar of Frost
  -- 		[115989]	=	"DEATHKNIGHT", -- Unholy Blight
  -- 		[48792]	=	"DEATHKNIGHT", -- Icebound Fortitude
  -- 		--[55050]	=	"DEATHKNIGHT", -- Heart Strike
  -- 		[55233]	=	"DEATHKNIGHT", -- Vampiric Blood
  -- 		[49576]	=	"DEATHKNIGHT", -- Death Grip
  -- 		[119975]	=	"DEATHKNIGHT", -- Conversion
  -- 		[56222]	=	"DEATHKNIGHT", -- Dark Command
  -- 		[114866]	=	"DEATHKNIGHT", -- Soul Reaper
  -- 		--[73975]	=	"DEATHKNIGHT", -- Necrotic Strike
  -- 		[45529]	=	"DEATHKNIGHT", -- Blood Tap
  -- 		[130735]	=	"DEATHKNIGHT", -- Soul Reaper
  -- 		[50842]	=	"DEATHKNIGHT", -- Pestilence
  -- 		[48743]	=	"DEATHKNIGHT", -- Death Pact
  -- 		[47528]	=	"DEATHKNIGHT", -- Mind Freeze
  -- 		[123693]	=	"DEATHKNIGHT", -- Plague Leech
  -- 		[3714]	=	"DEATHKNIGHT", -- Path of Frost
  -- 		[48263]	=	"DEATHKNIGHT", -- Blood Presence
  -- 		[49039]	=	"DEATHKNIGHT", -- Lichborne
  -- 		[49028]	=	"DEATHKNIGHT", -- Dancing Rune Weapon
  -- 		[47568]	=	"DEATHKNIGHT", -- Empower Rune Weapon
  -- 		[96268]	=	"DEATHKNIGHT", -- Death's Advance
  -- 		--[49016]	=	"DEATHKNIGHT", -- Unholy Frenzy
  -- 		[49206]	=	"DEATHKNIGHT", -- Summon Gargoyle
  -- 		[48266]	=	"DEATHKNIGHT", -- Frost Presence
  -- 		--[45902]	=	"DEATHKNIGHT", -- Blood Strike
  -- 		[77535]	=	"DEATHKNIGHT", --Blood Shield (heal)
  -- 		[45470]	=	"DEATHKNIGHT", --Death Strike (heal)
  -- 		[53365]	=	"DEATHKNIGHT", --Unholy Strength (heal)
  -- 		[48707]	=	"DEATHKNIGHT", -- Anti-Magic Shell (heal)
  -- 		[48982]	=	"DEATHKNIGHT", --rune tap
  -- 		[49020]	=	"DEATHKNIGHT", --obliterate
  -- 		[49143]	=	"DEATHKNIGHT", --frost strike
  -- 		[55095]	=	"DEATHKNIGHT", --frost fever
  -- 		[55078]	=	"DEATHKNIGHT", --blood plague
  -- 		[49184]	=	"DEATHKNIGHT", --howling blast
  -- 		[49998]	=	"DEATHKNIGHT", --death strike
  -- 		[55090]	=	"DEATHKNIGHT",--scourge strike
  -- 		[47632]	=	"DEATHKNIGHT",--death coil
  --
  -- 	-- Druid
  -- 		[145110]	=	"DRUID", -- "Ysera's Gift"
  -- 		[155777]	=	"DRUID", -- "Rejuvenation (Germination)"
  -- 		[101024]	=	"DRUID", -- "Glyph of Ferocious Bite"
  -- 		[124988]	=	"DRUID", -- "Nature's Vigil"
  -- 		[172176]	=	"DRUID", -- "Dream of Cenarius"
  -- 		[102352]	=	"DRUID", -- "Cenarion Ward"
  -- 		[162359]	=	"DRUID", -- "Genesis"
  -- 		[157982]	=	"DRUID", -- "Tranquility"
  -- 		[155835]	=	"DRUID", -- "Bristling Fur"
  -- 		[20484]	=	"DRUID", -- "Rebirth"
  -- 		[106839]	=	"DRUID", -- "Skull Bash"
  -- 		[42231]	=	"DRUID", -- "Hurricane"
  -- 		[164815]	=	"DRUID", -- "Sunfire"
  -- 		[164812]	=	"DRUID", -- "Moonfire"
  -- 		[106785]	=	"DRUID", -- "Swipe"
  -- 		[50288]	=	"DRUID", -- "Starfall"
  -- 		[152221]	=	"DRUID", -- "Stellar Flare"
  -- 		[80313]	=	"DRUID", -- "Pulverize"
  -- 		[124991]	=	"DRUID", -- "Nature's Vigil"
  -- 		[33917]	=	"DRUID", -- "Mangle"
  -- 		--[80965]	=	 "DRUID", --  Skull Bash
  -- 		--[16689]	=	 "DRUID", --  Nature's Grasp
  -- 		[102417]	=	 "DRUID", --  Wild Charge
  -- 		--[5229]	=	 "DRUID", --  Enrage
  -- 		[78675]	=	 "DRUID", --  Solar Beam
  -- 		[102351]	=	 "DRUID", --  Cenarion Ward
  -- 		--[9005]	=	 "DRUID", --  Pounce
  -- 		[114282]	=	 "DRUID", --  Treant Form
  -- 		[5215]	=	 "DRUID", --  Prowl
  -- 		[52610]	=	 "DRUID", --  Savage Roar
  -- 		[22570]	=	 "DRUID", --  Maim
  -- 		[102401]	=	 "DRUID", --  Wild Charge
  -- 		[33831]	=	 "DRUID", --  Force of Nature
  -- 		[102355]	=	 "DRUID", --  Faerie Swarm
  -- 		[102706]	=	 "DRUID", --  Force of Nature
  -- 		[16914]	=	 "DRUID", --  Hurricane
  -- 		[2908]	=	 "DRUID", --  Soothe
  -- 		--[62078]	=	 "DRUID", --  Swipe
  -- 		[102793]	=	 "DRUID", --  Ursol's Vortex
  -- 		[106996]	=	 "DRUID", --  Astral Storm
  -- 		--[6785]	=	 "DRUID", --  Ravage
  -- 		[106898]	=	 "DRUID", --  Stampeding Roar
  -- 		[33891]	=	 "DRUID", --  Incarnation: Tree of Life
  -- 		[102359]	=	 "DRUID", --  Mass Entanglement
  -- 		[108293]	=	 "DRUID", --  Heart of the Wild
  -- 		[5211]	=	 "DRUID", --  Mighty Bash
  -- 		--[102795]	=	 "DRUID", --  Bear Hug
  -- 		[108291]	=	 "DRUID", --  Heart of the Wild
  -- 		[18562]	=	 "DRUID", --Swiftmend
  -- 		--[106922]	=	 "DRUID", -- Might of Ursoc
  -- 		[132158]	=	 "DRUID", -- Nature's Swiftness
  -- 		[33763]	=	 "DRUID", -- Lifebloom
  -- 		[1126]	=	 "DRUID", -- Mark of the Wild
  -- 		[6807]	=	 "DRUID", -- Maul
  -- 		[33745]	=	 "DRUID", -- Lacerate
  -- 		[145205]	=	 "DRUID", -- Wild Mushroom
  -- 		[77761]	=	 "DRUID", -- Stampeding Roar
  -- 		--[102791]	=	 "DRUID", -- Wild Mushroom: Bloom
  -- 		[16953]	=	 "DRUID", -- Primal Fury
  -- 		[102693]	=	 "DRUID", -- Force of Nature
  -- 		[145518]	=	 "DRUID", -- Genesis
  -- 		[22812]	=	 "DRUID", -- Barkskin
  -- 		[770]	=	 "DRUID", -- Faerie Fire
  -- 		[106951]	=	 "DRUID", -- Berserk
  -- 		[124974]	=	 "DRUID", -- Nature's Vigil
  -- 		[105697]	=	 "DRUID", -- Virmen's Bite
  -- 		[5225]	=	 "DRUID", -- Track Humanoids
  -- 		[102280]	=	 "DRUID", -- Displacer Beast
  -- 		[102543]	=	 "DRUID", -- Incarnation: King of the Jungle
  -- 		[1850]	=	 "DRUID", -- Dash
  -- 		[77764]	=	 "DRUID", -- Stampeding Roar
  -- 		[22568]	=	 "DRUID", -- Ferocious Bite
  -- 		--[779]	=	 "DRUID", -- Swipe
  -- 		[147349]	=	 "DRUID", -- Wild Mushroom
  -- 		[77758]	=	 "DRUID", -- Thrash
  -- 		[108294]	=	 "DRUID", -- Heart of the Wild
  -- 		[106830]	=	 "DRUID", -- Thrash
  -- 		[108292]	=	 "DRUID", -- Heart of the Wild
  -- 		[768]	=	 "DRUID", -- Cat Form
  -- 		--[127538]	=	 "DRUID", -- Savage Roar
  -- 		[61336]	=	 "DRUID", -- Survival Instincts
  -- 		--[114236]	=	 "DRUID", -- Shred!
  -- 		[146323]	=	 "DRUID", -- Inward Contemplation
  -- 		[22842]	=	 "DRUID", -- Frenzied Regeneration
  -- 		[108238]	=	 "DRUID", -- Renewal
  -- 		[16979]	=	 "DRUID", -- Wild Charge
  -- 		[50334]	=	 "DRUID", -- Berserk
  -- 		[102558]	=	 "DRUID", -- Incarnation: Son of Ursoc
  -- 		[6795]	=	 "DRUID", -- Growl
  -- 		[48505]	=	 "DRUID", -- Starfall
  -- 		[78674]	=	 "DRUID", -- Starsurge
  -- 		[102560]	=	 "DRUID", -- Incarnation: Chosen of Elune
  -- 		[112071]	=	 "DRUID", -- Celestial Alignment
  -- 		[61391]	=	 "DRUID", -- Typhoon
  -- 		[24858]	=	 "DRUID", -- Moonkin Form
  -- 		[136086]	=	 "DRUID", -- Archer's Grace
  -- 		[127663]	=	 "DRUID", -- Astral Communion
  -- 		[49376]	=	 "DRUID", -- Wild Charge
  -- 		[62606]	=	 "DRUID", -- Savage Defense
  -- 		--[80964]	=	 "DRUID", -- Skull Bash
  -- 		[1822] 	=	"DRUID", --rake
  -- 		[1079] 	=	"DRUID", --rip
  -- 		[5221] 	=	"DRUID", --shred
  -- 		--[33876]	=	"DRUID", --mangle
  -- 		--[33878]	=	"DRUID", --mangle (energy)
  -- 		--[102545]	=	"DRUID", --ravage!
  -- 		--[33878]	=	"DRUID", --mangle (energy gain)
  -- 		[17057]	=	"DRUID", --bear form (energy gain)
  -- 		[16959]	=	"DRUID", --primal fury (energy gain)
  -- 		[5217]	=	"DRUID", --tiger's fury (energy gain)
  -- 		[68285]	=	"DRUID", --leader of the pack (mana)
  -- 		[5176]	=	"DRUID", --wrath
  -- 		[93402]	=	"DRUID", --sunfire
  -- 		[2912]	=	"DRUID", --starfire
  -- 		[8921]	=	"DRUID", --moonfire
  -- 		--[81070]	=	"DRUID", --eclipse
  -- 		--[29166]	=	"DRUID", --innervate
  -- 		[774]	=	"DRUID", --rejuvenation
  -- 		--[44203]	=	"DRUID", --tranquility
  -- 		[48438]	=	"DRUID", --wild growth
  -- 		[81269]	=	"DRUID", --shiftmend
  -- 		--[102792]	=	"DRUID", --wind moshroom: bloom
  -- 		[5185]	=	"DRUID", --healing touch
  -- 		[8936]	=	"DRUID", --regrowth
  -- 		[33778]	=	"DRUID", --lifebloom
  -- 		[48503]	=	"DRUID", --living seed
  -- 		--[50464]	=	"DRUID", --nourish
  --
  -- 	-- Hunter
  -- 		[53353]	=	"HUNTER", -- "Chimaera Shot"
  -- 		[164851]	=	"HUNTER", -- "Kill Shot"
  -- 		[164857]	=	"HUNTER", -- "Survivalist"
  -- 		[115927]	=	"HUNTER", -- "Liberation"
  -- 		[132764]	=	"HUNTER", -- "Dire Beast"
  -- 		[160206]	=	"HUNTER", -- "Lone Wolf: Power of the Primates"
  -- 		[13813]	=	"HUNTER", -- "Explosive Trap"
  -- 		[60192]	=	"HUNTER", -- "Freezing Trap"
  -- 		[172106]	=	"HUNTER", -- "Aspect of the Fox"
  -- 		[162537]	=	"HUNTER", -- "Poisoned Ammo"
  -- 		[162536]	=	"HUNTER", -- "Incendiary Ammo"
  -- 		[13812]	=	"HUNTER", -- "Explosive Trap"
  -- 		[157708]	=	"HUNTER", -- "Kill Shot"
  -- 		[120761]	=	"HUNTER", -- "Glaive Toss"
  -- 		[171454]	=	"HUNTER", -- "Chimaera Shot"
  -- 		[162541]	=	"HUNTER", -- "Incendiary Ammo"
  -- 		--[19503]	=	"HUNTER",--  Scatter Shot HUNTER
  -- 		[83245]	=	"HUNTER",--  Call Pet 5 HUNTER
  -- 		[51753]	=	"HUNTER",--  Camouflage HUNTER
  -- 		--[13165]	=	"HUNTER",--  Aspect of the Hawk HUNTER
  -- 		[109259]	=	"HUNTER",--  Powershot HUNTER
  -- 		[53271]	=	"HUNTER",--  Master's Call HUNTER
  -- 		[20736]	=	"HUNTER",--  Distracting Shot HUNTER
  -- 		[1543]	=	"HUNTER",--  Flare HUNTER
  -- 		[3674]	=	"HUNTER",-- Black Arrow
  -- 		[117050]	=	"HUNTER",-- Glaive Toss
  -- 		--[1978]	=	"HUNTER",-- Serpent Sting
  -- 		[781]	=	"HUNTER",-- Disengage
  -- 		[34026]	=	"HUNTER",-- Kill Command
  -- 		[82948]	=	"HUNTER",-- Snake Trap
  -- 		[2643]	=	"HUNTER",-- Multi-Shot
  -- 		[109248]	=	"HUNTER",-- Binding Shot
  -- 		[149365]	=	"HUNTER",-- Dire Beast
  -- 		[120679]	=	"HUNTER",-- Dire Beast
  -- 		[82726]	=	"HUNTER",-- Fervor
  -- 		[3045]	=	"HUNTER",-- Rapid Fire
  -- 		[883]	=	"HUNTER",-- Call Pet 1
  -- 		[19574]	=	"HUNTER",-- Bestial Wrath
  -- 		[148467]	=	"HUNTER",-- Deterrence
  -- 		[109304]	=	"HUNTER",-- Exhilaration
  -- 		[82939]	=	"HUNTER",-- Explosive Trap
  -- 		[19386]	=	"HUNTER",-- Wyvern Sting
  -- 		[131894]	=	"HUNTER",-- A Murder of Crows
  -- 		[13159]	=	"HUNTER",-- Aspect of the Pack
  -- 		[109260]	=	"HUNTER",-- Aspect of the Iron Hawk
  -- 		[121818]	=	"HUNTER",-- Stampede
  -- 		[19434]	=	"HUNTER",-- Aimed Shot
  -- 		[82941]	=	"HUNTER",-- Ice Trap
  -- 		[83242]	=	"HUNTER",-- Call Pet 2
  -- 		[120697]	=	"HUNTER",-- Lynx Rush
  -- 		[56641]	=	"HUNTER",-- Steady Shot
  -- 		[82692]	=	"HUNTER",-- Focus Fire
  -- 		--[34490]	=	"HUNTER",-- Silencing Shot
  -- 		[53209]	=	"HUNTER",-- Chimera Shot
  -- 		--[82928]	=	"HUNTER",-- Aimed Shot!
  -- 		[83243]	=	"HUNTER",-- Call Pet 3
  -- 		[5116]	=	"HUNTER",-- Concussive Shot
  -- 		[1130]	=	"HUNTER",--'s Mark
  -- 		[34477]	=	"HUNTER",-- Misdirection
  -- 		[19263]	=	"HUNTER",-- Deterrence
  -- 		[147362]	=	"HUNTER",-- Counter Shot
  -- 		[19801]	=	"HUNTER",-- Tranquilizing Shot
  -- 		--[82654]	=	"HUNTER",-- Widow Venom
  -- 		[2641]	=	"HUNTER",-- Dismiss Pet
  -- 		[83244]	=	"HUNTER",-- Call Pet 4
  -- 		[5118]	=	"HUNTER",-- Aspect of the Cheetah
  -- 		[120360]	=	"HUNTER",-- Barrage
  -- 		[19577]	=	"HUNTER",-- Intimidation
  -- 		[131900]	=	"HUNTER",--a murder of crows
  -- 		[118253]	=	"HUNTER",--serpent sting
  -- 		[77767]	=	"HUNTER",--cobra shot
  -- 		[3044]	=	"HUNTER",--arcane shot
  -- 		[53301]	=	"HUNTER",--explosive shot
  -- 		[120361]	=	"HUNTER",--barrage
  -- 		[53351]	=	"HUNTER",--kill shot
  --
  -- 	-- Mage
  -- 		[87023]	=	"MAGE", -- "Cauterize"
  -- 		[152087]	=	"MAGE", -- "Prismatic Crystal"
  -- 		[157750]	=	"MAGE", -- "Summon Water Elemental"
  -- 		[159916]	=	"MAGE", -- "Amplify Magic"
  -- 		[157913]	=	"MAGE", -- "Evanesce"
  -- 		[153561]	=	"MAGE", -- "Meteor"
  -- 		[157978]	=	"MAGE", -- "Unstable Magic"
  -- 		[157980]	=	"MAGE", -- "Supernova"
  -- 		[153564]	=	"MAGE", -- "Meteor"
  -- 		[44461]	=	"MAGE", -- "Living Bomb"
  -- 		[148022]	=	"MAGE", -- "Icicle"
  -- 		[155152]	=	"MAGE", -- "Prismatic Crystal"
  -- 		[108839]	=	"MAGE",--  Ice Floes
  -- 		[7302]	=	"MAGE",--  Frost Armor
  -- 		[31661]	=	"MAGE",--  Dragon's Breath
  -- 		[53140]	=	"MAGE",--  Teleport: Dalaran
  -- 		[11417]	=	"MAGE",--  Portal: Orgrimmar
  -- 		[42955]	=	"MAGE",--  Conjure Refreshment
  -- 		[44457]	=	"MAGE",-- Living Bomb
  -- 		[1953]	=	"MAGE",-- Blink
  -- 		[108843]	=	"MAGE",-- Blazing Speed
  -- 		--[131078]	=	"MAGE",-- Icy Veins
  -- 		[12043]	=	"MAGE",-- Presence of Mind
  -- 		[108978]	=	"MAGE",-- Alter Time
  -- 		[55342]	=	"MAGE",-- Mirror Image
  -- 		[84714]	=	"MAGE",-- Frozen Orb
  -- 		[45438]	=	"MAGE",-- Ice Block
  -- 		[115610]	=	"MAGE",-- Temporal Shield
  -- 		[110960]	=	"MAGE",-- Greater Invisibility
  -- 		[110959]	=	"MAGE",-- Greater Invisibility
  -- 		[11129]	=	"MAGE",-- Combustion
  -- 		[11958]	=	"MAGE",-- Cold Snap
  -- 		[61316]	=	"MAGE",-- Dalaran Brilliance
  -- 		[112948]	=	"MAGE",-- Frost Bomb
  -- 		[2139]	=	"MAGE",-- Counterspell
  -- 		[80353]	=	"MAGE",-- Time Warp
  -- 		[2136]	=	"MAGE",-- Fire Blast
  -- 		[7268]	=	"MAGE",-- Arcane Missiles
  -- 		[111264]	=	"MAGE",-- Ice Ward
  -- 		[114923]	=	"MAGE",-- Nether Tempest
  -- 		[2120]	=	"MAGE",-- Flamestrike
  -- 		[44425]	=	"MAGE",-- Arcane Barrage
  -- 		[12042]	=	"MAGE",-- Arcane Power
  -- 		[1459]	=	"MAGE",-- Arcane Brilliance
  -- 		[127140]	=	"MAGE",-- Alter Time
  -- 		[116011]	=	"MAGE",-- Rune of Power
  -- 		[116014]	=	"MAGE",-- Rune of Power
  -- 		[132627]	=	"MAGE",-- Teleport: Vale of Eternal Blossoms
  -- 		[31687]	=	"MAGE",-- Summon Water Elemental
  -- 		[3567]	=	"MAGE",-- Teleport: Orgrimmar
  -- 		[30449]	=	"MAGE",-- Spellsteal
  -- 		[44572]	=	"MAGE",-- Deep Freeze
  -- 		[113724]	=	"MAGE",-- Ring of Frost
  -- 		[132626]	=	"MAGE",-- Portal: Vale of Eternal Blossoms
  -- 		[12472]	=	"MAGE",-- Icy Veins
  -- 		[116]	=	"MAGE",--frost bolt
  -- 		[30455]	=	"MAGE",--ice lance
  -- 		[84721]	=	"MAGE",--frozen orb
  -- 		[1449]	=	"MAGE",--arcane explosion
  -- 		[113092]	=	"MAGE",--frost bomb
  -- 		[115757]	=	"MAGE",--frost nova
  -- 		[44614]	=	"MAGE",--forstfire bolt
  -- 		[42208]	=	"MAGE",--blizzard
  -- 		[11426]	=	"MAGE",--Ice Barrier (heal)
  -- 		[11366]	=	"MAGE",--pyroblast
  -- 		[133]	=	"MAGE",--fireball
  -- 		[108853]	=	"MAGE",--infernoblast
  -- 		[2948]	=	"MAGE",--scorch
  -- 		[30451]	=	"MAGE",--arcane blase
  -- 		[12051]	=	"MAGE",--evocation
  --
  -- 	-- Monk
  -- 		[116995]	=	"MONK", -- "Surging Mist"
  -- 		[162530]	=	"MONK", -- "Rushing Jade Wind"
  -- 		[157675]	=	"MONK", -- "Chi Explosion"
  -- 		[157590]	=	"MONK", -- "Breath of the Serpent"
  -- 		[128591]	=	"MONK", -- "Blackout Kick"
  -- 		[122281]	=	"MONK", -- "Healing Elixirs"
  -- 		[124101]	=	"MONK", -- "Zen Sphere: Detonate"
  -- 		[119031]	=	"MONK", -- "Gift of the Serpent"
  -- 		[137562]	=	"MONK", -- "Nimble Brew"
  -- 		[157535]	=	"MONK", -- "Breath of the Serpent"
  -- 		[152173]	=	"MONK", -- "Serenity"
  -- 		[152175]	=	"MONK", -- "Hurricane Strike"
  -- 		[148187]	=	"MONK", -- "Rushing Jade Wind"
  -- 		[124098]	=	"MONK", -- "Zen Sphere"
  -- 		[125033]	=	"MONK", -- "Zen Sphere: Detonate"
  -- 		[158221]	=	"MONK", -- "Hurricane Strike"
  -- 		[115129]	=	"MONK", -- "Expel Harm"
  -- 		[152174]	=	"MONK", -- "Chi Explosion"
  -- 		[123586]	=	"MONK", -- "Flying Serpent Kick"
  -- 		[115176]	=	"MONK", -- Zen Meditation cooldown
  -- 		[115203]	=	"MONK", -- Fortifying Brew
  -- 		--[115213]	=	"MONK", -- Avert Harm
  --
  -- 		[124081]	=	"MONK", -- Zen Sphere
  -- 		[125355]	=	"MONK", -- Healing Sphere
  -- 		[122278]	=	"MONK", -- Dampen Harm
  -- 		[115450]	=	"MONK", -- Detox
  --
  -- 		[121827]	=	"MONK", -- Roll
  -- 		[115315]	=	"MONK", -- Summon Black Ox Statue
  -- 		[115399]	=	"MONK", -- Chi Brew
  -- 		[101643]	=	"MONK", -- Transcendence
  -- 		[115546]	=	"MONK", -- Provoke
  -- 		[115294]	=	"MONK", -- Mana Tea
  -- 		[116680]	=	"MONK", -- Thunder Focus Tea
  -- 		[115070]	=	"MONK", -- Stance of the Wise Serpent
  -- 		[115069]	=	"MONK", -- Stance of the Sturdy Ox
  --
  -- 		[119381]	=	"MONK", -- Leg Sweep
  -- 		[115695]	=	"MONK", -- Jab
  -- 		[137639]	=	"MONK", -- Storm, Earth, and Fire
  -- 		--[115073]	=	"MONK", -- Spinning Fire Blossom
  -- 		[115008]	=	"MONK", -- Chi Torpedo
  -- 		[121828]	=	"MONK", -- --Chi Torpedo
  -- 		[115180]	=	"MONK", -- Dizzying Haze
  -- 		[123986]	=	"MONK", -- Chi Burst
  -- 		[130654]	=	"MONK", -- Chi Burst
  -- 		[148135]	=	"MONK", -- Chi Burst
  -- 		[119392]	=	"MONK", -- Charging Ox Wave
  -- 		[116095]	=	"MONK", -- Disable
  -- 		[115687]	=	"MONK", -- Jab
  -- 		[117993]	=	"MONK", -- Chi Torpedo
  -- 		[100780]	=	"MONK", -- Jab
  -- 		[116740]	=	"MONK", -- Tigereye Brew
  -- 		[124682]	=	"MONK", -- Enveloping Mist
  -- 		[101545]	=	"MONK", -- Flying Serpent Kick
  -- 		[109132]	=	"MONK", -- Roll
  -- 		[122470]	=	"MONK", -- Touch of Karma
  -- 		[117418]	=	"MONK", -- Fists of Fury
  -- 		[113656]	=	"MONK", -- Fists of Fury
  -- 		[115698]	=	"MONK", -- Jab
  -- 		[115460]	=	"MONK", -- Healing Sphere
  -- 		[115098]	=	"MONK", -- Chi Wave
  -- 		--[115464]	=	"MONK", -- Healing Sphere
  -- 		[115151]	=	"MONK", -- Renewing Mist
  -- 		[117952]	=	"MONK", -- Crackling Jade Lightning
  -- 		[122783]	=	"MONK", -- Diffuse Magic
  -- 		[115078]	=	"MONK", -- Paralysis
  -- 		[116705]	=	"MONK", -- Spear Hand Strike
  -- 		[123904]	=	"MONK", -- Invoke Xuen, the White Tiger
  -- 		--[116709]	=	"MONK", -- Spear Hand Strike
  -- 		[147489]	=	"MONK", -- Expel Harm
  -- 		[101546]	=	"MONK", -- Spinning Crane Kick
  -- 		[115313]	=	"MONK", -- Summon Jade Serpent Statue
  -- 		[135920]	=	"MONK", -- Gift of the Serpent
  -- 		[116841]	=	"MONK", -- Tiger's Lust
  -- 		[116694]	=	"MONK", -- Surging Mist
  -- 		[116847]	=	"MONK", -- Rushing Jade Wind
  -- 		[108557]	=	"MONK", -- Jab
  -- 		[115181]	=	"MONK", -- Breath of Fire
  -- 		[121253]	=	"MONK", -- Keg Smash
  -- 		[124506]	=	"MONK", -- Gift of the Ox
  -- 		[124503]	=	"MONK", -- Gift of the Ox
  -- 		[115288]	=	"MONK", -- Energizing Brew
  -- 		[115308]	=	"MONK", -- Elusive Brew
  -- 		[116781]	=	"MONK", -- Legacy of the White Tiger
  -- 		[115921]	=	"MONK", -- Legacy of the Emperor
  -- 		[115693]	=	"MONK", -- Jab
  -- 		[124507]	=	"MONK", -- Gift of the Ox
  -- 		[119582]	=	"MONK", -- Purifying Brew
  -- 		[115080]	=	"MONK", -- Touch of Death
  -- 		--[135914]	=	"MONK", -- Healing Sphere
  -- 		[126892]	=	"MONK", -- Zen Pilgrimage
  -- 		[116849]	=	"MONK", -- Life Cocoon
  -- 		[116844]	=	"MONK", -- Ring of Peace
  -- 		[107428]	=	"MONK", --rising sun kick
  -- 		[100784]	=	"MONK", --blackout kick
  -- 		[132467]	=	"MONK", --Chi wave
  -- 		[107270]	=	"MONK", --spinning crane kick
  -- 		[100787]	=	"MONK", --tiger palm
  -- 		[123761]	=	"MONK", --mana tea
  -- 		[119611]	=	"MONK", --renewing mist
  -- 		[115310]	=	"MONK", --revival
  -- 		[116670]	=	"MONK", --uplift
  -- 		[115175]	=	"MONK", --soothing mist
  -- 		[124041]	=	"MONK", --gift of the serpent
  -- 		[124040]	=	"MONK", -- shi torpedo
  -- 		[132120]	=	"MONK", -- enveloping mist
  -- 		[132463]	=	"MONK", -- shi wave
  -- 		[117895]	=	"MONK", --eminence (statue)
  -- 		[115295]	=	"MONK", --guard
  -- 		[115072]	=	"MONK", --expel harm
  --
  -- 	-- Paladin
  -- 		[121129]	=	"PALADIN", -- "Daybreak"
  -- 		[159375]	=	"PALADIN", -- "Shining Protector"
  -- 		[130551]	=	"PALADIN", -- "Word of Glory"
  -- 		[115536]	=	"PALADIN", -- "Glyph of Protector of the Innocent"
  -- 		[66235]	=	"PALADIN", -- "Ardent Defender"
  -- 		[152262]	=	"PALADIN", -- "Seraphim"
  -- 		[20164]	=	"PALADIN", -- "Seal of Justice"
  -- 		[20170]	=	"PALADIN", -- "Seal of Justice"
  -- 		[157122]	=	"PALADIN", -- "Holy Shield"
  -- 		[96172]	=	"PALADIN", -- "Hand of Light"
  -- 		[101423]	=	"PALADIN", -- "Seal of Righteousness"
  -- 		[42463]	=	"PALADIN", -- "Seal of Truth"
  -- 		[25912]	=	"PALADIN", -- "Holy Shock"
  -- 		[114852]	=	"PALADIN", -- "Holy Prism"
  -- 		[114919]	=	"PALADIN", -- "Arcing Light"
  -- 		[31850] 	= 	"PALADIN", -- Ardent Defender
  -- 		[31842] 	= 	"PALADIN", -- Divine Favor
  -- 		[1044] 	= 	"PALADIN", -- Hand of Freedom
  -- 		[114039] 	= 	"PALADIN", -- Hand of Purity
  -- 		[4987] 	= 	"PALADIN", -- Cleanse
  -- 		[136494] 	= 	"PALADIN", -- Word of Glory
  -- 		--[54428] 	= 	"PALADIN", -- Divine Plea
  -- 		[7328] 	= 	"PALADIN", -- Redemption
  -- 		[116467] 	= 	"PALADIN", -- Consecration
  -- 		[31801] 	= 	"PALADIN", -- Seal of Truth
  -- 		[20165] 	= 	"PALADIN", -- Seal of Insight
  -- 		[20473]	=	"PALADIN",-- Holy Shock
  -- 		[114158]	=	"PALADIN",-- Light's Hammer
  -- 		[85673]	=	"PALADIN",-- Word of Glory
  -- 		[85499]	=	"PALADIN",-- Speed of Light
  -- 		--[84963]	=	"PALADIN",-- Inquisition
  -- 		[31884]	=	"PALADIN",-- Avenging Wrath
  -- 		[24275]	=	"PALADIN",-- Hammer of Wrath
  -- 		[114165]	=	"PALADIN",-- Holy Prism
  -- 		[20925]	=	"PALADIN",-- Sacred Shield
  -- 		[53563]	=	"PALADIN",-- Beacon of Light
  -- 		[633]	=	"PALADIN",-- Lay on Hands
  -- 		[88263]	=	"PALADIN",-- Hammer of the Righteous
  -- 		[53595]	=	"PALADIN",-- Hammer of the Righteous
  -- 		[53600]	=	"PALADIN",-- Shield of the Righteous
  -- 		[26573]	=	"PALADIN",-- Consecration
  -- 		[119072]	=	"PALADIN",-- Holy Wrath
  -- 		[105593]	=	"PALADIN",-- Fist of Justice
  -- 		[114163]	=	"PALADIN",-- Eternal Flame
  -- 		[62124]	=	"PALADIN",-- Reckoning
  -- 		[121783]	=	"PALADIN",-- Emancipate
  -- 		[98057]	=	"PALADIN",-- Grand Crusader
  -- 		[642]	=	"PALADIN",-- Divine Shield
  -- 		[122032]	=	"PALADIN",-- Exorcism
  -- 		[20217]	=	"PALADIN",-- Blessing of Kings
  -- 		[96231]	=	"PALADIN",-- Rebuke
  -- 		[105809]	=	"PALADIN",-- Holy Avenger
  -- 		[25780]	=	"PALADIN",-- Righteous Fury
  -- 		[115750]	=	"PALADIN",-- Blinding Light
  -- 		[31821]	=	"PALADIN",-- Devotion Aura
  -- 		[53385]	=	"PALADIN",-- Divine Storm
  -- 		[20154]	=	"PALADIN",-- Seal of Righteousness
  -- 		[19740]	=	"PALADIN",-- Blessing of Might
  -- 		[148039]	=	"PALADIN",-- Sacred Shield
  -- 		[82326]	=	"PALADIN",-- Divine Light
  -- 		[35395]	=	"PALADIN",--cruzade strike
  -- 		[879]	=	"PALADIN",--exorcism
  -- 		[85256]	=	"PALADIN",--templar's verdict
  -- 		[20167]	=	"PALADIN",--seal of insight (mana)
  -- 		[31935]	=	"PALADIN",--avenger's shield
  -- 		[20271]	=	"PALADIN", --judgment
  -- 		[35395]	=	"PALADIN", --cruzader strike
  -- 		[81297]	=	"PALADIN", --consacration
  -- 		[31803]	=	"PALADIN", --censure
  -- 		[65148]	=	"PALADIN", --Sacred Shield
  -- 		[20167]	=	"PALADIN", --Seal of Insight
  -- 		[86273]	=	"PALADIN", --illuminated healing
  -- 		[85222]	=	"PALADIN", --light of dawn
  -- 		[53652]	=	"PALADIN", --beacon of light
  -- 		[82327]	=	"PALADIN", --holy radiance
  -- 		[119952]	=	"PALADIN", --arcing light
  -- 		[25914]	=	"PALADIN", --holy shock
  -- 		[19750]	=	"PALADIN", --flash of light
  --
  -- 	-- Priest
  -- 		[121148]	=	"PRIEST", -- "Cascade"
  -- 		[94472]	=	"PRIEST", -- "Atonement"
  -- 		[126154]	=	"PRIEST", -- "Lightwell Renew"
  -- 		[23455]	=	"PRIEST", -- "Holy Nova"
  -- 		[140815]	=	"PRIEST", -- "Power Word: Solace"
  -- 		[56160]	=	"PRIEST", -- "Glyph of Power Word: Shield"
  -- 		[152116]	=	"PRIEST", -- "Saving Grace"
  -- 		[147193]	=	"PRIEST", -- "Shadowy Apparition"
  -- 		[155361]	=	"PRIEST", -- "Void Entropy"
  -- 		[73325]	=	"PRIEST", -- "Leap of Faith"
  -- 		[155245]	=	"PRIEST", -- "Clarity of Purpose"
  -- 		[155521]	=	"PRIEST", -- "Auspicious Spirits"
  -- 		[148859]	=	"PRIEST", -- "Shadowy Apparition"
  -- 		[120696]	=	"PRIEST", -- "Halo"
  -- 		[122128]	=	"PRIEST", -- "Divine Star"
  -- 		[132157]	=	"PRIEST", -- "Holy Nova"
  -- 		[19236] 	= 	"PRIEST", -- Desperate Prayer
  -- 		[47788] 	= 	"PRIEST", -- Guardian Spirit
  -- 		[81206] 	= 	"PRIEST", -- Chakra: Sanctuary
  -- 		[62618] 	= 	"PRIEST", -- Power Word: Barrier
  -- 		[32375] 	= 	"PRIEST", -- Mass Dispel
  -- 		[32546] 	= 	"PRIEST", -- Binding Heal
  -- 		[126135] 	= 	"PRIEST", -- Lightwell
  -- 		[81209] 	= 	"PRIEST", -- Chakra: Chastise
  -- 		[81208] 	= 	"PRIEST", -- Chakra: Serenity
  -- 		[2006] 	= 	"PRIEST", -- Resurrection
  -- 		[1706] 	= 	"PRIEST", -- Levitate
  -- 		[73510] 	= 	"PRIEST", -- Mind Spike
  -- 		[127632] 	= 	"PRIEST", -- Cascade
  -- 		--[108921] 	= 	"PRIEST", -- Psyfiend
  -- 		[88625] 	= 	"PRIEST", -- Holy Word: Chastise
  -- 		[121135]	=	"PRIEST", -- Cascade
  -- 		[122121]	=	"PRIEST", -- Divine Star
  -- 		[110744]	=	"PRIEST", -- Divine Star
  -- 		[8122]	=	"PRIEST", -- Psychic Scream
  -- 		[81700]	=	"PRIEST", -- Archangel
  -- 		[123258]	=	"PRIEST", -- Power Word: Shield
  -- 		[48045]	=	"PRIEST", -- Mind Sear
  -- 		[49821]	=	"PRIEST", -- Mind Sear
  -- 		[123040]	=	"PRIEST", -- Mindbender
  -- 		[121536]	=	"PRIEST", -- Angelic Feather
  -- 		[121557]	=	"PRIEST", -- Angelic Feather
  -- 		[88685]	=	"PRIEST", -- Holy Word: Sanctuary
  -- 		[88684]	=	"PRIEST", -- Holy Word: Serenity
  -- 		[33076]	=	"PRIEST", -- Prayer of Mending
  -- 		[32379]	=	"PRIEST", -- Shadow Word: Death
  -- 		[129176]	=	"PRIEST", -- Shadow Word: Death
  -- 		[586]	=	"PRIEST", -- Fade
  -- 		[120517]	=	"PRIEST", -- Halo
  -- 		--[64901]	=	"PRIEST", -- Hymn of Hope
  -- 		[64843]	=	"PRIEST", -- Divine Hymn
  -- 		[64844]	=	"PRIEST", -- Divine Hymn
  -- 		[34433]	=	"PRIEST", -- Shadowfiend
  -- 		[120644]	=	"PRIEST", -- Halo
  -- 		[15487]	=	"PRIEST", -- Silence
  -- 		--[89485]	=	"PRIEST", -- Inner Focus
  -- 		[109964]	=	"PRIEST", -- Spirit Shell
  -- 		[129197]	=	"PRIEST", -- Mind Flay (Insanity)
  -- 		[112833]	=	"PRIEST", -- Spectral Guise
  -- 		[47750]	=	"PRIEST", -- Penance
  -- 		[33206]	=	"PRIEST", -- Pain Suppression
  -- 		[15286]	=	"PRIEST", -- Vampiric Embrace
  -- 		--[588]	=	"PRIEST", -- Inner Fire
  -- 		[21562]	=	"PRIEST", -- Power Word: Fortitude
  -- 		--[73413]	=	"PRIEST", -- Inner Will
  -- 		[10060]	=	"PRIEST", -- Power Infusion
  -- 		--[2050]	=	"PRIEST", -- Heal
  -- 		[15473]	=	"PRIEST", -- Shadowform
  -- 		[108920]	=	"PRIEST", -- Void Tendrils
  -- 		[47585]	=	"PRIEST", -- Dispersion
  -- 		[123259]	=	"PRIEST", -- Prayer of Mending
  -- 		[34650]	=	"PRIEST", --mana leech (pet)
  -- 		[589]	=	"PRIEST", --shadow word: pain
  -- 		[34914]	=	"PRIEST", --vampiric touch
  -- 		--[34919]	=	"PRIEST", --vampiric touch (mana)
  -- 		[15407]	=	"PRIEST", --mind flay
  -- 		[8092]	=	"PRIEST", --mind blast
  -- 		[15290]	=	"PRIEST",-- Vampiric Embrace
  -- 		[127626]	=	"PRIEST",--devouring plague (heal)
  -- 		[2944]	=	"PRIEST",--devouring plague (damage)
  -- 		[585]	=	"PRIEST", --smite
  -- 		[47666]	=	"PRIEST", --penance
  -- 		[14914]	=	"PRIEST", --holy fire
  -- 		[81751]	=	"PRIEST",  --atonement
  -- 		[47753]	=	"PRIEST",  --divine aegis
  -- 		[33110]	=	"PRIEST", --prayer of mending
  -- 		[77489]	=	"PRIEST", --mastery echo of light
  -- 		[596]	=	"PRIEST", --prayer of healing
  -- 		[34861]	=	"PRIEST", --circle of healing
  -- 		[139]	=	"PRIEST", --renew
  -- 		[120692]	=	"PRIEST", --halo
  -- 		[2060]	=	"PRIEST", --greater heal
  -- 		[110745]	=	"PRIEST", --divine star
  -- 		[2061]	=	"PRIEST", --flash heal
  -- 		[88686]	=	"PRIEST", --santuary
  -- 		[17]		=	"PRIEST", --power word: shield
  -- 		--[64904]	=	"PRIEST", --hymn of hope
  -- 		[129250]	=	"PRIEST", --power word: solace
  --
  -- 	-- Rogue
  -- 		[112974]	=	"ROGUE", -- "Leeching Poison"
  -- 		[13877]	=	"ROGUE", -- "Blade Flurry"
  -- 		[57934]	=	"ROGUE", -- "Tricks of the Trade"
  -- 		[152151]	=	"ROGUE", -- "Shadow Reflection"
  -- 		[3408]	=	"ROGUE", -- "Crippling Poison"
  -- 		[157584]	=	"ROGUE", -- "Instant Poison"
  -- 		[114018]	=	"ROGUE", -- "Shroud of Concealment"
  -- 		[152150]	=	"ROGUE", -- "Death from Above"
  -- 		[168963]	=	"ROGUE", -- "Rupture"
  -- 		[22482]	=	"ROGUE", -- "Blade Flurry"
  -- 		[57841]	=	"ROGUE", -- "Killing Spree"
  -- 		[57842]	=	"ROGUE", -- "Killing Spree Off-Hand"
  -- 		[79136]	=	"ROGUE", -- "Venomous Wound"
  -- 		[157607]	=	"ROGUE", -- Instant Poison
  -- 		[86392]	=	"ROGUE", -- "Main Gauche"
  -- 		[74001] 	= 	"ROGUE", -- Combat Readiness
  -- 		[14183] 	= 	"ROGUE", -- Premeditation
  -- 		[108211] 	= 	"ROGUE", -- Leeching Poison
  -- 		--[5761] 	= 	"ROGUE", -- Mind-numbing Poison
  -- 		[8679] 	= 	"ROGUE", -- Wound Poison
  --
  -- 		[137584] 	= 	"ROGUE", -- Shuriken Toss
  -- 		[137585] 	= 	"ROGUE", -- Shuriken Toss Off-hand
  -- 		[1833] 	= 	"ROGUE", -- Cheap Shot
  -- 		[121733] 	= 	"ROGUE", -- Throw
  -- 		[1776] 	= 	"ROGUE", -- Gouge
  -- 		[108212]	=	"ROGUE", -- Burst of Speed
  -- 		[27576]	=	"ROGUE", -- Mutilate Off-Hand
  -- 		[1329]	=	"ROGUE", -- Mutilate
  -- 		[5171]	=	"ROGUE", -- Slice and Dice
  -- 		[2983]	=	"ROGUE", -- Sprint
  -- 		[1966]	=	"ROGUE", -- Feint
  -- 		[36554]	=	"ROGUE", -- Shadowstep
  -- 		[31224]	=	"ROGUE", -- Cloak of Shadows
  -- 		[1784]	=	"ROGUE", -- Stealth
  -- 		[84617]	=	"ROGUE", -- Revealing Strike
  -- 		[13750]	=	"ROGUE", -- Adrenaline Rush
  -- 		--[121471]	=	"ROGUE", -- Shadow Blades
  -- 		--[121473]	=	"ROGUE", -- Shadow Blade
  -- 		[1752]	=	"ROGUE", -- Sinister Strike
  -- 		[51690]	=	"ROGUE", -- Killing Spree
  -- 		--[121474]	=	"ROGUE", -- Shadow Blade Off-hand
  -- 		[1766]	=	"ROGUE", -- Kick
  -- 		[76577]	=	"ROGUE", -- Smoke Bomb
  -- 		[5277]	=	"ROGUE", -- Evasion
  -- 		[137619]	=	"ROGUE", -- Marked for Death
  -- 		--[8647]	=	"ROGUE", -- Expose Armor
  -- 		[79140]	=	"ROGUE", -- Vendetta
  -- 		[51713]	=	"ROGUE", -- Shadow Dance
  -- 		[2823]	=	"ROGUE", -- Deadly Poison
  -- 		[115191]	=	"ROGUE", -- Stealth
  -- 		--[108215]	=	"ROGUE", -- Paralytic Poison
  -- 		[14185]	=	"ROGUE", -- Preparation
  -- 		[2094]	=	"ROGUE", -- Blind
  -- 		[121411]	=	"ROGUE", -- Crimson Tempest
  -- 		[53]		= 	"ROGUE", --backstab
  -- 		[8680]	= 	"ROGUE", --wound pouson
  -- 		[2098]	= 	"ROGUE", --eviscerate
  -- 		[2818]	=	"ROGUE", --deadly poison
  -- 		[113780]	=	"ROGUE", --deadly poison
  -- 		[51723]	=	"ROGUE", --fan of knifes
  -- 		[111240]	=	"ROGUE", --dispatch
  -- 		[703]	=	"ROGUE", --garrote
  -- 		[1943]	=	"ROGUE", --rupture
  -- 		[114014]	=	"ROGUE", --shuriken toss
  -- 		[16511]	=	"ROGUE", --hemorrhage
  -- 		[89775]	=	"ROGUE", --hemorrhage
  -- 		[8676]	=	"ROGUE", --amcush
  -- 		[5374]	=	"ROGUE", --mutilate
  -- 		[32645]	=	"ROGUE", --envenom
  -- 		[1943]	=	"ROGUE", --rupture
  -- 		[73651]	=	"ROGUE", --Recuperate (heal)
  -- 		[35546]	=	"ROGUE", --combat potency (energy)
  -- 		[98440]	=	"ROGUE", --relentless strikes (energy)
  -- 		[51637]	=	"ROGUE", --venomous vim (energy)
  --
  -- 	-- Shaman
  -- 		[55533]	=	"SHAMAN", -- "Glyph of Healing Wave"
  -- 		[157503]	=	"SHAMAN", -- "Cloudburst"
  -- 		[137808]	=	"SHAMAN", -- "Flames of Life"
  -- 		[114911]	=	"SHAMAN", -- "Ancestral Guidance"
  -- 		[165344]	=	"SHAMAN", -- "Ascendance"
  -- 		[157153]	=	"SHAMAN", -- "Cloudburst Totem"
  -- 		[152256]	=	"SHAMAN", -- "Storm Elemental Totem"
  -- 		[21169]	=	"SHAMAN", -- "Reincarnation"
  -- 		[2008]	=	"SHAMAN", -- "Ancestral Spirit"
  -- 		[73685]	=	"SHAMAN", -- "Unleash Life"
  -- 		[165462]	=	"SHAMAN", -- "Unleash Flame"
  -- 		[152255]	=	"SHAMAN", -- "Liquid Magma"
  -- 		[8190]	=	"SHAMAN", -- "Magma Totem"
  -- 		[108287]	=	"SHAMAN", -- "Totemic Projection"
  -- 		[8349]	=	"SHAMAN", -- "Fire Nova"
  -- 		[77478]	=	"SHAMAN", -- "Earthquake"
  -- 		[114089]	=	"SHAMAN", -- "Windlash"
  -- 		[114093]	=	"SHAMAN", -- "Windlash Off-Hand"
  -- 		[115357]	=	"SHAMAN", -- "Windstrike"
  -- 		[115360]	=	"SHAMAN", -- "Windstrike Off-Hand"
  -- 		[88767]	=	"SHAMAN", -- "Fulmination"
  -- 		[170379]	=	"SHAMAN", -- "Molten Earth"
  -- 		[177601]	=	"SHAMAN", -- "Liquid Magma"
  -- 		[10444]	=	"SHAMAN", -- "Flametongue Attack"
  -- 		[32176]	=	"SHAMAN", -- "Stormstrike Off-Hand"
  -- 		[51886] 	= 	"SHAMAN", -- Cleanse Spirit
  -- 		[98008] 	= 	"SHAMAN", -- Spirit Link Totem
  -- 		[8177] 	= 	"SHAMAN", -- Grounding Totem
  -- 		[8143] 	= 	"SHAMAN", -- Tremor Totem
  -- 		[108273] 	= 	"SHAMAN", -- Windwalk Totem
  -- 		[51514] 	= 	"SHAMAN", -- Hex
  -- 		--[73682] 	= 	"SHAMAN", -- Unleash Frost
  -- 		--[8033] 	= 	"SHAMAN", -- Frostbrand Weapon
  -- 		[114074] 	= 	"SHAMAN", -- Lava Beam
  -- 		--[120668]	=	"SHAMAN", --Stormlash Totem
  -- 		[2894]	=	"SHAMAN", -- Fire Elemental Totem
  -- 		[2825]	=	"SHAMAN", -- Bloodlust
  -- 		[114049]	=	"SHAMAN", -- Ascendance
  -- 		[73680]	=	"SHAMAN", -- Unleash Elements
  -- 		[5394]	=	"SHAMAN", -- Healing Stream Totem
  -- 		[108280]	=	"SHAMAN", -- Healing Tide Totem
  -- 		[3599]	=	"SHAMAN", -- Searing Totem
  -- 		[73920]	=	"SHAMAN", -- Healing Rain
  -- 		[2645]	=	"SHAMAN", -- Ghost Wolf
  -- 		[16166]	=	"SHAMAN", -- Elemental Mastery
  -- 		[108281]	=	"SHAMAN", -- Ancestral Guidance
  -- 		[108270]	=	"SHAMAN", -- Stone Bulwark Totem
  -- 		[108285]	=	"SHAMAN", -- Call of the Elements
  -- 		[115356]	=	"SHAMAN", -- Stormblast
  -- 		[60103]	=	"SHAMAN", -- Lava Lash
  -- 		[51533]	=	"SHAMAN", -- Feral Spirit
  -- 		[17364]	=	"SHAMAN", -- Stormstrike
  -- 		[16188]	=	"SHAMAN", -- Ancestral Swiftness
  -- 		[2062]	=	"SHAMAN", -- Earth Elemental Totem
  -- 		--[8024]	=	"SHAMAN", -- Flametongue Weapon
  -- 		[51485]	=	"SHAMAN", -- Earthgrab Totem
  -- 		--[331]	=	"SHAMAN", -- Healing Wave
  -- 		[61882]	=	"SHAMAN", -- Earthquake
  -- 		[52127]	=	"SHAMAN", -- Water Shield
  -- 		[77472]	=	"SHAMAN", -- Greater Healing Wave
  -- 		[108269]	=	"SHAMAN", -- Capacitor Totem
  -- 		[79206]	=	"SHAMAN", -- Spiritwalker's Grace
  -- 		[57994]	=	"SHAMAN", -- Wind Shear
  -- 		[108271]	=	"SHAMAN", -- Astral Shift
  -- 		[30823]	=	"SHAMAN", --istic Rage
  -- 		[77130]	=	"SHAMAN", -- Purify Spirit
  -- 		[58875]	=	"SHAMAN", -- Spirit Walk
  -- 		[36936]	=	"SHAMAN", -- Totemic Recall
  -- 		--[51730]	=	"SHAMAN", -- Earthliving Weapon
  -- 		[8056]	=	"SHAMAN", -- Frost Shock
  -- 		--[88765]	=	"SHAMAN", --rolling thunder (mana)
  -- 		[51490]	=	"SHAMAN", --thunderstorm (mana)
  -- 		--[82987]	=	"SHAMAN", --telluric currents glyph (mana)
  -- 		[101033]	=	"SHAMAN", --resurgence (mana)
  -- 		[51505]	=	"SHAMAN", --lava burst
  -- 		[8050]	=	"SHAMAN", --flame shock
  -- 		[117014]	=	"SHAMAN", --elemental blast
  -- 		[403]	=	"SHAMAN", --lightning bolt
  -- 		--[45284]	=	"SHAMAN", --lightning bolt
  -- 		[421]	=	"SHAMAN", --chain lightining
  -- 		[32175]	=	"SHAMAN", --stormstrike
  -- 		[25504]	=	"SHAMAN", --windfury
  -- 		[8042]	=	"SHAMAN", --earthshock
  -- 		[26364]	=	"SHAMAN", --lightning shield
  -- 		[117014]	=	"SHAMAN", --elemental blast
  -- 		[73683]	=	"SHAMAN", --unleash flame
  -- 		[51522]	=	"SHAMAN", --primal wisdom (mana)
  -- 		--[63375]	=	"SHAMAN", --primal wisdom (mana)
  -- 		[114942]	=	"SHAMAN", --healing tide
  -- 		[73921]	=	"SHAMAN", --healing rain
  -- 		[1064]	=	"SHAMAN", --chain heal
  -- 		[52042]	=	"SHAMAN", --healing stream totem
  -- 		[61295]	=	"SHAMAN", --riptide
  -- 		--[51945]	=	"SHAMAN", --earthliving
  -- 		[114083]	=	"SHAMAN", --restorative mists
  -- 		[8004]	=	"SHAMAN", --healing surge
  --
  -- 	-- Warlock
  -- 		[108447]	=	"WARLOCK", -- "Soul Link"
  -- 		[108508]	=	"WARLOCK", -- "Mannoroth's Fury"
  -- 		[108482]	=	"WARLOCK", -- "Unbound Will"
  -- 		[157897]	=	"WARLOCK", -- "Summon Terrorguard"
  -- 		[111771]	=	"WARLOCK", -- "Demonic Gateway"
  -- 		[157899]	=	"WARLOCK", -- "Summon Abyssal"
  -- 		[157757]	=	"WARLOCK", -- "Summon Doomguard"
  -- 		[119915]	=	"WARLOCK", -- "Wrathstorm"
  -- 		[137587]	=	"WARLOCK", -- "Kil'jaeden's Cunning"
  -- 		[1949]	=	"WARLOCK", -- "Hellfire"
  -- 		[171140]	=	"WARLOCK", -- "Shadow Lock"
  -- 		[104025]	=	"WARLOCK", -- "Immolation Aura"
  -- 		[119905]	=	"WARLOCK", -- "Cauterize Master"
  -- 		[119913]	=	"WARLOCK", -- "Fellash"
  -- 		[111898]	=	"WARLOCK", -- "Grimoire: Felguard"
  -- 		[30146]	=	"WARLOCK", -- "Summon Felguard"
  -- 		[119914]	=	"WARLOCK", -- "Felstorm"
  -- 		[86121]	=	"WARLOCK", -- "Soul Swap"
  -- 		[86213]	=	"WARLOCK", -- "Soul Swap Exhale"
  -- 		[157695]	=	"WARLOCK", -- "Demonbolt"
  -- 		[86040]	=	"WARLOCK", -- "Hand of Gul'dan"
  -- 		[124915]	=	"WARLOCK", -- "Chaos Wave"
  -- 		[22703]	=	"WARLOCK", -- "Infernal Awakening"
  -- 		[5857]	=	"WARLOCK", -- "Hellfire"
  -- 		[129476]	=	"WARLOCK", -- "Immolation Aura"
  -- 		[152108]	=	"WARLOCK", -- "Cataclysm"
  -- 		[27285]	=	"WARLOCK", -- "Seed of Corruption"
  -- 		[131740]	=	"WARLOCK", -- "Corruption"
  -- 		[131737]	=	"WARLOCK", -- "Agony"
  -- 		[131736]	=	"WARLOCK", -- "Unstable Affliction"
  -- 		[80240] 	= 	"WARLOCK", -- Havoc
  -- 		[112921] 	= 	"WARLOCK", -- Summon Abyssal
  -- 		[48020] 	= 	"WARLOCK", -- Demonic Circle: Teleport
  -- 		[111397] 	= 	"WARLOCK", -- Blood Horror
  -- 		[112869] 	= 	"WARLOCK", -- Summon Observer
  -- 		[1454] 	= 	"WARLOCK", -- Life Tap
  -- 		[112868] 	= 	"WARLOCK", -- Summon Shivarra
  -- 		[112869] 	= 	"WARLOCK", -- Summon Observer
  -- 		[120451] 	= 	"WARLOCK", -- Flames of Xoroth
  -- 		[29893] 	= 	"WARLOCK", -- Create Soulwell
  -- 		[114189] 	= 	"WARLOCK", -- Health Funnel
  -- 		[112866] 	= 	"WARLOCK", -- Summon Fel Imp
  -- 		[108683] 	= 	"WARLOCK", -- Fire and Brimstone
  -- 		[688] 	= 	"WARLOCK", -- Summon Imp
  -- 		--[112092] 	= 	"WARLOCK", -- Shadow Bolt
  -- 		[113861] 	= 	"WARLOCK", -- Dark Soul: Knowledge
  -- 		--[103967] 	= 	"WARLOCK", -- Carrion Swarm
  -- 		[112870] 	= 	"WARLOCK", -- Summon Wrathguard
  -- 		[104316] 	= 	"WARLOCK", -- Imp Swarm
  -- 		[17962]	=	"WARLOCK", -- Conflagrate
  -- 		[108359]	=	"WARLOCK", -- Dark Regeneration
  -- 		[110913]	=	"WARLOCK", -- Dark Bargain
  -- 		[105174]	=	"WARLOCK", -- Hand of Gul'dan
  -- 		[697]	=	"WARLOCK", -- Summon Voidwalker
  -- 		[6201]	=	"WARLOCK", -- Create Healthstone
  -- 		[146739]	=	"WARLOCK", -- Corruption
  -- 		[109151]	=	"WARLOCK", -- Demonic Leap
  -- 		-- [104773]	=	"WARLOCK", -- Unending Resolve
  -- 		[103958]	=	"WARLOCK", -- Metamorphosis
  -- 		[119678]	=	"WARLOCK", -- Soul Swap
  -- 		--[6229]	=	"WARLOCK", -- Twilight Ward
  -- 		[74434]	=	"WARLOCK", -- Soulburn
  -- 		[30283]	=	"WARLOCK", -- Shadowfury
  -- 		[113860]	=	"WARLOCK", -- Dark Soul: Misery
  -- 		[108503]	=	"WARLOCK", -- Grimoire of Sacrifice
  -- 		[104232]	=	"WARLOCK", -- Rain of Fire
  -- 		[6353]	=	"WARLOCK", -- Soul Fire
  -- 		[689]	=	"WARLOCK", -- Drain Life
  -- 		[17877]	=	"WARLOCK", -- Shadowburn
  -- 		[113858]	=	"WARLOCK", -- Dark Soul: Instability
  -- 		--[1490]	=	"WARLOCK", -- Curse of the Elements
  -- 		[114635]	=	"WARLOCK", -- Ember Tap
  -- 		[27243]	=	"WARLOCK", -- Seed of Corruption
  -- 		--[131623]	=	"WARLOCK", -- Twilight Ward
  -- 		[6789]	=	"WARLOCK", -- Mortal Coil
  -- 		[111400]	=	"WARLOCK", -- Burning Rush
  -- 		[124916]	=	"WARLOCK", -- Chaos Wave
  -- 		--[1120]	=	"WARLOCK", -- Drain Soul
  -- 		[109773]	=	"WARLOCK", -- Dark Intent
  -- 		[112927]	=	"WARLOCK", -- Summon Terrorguard
  -- 		[1122]	=	"WARLOCK", -- Summon Infernal
  -- 		[108416]	=	"WARLOCK", -- Sacrificial Pact
  -- 		[5484]	=	"WARLOCK", -- Howl of Terror
  -- 		[29858]	=	"WARLOCK", -- Soulshatter
  -- 		[18540]	=	"WARLOCK", -- Summon Doomguard
  -- 		--[89420]	=	"WARLOCK", -- Drain Life
  -- 		[20707]	=	"WARLOCK", -- Soulstone
  -- 		[132413]	=	"WARLOCK", -- Shadow Bulwark
  -- 		--[109466]	=	"WARLOCK", -- Curse of Enfeeblement
  -- 		[48018]	=	"WARLOCK", -- Demonic Circle: Summon
  -- 		--[77799]	=	"WARLOCK", --fel flame
  -- 		[63106]	=	"WARLOCK", --siphon life
  -- 		[1454]	=	"WARLOCK", --life tap
  -- 		[103103]	=	"WARLOCK", --malefic grasp
  -- 		[980]	=	"WARLOCK", --agony
  -- 		[30108]	=	"WARLOCK", --unstable affliction
  -- 		[172]	=	"WARLOCK", --corruption
  -- 		[48181]	=	"WARLOCK", --haunt
  -- 		[29722]	=	"WARLOCK", --incenerate
  -- 		[348]	=	"WARLOCK", --Immolate
  -- 		[116858]	=	"WARLOCK", --Chaos Bolt
  -- 		[114654]	=	"WARLOCK", --incinerate
  -- 		[108686]	=	"WARLOCK", --immolate
  -- 		[108685]	=	"WARLOCK", --conflagrate
  -- 		[104233]	=	"WARLOCK", --rain of fire
  -- 		[103964]	=	"WARLOCK", --touch os chaos
  -- 		[686]	=	"WARLOCK", --shadow bolt
  -- 		--[114328]	=	"WARLOCK", --shadow bolt glyph
  -- 		[140719]	=	"WARLOCK", --hellfire
  -- 		[104027]	=	"WARLOCK", --soul fire
  -- 		[603]	=	"WARLOCK", --doom
  -- 		[108371]	=	"WARLOCK", --Harvest life
  --
  -- 	-- Warrior
  -- 		[117313]	=	"WARRIOR", -- "Bloodthirst Heal"
  -- 		[118779]	=	"WARRIOR", -- "Victory Rush"
  -- 		[118340]	=	"WARRIOR", -- "Impending Victory"
  -- 		[114029]	=	"WARRIOR", -- "Safeguard"
  -- 		[156291]	=	"WARRIOR", -- "Gladiator Stance"
  -- 		[772]	=	"WARRIOR", -- "Rend"
  -- 		[156321]	=	"WARRIOR", -- "Shield Charge"
  -- 		[3411]	=	"WARRIOR", -- "Intervene"
  -- 		[12723]	=	"WARRIOR", -- "Sweeping Strikes"
  -- 		[34428]	=	"WARRIOR", -- "Victory Rush"
  -- 		[44949]	=	"WARRIOR", -- "Whirlwind Off-Hand"
  -- 		[176289]	=	"WARRIOR", -- "Siegebreaker"
  -- 		[174736]	=	"WARRIOR", -- "Enhanced Rend"
  -- 		[167105]	=	"WARRIOR", -- "Colossus Smash"
  -- 		[163558]	=	"WARRIOR", -- "Execute Off-Hand"
  -- 		[95738]	=	"WARRIOR", -- "Bladestorm Off-Hand"
  -- 		[145585]	=	"WARRIOR", -- "Storm Bolt Off-Hand"
  -- 		[2565] 	= 	"WARRIOR", -- Shield Block
  -- 		[2457] 	= 	"WARRIOR", -- Battle Stance
  -- 		[12328] 	= 	"WARRIOR", -- Sweeping Strikes
  -- 		[114192] 	= 	"WARRIOR", -- Mocking Banner
  -- 		[12323] 	= 	"WARRIOR", -- Piercing Howl
  -- 		--[122475] 	= 	"WARRIOR", -- Throw
  -- 		--[845] 	= 	"WARRIOR", -- Cleave
  -- 		[5246] 	= 	"WARRIOR", -- Intimidating Shout
  -- 		--[7386] 	= 	"WARRIOR", -- Sunder Armor
  -- 		[107566] 	= 	"WARRIOR", -- Staggering Shout
  -- 		[86346]	=	"WARRIOR", -- Colossus Smash
  -- 		[18499]	=	"WARRIOR", -- Berserker Rage
  -- 		[107570]	=	"WARRIOR", -- Storm Bolt
  -- 		[1680]	=	"WARRIOR", -- Whirlwind
  -- 		[85384]	=	"WARRIOR", -- Raging Blow Off-Hand
  -- 		[85288]	=	"WARRIOR", -- Raging Blow
  -- 		[100]	=	"WARRIOR", -- Charge
  -- 		--[7384]	=	"WARRIOR", -- Overpower
  -- 		[23881]	=	"WARRIOR", -- Bloodthirst
  -- 		[118000]	=	"WARRIOR", -- Dragon Roar
  -- 		[50622]	=	"WARRIOR", -- Bladestorm
  -- 		[46924]	=	"WARRIOR", -- Bladestorm
  -- 		[6673]	=	"WARRIOR", -- Battle Shout
  -- 		[103840]	=	"WARRIOR", -- Impending Victory
  -- 		[5308]	=	"WARRIOR", -- Execute
  -- 		[57755]	=	"WARRIOR", -- Heroic Throw
  -- 		[871]	=	"WARRIOR", -- Shield Wall
  -- 		[97462]	=	"WARRIOR", -- Rallying Cry
  -- 		[118038]	=	"WARRIOR", -- Die by the Sword
  -- 		--[114203]	=	"WARRIOR", -- Demoralizing Banner
  -- 		[52174]	=	"WARRIOR", -- Heroic Leap
  -- 		[1719]	=	"WARRIOR", -- Recklessness
  -- 		--[114207]	=	"WARRIOR", -- Skull Banner
  -- 		[1715]	=	"WARRIOR", -- Hamstring
  -- 		[107574]	=	"WARRIOR", -- Avatar
  -- 		[46968]	=	"WARRIOR", -- Shockwave
  -- 		[6343]	=	"WARRIOR", -- Thunder Clap
  -- 		[12292]	=	"WARRIOR", -- Bloodbath
  -- 		[64382]	=	"WARRIOR", -- Shattering Throw
  -- 		[114028]	=	"WARRIOR", -- Mass Spell Reflection
  -- 		[55694]	=	"WARRIOR", -- Enraged Regeneration
  -- 		[6552]	=	"WARRIOR", -- Pummel
  -- 		[6572]	=	"WARRIOR", -- Revenge
  -- 		[112048]	=	"WARRIOR", -- Shield Barrier
  -- 		[23920]	=	"WARRIOR", -- Spell Reflection
  -- 		[12975]	=	"WARRIOR", -- Last Stand
  -- 		[355]	=	"WARRIOR", -- Taunt
  -- 		[102060]	=	"WARRIOR", -- Disrupting Shout
  --
  -- 		[100130]	=	"WARRIOR", --wild strike
  -- 		[96103]	=	"WARRIOR", --raging blow
  -- 		[12294]	=	"WARRIOR", --mortal strike
  -- 		[1464]	=	"WARRIOR", --Slam
  -- 		[23922]	=	"WARRIOR", --shield slam
  -- 		[20243]	=	"WARRIOR", --devastate
  -- 		--[11800]	=	"WARRIOR", --dragon roar
  -- 		[115767]	=	"WARRIOR", --deep wounds
  -- 		[109128]	=	"WARRIOR", --charge
  -- 		--[11294]	=	"WARRIOR", --mortal strike
  -- 		[109128]	=	"WARRIOR", --charge
  -- 		[12880]	=	"WARRIOR", --enrage
  -- 		--[29842]	=	"WARRIOR", --undribled wrath
  -- }
  local RACE_ICON_TCOORDS = {
  	["HUMAN_MALE"]		= {0, 0.125, 0, 0.25},
  	["DWARF_MALE"]		= {0.125, 0.25, 0, 0.25},
  	["GNOME_MALE"]		= {0.25, 0.375, 0, 0.25},
  	["NIGHTELF_MALE"]	= {0.375, 0.5, 0, 0.25},

  	["TAUREN_MALE"]		= {0, 0.125, 0.25, 0.5},
  	["SCOURGE_MALE"]	= {0.125, 0.25, 0.25, 0.5},
  	["TROLL_MALE"]		= {0.25, 0.375, 0.25, 0.5},
  	["ORC_MALE"]		= {0.375, 0.5, 0.25, 0.5},

  	["HUMAN_FEMALE"]	= {0, 0.125, 0.5, 0.75},
  	["DWARF_FEMALE"]	= {0.125, 0.25, 0.5, 0.75},
  	["GNOME_FEMALE"]	= {0.25, 0.375, 0.5, 0.75},
  	["NIGHTELF_FEMALE"]	= {0.375, 0.5, 0.5, 0.75},

  	["TAUREN_FEMALE"]	= {0, 0.125, 0.75, 1.0},
  	["SCOURGE_FEMALE"]	= {0.125, 0.25, 0.75, 1.0},
  	["TROLL_FEMALE"]	= {0.25, 0.375, 0.75, 1.0},
  	["ORC_FEMALE"]		= {0.375, 0.5, 0.75, 1.0},

  	["BLOODELF_MALE"]	= {0.5, 0.625, 0.25, 0.5},
  	["BLOODELF_FEMALE"]	= {0.5, 0.625, 0.75, 1.0},

  	["DRAENEI_MALE"]	= {0.5, 0.625, 0, 0.25},
  	["DRAENEI_FEMALE"]	= {0.5, 0.625, 0.5, 0.75},

  	["GOBLIN_MALE"]		= {0.625, 0.750, 0.25, 0.5},
  	["GOBLIN_FEMALE"]	= {0.625, 0.750, 0.75, 1.0},

  	["WORGEN_MALE"]		= {0.625, 0.750, 0, 0.25},
  	["WORGEN_FEMALE"]	= {0.625, 0.750, 0.5, 0.75},

  	["PANDAREN_MALE"]	= {0.750, 0.875, 0, 0.25},
  	["PANDAREN_FEMALE"]	= {0.750, 0.875, 0.5, 0.75},
  }
  local classIndex = {
    [1] = "Warrior",
    [2] = "Paladin",
    [3] = "Hunter",
    [4] = "Rogue",
    [5] = "Priest",
    [6] = "Death Knight",
    [7] = "Shaman",
    [8] = "Mage",
    [9] = "Warlock",
    [10] = "Monk",
    [11] = "Druid",
  }
  local RaceMap = {
    [1] = "Human",
    [2] = "Orc",
    [3] = "Dwarf",
    [4] = "NightElf",
    [5] = "Scourge",
    [6] = "Tauren",
    [7] = "Gnome",
    [8] = "Troll",
    [9] = "Goblin",
    [10] = "BloodElf",
    [11] = "Draenei",
    [22] = "Worgen",
    [25] = "Pandaren",
    [26] = "Pandaren",
    [24] = "Pandaren",
  }
  local Cache = {
    [1] = {71,78,100,355,469,772,871,1160,1464,1680,1715,1719,2457,2565,3127,3411,
            5246,5308,6343,6544,6552,6572,6673,12292,12294,12323,12328,12712,12950,
            12975,13046,18499,20243,23588,23881,23920,23922,29144,29725,29838,34428,
            46915,46917,46924,46953,46968,55694,56636,57755,64382,76838,76856,76857,
            81099,84608,85288,86101,86110,86535,88163,97462,100130,103826,103827,103828,
            103840,107570,107574,114028,114029,114030,114192,115767,118000,118038,
            122509,123829,145585,152276,152277,152278,156287,156321,158298,158836,
            159362,161608,161798,163201,163558,165365,165383,165393,167105,167188,
            169679,169680,169683,169685,174736,174926,176289,176318,},
    [2] = {498,633,642,853,879,1022,1038,1044,2812,4987,6940,7328,10326,13819,19740,
            19750,20066,20154,20164,20165,20217,20271,20473,20925,23214,24275,25780,
            25956, 26023,26573,31801,31821,31842,31850,31868,31884,31935,32223,34767,
            34769,35395,53376,53385,53503,53551,53563,53576,53592,53595,53600,62124,
            69820,69826,73629,73630,76669,76671,76672,82242,82326,82327,85043,85222,
            85256,85499,85673,85804,86102,86103,86172,86539,86659,87172,88821,96231,
            105361,105424,105593,105622,105805,105809,112859,114039,114154,114157,
            114158,114163,114165,115675,115750,119072,121783,123830,130552,136494,
            140333,148039,152261,152262,152263,156910,157007,157047,157048,158298,
            159374,161608,161800,165375,165380,165381,167187,171648,},
    [3] = {136,781,883,982,1462,1494,1499,1515,1543,2641,2643,3044,3045,3674,5116,
            5118,5384,6197,6991,8737,13159,13809,13813,19263,19386,19387,19434,19506,
            19574,19577,19623,19801,19878,19879,19880,19882,19883,19884,19885,20736,
            34026,34477,34483,34954,35110,51753,53209,53253,53260,53270,53271,53301,
            53351,56315,56641,63458,76657,76658,76659,77767,77769,82692,83242,83243,
            83244,83245,87935,93321,93322,109212,109215,109248,109259,109260,109298,
            109304,109306,115939,117050,117526,118675,120360,120679,121818,130392,
            131894,138430,147362,152244,152245,155228,157443,162534,163485,164856,
            165378,165389,165396,172106,177667,},
    [4] = {53,408,703,921,1329,1725,1752,1766,1776,1784,1804,1833,1856,1860,1943,1966,
            2094,2098,2823,2836,2983,3408,5171,5277,5938,6770,8676,8679,13750,13877,
            14062,14117,14161,14183,14185,14190,16511,26679,31209,31220,31223,31224,
            31230,32645,35551,36554,51667,51690,51701,51713,51723,57934,58423,61329,
            73651,74001,76577,76803,76806,76808,79008,79134,79140,79147,79152,82245,
            84601,84617,84654,91023,108208,108209,108210,108211,108212,108216,111240,
            113742,114014,114015,114018,121152,121411,121733,131511,137619,138106,
            152150,152151,152152,154904,157442,165390,},
    [5] = {17,139,527,528,585,586,589,596,605,1706,2006,2060,2061,2096,2944,6346,8092,
            8122,9484,10060,14914,15286,15407,15473,15487,19236,20711,21562,32375,
            32379,32546,33076,33206,34433,34861,34914,45243,47515,47517,47536,47540,
            47585,47788,48045,49868,52798,62618,63733,64044,64129,64843,73325,73510,
            77484,77485,77486,78203,81206,81208,81209,81662,81700,81749,81782,87336,
            88625,88684,95649,95740,95860,95861,108920,108942,108945,109142,109175,
            109186,109964,110744,112833,120517,120644,121135,121536,122121,123040,
            126135,127632,129250,132157,139139,152116,152117,152118,155245,155246,
            155271,155361,162448,162452,165201,165362,165370,165376,},
    [6] = {674,3714,42650,43265,45462,45477,45524,45529,46584,47476,47528,47541,47568,
            48263,48265,48266,48707,48743,48792,48982,49020,49028,49039,49143,49184,
            49206,49222,49509,49530,49572,49576,49998,50029,50034,50041,50371,50385,
            50392,50842,50887,50977,51052,51128,51160,51271,51462,51986,53331,53342,
            53343,53344,53428,54447,54637,55078,55090,55095,55233,55610,56222,56835,
            57330,59057,61999,62158,63560,66192,77513,77514,77515,77575,77606,81127,
            81136,81164,81229,81333,82246,85948,86113,86524,86536,86537,91107,96268,
            108194,108196,108199,108200,108201,111673,114556,114866,115989,119975,
            123693,130735,130736,152279,152280,152281,155522,158298,161497,161608,
            161797,165394,165395,178819,},
    [7] = {324,370,403,421,546,556,974,1064,1535,2008,2062,2484,2645,2825,2894,3599,
            5394,6196,8004,8042,8050,8056,8143,8177,8190,8737,10400,16166,16188,16196,
            16213,16282,17364,20608,29000,30814,30823,30884,32182,33757,36936,51485,
            51490,51505,51514,51522,51530,51533,51564,51886,52127,57994,58875,60103,
            60188,61295,61882,62099,63374,73680,73899,73920,77130,77223,77226,77472,
            77756,79206,86099,86100,86108,86529,86629,88766,95862,98008,108269,108270,
            108271,108273,108280,108281,108282,108283,108284,108285,108287,112858,
            114050,114051,114052,116956,117012,117013,117014,123099,147074,152255,
            152256,152257,157153,157154,157444,165368,165391,165399,165462,165477,
            165479,166221,170374,},
    [8] = {10,66,116,118,120,122,130,133,475,1449,1459,1463,1953,2120,2136,2139,2948,
            3561,3562,3563,3565,3566,3567,5143,6117,7302,10059,11129,11366,11416,
            11417,11418,11419,11420,11426,11958,12042,12043,12051,12472,12846,12982,
            28271,28272,30449,30451,30455,30482,31589,31661,31687,32266,32267,32271,
            32272,33690,33691,35715,35717,42955,43987,44425,44457,44549,44572,44614,
            45438,49358,49359,49360,49361,53140,53142,55342,61305,61316,61721,61780,
            76547,76613,80353,84714,86949,88342,88344,88345,88346,102051,108839,
            108843,108853,108978,110959,111264,112948,112965,113724,114664,114923,
            116011,117216,117957,120145,120146,126819,132620,132621,132626,132627,
            140468,152087,153561,153595,153626,155147,155148,155149,157913,157976,
            157980,157981,157997,159916,161353,161354,161355,161372,165357,165359,
            165360,176242,176244,176246,176248,},
    [9] = {126,172,348,686,688,689,691,697,698,710,712,755,980,1098,1122,1454,1949,
            5484,5697,5740,5782,5784,6201,6353,6789,17877,17962,18540,20707,23161,
            27243,29722,29858,29893,30108,30146,30283,48018,48020,48181,74434,77215,
            77219,77220,80240,86121,93375,101976,103103,103958,104315,104773,105174,
            108359,108370,108371,108415,108416,108482,108499,108501,108503,108505,
            108508,108558,108647,108683,108869,109151,109773,109784,110913,111397,
            111400,111546,111771,113858,113860,113861,114592,114635,116858,117198,
            117896,119898,120451,122351,124913,137587,152107,152108,152109,157695,
            157696,165363,165367,165392,166928,171975,174848,},
    [10] = {100780,100784,100787,101545,101546,101643,103985,107428,109132,113656,
              115008,115069,115070,115072,115074,115078,115080,115098,115151,115173,
              115174,115175,115176,115178,115180,115181,115203,115288,115294,115295,
              115308,115310,115313,115315,115396,115399,115450,115451,115460,115546,
              115636,115921,116092,116095,116645,116670,116680,116694,116705,116740,
              116781,116812,116841,116844,116847,116849,117906,117907,117952,117967,
              119381,119392,119582,119996,120224,120225,120227,120272,120277,121253,
              121278,121817,122278,122280,122470,122783,123766,123904,123980,123986,
              124081,124146,124502,124682,126060,126892,126895,128595,128938,137384,
              137562,137639,139598,152173,152174,152175,154436,154555,157445,157533,
              157535,157675,157676,158298,161608,165379,165397,165398,166916,173841,},
    [11] = {99,339,740,768,770,774,783,1079,1126,1822,1850,2782,2908,2912,5176,5185,
              5211,5215,5217,5221,5225,5487,6795,6807,8921,8936,16864,16870,16931,
              16961,16974,17007,17073,18562,18960,20484,22568,22570,22812,22842,24858,
              33605,33745,33763,33786,33831,33873,33891,33917,48438,48484,48500,48505,
              50769,52610,61336,62606,77492,77493,77495,77758,78674,78675,80313,85101,
              86093,86096,86097,86104,88423,88747,92364,93399,102280,102342,102351,
              102359,102401,102543,102558,102560,102693,102703,102706,102793,106707,
              106785,106830,106832,106839,106898,106952,108238,108291,108292,108293,
              108294,108299,108373,112071,112857,113043,114107,124974,125972,127663,
              131768,132158,132469,135288,145108,145205,145518,152220,152221,152222,
              155577,155578,155580,155672,155675,155783,155834,155835,157447,158298,
              158476,158477,158478,158497,158501,158504,159232,161608,164812,164815,
              165372,165374,165386,165387,165962,166142,166163,171746,179333,},
    ["PET"] = {[2649]=3,[16827]=3,[17253]=3,[24423]=3,[24450]=3,[24604]=3,[24844]=3,
                [26064]=3,[34889]=3,[35290]=3,[35346]=3,[49966]=3,[50256]=3,[50433]=3,
                [50518]=3,[50519]=3,[54644]=3,[54680]=3,[57386]=3,[58604]=3,[65220]=3,
                [88680]=3,[90309]=3,[90328]=3,[90339]=3,[90347]=3,[90355]=3,[90361]=3,
                [90363]=3,[90364]=3,[92380]=3,[93433]=3,[93435]=3,[94019]=3,[94022]=3,
                [126259]=3,[126309]=3,[126311]=3,[126364]=3,[126373]=3,[126393]=3,
                [128432]=3,[128433]=3,[128997]=3,[135678]=3,[137798]=3,[159733]=3,
                [159735]=3,[159736]=3,[159788]=3,[159926]=3,[159931]=3,[159953]=3,
                [159956]=3,[159988]=3,[160003]=3,[160007]=3,[160011]=3,[160014]=3,
                [160017]=3,[160018]=3,[160039]=3,[160044]=3,[160045]=3,[160049]=3,
                [160052]=3,[160057]=3,[160060]=3,[160063]=3,[160065]=3,[160067]=3,
                [160073]=3,[160074]=3,[160077]=3,[160452]=3,[173035]=3,[47468]=6,
                [47481]=6,[47482]=6,[47484]=6,[62137]=6,[91776]=6,[91778]=6,[91797]=6,
                [91800]=6,[91802]=6,[91809]=6,[91837]=6,[91838]=6,[36213]=7,[57984]=7,
                [117588]=7,[118297]=7,[118337]=7,[118345]=7,[118347]=7,[118350]=7,
                [157331]=7,[157333]=7,[157348]=7,[157375]=7,[157382]=7,[3110]=9,
                [3716]=9,[6358]=9,[6360]=9,[7814]=9,[7870]=9,[17735]=9,[17767]=9,
                [19505]=9,[19647]=9,[30151]=9,[30153]=9,[30213]=9,[32233]=9,[54049]=9,
                [89751]=9,[89766]=9,[89792]=9,[89808]=9,[112042]=9,[114355]=9,
                [115232]=9,[115236]=9,[115268]=9,[115276]=9,[115284]=9,[115408]=9,
                [115578]=9,[115625]=9,[115746]=9,[115748]=9,[115770]=9,[115778]=9,
                [115781]=9,[115831]=9,[117225]=9,[119899]=9,[134477]=9,[170176]=9,},
    ["RACIAL"] = {[822]=10,[5227]=5,[6562]=11,[7744]=5,[20549]=6,[20550]=6,[20551]=6,
                    [20552]=6,[20555]=8,[20557]=8,[20572]={2,45},[20573]=2,[20577]=5,
                    [20579]=5,[20582]=4,[20583]=4,[20585]=4,[20589]=7,[20591]={7,978},
                    [20592]=7,[20593]=7,[20594]=3,[20596]=3,[20598]=1,[20599]=1,
                    [25046]={10,8},[26297]=8,[28730]={10,400},[28875]=11,[28877]=10,
                    [28880]={11,1},[33697]={2,576},[33702]={2,384},[50613]={10,32},
                    [58943]=8,[58984]=4,[59221]=11,[59224]=3,[59542]={11,2},[59543]={11,4},
                    [59544]={11,16},[59545]={11,32},[59547]={11,64},[59548]={11,128},
                    [59752]=1,[68975]=22,[68976]=22,[68978]=22,[68992]=22,[68996]=22,
                    [69041]=9,[69042]=9,[69044]=9,[69045]=9,[69046]=9,[69070]=9,
                    [69179]={10,1},[80483]={10,4},[87840]=22,[92680]=7,[92682]=3,
                    [94293]=22,[107072]=24,[107073]=24,[107074]=24,[107076]=24,[107079]={24,8},
                    [121093]={11,528},[129597]={10,512},[131701]=24,[143368]=25,[143369]=26,
                    [154742]=10,[154743]=6,[154744]={7,520},[154746]={7,1},[154747]={7,32},
                    [154748]=4,[155145]={10,2},},
  }
end
