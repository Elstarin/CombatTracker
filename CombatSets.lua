if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
local buttonClickNum = 7

local function saveDataSet(db)
  if db then -- Save current DB
    CT:Print("Saving data set:", db.setName .. ".")
    if not db.stop then
      db.stop = GetTime()
    end

    local _, specName = GetSpecializationInfo(GetSpecialization())
    tinsert(CombatTrackerCharDB[specName].sets, 1, db)
  end
end

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

function CT.startTracking(message)
  -- if CT.tracking then CT:Print("Already tracking! Message:", message) return end
  if CT.tracking then return end
  CT:Print(message or "Starting tracking, but no start message was sent.")

  -- CT.resetData()
  local set, db = CT.buildNewSet()

  set.GUID = UnitGUID("player")
  set.petGUID = UnitGUID("pet")

  if db.stop then
    print("db.stop exists in start tracking.")
    db.stop = nil
  end

  CT.combatStart = GetTime()
  CT.current.startTime = GetTime()
  CT.current.stopTime = nil

  CT.tracking = true
  CT.inCombat = true
  CT.combatStop = nil

  CT.iterateAuras()
  CT.iterateCooldowns()
  CT.loadDefaultGraphs()
end

function CT.stopTracking()
  CT:Print("Stopping tracking.")
  CT.combatStop = GetTime()

  CT.currentDB.stop = GetTime()
  saveDataSet(CT.currentDB)

  CT.currentDB = nil
  CT.current = nil

  CT.inCombat = false
  CT.tracking = false

  CT.finalizeGraphLength()
end

function CT.createSetButtons(menu, table)
  -- CT.createSavedSetButtons(table)
  -- menu = nil -- NOTE: Testing only

  if not menu then return end

  local widestButton = 0
  local height = 0
  local width = menu:GetWidth()
  local y = 0

  for i = 1, max(#menu, #table) do
    local b = menu[i]

    if table[i] then
      if not b then
        menu[i] = CreateFrame("CheckButton", nil, menu)
        b = CT.createSmallButton(menu[i], false, true)
        b:SetPoint("LEFT", 0, 0)
        b:SetPoint("RIGHT", 0, 0)
        b.title:SetTextColor(1, 1, 1, 1)
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        b:SetScript("OnClick", function(self, click)
          if click == "LeftButton" then
            if self:GetChecked() then
              local set, db = CT.loadSavedSet(table[i])
              CT.forceUpdate = true

              for i = 1, #menu do -- Uncheck any previously checked buttons, so only one is checked at any time
                if menu[i] ~= self and menu[i]:GetChecked() then
                  menu[i]:SetChecked(false)
                end
              end
            else
              if CT.current then
                CT:Print("Setting displayed back to current.")
                CT.displayed = CT.current
                CT.displayedDB = CT.currentDB
                CT.forceUpdate = true
              end
            end
          elseif click == "RightButton" then
            local t = tremove(table, i) -- Remove saved variables
            t = nil

            if not InCombatLockdown() then
              collectgarbage("collect")
            end

            CT.createSetButtons(menu, table) -- Refresh list
          end
        end)
      end

      b:Show()
      local text = table[i].setName or "Unknown"
      local time = CT.formatTimer(table[i].fightLength) or "0:00"
      b.title:SetJustifyH("LEFT")
      b.title:SetFormattedText("%s. %s%s|r (%s%s|r)", i, "|cFFFFFF00", text, "|cFF00CCFF", time)

      local stringWidth = b.title:GetWidth()
      if stringWidth > widestButton then
        widestButton = stringWidth
      end

      b:SetSize(width - 5, 20)
      b:SetPoint("TOP", menu, 0, y)
      y = y - 20

      height = height + 20
    elseif b then
      b:Hide()
    end
  end

  menu:SetWidth(widestButton + 20)
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

local function basicSetData(set, db)
  CT.graphList = CT.graphList and wipe(CT.graphList) or {}

  db.activity = db.activity or {}
  db.spells = db.spells or {}
  db.auras = db.auras or {}
  db.stance = db.stance or {}

  db.healing = db.healing or {}
  db.healingTaken = db.healingTaken or {}
  db.damage = db.damage or {}
  db.damageTaken = db.damageTaken or {}
  db.petDamage = db.petDamage or {}

  db.units = db.units or {}
  db.targets = db.targets or {}
  db.target = db.target or {}
  db.focus = db.focus or {}

  set.power = {}
  set.bossID = {}

  set.power = {}
  set.playerName = GetUnitName("player", false)
  set.petName = GetUnitName("pet", false)
  set.prevTarget = "None"
  set.prevFocus = "None"

  CT.settings.spellCooldownThrottle = 0.0085
end

local function basicPowerData(set, db)
  for i = 0, #CT.powerTypes do
    local maxPower = UnitPowerMax("player", i)

    if maxPower > 0 then
      local powerName = CT.powerTypesFormatted[i]
      set.power[powerName] = {}
      local power = set.power[powerName]

      set.power[#set.power + 1] = power -- Indexed reference
      set.power[i] = power -- Reference by power number

      power.index = i
      power.name = powerName
      power.maxPower = maxPower
      power.currentPower = UnitPower("player", i)

      power.accuratePower = power.currentPower
      power.total = 0
      power.wasted = 0
      power.effective = 0
      power.skip = true

      power.spells = {}
      power.spellCosts = {}
      power.spellList = {}
      power.spellList.numAdded = 0
      power.costFrames = {}

      do -- Get power text color
        if powerName == "Mana" then
          power.tColor = "|cFF0000FF"
        elseif powerName == "Rage" then
          power.tColor = "|cFFFF0000"
        elseif powerName == "Focus" then
          power.tColor = "|cFFFF8040"
        elseif powerName == "Energy" then
          power.tColor = "|cFFFFFF00"
        elseif powerName == "Combo Points" then
          power.tColor = "|cFFFFFFFF"
        elseif powerName == "Chi" then
          power.tColor = "|cFFB5FFEB"
        elseif powerName == "Runes" then
          power.tColor = "|cFF808080"
        elseif powerName == "Runic Power" then
          power.tColor = "|cFF00D1FF"
        elseif powerName == "Soul Shards" then
          power.tColor = "|cFF80528C"
        elseif powerName == "Eclipse" then
          power.tColor = "|cFF4D85E6"
        elseif powerName == "Holy Power" then
          power.tColor = "|cFFF2E699"
        elseif powerName == "Demonic Fury" then
          power.tColor = "|cFF80528C"
        elseif powerName == "Burning Embers" then
          power.tColor = "|cFFBF6B02"
        else
          print("No text color found for " .. powerName .. ".")
        end
      end

      CT.graphList[#CT.graphList + 1] = CT.powerTypesFormatted[i]
    end
  end
end

local function basicGraphData(set, db, role)
  CT.graphList[#CT.graphList + 1] = "Healing"
  CT.graphList[#CT.graphList + 1] = "Damage"
  CT.graphList[#CT.graphList + 1] = "Damage Taken"

  if GetUnitName("pet", false) then
    CT.graphList[#CT.graphList + 1] = "Total Damage"
    CT.graphList[#CT.graphList + 1] = "Pet Damage"
  end

  set.graphs = {}
  db.graphs = db.graphs or {}

  set.graphs.updateDelay = 0.2
  set.graphs.lastUpdate = 0
  set.graphs.splitAmount = 500

  for index, name in ipairs(CT.graphList) do
    set.graphs[name] = {}
    local setGraph = set.graphs[name]

    db.graphs[name] = db.graphs[name] or {}
    local dbGraph = db.graphs[name]

    dbGraph.__index = dbGraph
    setmetatable(setGraph, dbGraph)

    dbGraph.data = dbGraph.data or {}
    dbGraph.XMin = dbGraph.XMin or 0
    dbGraph.XMax = dbGraph.XMax or 10
    dbGraph.YMin = dbGraph.YMin or -5
    dbGraph.YMax = dbGraph.YMax or 105
    dbGraph.shown = dbGraph.shown or false

    setGraph.lines = {}
    setGraph.name = name
    setGraph.splitCount = 1
    setGraph.startX = 10
    setGraph.startY = dbGraph.YMax
    setGraph.toggle = CT.toggleNormalGraph
    setGraph.refresh = CT.refreshNormalGraph
    setGraph.update, setGraph.color = CT.getGraphUpdateFunc(setGraph, set, db, name)
  end
end

local function basicUptimeGraphData(set, db)
  set.uptimeGraphs = {}
  set.uptimeGraphs.cooldowns = {}
  set.uptimeGraphs.buffs = {}
  set.uptimeGraphs.debuffs = {}
  set.uptimeGraphs.misc = {}

  db.uptimeGraphs = db.uptimeGraphs or {}
  db.uptimeGraphs.cooldowns = db.uptimeGraphs.cooldowns or {}
  db.uptimeGraphs.buffs = db.uptimeGraphs.buffs or {}
  db.uptimeGraphs.debuffs = db.uptimeGraphs.debuffs or {}
  db.uptimeGraphs.misc = db.uptimeGraphs.misc or {}

  function set.addCooldown(spellID, spellName, color)
    print("Adding cooldown graph:", spellName)
    local setGraph = set.uptimeGraphs.cooldowns[spellID]
    local dbGraph = db.uptimeGraphs.cooldowns[spellID]

    if not setGraph then
      set.uptimeGraphs.cooldowns[spellID] = {}
      setGraph = set.uptimeGraphs.cooldowns[spellID]
    end

    if not dbGraph then
      db.uptimeGraphs.cooldowns[spellID] = {}
      dbGraph = db.uptimeGraphs.cooldowns[spellID]
    end

    dbGraph.__index = dbGraph
    setmetatable(setGraph, dbGraph)

    dbGraph.data = dbGraph.data or {[1] = 0}
    dbGraph.XMin = dbGraph.XMin or 0
    dbGraph.XMax = dbGraph.XMax or 10
    dbGraph.YMin = dbGraph.YMin or 0
    dbGraph.YMax = dbGraph.YMax or 10
    dbGraph.shown = dbGraph.shown or false

    setGraph.lines = {}
    setGraph.name = spellName
    setGraph.spellID = spellID
    setGraph.category = "cooldowns"
    setGraph.toggle = CT.toggleUptimeGraph
    setGraph.refresh = CT.refreshUptimeGraph
    setGraph.color = color or CT.colors.yellow
    setGraph.endNum = 1
    setGraph.startX = 10
    setGraph.frame = CT.graphFrame

    setGraph:toggle("show")
    setGraph:refresh(true)

    return setGraph, dbGraph
  end

  function set.addAura(spellID, spellName, type, count, color)
    print("Adding aura graph:", spellName)

    local setGraph = set.uptimeGraphs[type][spellID]
    local dbGraph = db.uptimeGraphs[type][spellID]

    if not setGraph then
      set.uptimeGraphs[type][spellID] = {}
      setGraph = set.uptimeGraphs[type][spellID]
    end

    if not dbGraph then
      db.uptimeGraphs[type][spellID] = {}
      dbGraph = db.uptimeGraphs[type][spellID]
    end

    dbGraph.__index = dbGraph
    setmetatable(setGraph, dbGraph)

    setGraph.name = spellName
    setGraph.spellID = spellID
    setGraph.frame = CT.uptimeGraphFrame
    setGraph.toggle = CT.toggleUptimeGraph

    setGraph.addNewLine = function(GUID, unitName)
      if not setGraph[GUID] then
        local num = #setGraph + 1

        print("Adding new line for", unitName .. ".")

        if not setGraph[num] then setGraph[num] = {
            ["lines"] = {},
            ["endNum"] = 1,
            ["startX"] = 10,
            ["color"] = color or CT.colors.blue,
            ["refresh"] = CT.refreshUptimeGraph,
            ["spellID"] = spellID,
            ["category"] = type,
            ["GUID"] = GUID,
          }
        end

        if not dbGraph[num] then dbGraph[num] = {
            ["data"] = {[1] = 0},
            ["shown"] = false,
            ["XMin"] = 0,
            ["XMax"] = 10,
            ["YMin"] = 0,
            ["YMax"] = 10,
            ["Y"] = num * -10,
            ["unitName"] = unitName,
          }
        end

        dbGraph[num].__index = dbGraph[num]
        setmetatable(setGraph[num], dbGraph[num])

        setGraph[GUID] = setGraph[num]
      end
    end

    setGraph:toggle("show")
    -- setGraph:refresh(true)

    return setGraph, dbGraph
  end

  -- local setGraph, dbGraph = set.addCooldown(20473, "Holy Shock", CT.colors.yellow)
end

function CT.buildNewSet()
  local set, db = CT.current, CT.currentDB

  if CT.graphFrame then CT.graphFrame:hideAllGraphs() end

  do -- Create the set table
    local _, specName, description, specIcon, background, role, primaryStat = GetSpecializationInfo(GetSpecialization())

    saveDataSet(db)

    -- wipeSVars = true
    if wipeSVars then
      CT:Print("Wiping all saved data sets.")
      CombatTrackerCharDB[specName].sets = {}
    end

    set = {}

    CombatTrackerCharDB[specName].sets.currentDB = {}
    db = CombatTrackerCharDB[specName].sets.currentDB

    db.__index = db
    setmetatable(set, db)

    db.setName = nameCurrentSet(set)
    db.start = GetTime()
    set.role = role

    CT.updateLocalData(set, db)
  end

  basicSetData(set, db)
  basicPowerData(set, db)
  basicGraphData(set, db)
  basicUptimeGraphData(set, db)

  CT.current = set
  CT.currentDB = db

  if not CT.displayed then -- No display, so default to this current set
    CT.displayed = set
    CT.displayedDB = db
  end

  CT.displayed = set -- NOTE: Testing only
  CT.displayedDB = db -- NOTE: Testing only

  return set, db
end

function CT.loadSavedSet(db)
  if not db then CT:Print("Tried to load a set without passing the DB table!") return end

  if CT.graphFrame then CT.graphFrame:hideAllGraphs() end

  local _, specName, description, specIcon, background, role, primaryStat = GetSpecializationInfo(GetSpecialization())

  local set = {}

  db.__index = db
  setmetatable(set, db)

  set.role = role

  basicSetData(set, db)
  basicPowerData(set, db)
  basicGraphData(set, db)
  basicUptimeGraphData(set, db)

  CT.displayed = set
  CT.displayedDB = db

  CT.loadDefaultGraphs()

  return set, db
end
