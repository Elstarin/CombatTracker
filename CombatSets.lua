if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
local buttonClickNum = 7

function CT.addNewSet()
  local _, specName = GetSpecializationInfo(GetSpecialization())

  if CT.current then tinsert(CombatTrackerCharDB[specName].sets, 1, CT.current) end
  CombatTrackerCharDB[specName].sets.current = {}
  CT.current = CombatTrackerCharDB[specName].sets.current

  CT.setBasicData()
  CT.nameCurrentSet()
  CT.getPlayerDetails()

  if not CT.displayed then CT.displayed = CT.current end

  CT.showLineGraph(nil, CT.buttons[buttonClickNum].name)

  local foundGraph
  for index, v in ipairs(CT.current.uptimeGraphs.categories) do
    for i = 1, #v do
      if v[i].name == buttonName then
        foundGraph = true
        CT.toggleUptimeGraph(v[i], true)
      end
    end
  end

  if not foundGraph then
    for index, v in ipairs(CT.current.uptimeGraphs.categories) do
      for i = 1, #v do
        if v[i].name == "Activity" then
          CT.toggleUptimeGraph(v[i], true)
        end
      end
    end
  end
end

function CT.nameCurrentSet()
  do -- Find a name for this set
    local name

    for i = 1, 5 do -- First look for a hostile boss name
      local unitID = "boss" .. i
      local bossName = UnitName(unitID)
      local reaction = UnitReaction("player", unitID)

      if bossName and reaction == 2 or reaction == 4 then
        name = bossName
        break
      end
    end

    if not name then -- Failed to find a hostile boss, check other potential units
      if not name and UnitExists("target") then
        local reaction = UnitReaction("player", "target")
        if reaction == 2 or reaction == 4 then
          name = UnitName("target")
        end
      end

      if not name and UnitExists("mouseover") then
        local reaction = UnitReaction("player", "mouseover")
        if reaction == 2 or reaction == 4 then
          name = UnitName("mouseover")
        end
      end

      if not name and UnitExists("pettarget") then
        local reaction = UnitReaction("player", "pettarget")
        if reaction == 2 or reaction == 4 then
          name = UnitName("pettarget")
        end
      end

      if not name and UnitExists("focus") then
        local reaction = UnitReaction("player", "focus")
        if reaction == 2 or reaction == 4 then
          name = UnitName("focus")
        end
      end
    end

    name = name or "None"

    CT.fightName = name
    CT.current.fightName = name -- Add the fight name to the active set

    if CT.base.expander then
      CT.base.expander.titleData.rightText1:SetText(name)
    end
  end
end

function CT.startTracking()
  if CT.tracking then return end

  -- CT.resetData()
  CT.buildNewSet()

  do -- Get GUIDs
    CT.current.GUID = UnitGUID("player")
    CT.current.petGUID = UnitGUID("pet")
  end

  CT.combatStart = GetTime()
  CT.current.startTime = GetTime()
  CT.current.stopTime = nil

  CT.tracking = true
  CT.inCombat = true
  CT.combatStop = nil

  CT.iterateAuras()
  CT.iterateCooldowns()
end

function CT.stopTracking()
  CT.combatStop = GetTime()
  CT.finalizeGraphLength()
  CT.tracking = false
  CT.inCombat = false
end

function CT.createSetButtons(menu, table)
  if not menu then return end

  local height = 0
  local width = menu:GetWidth()
  local y = 0

  for i = 1, max(#menu, #table) do
    local b = menu[i]

    if table[i] then
      if not b then
        menu[i] = CreateFrame("CheckButton", nil, menu)
        b = CT.createSmallButton(menu[i], true, true)
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        b:SetScript("OnClick", function(self, click)
          if click == "LeftButton" then
            if self:GetChecked() then
              CT:Print("Setting displayed to table[i].", CT.displayed, table[i])
              CT.displayed = table[i]
              CT.forceUpdate = true

              for i = 1, #menu do -- Uncheck any previously checked buttons, so only one is checked at any time
                if menu[i] ~= self and menu[i]:GetChecked() then
                  menu[i]:SetChecked(false)
                end
              end
            else
              CT.displayed = CT.current
              CT:Print("Setting displayed back to current.")
              CT.forceUpdate = true
            end
          elseif click == "RightButton" then
            local t = tremove(table, index) -- Remove saved variables
            t = nil

            if not InCombatLockdown() then
              collectgarbage("collect")
            end

            CT.createSetButtons(menu, table) -- Refresh list
          end
        end)
      end

      b:Show()
      b.index:SetFormattedText("%s.", i)
      local text = table[i].fightName or "Unknown"
      local time = CT.formatTimer(table[i].fightLength) or "0:00"
      b.title:SetFormattedText("%s (%s)", text, time)

      b:SetSize(width - 5, 20)
      b:SetPoint("TOP", menu, 0, y)
      y = y - 20

      height = height + 20
    elseif b then
      b:Hide()
    end
  end

  menu:SetHeight(height)
end

local function nameCurrentSet(set)
  local name

  if not name then -- First look for a hostile boss name
    for i = 1, 5 do
      local unitID = "boss" .. i
      local bossName = UnitName(unitID)
      local reaction = UnitReaction("player", unitID)

      if bossName and reaction == 2 or reaction == 4 then
        name = bossName
        break
      end
    end
  end

  if not name then -- Failed to find a hostile boss, check other potential units
    if not name and UnitExists("target") then
      local reaction = UnitReaction("player", "target")
      if reaction == 2 or reaction == 4 then
        name = UnitName("target")
      end
    end

    if not name and UnitExists("mouseover") then
      local reaction = UnitReaction("player", "mouseover")
      if reaction == 2 or reaction == 4 then
        name = UnitName("mouseover")
      end
    end

    if not name and UnitExists("pettarget") then
      local reaction = UnitReaction("player", "pettarget")
      if reaction == 2 or reaction == 4 then
        name = UnitName("pettarget")
      end
    end

    if not name and UnitExists("focus") then
      local reaction = UnitReaction("player", "focus")
      if reaction == 2 or reaction == 4 then
        name = UnitName("focus")
      end
    end
  end

  name = name or "None"

  return name
end

local function basicSetData(set, temp)
  if set then
    set.activity = {}
    set.spells = {}
    set.auras = {}
    set.stance = {}

    set.healing = {}
    set.healingTaken = {}
    set.damage = {}
    set.damageTaken = {}
    set.petDamage = {}

    set.units = {}
    set.targets = {}
    set.focus = {}

    set.power = {}
    set.bossID = {}
  end

  temp.name = GetUnitName("player", false)
  temp.petName = GetUnitName("pet", false)
  temp.prevTarget = "None"
  temp.prevFocus = "None"

  CT.settings.spellCooldownThrottle = 0.0085
end

local function basicPowerData(set, temp)
  for i = 0, #CT.powerTypes do
    local maxPower = UnitPowerMax("player", i)

    if maxPower > 0 then
      local name = CT.powerTypesFormatted[i]

      set.power[#set.power + 1] = {
        ["name"] = name,
        ["index"] = i,
        ["maxPower"] = maxPower,
      }

      set.power[name] = {
        ["index"] = i,
        ["maxPower"] = maxPower,
      }

      CT.graphList[#CT.graphList + 1] = CT.powerTypesFormatted[i]
    end
  end
end

local function basicGraphData(set, temp)
  CT.graphList[#CT.graphList + 1] = "Healing"
  CT.graphList[#CT.graphList + 1] = "Damage"
  CT.graphList[#CT.graphList + 1] = "Damage Taken"

  if GetUnitName("pet", false) then
    CT.graphList[#CT.graphList + 1] = "Total Damage"
    CT.graphList[#CT.graphList + 1] = "Pet Damage"
  end

  if set then set.graphs = {} end

  temp.graphs = {}

  temp.graphs.updateDelay = 0.2
  temp.graphs.lastUpdate = 0
  temp.graphs.splitAmount = 500

  for index, name in ipairs(CT.graphList) do
    local graphSet

    if set then
      set.graphs[name] = {}
      graphSet = set.graphs[name]

      graphSet.data = {}
      graphSet.XMin = 0
      graphSet.XMax = 10
      graphSet.YMin = -5
      graphSet.YMax = 105
    else
      graphSet = temp.parentSet
    end

    temp.graphs[name] = {}
    local graphTemp = temp.graphs[name]

    graphTemp.data = graphSet.data
    graphTemp.XMin = graphSet.XMin
    graphTemp.XMax = graphSet.XMax
    graphTemp.YMin = graphSet.YMin
    graphTemp.YMax = graphSet.YMax

    graphTemp.lines = {}
    graphTemp.name = name
    graphTemp.shown = false
    graphTemp.endNum = 2
    graphTemp.splitCount = 0
    graphTemp.startX = 10
    graphTemp.startY = YMax or graphSet.YMax
    graphTemp.toggle = CT.toggleNormalGraph
    graphTemp.refresh = CT.refreshNormalGraph
    graphTemp.update, graphTemp.color = CT.getGraphUpdateFunc(set, temp, name)
  end
end

local function basicUptimeGraphData(set, temp) -- NOTE: Meta table here?
  local graphSet = temp.parentSet

  if set then
    set.uptimeGraphs = {}
    graphSet = set.uptimeGraphs
    graphSet.cooldowns = {}
    graphSet.buffs = {}
    graphSet.debuffs = {}
    graphSet.misc = {}
  end

  temp.uptimeGraphs = {}
  local graphTemp = temp.uptimeGraphs
  graphTemp.cooldowns = {}
  graphTemp.buffs = {}
  graphTemp.debuffs = {}
  graphTemp.misc = {}

  function graphTemp.addCooldown(spellID, spellName, color)
    local graph = graphSet.cooldowns[spellID]

    if not graph then
      graphSet.cooldowns[spellID] = {}
      graph = graphSet.cooldowns[spellID]
      graph.data = {}
    end

    graphTemp.cooldowns[spellID] = {}
    graphTemp.cooldowns[spellID].data = graph.data
  end
end

function CT.buildNewSet()
  CT:Print("Building a new data set.")
  local set = CT.current

  do -- Create the set table
    local _, specName = GetSpecializationInfo(GetSpecialization())

    if set then -- Save current set
      if set.temp then set.temp = nil end -- Remove this before saving it

      tinsert(CombatTrackerCharDB[specName].sets, 1, set)
    end

    CombatTrackerCharDB[specName].sets.current = {}
    set = CombatTrackerCharDB[specName].sets.current

    set.name = nameCurrentSet(set)
    set.start = GetTime()

    set.temp = {} -- The table that will be deleted before saving
    set.temp.parentSet = set
    CT.updateLocalData(set)
  end

  basicSetData(set, set.temp)
  basicPowerData(set, set.temp)
  basicGraphData(set, set.temp)
  basicUptimeGraphData(set, set.temp)

  CT.current = set
  if not CT.displayed then CT.displayed = set end
end

function CT.loadSavedSet(set)
  if not set then CT:Print("Tried to load a set without passing the set table!") return end

  set.temp = {} -- The table that will be deleted before saving
  set.temp.parentSet = set

  basicSetData(nil, set.temp)
  basicGraphData(nil, set.temp)
  basicUptimeGraphData(nil, set.temp)

  CT.displayed = set
end
