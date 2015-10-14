if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
local colors = CT.colors
local func = CT.updateFunctions
local addLineGraph = CT.addLineGraph
local debug = CT.debug
CT.graphList = {}
CT.uptimeGraphList = {}
--------------------------------------------------------------------------------
-- General Spec Data
--------------------------------------------------------------------------------
local function addBasicGraphs(role)
  if not CT.current then return end

  local graphs = CT.current.graphs
  local uptimeGraphs = CT.current.uptimeGraphs

  if role == "HEALER" then
    graphs.default = "Healing"
  elseif role == "DAMAGER" then
    graphs.default = "Damage"
  elseif role == "TANK" then
    graphs.default = "Damage"
  end

  uptimeGraphs.default = "Activity"

  do  -- Generic graphs for all classes/specs
    do -- Target uptime
      if not uptimeGraphs.misc["Target"] then -- Target Uptime Graph
        uptimeGraphs.misc["Target"] = {}
        uptimeGraphs.misc[#uptimeGraphs.misc + 1] = uptimeGraphs.misc["Target"]
      end

      local t = uptimeGraphs.misc["Target"]

      if shown then
        if uptimeGraphs.shownList then
          uptimeGraphs.shownList[#uptimeGraphs.shownList + 1] = t
        else
          uptimeGraphs.shownList = {t}
        end

        CT.toggleUptimeGraph(t)
      end

      if data then wipe(data) else data = {} end
      if unitName then wipe(unitName) else unitName = {} end
      if colorChange then wipe(colorChange) else colorChange = {} end

      data[1] = 0
      data[2] = 0
      unitName[2] = "None"
      refresh = CT.refreshUptimeGraph
      name = "Target"
      category = "Misc"
      group = "Targeted"
      colorPrimary = colors.lightgreen
      colorSecondary = colors.lightblue
      color = colors.lightgreen
      startX = 10
      XMin = 0
      XMax = 10
      YMin = 0
      YMax = 10
      endNum = 1

      if CT.uptimeGraphLines[category][name] then -- This should mean the graph was previously created in another set
        for num, line in pairs(CT.uptimeGraphLines[category][name]) do
          line:Hide()
        end

        wipe(CT.uptimeGraphLines[category][name])
      else
        CT.uptimeGraphLines[category][name] = {}
      end
    end

    do -- Focus Target Uptime Graph
      if not uptimeGraphs.misc["Focus Target"] then
        uptimeGraphs.misc["Focus Target"] = {}
        uptimeGraphs.misc[#uptimeGraphs.misc + 1] = uptimeGraphs.misc["Focus Target"]
      end

      local t = uptimeGraphs.misc["Focus Target"]

      if shown then
        if uptimeGraphs.shownList then
          uptimeGraphs.shownList[#uptimeGraphs.shownList + 1] = t
        else
          uptimeGraphs.shownList = {t}
        end

        CT.toggleUptimeGraph(t)
      end

      if data then wipe(data) else data = {} end
      if unitName then wipe(unitName) else unitName = {} end
      if colorChange then wipe(colorChange) else colorChange = {} end

      data[1] = 0
      data[2] = 0
      unitName[2] = "None"
      refresh = CT.refreshUptimeGraph
      name = "Focus Target"
      category = "Misc"
      group = "Focused"
      colorPrimary = colors.lightgreen
      colorSecondary = colors.lightblue
      color = colors.lightgreen
      startX = 10
      XMin = 0
      XMax = 10
      YMin = 0
      YMax = 10
      endNum = 1

      if CT.uptimeGraphLines[category][name] then -- This should mean the graph was previously created in another set
        for num, line in pairs(CT.uptimeGraphLines[category][name]) do
          line:Hide()
        end

        wipe(CT.uptimeGraphLines[category][name])
      else
        CT.uptimeGraphLines[category][name] = {}
      end
    end

    do -- Activity Uptime Graph
      if not uptimeGraphs.cooldowns["Activity"] then
        uptimeGraphs.cooldowns["Activity"] = {}
        uptimeGraphs.cooldowns[#uptimeGraphs.cooldowns + 1] = uptimeGraphs.cooldowns["Activity"]
      end

      local t = uptimeGraphs.cooldowns["Activity"]

      data = {}
      spellName = {}

      data[1] = 0
      refresh = CT.refreshUptimeGraph
      name = "Activity"
      category = "Cooldown"
      group = "Duration"
      color = colors.orange
      startX = 10
      XMin = 0
      XMax = 10
      YMin = 0
      YMax = 10
      endNum = 1

      if CT.uptimeGraphLines[category][name] then -- This should mean the graph was previously created in another set
        for num, line in pairs(CT.uptimeGraphLines[category][name]) do
          line:Hide()
        end

        wipe(CT.uptimeGraphLines[category][name])
      else
        CT.uptimeGraphLines[category][name] = {}
      end
    end

    addLineGraph("Healing", {"HPS", 100}, colors.green, -200, 10000) -- Healing graph
    CT.graphList[#CT.graphList + 1] = "Healing"

    addLineGraph("Damage", {"DPS", 100}, colors.orange, -200, 10000) -- Damage graph
    CT.graphList[#CT.graphList + 1] = "Damage"

    addLineGraph("Damage Taken", {"DPS", 100}, colors.red, -200, 10000) -- Damage taken graph
    CT.graphList[#CT.graphList + 1] = "Damage Taken"

    if GetUnitName("pet", false) then
      addLineGraph("Total Damage", {"DPS", 100}, colors.orange, -200, 10000) -- Total damage (player + pet)
      CT.graphList[#CT.graphList + 1] = "Total Damage"

      addLineGraph("Pet Damage", {"DPS", 100}, colors.lightgrey, -200, 10000) -- Pet Damage
      CT.graphList[#CT.graphList + 1] = "Pet Damage"
    end
  end

  do -- Resource graphs
    if CT.power["Mana"] then
      addLineGraph("Mana", {"percent"}, colors.mana, -5, 105)
    end

    if CT.power["Focus"] then
      addLineGraph("Focus", {"percent"}, colors.focus, -5, 105)
    end

    if CT.power["Rage"] then
      addLineGraph("Rage", {"percent"}, colors.rage, -5, 105)
    end

    if CT.power["Demonic Fury"] then -- Demonic Fury
      addLineGraph("Demonic Fury", {"percent"}, colors.demonicFury, -5, 105)
    end

    if CT.power["Energy"] then -- Energy
      addLineGraph("Energy", {"percent"}, colors.energy, -5, 105)
    end

    if CT.power["Runic Power"] then -- Runic Power
      addLineGraph("Runic Power", {"percent"}, colors.runicPower, -5, 105)
    end

    if CT.power["Holy Power"] then -- Holy Power
      addLineGraph("Holy Power", {"/", 20}, colors.holyPower, -5, 105)
    end

    if CT.power["Shadow Orbs"] then -- Shadow Orbs
      addLineGraph("Shadow Orbs", {"/", 20}, colors.shadowOrbs, -5, 105)
    end

    if CT.power["Combo Points"] then
      if CT.player.talents[6] == "Anticipation" then -- Combo Points (Anticipation)
        addLineGraph("Combo Points", {"/", 20}, colors.comboPoints, -0.2, 10.2)
      else
        addLineGraph("Combo Points", {"/", 20}, colors.comboPoints, -0.1, 5.1)
      end
    end

    if CT.power["Chi"] then -- Chi
      addLineGraph("Chi", {"/", 20}, colors.chi, -0.1, 5.1)
    end

    if CT.power["Soul Shards"] then -- Soul Shards
      addLineGraph("Soul Shards", {"/", 25}, colors.soulShards, -0.1, 4.1)
    end

    if CT.power["Burning Embers"] then -- Burning Embers
      addLineGraph("Burning Embers", {"/", 10}, colors.burningEmbers, -0.4, 40.1)
    end
  end
end
--------------------------------------------------------------------------------
-- Class Details
--------------------------------------------------------------------------------
local class, CLASS, classID = UnitClass("player")
local tierLevels = CLASS_TALENT_LEVELS[class] or CLASS_TALENT_LEVELS.DEFAULT

CT.player.class = class
CT.player.CLASS = CLASS

local classFunc

if CLASS == "DEATHKNIGHT" then
  local function deathKnight(specName)
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    if specName == "Blood" then

    elseif specName == "Unholy" then

    elseif specName == "Frost" then

    end
  end

  classFunc = deathKnight
elseif CLASS == "DRUID" then
  local function druid(specName)
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    if specName == "Feral" then

    elseif specName == "Balance" then

    elseif specName == "Restoration" then

    elseif specName == "Guardian" then

    end
  end

  classFunc = druid
elseif CLASS == "HUNTER" then
  local function hunter(specName)
    local data = {}

    data[#data + 1] = { -- Focus
      name = "Focus",
      powerIndex = 2,
      func = func.resource1,
      expanderFunc = func.expanderResource1,
      dropDownFunc = CT.type1,
      lines = { "Focus Gained:", "Focus Wasted:", "Effective Gain:", "",
                  "Times Capped:", "Seconds Capped:", },
    }

    data[#data + 1] = { -- Activity
      name = "Activity",
      func = func.activity,
      dropDownFunc = CT.type2,
      lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",},
      icon = "Interface/ICONS/Ability_DualWield.png",
    }

    data[#data + 1] = { -- All Casts
      name = "All Casts",
      func = func.allCasts,
      expanderFunc = func.expanderAllCasts,
      dropDownFunc = CT.type4,
      lines = {},
    }

    data[#data + 1] = { -- Damage
      name = "Damage",
      func = func.damage,
      expanderFunc = func.expanderDamage,
      dropDownFunc = CT.type1,
      lines = {"Total Damage:", "Average DPS:",},
    }

    if specName == "Survival" then
      data[#data + 1] = { -- Explosive Shot
        name = "Explosive Shot",
        spellID = 53301,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        costsPower = 1,
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",},
      }

      -- CT.addCooldownGraph(53301, "Explosive Shot", colors.yellow)

      data[#data + 1] = { -- Black Arrow
        name = "Black Arrow",
        spellID = 3674,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        costsPower = 1,
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",},
      }

      -- CT.addCooldownGraph(3674, "Black Arrow", colors.yellow)
    elseif specName == "Marksmanship" then
      data[#data + 1] = { -- Chimaera Shot
        name = "Chimaera Shot",
        spellID = 53209,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        costsPower = 1,
        lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Focus Spent:", "Reset Casts:", "Longest Delay:", "",
                    "Procs Used:", "Total Procs:", "Biggest Hit:", "Average Hit:",},
      }

      -- CT.addCooldownGraph(53209, "Chimaera Shot", colors.yellow)

      data[#data + 1] = { -- Kill Shot
        name = "Kill Shot",
        spellID = 53351,
        func = func.execute,
        expanderFunc = func.expanderExecute,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Reset Casts:", "Longest Delay:", "", "",
                    "Procs Used:", "Total Procs:", "Biggest Hit:", "Average Hit:",},
      }

      -- CT.addCooldownGraph(53351, "Kill Shot", colors.yellow)
    elseif specName == "Beast Master" then
      data[#data + 1] = { -- Kill Command TODO: SpellID
        name = "Kill Command",
        -- spellID = 53209,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        costsPower = 1,
        lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Focus Spent:", "Reset Casts:", "Longest Delay:", "",
                    "Procs Used:", "Total Procs:", "Biggest Hit:", "Average Hit:",},
      }

      data[#data + 1] = { -- Kill Shot
        name = "Kill Shot",
        spellID = 53351,
        func = func.execute,
        expanderFunc = func.expanderExecute,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Reset Casts:", "Longest Delay:", "", "",
                    "Procs Used:", "Total Procs:", "Biggest Hit:", "Average Hit:",},
      }

      -- CT.addCooldownGraph(53351, "Kill Shot", colors.yellow)
    end

    return data
  end

  classFunc = hunter
elseif CLASS == "MAGE" then
  local function mage(specName)
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    do -- Activity
      data[#data + 1] = {}

      name = "Activity"
      func = func.activity
      expanderFunc = func.expanderActivity
      dropDownFunc = CT.type2
      lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",}
      icon = "Interface/ICONS/Ability_DualWield.png"
    end

    do -- Damage
      data[#data + 1] = {}

      name = "Damage"
      func = func.damage
      dropDownFunc = CT.type1
      lines = {"Total Gain:", "Total Loss:",}
      icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
    end

    do -- All Casts
      data[#data + 1] = {}

      name = "All Casts"
      func = func.allCasts
      expanderFunc = func.expanderAllCasts
      dropDownFunc = CT.type4
      lines = {}
    end

    if specName == "Frost" then

    elseif specName == "Arcane" then
      -- do -- Crusader Strike
      --   data[#data + 1] = {}
      --
      --   name = "Crusader Strike"
      --   spellID = 35395
      --   func = func.shortCD
      --   expanderFunc = func.expanderShortCD
      --   dropDownFunc = CT.type2
      --   lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
      --                 "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
      --                 "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
      --                 "Average Heal:",}
      --   costsPower = 1
      --   givesPower = 2
      --   CT.addCooldownGraph(35395, "Crusader Strike", colors.yellow)
      -- end
    elseif specName == "Fire" then

    end
  end

  classFunc = mage
elseif CLASS == "MONK" then
  local uptimeGraphs = CT.current.uptimeGraphs
  local graphs = CT.current.graphs

  local function monk(specName)
    if specName == "Windwalker" then

    elseif specName == "Mistweaver" then

    elseif specName == "Brewmaster" then

    end
  end

  classFunc = monk
elseif CLASS == "PALADIN" then
  local function paladin(specName)
    local data = {}

    local graphs, uptimeGraphs
    if CT.current then
      uptimeGraphs = CT.current.uptimeGraphs
      graphs = CT.current.graphs
    end

    if specName == "Retribution" then
      data[#data + 1] = { -- Activity
        name = "Activity",
        dropDownFunc = CT.type2,
        lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                      "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                      "Total Hard Casts:",},
        icon = "Interface/ICONS/Ability_DualWield.png",
        func = func.activity,
        expanderFunc = func.expanderActivity,
      }

      data[#data + 1] = { -- Holy Power
        name = "Holy Power",
        powerIndex = 9,
        func = func.resource2,
        expanderFunc = func.expanderResource2,
        dropDownFunc = CT.type1,
        lines = {"Total Gain:", "Total Loss:",},
        icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png",
      }

      data[#data + 1] = { -- Damage
        name = "Damage",
        func = func.damage,
        dropDownFunc = CT.type1,
        lines = {"Total Gain:", "Total Loss:",},
        icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png",
      }

      data[#data + 1] = { -- Crusader Strike
        name = "Crusader Strike",
        spellID = 35395,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",},
        costsPower = 1,
        givesPower = 2,
      }

      -- CT.addCooldownGraph(35395, "Crusader Strike", colors.yellow)

      data[#data + 1] = { -- Judgment
        name = "Judgment",
        spellID = 20271,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        costsPower = 1,
        givesPower = 2,
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",},
      }

      -- CT.addCooldownGraph(20271, "Judgment", colors.yellow)

      data[#data + 1] = { -- Exorcism
        name = "Exorcism",
        spellID = 879,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        costsPower = 1,
        givesPower = 2,
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",},
      }

      -- CT.addCooldownGraph(879, "Exorcism", colors.yellow)

      do -- Light's hammer, holy prism, or execution sentence
        local talent = CT.player.talents[6]

        if talent and talent == "Light's Hammer" then
          data[#data + 1] = {
            name = talent,
            spellID = 114158,
            func = func.longCD,
            dropDownFunc = CT.type3,
            costsPower = 1,
            lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",},
          }

          -- CT.addCooldownGraph(spellID, CT.player.talents[6], colors.yellow)
        elseif talent and talent == "Execution Sentence" then
          data[#data + 1] = {
            name = talent,
            spellID = 114916,
            func = func.longCD,
            dropDownFunc = CT.type3,
            costsPower = 1,
            lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",},
          }

          -- CT.addCooldownGraph(spellID, CT.player.talents[6], colors.yellow)
        elseif talent and talent == "Holy Prism" then
          data[#data + 1] = {
            name = talent,
            spellID = 114165,
            func = func.shortCD,
            expanderFunc = func.expanderShortCD,
            dropDownFunc = CT.type2,
            costsPower = 1,
            lines = {"Percent on CD:", "Percent off CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:", "Average Targets Hit:",},
          }

          -- CT.addCooldownGraph(spellID, CT.player.talents[6], colors.yellow)
        end
      end

      if CT.player.talents[7] and CT.player.talents[7] == "Seraphim" or CT.player.talents[7] == "Empowered Seals" then
        local talent = CT.player.talents[7]

        if name == "Seraphim" then
          data[#data + 1] = {
            spellID = 152262,
            func = func.auraUptime,
            expanderFunc = func.expanderAuraUptime,
            dropDownFunc = CT.type2,
            name = talent,
            costsPower = 1,
            lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                        "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                        "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                        "Percent of Healing:", "Procs Used:", "Total Procs:", "",},
          }

          -- CT.addAuraGraph(86273, name, "Buff", nil, colors.blue)
        elseif name == "Empowered Seals" then
          data[#data + 1] = {
            spellID = 114916,
            func = func.longCD,
            dropDownFunc = CT.type3,
            name = talent,
            costsPower = 1,
            lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",},
          }
        elseif name == "Holy Prism" then

        end

        -- CT.addCooldownGraph(spellID, name, colors.yellow)
      end

      data[#data + 1] = { -- Stance
        name = "Stance",
        func = func.stance,
        expanderFunc = func.expanderStance,
        dropDownFunc = CT.type2,
        lines = {"Total Gained", "Applied / Refreshed", "Expired Early",},
      }
    elseif specName == "Holy" then
      data[#data + 1] = { -- Activity
        name = "Activity",
        func = func.activity,
        expanderFunc = func.expanderActivity,
        dropDownFunc = CT.type2,
        icon = "Interface/ICONS/Ability_DualWield.png",
        lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                      "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                      "Total Hard Casts:",},
      }

      data[#data + 1] = { -- Mana
        name = "Mana",
        powerIndex = 0,
        func = func.resource1,
        expanderFunc = func.expanderResource1,
        dropDownFunc = CT.type1,
        lines = { "Mana Gained:", "Mana Wasted:", "Effective Gain:", "",
                    "Times Capped:", "Seconds Capped:", },
      }

      data[#data + 1] = { -- Holy Power
        name = "Holy Power",
        powerIndex = 9,
        func = func.resource2,
        expanderFunc = func.expanderResource2,
        dropDownFunc = CT.type1,
        icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png",
        lines = { "Holy Power Gained:", "Holy Power Wasted:", "", "",
                  "Times Capped:", "Seconds Capped:", },
      }

      data[#data + 1] = { -- Healing
        name = "Healing",
        func = func.healing,
        dropDownFunc = CT.type1,
        icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png",
        lines = {"Total Gain:", "Total Loss:",},
      }

      data[#data + 1] = { -- Illuminated Healing
        name = "Illuminated Healing",
        spellID = 86273,
        func = func.auraUptime,
        expanderFunc = func.expanderAuraUptime,
        dropDownFunc = CT.type2,
        lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                  "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                  "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                  "Percent of Healing:", "Procs Used:", "Total Procs:", "",},
      }

      -- CT.addAuraGraph(86273, "Illuminated Healing", "Buff", nil, colors.blue)

      data[#data + 1] = { -- All Casts
        name = "All Casts",
        func = func.allCasts,
        expanderFunc = func.expanderAllCasts,
        dropDownFunc = CT.type4,
        lines = {},
      }

      data[#data + 1] = { -- Holy Shock
        name = "Holy Shock",
        spellID = 20473,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Holy Power Gained:", "Holy Power Spent:", "Reset Casts:", "Longest Delay:",
                    "Procs Used:", "Total Procs:", "Biggest Heal:", "Average Heal:",},
        costsPower = 1,
        givesPower = 2,
      }
      -- CT.addCooldownGraph(20473, "Holy Shock", colors.yellow)

      do -- Light's hammer, holy prism, or execution sentence
        local talent = CT.player.talents[6]

        if talent and talent == "Light's Hammer" then
          data[#data + 1] = {
            name = talent,
            spellID = 114158,
            func = func.longCD,
            dropDownFunc = CT.type3,
            costsPower = 1,
            lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",},
          }

          -- CT.addCooldownGraph(spellID, CT.player.talents[6], colors.yellow)
        elseif talent and talent == "Execution Sentence" then
          data[#data + 1] = {
            name = talent,
            spellID = 114916,
            func = func.longCD,
            dropDownFunc = CT.type3,
            costsPower = 1,
            lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",},
          }

          -- CT.addCooldownGraph(spellID, CT.player.talents[6], colors.yellow)
        elseif talent and talent == "Holy Prism" then
          data[#data + 1] = {
            name = talent,
            spellID = 114165,
            func = func.shortCD,
            expanderFunc = func.expanderShortCD,
            dropDownFunc = CT.type2,
            costsPower = 1,
            lines = {"Percent on CD:", "Percent off CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:", "Average Targets Hit:",},
          }

          -- CT.addCooldownGraph(spellID, CT.player.talents[6], colors.yellow)
        end
      end

      if CT.player.talents[7] and not IsPassiveSpell(CT.player.talents[7]) then
        data[#data + 1] = {
          name = CT.player.talents[7],
          func = func.shortCD,
          dropDownFunc = CT.type2,
          costsPower = 1,
          lines = {"None", "None"},
        }
      end

      data[#data + 1] = { -- Divine Protection
        name = "Divine Protection",
        spellID = 498,
        func = func.longCD,
        dropDownFunc = CT.type3,
        costsPower = 1,
        lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",},
      }

      data[#data + 1] = {
        name = "Cleanse",
        func = func.dispel,
        dropDownFunc = CT.type2,
        costsPower = 1,
        lines = {"None", "None",},
      }

      data[#data + 1] = { -- Stance
        name = "Stance",
        func = func.stance,
        expanderFunc = func.expanderStance,
        dropDownFunc = CT.type2,
        lines = {"Total Gained", "Applied / Refreshed", "Expired Early",},
      }

      CT.executePercent = 20
    elseif specName == "Protection" then
      data[#data + 1] = { -- Activity
        name = "Activity",
        func = func.activity,
        expanderFunc = func.expanderActivity,
        dropDownFunc = CT.type2,
        icon = "Interface/ICONS/Ability_DualWield.png",
        lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                      "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                      "Total Hard Casts:",},
      }

      data[#data + 1] = { -- Holy Power
        name = "Holy Power",
        powerIndex = 9,
        func = func.resource2,
        expanderFunc = func.expanderResource2,
        dropDownFunc = CT.type1,
        lines = {"Total Gain:", "Total Loss:",},
        icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png",
      }

      data[#data + 1] = { -- Damage
        name = "Damage",
        func = func.damage,
        dropDownFunc = CT.type1,
        icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png",
        lines = {"Total Gain:", "Total Loss:",},
      }

      data[#data + 1] = { -- All Casts
        name = "All Casts",
        func = func.allCasts,
        expanderFunc = func.expanderAllCasts,
        dropDownFunc = CT.type4,
        lines = {},
      }

      data[#data + 1] = { -- Damage Taken
        name = "Damage Taken",
        func = func.damage,
        dropDownFunc = CT.type1,
        lines = {"Total Gain:", "Total Loss:",},
        icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png",
      }

      data[#data + 1] = { -- Crusader Strike
        name = "Crusader Strike",
        spellID = 35395,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        costsPower = 1,
        givesPower = 2,
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",},
      }

      -- CT.addCooldownGraph(35395, "Crusader Strike", colors.yellow)

      data[#data + 1] = { -- Judgment
        name = "Judgment",
        spellID = 20271,
        func = func.shortCD,
        expanderFunc = func.expanderShortCD,
        dropDownFunc = CT.type2,
        costsPower = 1,
        givesPower = 2,
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",},
      }

      -- CT.addCooldownGraph(20271, "Judgment", colors.yellow)

      do -- Light's hammer, holy prism, or execution sentence
        local talent = CT.player.talents[6]

        if talent and talent == "Light's Hammer" then
          data[#data + 1] = {
            name = talent,
            spellID = 114158,
            func = func.longCD,
            dropDownFunc = CT.type3,
            costsPower = 1,
            lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",},
          }

          -- CT.addCooldownGraph(spellID, CT.player.talents[6], colors.yellow)
        elseif talent and talent == "Execution Sentence" then
          data[#data + 1] = {
            name = talent,
            spellID = 114916,
            func = func.longCD,
            dropDownFunc = CT.type3,
            costsPower = 1,
            lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",},
          }

          -- CT.addCooldownGraph(spellID, CT.player.talents[6], colors.yellow)
        elseif talent and talent == "Holy Prism" then
          data[#data + 1] = {
            name = talent,
            spellID = 114165,
            func = func.shortCD,
            expanderFunc = func.expanderShortCD,
            dropDownFunc = CT.type2,
            costsPower = 1,
            lines = {"Percent on CD:", "Percent off CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:", "Average Targets Hit:",},
          }

          -- CT.addCooldownGraph(spellID, CT.player.talents[6], colors.yellow)
        end
      end

      if CT.player.talents[7] and CT.player.talents[7] == "Seraphim" or CT.player.talents[7] == "Empowered Seals" then
        data[#data + 1] = {}

        name = CT.player.talents[7]
        costsPower = 1

        if name == "Seraphim" then
          spellID = 152262
          func = func.auraUptime
          expanderFunc = func.expanderAuraUptime
          dropDownFunc = CT.type2
          lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                      "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                      "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                      "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

          -- CT.addAuraGraph(86273, name, "Buff", nil, colors.blue)
        elseif name == "Empowered Seals" then
          -- spellID = 114916
          -- func = func.longCD
          -- dropDownFunc = CT.type3
          -- lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
        elseif name == "Holy Prism" then

        end

        -- CT.addCooldownGraph(spellID, name, colors.yellow)
      end

      data[#data + 1] = { -- Stance
        name = "Stance",
        func = func.stance,
        expanderFunc = func.expanderStance,
        dropDownFunc = CT.type2,
        lines = {"Total Gained", "Applied / Refreshed", "Expired Early",},
      }
    end

    return data
  end

  classFunc = paladin
elseif CLASS == "PRIEST" then
  local function priest(specName)
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    if specName == "Discipline" then

    elseif specName == "Holy" then

    elseif specName == "Shadow" then

    end
  end

  classFunc = priest
elseif CLASS == "ROGUE" then
  local function rogue(specName)
    local data = {}

    data[#data + 1] = { -- Activity
      name = "Activity",
      func = func.activity,
      expanderFunc = func.expanderActivity,
      dropDownFunc = CT.type2,
      icon = "Interface/ICONS/Ability_DualWield.png",
      lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",},
    }

    data[#data + 1] = { -- Energy
      name = "Energy",
      powerIndex = 3,
      func = func.resource1,
      expanderFunc = func.expanderResource1,
      dropDownFunc = CT.type1,
      lines = { "Total Gained:", "Total Wasted:", "Effective Gain:", "",
                  "Times Capped:", "Seconds Capped:", },
    }

    data[#data + 1] = { -- Combo Points
      name = "Combo Points",
      func = func.resource2,
      expanderFunc = func.expanderResource2,
      dropDownFunc = CT.type1,
      lines = {"Total Gain:", "Total Loss:",},
      -- icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png",
    }

    if specName == "Subtlety" then

    elseif specName == "Assassination" then
      data[#data + 1] = { -- Deadly Poison
        name = "Deadly Poison",
        spellID = 2823,
        func = func.auraUptime,
        expanderFunc = func.expanderAuraUptime,
        dropDownFunc = CT.type2,
        lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",},
      }

      -- CT.addAuraGraph(spellID, name, "Buff", nil, colors.green)

      data[#data + 1] = { -- Envenom
        name = "Envenom",
        spellID = 32645,
        func = func.auraUptime,
        expanderFunc = func.expanderEnvenom,
        dropDownFunc = CT.type2,
        lines = {"Uptime:", "Longest Delay:", "Avg Energy Level:", "Avg Combo Points:",
                    "Total Casts:", "Times Refreshed:", "Wasted Time:", "Avg Wasted Time:",},
      }

      -- CT.addAuraGraph(spellID, name, "Buff", nil, colors.green)

      data[#data + 1] = { -- Dispatch
        name = "Dispatch",
        spellID = 111240,
        func = func.shortCD,
        expanderFunc = func.expanderExecute,
        dropDownFunc = CT.type2,
        lines = { "Number of Casts:", "Max Possible Casts:", "", "",
                    "Blindside Procs:", "Procs Used:", "Procs Wasted:", "",
                    "", "", "", "",
                    "",},
      }

      data[#data + 1] = { -- Vendetta
        name = "Vendetta",
        spellID = 79140,
        func = func.longCD,
        expanderFunc = func.expanderBurstCD,
        dropDownFunc = CT.type3,
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:", "Longest Delay:",
                      "Total Casts:", "", "", "",
                      "", "", "", "",
                      "",},
      }

      CT.addCooldownGraph(spellID, name, colors.orange)

      data[#data + 1] = { -- Defensives
        name = "Defensives",
        spellID = 0,
        func = func.auraUptime,
        expanderFunc = func.expanderDefensives,
        dropDownFunc = CT.type2,
        lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",},
      }
    elseif specName == "Combat" then

    end

    return data
  end

  classFunc = rogue
elseif CLASS == "SHAMAN" then
  local function shaman(specName)
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    do -- Activity
      data[#data + 1] = {}

      name = "Activity"
      func = func.activity
      expanderFunc = func.expanderActivity
      dropDownFunc = CT.type2
      lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",}
      icon = "Interface/ICONS/Ability_DualWield.png"
    end

    do -- Damage
      data[#data + 1] = {}

      name = "Damage"
      func = func.damage
      dropDownFunc = CT.type1
      lines = {"Total Gain:", "Total Loss:",}
      icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
    end

    do -- All Casts
      data[#data + 1] = {}

      name = "All Casts"
      func = func.allCasts
      expanderFunc = func.expanderAllCasts
      dropDownFunc = CT.type4
      lines = {}
    end

    if specName == "Enhancement" then
      do -- Stormstrike
        data[#data + 1] = {}

        name = "Stormstrike"
        spellID = 17364
        func = func.shortCD
        expanderFunc = func.expanderShortCD
        dropDownFunc = CT.type2
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        costsPower = 1
        CT.addCooldownGraph(17364, "Stormstrike", colors.yellow)
      end

      do -- Lava Lash
        data[#data + 1] = {}

        name = "Lava Lash"
        spellID = 60103
        func = func.shortCD
        expanderFunc = func.expanderShortCD
        dropDownFunc = CT.type2
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        costsPower = 1
        CT.addCooldownGraph(60103, "Lava Lash", colors.yellow)
      end

      do -- Flame Shock
        data[#data + 1] = {}

        name = "Flame Shock"
        spellID = 8050
        func = func.shortCD
        expanderFunc = func.expanderShortCD
        dropDownFunc = CT.type2
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        costsPower = 1

        -- CT.addAuraGraph(8050, "Flame Shock", "Debuff", nil, colors.blue)
      end
    elseif specName == "Elemental" then
      do -- Flame Shock
        data[#data + 1] = {}

        name = "Flame Shock"
        spellID = 8050
        func = func.shortCD
        expanderFunc = func.expanderShortCD
        dropDownFunc = CT.type2
        lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        costsPower = 1

        -- CT.addAuraGraph(8050, "Flame Shock", "Debuff", nil, colors.blue)
      end
    elseif specName == "Restoration" then

    end
  end

  classFunc = shaman
elseif CLASS == "WARLOCK" then
  local function warlock(specName)
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    do -- Activity
      data[#data + 1] = {}

      name = "Activity"
      func = func.activity
      expanderFunc = func.expanderActivity
      dropDownFunc = CT.type2
      lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",}
      icon = "Interface/ICONS/Ability_DualWield.png"
    end

    do -- Damage
      data[#data + 1] = {}

      name = "Damage"
      func = func.damage
      dropDownFunc = CT.type1
      lines = {"Total Gain:", "Total Loss:",}
      icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
    end

    do -- All Casts
      data[#data + 1] = {}

      name = "All Casts"
      func = func.allCasts
      expanderFunc = func.expanderAllCasts
      dropDownFunc = CT.type4
      lines = {}
    end

    if specName == "Demonology" then

    elseif specName == "Affliction" then
      do -- Agony
        data[#data + 1] = {}

        name = "Agony"
        spellID = 980
        func = func.auraUptime
        expanderFunc = func.expanderAuraUptime
        dropDownFunc = CT.type2
        lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        -- CT.addAuraGraph(980, "Agony", "Debuff", nil, colors.blue)
      end

      do -- Corruption
        data[#data + 1] = {}

        name = "Corruption"
        spellID = 172
        func = func.auraUptime
        expanderFunc = func.expanderAuraUptime
        dropDownFunc = CT.type2
        lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        -- CT.addAuraGraph(172, "Corruption", "Debuff", nil, colors.blue)
      end

      do -- Unstable Affliction
        data[#data + 1] = {}

        name = "Unstable Affliction"
        spellID = 30108
        func = func.auraUptime
        expanderFunc = func.expanderAuraUptime
        dropDownFunc = CT.type2
        lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        -- CT.addAuraGraph(30108, "Unstable Affliction", "Debuff", nil, colors.blue)
      end

      do -- Haunt
        data[#data + 1] = {}

        name = "Haunt"
        spellID = 48181
        func = func.auraUptime
        expanderFunc = func.expanderAuraUptime
        dropDownFunc = CT.type2
        lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        -- CT.addAuraGraph(48181, "Haunt", "Debuff", nil, colors.blue)
      end
    elseif specName == "Destruction" then
      do -- Burning Embers
        data[#data + 1] = {}

        name = "Burning Embers"
        powerIndex = 14
        func = func.resource1
        expanderFunc = func.expanderResource1
        dropDownFunc = CT.type1
        lines = { "Focus Gained:", "Focus Wasted:", "Effective Gain:", "",
                    "Times Capped:", "Seconds Capped:", }
      end

      do -- Immolate
        data[#data + 1] = {}

        name = "Immolate"
        spellID = 348
        func = func.auraUptime
        expanderFunc = func.expanderAuraUptime
        dropDownFunc = CT.type2
        lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        -- CT.addAuraGraph(348, "Immolate", "Debuff", nil, colors.blue)
      end

      do -- Conflagrate
        data[#data + 1] = {}

        name = "Conflagrate"
        spellID = 17962
        func = func.shortCD
        expanderFunc = func.expanderShortCD
        dropDownFunc = CT.type2
        lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Holy Power Gained:", "Holy Power Spent:", "Reset Casts:", "Longest Delay:",
                    "Procs Used:", "Total Procs:", "Biggest Heal:", "Average Heal:",}
        costsPower = 1
        givesPower = 2

        CT.addCooldownGraph(17962, "Conflagrate", colors.yellow)
      end
    end
  end

  classFunc = warlock
elseif CLASS == "WARRIOR" then
  local function warrior(specName)
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    if specName == "Arms" then

    elseif specName == "Fury" then

    elseif specName == "Protection" then

    end
  end

  classFunc = warrior
end

function CT.getPlayerDetails()
  local specNum = GetSpecialization()
  local activeSpec = GetActiveSpecGroup()

  local specID, specName, description, specIcon, background, role, primaryStat

  if specNum then -- Can be nil if a spec is not selected
    specID, specName, description, specIcon, background, role, primaryStat = GetSpecializationInfo(specNum)
    CT.player.specName = specName
    CT.player.specNum = specNum
    CT.player.specIcon = specIcon
    CT.player.role = role
    CT.player.primaryStat = primaryStat

    for i = 1, #tierLevels do
      for v = 1, 3 do
        local talentID, name, texture, selected, available = GetTalentInfo(i, v, activeSpec)
        if selected then
          CT.player.talents[i] = name
        end
      end
    end
  end

  CT.specData = classFunc(specName)

  if not CT.specData then return debug("No spec data table returned from classFunc") end

  return CT.specData
end


--[[ TEMPLATES

do -- Activity
  data[#data + 1] = {}

  name = "Activity"
  func = func.activity
  expanderFunc = func.expanderActivity
  dropDownFunc = CT.type2
  lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                "Total Hard Casts:",}
  icon = "Interface/ICONS/Ability_DualWield.png"
end

do -- Damage
  data[#data + 1] = {}

  name = "Damage"
  func = func.damage
  dropDownFunc = CT.type1
  lines = {"Total Gain:", "Total Loss:",}
  icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
end

do -- All Casts
  data[#data + 1] = {}

  name = "All Casts"
  func = func.allCasts
  expanderFunc = func.expanderAllCasts
  dropDownFunc = CT.type4
  lines = {}
end

do -- Crusader Strike
  data[#data + 1] = {}

  name = "Crusader Strike"
  spellID = 35395
  func = func.shortCD
  expanderFunc = func.expanderShortCD
  dropDownFunc = CT.type2
  lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                "Average Heal:",}
  costsPower = 1
  givesPower = 2
  CT.addCooldownGraph(35395, "Crusader Strike", colors.yellow)
end

]]
