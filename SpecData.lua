if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
local colors = CT.colors
local func = CT.updateFunctions
local addLineGraph = CT.addLineGraph
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

      if t.shown then
        if uptimeGraphs.shownList then
          uptimeGraphs.shownList[#uptimeGraphs.shownList + 1] = t
        else
          uptimeGraphs.shownList = {t}
        end

        CT.toggleUptimeGraph(t)
      end

      if t.data then wipe(t.data) else t.data = {} end
      if t.unitName then wipe(t.unitName) else t.unitName = {} end
      if t.colorChange then wipe(t.colorChange) else t.colorChange = {} end

      t.data[1] = 0
      t.data[2] = 0
      t.unitName[2] = "None"
      t.refresh = CT.refreshUptimeGraph
      t.name = "Target"
      t.category = "Misc"
      t.group = "Targeted"
      t.colorPrimary = colors.lightgreen
      t.colorSecondary = colors.lightblue
      t.color = colors.lightgreen
      t.startX = 10
      t.XMin = 0
      t.XMax = 10
      t.YMin = 0
      t.YMax = 10
      t.endNum = 1

      if CT.uptimeGraphLines[t.category][t.name] then -- This should mean the graph was previously created in another set
        for num, line in pairs(CT.uptimeGraphLines[t.category][t.name]) do
          line:Hide()
        end

        wipe(CT.uptimeGraphLines[t.category][t.name])
      else
        CT.uptimeGraphLines[t.category][t.name] = {}
      end
    end

    do -- Focus Target Uptime Graph
      if not uptimeGraphs.misc["Focus Target"] then
        uptimeGraphs.misc["Focus Target"] = {}
        uptimeGraphs.misc[#uptimeGraphs.misc + 1] = uptimeGraphs.misc["Focus Target"]
      end

      local t = uptimeGraphs.misc["Focus Target"]

      if t.shown then
        if uptimeGraphs.shownList then
          uptimeGraphs.shownList[#uptimeGraphs.shownList + 1] = t
        else
          uptimeGraphs.shownList = {t}
        end

        CT.toggleUptimeGraph(t)
      end

      if t.data then wipe(t.data) else t.data = {} end
      if t.unitName then wipe(t.unitName) else t.unitName = {} end
      if t.colorChange then wipe(t.colorChange) else t.colorChange = {} end

      t.data[1] = 0
      t.data[2] = 0
      t.unitName[2] = "None"
      t.refresh = CT.refreshUptimeGraph
      t.name = "Focus Target"
      t.category = "Misc"
      t.group = "Focused"
      t.colorPrimary = colors.lightgreen
      t.colorSecondary = colors.lightblue
      t.color = colors.lightgreen
      t.startX = 10
      t.XMin = 0
      t.XMax = 10
      t.YMin = 0
      t.YMax = 10
      t.endNum = 1

      if CT.uptimeGraphLines[t.category][t.name] then -- This should mean the graph was previously created in another set
        for num, line in pairs(CT.uptimeGraphLines[t.category][t.name]) do
          line:Hide()
        end

        wipe(CT.uptimeGraphLines[t.category][t.name])
      else
        CT.uptimeGraphLines[t.category][t.name] = {}
      end
    end

    do -- Activity Uptime Graph
      if not uptimeGraphs.cooldowns["Activity"] then
        uptimeGraphs.cooldowns["Activity"] = {}
        uptimeGraphs.cooldowns[#uptimeGraphs.cooldowns + 1] = uptimeGraphs.cooldowns["Activity"]
      end

      local t = uptimeGraphs.cooldowns["Activity"]

      t.data = {}
      t.spellName = {}

      t.data[1] = 0
      t.refresh = CT.refreshUptimeGraph
      t.name = "Activity"
      t.category = "Cooldown"
      t.group = "Duration"
      t.color = colors.orange
      t.startX = 10
      t.XMin = 0
      t.XMax = 10
      t.YMin = 0
      t.YMax = 10
      t.endNum = 1

      if CT.uptimeGraphLines[t.category][t.name] then -- This should mean the graph was previously created in another set
        for num, line in pairs(CT.uptimeGraphLines[t.category][t.name]) do
          line:Hide()
        end

        wipe(CT.uptimeGraphLines[t.category][t.name])
      else
        CT.uptimeGraphLines[t.category][t.name] = {}
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
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    do -- Focus
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Focus"
      t.powerIndex = 2
      t.func = func.resource1
      t.expanderFunc = func.expanderResource1
      t.dropDownFunc = CT.type1
      t.lines = { "Focus Gained:", "Focus Wasted:", "Effective Gain:", "",
                  "Times Capped:", "Seconds Capped:", }
    end

    do -- Activity
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Activity"
      t.func = func.activity
      t.dropDownFunc = CT.type2
      t.lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",}
      t.icon = "Interface/ICONS/Ability_DualWield.png"
    end

    do -- All Casts
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "All Casts"
      t.func = func.allCasts
      t.expanderFunc = func.expanderAllCasts
      t.dropDownFunc = CT.type4
      t.lines = {}
    end

    do -- Damage
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Damage"
      t.func = func.damage
      t.expanderFunc = func.expanderDamage
      t.dropDownFunc = CT.type1
      t.lines = {"Total Damage:", "Average DPS:",}
    end

    do -- Pet uptime
      if not uptimeGraphs.misc["Pet"] then
        uptimeGraphs.misc["Pet"] = {}
        uptimeGraphs.misc[#uptimeGraphs.misc + 1] = uptimeGraphs.misc["Pet"]
      end

      local t = uptimeGraphs.misc["Pet"]
      t.data = {}
      t.data[1] = 0
      t.lines = {}
      t.spellName = {}
      t.refresh = CT.refreshUptimeGraph
      t.name = "Pet"
      t.category = "Misc"
      t.group = "Uptime"
      t.color = colors.orange
      t.startX = 10
      t.XMin = 0
      t.XMax = 10
      t.YMin = 0
      t.YMax = 10
      t.endNum = 1
    end

    if specName == "Survival" then
      do -- Explosive Shot
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Explosive Shot"
        t.spellID = 53301
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1

        CT.addCooldownGraph(53301, "Explosive Shot", colors.yellow)
      end

      do -- Black Arrow
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Black Arrow"
        t.spellID = 3674
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1

        CT.addCooldownGraph(3674, "Black Arrow", colors.yellow)
      end
    elseif specName == "Marksmanship" then
      do -- Chimaera Shot
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Chimaera Shot"
        t.spellID = 53209
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Focus Spent:", "Reset Casts:", "Longest Delay:", "",
                    "Procs Used:", "Total Procs:", "Biggest Hit:", "Average Hit:",}
        t.costsPower = 1

        CT.addCooldownGraph(53209, "Chimaera Shot", colors.yellow)
      end

      do -- Kill Shot
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Kill Shot"
        t.spellID = 53351
        t.func = func.execute
        t.expanderFunc = func.expanderExecute
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Reset Casts:", "Longest Delay:", "", "",
                    "Procs Used:", "Total Procs:", "Biggest Hit:", "Average Hit:",}

        CT.addCooldownGraph(53351, "Kill Shot", colors.yellow)
      end
    elseif specName == "Beast Master" then

    end
  end

  classFunc = hunter
elseif CLASS == "MAGE" then
  local function mage(specName)
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    do -- Activity
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Activity"
      t.func = func.activity
      t.expanderFunc = func.expanderActivity
      t.dropDownFunc = CT.type2
      t.lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",}
      t.icon = "Interface/ICONS/Ability_DualWield.png"
    end

    do -- Damage
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Damage"
      t.func = func.damage
      t.dropDownFunc = CT.type1
      t.lines = {"Total Gain:", "Total Loss:",}
      t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
    end

    do -- All Casts
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "All Casts"
      t.func = func.allCasts
      t.expanderFunc = func.expanderAllCasts
      t.dropDownFunc = CT.type4
      t.lines = {}
    end

    if specName == "Frost" then

    elseif specName == "Arcane" then
      -- do -- Crusader Strike
      --   CT.specData[#CT.specData + 1] = {}
      --   local t = CT.specData[#CT.specData]
      --   t.name = "Crusader Strike"
      --   t.spellID = 35395
      --   t.func = func.shortCD
      --   t.expanderFunc = func.expanderShortCD
      --   t.dropDownFunc = CT.type2
      --   t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
      --                 "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
      --                 "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
      --                 "Average Heal:",}
      --   t.costsPower = 1
      --   t.givesPower = 2
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
    local graphs, uptimeGraphs
    if CT.current then
      uptimeGraphs = CT.current.uptimeGraphs
      graphs = CT.current.graphs
    end

    if specName == "Retribution" then
      do -- Activity
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Activity"
        t.func = func.activity
        t.expanderFunc = func.expanderActivity
        t.dropDownFunc = CT.type2
        t.lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                      "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                      "Total Hard Casts:",}
        t.icon = "Interface/ICONS/Ability_DualWield.png"
      end

      do -- Holy Power
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Holy Power"
        t.powerIndex = 9
        t.func = func.resource2
        t.expanderFunc = func.expanderResource2
        t.dropDownFunc = CT.type1
        t.lines = {"Total Gain:", "Total Loss:",}
        t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
      end

      do -- Damage
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Damage"
        t.func = func.damage
        t.dropDownFunc = CT.type1
        t.lines = {"Total Gain:", "Total Loss:",}
        t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
      end

      do -- Crusader Strike
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Crusader Strike"
        t.spellID = 35395
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1
        t.givesPower = 2

        CT.addCooldownGraph(35395, "Crusader Strike", colors.yellow)
      end

      do -- Judgment
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Judgment"
        t.spellID = 20271
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1
        t.givesPower = 2

        CT.addCooldownGraph(20271, "Judgment", colors.yellow)
      end

      do -- Exorcism
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Exorcism"
        t.spellID = 879
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1
        t.givesPower = 2

        CT.addCooldownGraph(879, "Exorcism", colors.yellow)
      end

      if CT.player.talents[6] then
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = CT.player.talents[6]
        t.costsPower = 1

        if t.name == "Light's Hammer" then
          t.spellID = 114158
          t.func = func.longCD
          t.dropDownFunc = CT.type3
          t.lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
        elseif t.name == "Execution Sentence" then
          t.spellID = 114916
          t.func = func.longCD
          t.dropDownFunc = CT.type3
          t.lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
        elseif t.name == "Holy Prism" then
          t.spellID = 114165
          t.func = func.shortCD
          t.expanderFunc = func.expanderShortCD
          t.dropDownFunc = CT.type2
          t.lines = {"Percent on CD:", "Percent off CD:", "Seconds Wasted:", "Average Delay:",
                     "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                     "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                     "Average Heal:", "Average Targets Hit:",}
        end

        CT.addCooldownGraph(t.spellID, CT.player.talents[6], colors.yellow)
      end

      if CT.player.talents[7] and CT.player.talents[7] == "Seraphim" or CT.player.talents[7] == "Empowered Seals" then
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = CT.player.talents[7]
        t.costsPower = 1

        if t.name == "Seraphim" then
          t.spellID = 152262
          t.func = func.auraUptime
          t.expanderFunc = func.expanderAuraUptime
          t.dropDownFunc = CT.type2
          t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                      "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                      "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                      "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

          CT.addAuraGraph(86273, t.name, "Buff", nil, colors.blue)
        elseif t.name == "Empowered Seals" then
          -- t.spellID = 114916
          -- t.func = func.longCD
          -- t.dropDownFunc = CT.type3
          -- t.lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
        elseif t.name == "Holy Prism" then

        end

        CT.addCooldownGraph(t.spellID, t.name, colors.yellow)
      end

      do -- Stance
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Stance"
        t.func = func.stance
        t.expanderFunc = func.expanderStance
        t.dropDownFunc = CT.type2
        t.lines = {"Total Gained", "Applied / Refreshed", "Expired Early",}

        if CT.current then
          uptimeGraphs.misc["Stance"] = {}
          uptimeGraphs.misc[#uptimeGraphs.misc + 1] = uptimeGraphs.misc["Stance"]
          local t = uptimeGraphs.misc["Stance"]
          t.data = {}
          t.data[1] = 0
          t.spellName = {}
          t.colorChange = {}
          t.lines = {}
          t.refresh = CT.refreshUptimeGraph
          t.name = "Stance"
          t.category = "Misc"
          t.group = "Seal"
          t.colorPrimary = colors.lightgreen
          t.colorSecondary = colors.lightblue
          t.color = colors.lightgreen
          t.startX = 10
          t.XMin = 0
          t.XMax = 10
          t.YMin = 0
          t.YMax = 10
          t.endNum = 1

          CT.uptimeGraphLines[t.category][t.name] = {}
        end
      end

      return
    elseif specName == "Holy" then
      do -- Activity
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Activity"
        t.func = func.activity
        t.expanderFunc = func.expanderActivity
        t.dropDownFunc = CT.type2
        t.lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                      "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                      "Total Hard Casts:",}
        t.icon = "Interface/ICONS/Ability_DualWield.png"
      end

      do -- Mana
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Mana"
        t.powerIndex = 0
        t.func = func.resource1
        t.expanderFunc = func.expanderResource1
        t.dropDownFunc = CT.type1
        t.lines = { "Mana Gained:", "Mana Wasted:", "Effective Gain:", "",
                    "Times Capped:", "Seconds Capped:", }
      end

      do -- Holy Power
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Holy Power"
        t.powerIndex = 9
        t.func = func.resource2
        t.expanderFunc = func.expanderResource2
        t.dropDownFunc = CT.type1
        t.lines = { "Holy Power Gained:", "Holy Power Wasted:", "", "",
                    "Times Capped:", "Seconds Capped:", }
        t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
      end

      do -- Healing TODO: No expander func
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Healing"
        t.func = func.healing
        t.dropDownFunc = CT.type1
        t.lines = {"Total Gain:", "Total Loss:",}
        t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
      end

      do -- Illuminated Healing
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Illuminated Healing"
        t.spellID = 86273
        t.func = func.auraUptime
        t.expanderFunc = func.expanderAuraUptime
        t.dropDownFunc = CT.type2
        t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        CT.addAuraGraph(86273, "Illuminated Healing", "Buff", nil, colors.blue)
      end

      do -- All Casts
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "All Casts"
        t.func = func.allCasts
        t.expanderFunc = func.expanderAllCasts
        t.dropDownFunc = CT.type4
        t.lines = {}
      end

      do -- Holy Shock
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Holy Shock"
        t.spellID = 20473
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Holy Power Gained:", "Holy Power Spent:", "Reset Casts:", "Longest Delay:",
                    "Procs Used:", "Total Procs:", "Biggest Heal:", "Average Heal:",}
        t.costsPower = 1
        t.givesPower = 2

        CT.addCooldownGraph(20473, "Holy Shock", colors.yellow)
      end

      do -- CT.player.talents[6]
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = CT.player.talents[6]
        t.costsPower = 1

        if t.name == "Light's Hammer" then
          t.spellID = 114158
          t.func = func.longCD
          t.dropDownFunc = CT.type3
          t.lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
        elseif t.name == "Execution Sentence" then
          t.spellID = 114916
          t.func = func.longCD
          t.dropDownFunc = CT.type3
          t.lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
        elseif t.name == "Holy Prism" then
          t.spellID = 114165
          t.func = func.shortCD
          t.expanderFunc = func.expanderShortCD
          t.dropDownFunc = CT.type2
          t.lines = {"Percent on CD:", "Percent off CD:", "Seconds Wasted:", "Average Delay:",
                     "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                     "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                     "Average Heal:", "Average Targets Hit:",}
        end

        -- CT.addCooldownGraph(t.spellID, CT.player.talents[6], colors.yellow)
      end

      if not IsPassiveSpell(CT.player.talents[7]) then
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = CT.player.talents[7]
        t.func = func.shortCD
        t.dropDownFunc = CT.type2
        t.lines = {"None", "None"}
        t.costsPower = 1
      end

      -- do -- Divine Protection
      --   CT.specData[#CT.specData + 1] = {}
      --   local t = CT.specData[#CT.specData]
      --   t.name = "Divine Protection"
      --   t.spellID = 498
      --   t.func = func.longCD
      --   t.dropDownFunc = CT.type3
      --   t.lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
      --   t.costsPower = 1
      -- end

      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Cleanse"
      t.func = func.dispel
      t.dropDownFunc = CT.type2
      t.lines = {"None", "None",}
      t.costsPower = 1

      do -- Stance
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Stance"
        t.func = func.stance
        t.expanderFunc = func.expanderStance
        t.dropDownFunc = CT.type2
        t.lines = {"Total Gained", "Applied / Refreshed", "Expired Early",}

        if CT.current then
          uptimeGraphs.misc["Stance"] = {}
          uptimeGraphs.misc[#uptimeGraphs.misc + 1] = uptimeGraphs.misc["Stance"]
          local t = uptimeGraphs.misc["Stance"]
          t.data = {}
          t.data[1] = 0
          t.spellName = {}
          t.colorChange = {}
          t.lines = {}
          t.refresh = CT.refreshUptimeGraph
          t.name = "Stance"
          t.category = "Misc"
          t.group = "Seal"
          t.colorPrimary = colors.lightgreen
          t.colorSecondary = colors.lightblue
          t.color = colors.lightgreen
          t.startX = 10

          t.XMin = 0
          t.XMax = 10
          t.YMin = 0
          t.YMax = 10
          t.endNum = 1

          if CT.uptimeGraphLines[t.category][t.name] then -- This should mean the graph was previously created in another set
            for num, line in pairs(CT.uptimeGraphLines[t.category][t.name]) do
              line:Hide()
            end

            wipe(CT.uptimeGraphLines[t.category][t.name])
          else
            CT.uptimeGraphLines[t.category][t.name] = {}
          end
        end
      end

      CT.executePercent = 20
      return
    elseif specName == "Protection" then
      do -- Activity
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Activity"
        t.func = func.activity
        t.expanderFunc = func.expanderActivity
        t.dropDownFunc = CT.type2
        t.lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                      "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                      "Total Hard Casts:",}
        t.icon = "Interface/ICONS/Ability_DualWield.png"
      end

      do -- Holy Power
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Holy Power"
        t.powerIndex = 9
        t.func = func.resource2
        t.expanderFunc = func.expanderResource2
        t.dropDownFunc = CT.type1
        t.lines = {"Total Gain:", "Total Loss:",}
        t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
      end

      do -- Damage
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Damage"
        t.func = func.damage
        t.dropDownFunc = CT.type1
        t.lines = {"Total Gain:", "Total Loss:",}
        t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
      end

      do -- All Casts
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "All Casts"
        t.func = func.allCasts
        t.expanderFunc = func.expanderAllCasts
        t.dropDownFunc = CT.type4
        t.lines = {}
      end

      do -- Damage Taken
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Damage Taken"
        t.func = func.damage
        t.dropDownFunc = CT.type1
        t.lines = {"Total Gain:", "Total Loss:",}
        t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
      end

      do -- Crusader Strike
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Crusader Strike"
        t.spellID = 35395
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1
        t.givesPower = 2

        CT.addCooldownGraph(35395, "Crusader Strike", colors.yellow)
      end

      do -- Judgment
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Judgment"
        t.spellID = 20271
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1
        t.givesPower = 2

        CT.addCooldownGraph(20271, "Judgment", colors.yellow)
      end

      if CT.player.talents[6] then
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = CT.player.talents[6]
        t.costsPower = 1

        if t.name == "Light's Hammer" then
          t.spellID = 114158
          t.func = func.longCD
          t.dropDownFunc = CT.type3
          t.lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
        elseif t.name == "Execution Sentence" then
          t.spellID = 114916
          t.func = func.longCD
          t.dropDownFunc = CT.type3
          t.lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
        elseif t.name == "Holy Prism" then
          t.spellID = 114165
          t.func = func.shortCD
          t.expanderFunc = func.expanderShortCD
          t.dropDownFunc = CT.type2
          t.lines = {"Percent on CD:", "Percent off CD:", "Seconds Wasted:", "Average Delay:",
                     "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                     "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                     "Average Heal:", "Average Targets Hit:",}
        end

        CT.addCooldownGraph(t.spellID, CT.player.talents[6], colors.yellow)
      end

      if CT.player.talents[7] and CT.player.talents[7] == "Seraphim" or CT.player.talents[7] == "Empowered Seals" then
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = CT.player.talents[7]
        t.costsPower = 1

        if t.name == "Seraphim" then
          t.spellID = 152262
          t.func = func.auraUptime
          t.expanderFunc = func.expanderAuraUptime
          t.dropDownFunc = CT.type2
          t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                      "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                      "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                      "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

          CT.addAuraGraph(86273, t.name, "Buff", nil, colors.blue)
        elseif t.name == "Empowered Seals" then
          -- t.spellID = 114916
          -- t.func = func.longCD
          -- t.dropDownFunc = CT.type3
          -- t.lines = {"Total Delay:", "Average Delay:", "Average Delay", "%d. Cast Delay:",}
        elseif t.name == "Holy Prism" then

        end

        CT.addCooldownGraph(t.spellID, t.name, colors.yellow)
      end

      do -- Stance
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Stance"
        t.func = func.stance
        t.expanderFunc = func.expanderStance
        t.dropDownFunc = CT.type2
        t.lines = {"Total Gained", "Applied / Refreshed", "Expired Early",}

        uptimeGraphs.misc["Stance"] = {}
        uptimeGraphs.misc[#uptimeGraphs.misc + 1] = uptimeGraphs.misc["Stance"]
        local t = uptimeGraphs.misc["Stance"]
        t.data = {}
        t.data[1] = 0
        t.spellName = {}
        t.colorChange = {}
        t.lines = {}
        t.refresh = CT.refreshUptimeGraph
        t.name = "Stance"
        t.category = "Misc"
        t.group = "Seal"
        t.colorPrimary = colors.lightgreen
        t.colorSecondary = colors.lightblue
        t.color = colors.lightgreen
        t.startX = 10

        t.XMin = 0
        t.XMax = 10
        t.YMin = 0
        t.YMax = 10
        t.endNum = 1

        CT.uptimeGraphLines[t.category][t.name] = {}
      end
    end
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
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    do -- Activity
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Activity"
      t.func = func.activity
      t.expanderFunc = func.expanderActivity
      t.dropDownFunc = CT.type2
      t.lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",}
      t.icon = "Interface/ICONS/Ability_DualWield.png"
    end

    do -- Energy
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Energy"
      t.powerIndex = 3
      t.func = func.resource1
      t.expanderFunc = func.expanderResource1
      t.dropDownFunc = CT.type1
      t.lines = { "Total Gained:", "Total Wasted:", "Effective Gain:", "",
                  "Times Capped:", "Seconds Capped:", }
    end

    do -- Combo Points
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Combo Points"
      t.func = func.resource2
      t.expanderFunc = func.expanderResource2
      t.dropDownFunc = CT.type1
      t.lines = {"Total Gain:", "Total Loss:",}
      -- t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
    end

    if specName == "Subtlety" then

    elseif specName == "Assassination" then
      do -- Deadly Poison
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Deadly Poison"
        t.spellID = 2823
        t.func = func.auraUptime
        t.expanderFunc = func.expanderAuraUptime
        t.dropDownFunc = CT.type2
        t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        CT.addAuraGraph(t.spellID, t.name, "Buff", nil, colors.green)
      end

      do -- Deadly Poison
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Envenom"
        t.spellID = 32645
        t.func = func.auraUptime
        t.expanderFunc = func.expanderEnvenom
        t.dropDownFunc = CT.type2
        t.lines = {"Uptime:", "Longest Delay:", "Avg Energy Level:", "Avg Combo Points:",
                    "Total Casts:", "Times Refreshed:", "Wasted Time:", "Avg Wasted Time:",}

        CT.addAuraGraph(t.spellID, t.name, "Buff", nil, colors.green)
      end

      do -- Dispatch
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Dispatch"
        t.spellID = 111240
        t.func = func.shortCD
        t.expanderFunc = func.expanderExecute
        t.dropDownFunc = CT.type2
        t.lines = { "Number of Casts:", "Max Possible Casts:", "", "",
                    "Blindside Procs:", "Procs Used:", "Procs Wasted:", "",
                    "", "", "", "",
                    "",}
      end

      do -- Vendetta
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Vendetta"
        t.spellID = 79140
        t.func = func.longCD
        t.expanderFunc = func.expanderBurstCD
        t.dropDownFunc = CT.type3
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:", "Longest Delay:",
                      "Total Casts:", "", "", "",
                      "", "", "", "",
                      "",}

        CT.addCooldownGraph(t.spellID, t.name, colors.orange)
      end

      do -- Defensives
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Defensives"
        t.spellID = 0
        t.func = func.auraUptime
        t.expanderFunc = func.expanderDefensives
        t.dropDownFunc = CT.type2
        t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}
      end
    elseif specName == "Combat" then

    end
  end

  classFunc = rogue
elseif CLASS == "SHAMAN" then
  local function shaman(specName)
    local uptimeGraphs = CT.current.uptimeGraphs
    local graphs = CT.current.graphs

    do -- Activity
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Activity"
      t.func = func.activity
      t.expanderFunc = func.expanderActivity
      t.dropDownFunc = CT.type2
      t.lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",}
      t.icon = "Interface/ICONS/Ability_DualWield.png"
    end

    do -- Damage
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Damage"
      t.func = func.damage
      t.dropDownFunc = CT.type1
      t.lines = {"Total Gain:", "Total Loss:",}
      t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
    end

    do -- All Casts
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "All Casts"
      t.func = func.allCasts
      t.expanderFunc = func.expanderAllCasts
      t.dropDownFunc = CT.type4
      t.lines = {}
    end

    if specName == "Enhancement" then
      do -- Stormstrike
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Stormstrike"
        t.spellID = 17364
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1
        CT.addCooldownGraph(17364, "Stormstrike", colors.yellow)
      end

      do -- Lava Lash
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Lava Lash"
        t.spellID = 60103
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1
        CT.addCooldownGraph(60103, "Lava Lash", colors.yellow)
      end

      do -- Flame Shock
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Flame Shock"
        t.spellID = 8050
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1

        CT.addAuraGraph(8050, "Flame Shock", "Debuff", nil, colors.blue)
      end
    elseif specName == "Elemental" then
      do -- Flame Shock
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Flame Shock"
        t.spellID = 8050
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                      "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                      "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                      "Average Heal:",}
        t.costsPower = 1

        CT.addAuraGraph(8050, "Flame Shock", "Debuff", nil, colors.blue)
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
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Activity"
      t.func = func.activity
      t.expanderFunc = func.expanderActivity
      t.dropDownFunc = CT.type2
      t.lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                    "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                    "Total Hard Casts:",}
      t.icon = "Interface/ICONS/Ability_DualWield.png"
    end

    do -- Damage
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "Damage"
      t.func = func.damage
      t.dropDownFunc = CT.type1
      t.lines = {"Total Gain:", "Total Loss:",}
      t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
    end

    do -- All Casts
      CT.specData[#CT.specData + 1] = {}
      local t = CT.specData[#CT.specData]
      t.name = "All Casts"
      t.func = func.allCasts
      t.expanderFunc = func.expanderAllCasts
      t.dropDownFunc = CT.type4
      t.lines = {}
    end

    if specName == "Demonology" then

    elseif specName == "Affliction" then
      do -- Agony
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Agony"
        t.spellID = 980
        t.func = func.auraUptime
        t.expanderFunc = func.expanderAuraUptime
        t.dropDownFunc = CT.type2
        t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        CT.addAuraGraph(980, "Agony", "Debuff", nil, colors.blue)
      end

      do -- Corruption
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Corruption"
        t.spellID = 172
        t.func = func.auraUptime
        t.expanderFunc = func.expanderAuraUptime
        t.dropDownFunc = CT.type2
        t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        CT.addAuraGraph(172, "Corruption", "Debuff", nil, colors.blue)
      end

      do -- Unstable Affliction
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Unstable Affliction"
        t.spellID = 30108
        t.func = func.auraUptime
        t.expanderFunc = func.expanderAuraUptime
        t.dropDownFunc = CT.type2
        t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        CT.addAuraGraph(30108, "Unstable Affliction", "Debuff", nil, colors.blue)
      end

      do -- Haunt
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Haunt"
        t.spellID = 48181
        t.func = func.auraUptime
        t.expanderFunc = func.expanderAuraUptime
        t.dropDownFunc = CT.type2
        t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        CT.addAuraGraph(48181, "Haunt", "Debuff", nil, colors.blue)
      end
    elseif specName == "Destruction" then
      do -- Burning Embers
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Burning Embers"
        t.powerIndex = 14
        t.func = func.resource1
        t.expanderFunc = func.expanderResource1
        t.dropDownFunc = CT.type1
        t.lines = { "Focus Gained:", "Focus Wasted:", "Effective Gain:", "",
                    "Times Capped:", "Seconds Capped:", }
      end

      do -- Immolate
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Immolate"
        t.spellID = 348
        t.func = func.auraUptime
        t.expanderFunc = func.expanderAuraUptime
        t.dropDownFunc = CT.type2
        t.lines = {"Uptime:", "Downtime:", "Average Downtime:", "Longest Downtime:",
                    "Total Applications:", "Times Refreshed:", "Wasted Time:", "",
                    "Total Absorbs:", "Wasted Absorbs", "Average Absorb:", "Biggest Absorb:",
                    "Percent of Healing:", "Procs Used:", "Total Procs:", "",}

        CT.addAuraGraph(348, "Immolate", "Debuff", nil, colors.blue)
      end

      do -- Conflagrate
        CT.specData[#CT.specData + 1] = {}
        local t = CT.specData[#CT.specData]
        t.name = "Conflagrate"
        t.spellID = 17962
        t.func = func.shortCD
        t.expanderFunc = func.expanderShortCD
        t.dropDownFunc = CT.type2
        t.lines = { "Percent on CD:", "Seconds Wasted:", "Average Delay:", "Number of Casts:",
                    "Holy Power Gained:", "Holy Power Spent:", "Reset Casts:", "Longest Delay:",
                    "Procs Used:", "Total Procs:", "Biggest Heal:", "Average Heal:",}
        t.costsPower = 1
        t.givesPower = 2

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

  CT.specData = CT.specData and wipe(CT.specData) or {}

  classFunc(specName)
end


--[[ TEMPLATES

do -- Activity
  CT.specData[#CT.specData + 1] = {}
  local t = CT.specData[#CT.specData]
  t.name = "Activity"
  t.func = func.activity
  t.expanderFunc = func.expanderActivity
  t.dropDownFunc = CT.type2
  t.lines = {"Active Time:", "Percent:", "Seconds Active:", "Total Active Seconds:",
                "Seconds Casting:", "Seconds on GCD:", "", "", "Total Casts:", "Total Instant Casts:",
                "Total Hard Casts:",}
  t.icon = "Interface/ICONS/Ability_DualWield.png"
end

do -- Damage
  CT.specData[#CT.specData + 1] = {}
  local t = CT.specData[#CT.specData]
  t.name = "Damage"
  t.func = func.damage
  t.dropDownFunc = CT.type1
  t.lines = {"Total Gain:", "Total Loss:",}
  t.icon = "Interface/ICONS/Spell_Holy_DivineProvidence.png"
end

do -- All Casts
  CT.specData[#CT.specData + 1] = {}
  local t = CT.specData[#CT.specData]
  t.name = "All Casts"
  t.func = func.allCasts
  t.expanderFunc = func.expanderAllCasts
  t.dropDownFunc = CT.type4
  t.lines = {}
end

do -- Crusader Strike
  CT.specData[#CT.specData + 1] = {}
  local t = CT.specData[#CT.specData]
  t.name = "Crusader Strike"
  t.spellID = 35395
  t.func = func.shortCD
  t.expanderFunc = func.expanderShortCD
  t.dropDownFunc = CT.type2
  t.lines = {"Percent on CD:", "Seconds Wasted:", "Average Delay:",
                "Number of Casts:", "Spent:", "Gained:", "Reset Casts:",
                "Longest Delay:", "Procs Used:", "Total Procs:", "Biggest Heal:",
                "Average Heal:",}
  t.costsPower = 1
  t.givesPower = 2
  CT.addCooldownGraph(35395, "Crusader Strike", colors.yellow)
end

]]
