if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
local buttonClickNum = 7
local debug = CT.debug

local function saveDataSet(db) -- TODO: Save player's ilevel with the set, and make option to only save bosses
  if db then -- Save current DB
    -- debug("Saving data set:", db.setName .. ".")
    if not db.stop then
      db.stop = GetTime()
    end

    local _, specName = GetSpecializationInfo(GetSpecialization())
    tinsert(CombatTrackerCharDB[specName].sets, 1, db)
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
  -- if CT.tracking then return debug("Already tracking! Message:", message) end
  if CT.tracking then return end
  debug(message or "Starting tracking, but no start message was sent.")

  local set, db = CT.buildNewSet()

  if db.stop then
    debug("db.stop exists in start tracking.")
    db.stop = nil
  end

  CT.tracking = true
  CT.inCombat = true

  CT.iterateAuras()
  CT.iterateCooldowns()

  CT.loadActiveSet()

  -- CT:toggleUptimeGraph("clear")
end

function CT.stopTracking()
  debug("Stopping tracking.")

  CT.currentDB.stop = GetTime()
  saveDataSet(CT.currentDB)

  CT.currentDB = nil
  CT.current = nil

  CT.inCombat = false
  CT.tracking = false

  CT.finalizeGraphLength()
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

local function findSetIcon(set)
  -- local thisName = self:GetName()
  -- local texture = _G["PlayerPortrait"]:GetTexture()
  --
  -- set.icon = texture

  -- debug("Texture:", texture)
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
  set.playerGUID = UnitGUID("player")
  set.petGUID = UnitGUID("pet")
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

      power.tColor = CT.getPowerColor(powerName)

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

  for index = 1, #CT.graphList do
    local name = CT.graphList[index]

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

    if CT.settings.graphFilling then
      setGraph.fill = true
      setGraph.bars = {}
      setGraph.triangles = {}
    end
    
    setGraph.update, setGraph.color = CT.getGraphUpdateFunc(setGraph, set, db, name) -- Make sure this happens last, because I can set things for specific graphs here
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
    local setGraph = set.uptimeGraphs.cooldowns[spellID]
    local dbGraph = db.uptimeGraphs.cooldowns[spellID]

    if not setGraph then
      set.uptimeGraphs.cooldowns[spellID] = {}
      setGraph = set.uptimeGraphs.cooldowns[spellID]
      tinsert(set.uptimeGraphs.cooldowns, set.uptimeGraphs.cooldowns[spellID]) -- Indexed access
    end

    if not dbGraph then
      db.uptimeGraphs.cooldowns[spellID] = {}
      dbGraph = db.uptimeGraphs.cooldowns[spellID]
      dbGraph.shown = false
      dbGraph.name = spellName
      dbGraph.flags = {}
    end

    dbGraph.__index = dbGraph
    setmetatable(setGraph, dbGraph)

    setGraph.spellID = spellID
    setGraph.toggle = CT.toggleUptimeGraph
    setGraph.refresh = CT.refreshUptimeGraph

    setGraph.addNewLine = function(GUID, unitName)
      local GUID = GUID or set.playerGUID
      local unitName = unitName or set.playerName

      if not setGraph[GUID] then
        local num = #setGraph + 1

        setGraph[num] = {
            ["lines"] = {},
            ["endNum"] = 1,
            ["startX"] = 10,
            ["color"] = color or CT.colors.yellow,
            ["spellID"] = spellID,
            ["category"] = "cooldowns",
            ["GUID"] = GUID,
          }

        if not dbGraph[num] then dbGraph[num] = {
            ["data"] = {[1] = 0},
            ["XMin"] = 0,
            ["XMax"] = 10,
            ["YMin"] = 0,
            ["YMax"] = 10,
            ["Y"] = (num - 1) * -10,
            ["unitName"] = unitName,
          }
        end

        dbGraph[num].__index = dbGraph[num]
        setmetatable(setGraph[num], dbGraph[num])

        setGraph[GUID] = setGraph[num]
      end

      -- if dbGraph.shown then
      --   setGraph:toggle("show")
      -- end
    end

    return setGraph, dbGraph
  end

  function set.addAura(spellID, spellName, type, count, color, flags)
    local setGraph = set.uptimeGraphs[type][spellID]
    local dbGraph = db.uptimeGraphs[type][spellID]

    if not setGraph then
      set.uptimeGraphs[type][spellID] = {}
      setGraph = set.uptimeGraphs[type][spellID]
      tinsert(set.uptimeGraphs[type], set.uptimeGraphs[type][spellID]) -- Indexed access
    end

    if not dbGraph then
      db.uptimeGraphs[type][spellID] = {}
      dbGraph = db.uptimeGraphs[type][spellID]
      dbGraph.shown = false
      dbGraph.name = spellName
      dbGraph.flags = {}
    end

    dbGraph.__index = dbGraph
    setmetatable(setGraph, dbGraph)

    if flags then
      for flagName, value in pairs(flags) do

        if not dbGraph.flags[flagName] then
          dbGraph.flags[flagName] = value or {}
        end
      end
    end

    setGraph.spellID = spellID
    setGraph.toggle = CT.toggleUptimeGraph
    setGraph.refresh = CT.refreshUptimeGraph

    setGraph.addNewLine = function(GUID, unitName)
      if not setGraph[GUID] then
        local num = #setGraph + 1

        setGraph[num] = {
            ["lines"] = {},
            ["endNum"] = 1,
            ["startX"] = 10,
            ["color"] = color or CT.colors.blue,
            ["spellID"] = spellID,
            ["category"] = type,
            ["GUID"] = GUID,
          }

        if not dbGraph[num] then dbGraph[num] = {
            ["data"] = {[1] = 0},
            ["XMin"] = 0,
            ["XMax"] = 10,
            ["YMin"] = 0,
            ["YMax"] = 10,
            ["Y"] = (num - 1) * -10,
            ["unitName"] = unitName,
          }
        end

        dbGraph[num].__index = dbGraph[num]
        setmetatable(setGraph[num], dbGraph[num])

        setGraph[GUID] = setGraph[num]
      end

      -- if dbGraph.shown then
      --   setGraph:toggle("show")
      -- end
    end

    return setGraph, dbGraph
  end

  function set.addMisc(graphName, color, flags)
    local setGraph = set.uptimeGraphs.misc[graphName]
    local dbGraph = db.uptimeGraphs.misc[graphName]

    if not setGraph then
      set.uptimeGraphs.misc[graphName] = {}
      setGraph = set.uptimeGraphs.misc[graphName]
      tinsert(set.uptimeGraphs.misc, set.uptimeGraphs.misc[graphName]) -- Indexed access
    end

    if not dbGraph then
      db.uptimeGraphs.misc[graphName] = {}
      dbGraph = db.uptimeGraphs.misc[graphName]
      dbGraph.shown = false
      dbGraph.name = graphName
      dbGraph.flags = {}
    end

    dbGraph.__index = dbGraph
    setmetatable(setGraph, dbGraph)

    setGraph.toggle = CT.toggleUptimeGraph
    setGraph.refresh = CT.refreshUptimeGraph

    if flags then
      for flagName, value in pairs(flags) do

        if not dbGraph.flags[flagName] then
          dbGraph.flags[flagName] = value or {}
        end
      end
    end

    setGraph.addNewLine = function(GUID, unitName)
      local GUID = GUID or set.playerGUID
      local unitName = unitName or set.playerName

      if not setGraph[GUID] then
        local num = #setGraph + 1

        setGraph[num] = {
            ["lines"] = {},
            ["endNum"] = 1,
            ["startX"] = 10,
            ["color"] = color or CT.colors.orange,
            ["spellID"] = spellID,
            ["category"] = "misc",
            ["GUID"] = GUID,
          }

        if not dbGraph[num] then dbGraph[num] = {
            ["data"] = {[1] = 0},
            ["XMin"] = 0,
            ["XMax"] = 10,
            ["YMin"] = 0,
            ["YMax"] = 10,
            ["Y"] = (num - 1) * -10,
            ["unitName"] = unitName,
          }
        end

        dbGraph[num].__index = dbGraph[num]
        setmetatable(setGraph[num], dbGraph[num])

        setGraph[GUID] = setGraph[num]
      end
    end

    return setGraph, dbGraph
  end
end

local function registerDefaultGraphs(set, db) -- TODO: Pet uptime, stances, etc
  local GUID = set.playerGUID
  local playerName = set.playerName

  do -- Activity uptime
    local setGraph = set.uptimeGraphs.misc["Activity"]

    if not setGraph then
      local flags = {
        ["spellName"] = false,
        ["color"] = false,
      }
      setGraph = set.addMisc("Activity", CT.colors.orange, flags)

      setGraph.addNewLine(GUID, playerName)
    end
  end
end

function CT.buildNewSet()
  local set, db = CT.current, CT.currentDB

  if CT.graphFrame then CT.graphFrame:hideAllGraphs() end

  do -- Create the set table
    local _, specName, description, specIcon, background, role, primaryStat = GetSpecializationInfo(GetSpecialization())

    saveDataSet(db)

    set = {}

    CombatTrackerCharDB[specName].sets.currentDB = {}
    db = CombatTrackerCharDB[specName].sets.currentDB

    db.__index = db
    setmetatable(set, db)

    db.setName = nameCurrentSet(set)
    db.icon = findSetIcon(set)
    db.start = GetTime()
    set.role = role

    CT.updateLocalData(set, db)
  end

  basicSetData(set, db)
  basicPowerData(set, db)
  basicGraphData(set, db)
  basicUptimeGraphData(set, db)
  registerDefaultGraphs(set, db)

  CT.current = set
  CT.currentDB = db

  if not CT.displayed then -- No display, so default to this current set
    CT.displayed = set
    CT.displayedDB = db
  end

  CT.loadDefaultGraphs()
  CT.loadDefaultUptimeGraph()

  if CT.base and CT.base.expander then -- If base is loaded, set the name right away, otherwise it'll get set when expander is shown
    CT.base.expander.titleData.rightText1:SetText(db.setName)
  end

  return set, db
end

function CT.loadSavedSet(db)
  local _, specName, description, specIcon, background, role, primaryStat = GetSpecializationInfo(GetSpecialization())
  
  if not specName then return debug("Called loadSavedSet before player data (spec name) was available") end

  if not db then -- If a db table wasn't passed, load the most recent
    if specName and CombatTrackerCharDB[specName] and CombatTrackerCharDB[specName].sets then
      if CombatTrackerCharDB[specName].sets[1] then
        if CombatTrackerCharDB[specName].sets[1].start and CombatTrackerCharDB[specName].sets[1].stop then -- Make sure they are safe
          db = CombatTrackerCharDB[specName].sets[1]
        else
          return debug("Couldn't load set 1, because it doesn't have a start and/or stop. Returning.")
        end
      else
        return debug("Couldn't load default set, because there is no set 1. Returning.")
      end
    end

    if not db then return debug("Didn't pass a DB table, and failed to find db[1] to load.") end
  end

  if CT.graphFrame then
    if CT.graphFrame[1] then
      for i = 1, #CT.graphFrame do -- If there are multiple frames, iterate through all of them
        local frame = CT.graphFrame[i]
        frame:hideAllGraphs()
      end
    else
      CT.graphFrame:hideAllGraphs()
    end
  end

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

  if db.uptimeGraphs then -- Generate all the uptime graphs
    for graphName, dbGraph in pairs(db.uptimeGraphs["cooldowns"]) do
      local name = dbGraph.name or GetSpellInfo(graphName) or graphName
      local setGraph = set.addCooldown(graphName, name, CT.colors.yellow)

      for i = 1, #dbGraph do
        local GUID = dbGraph[i].unitName .. random(1, 1000000) -- Just generate a random number to act as a pseudo GUID
        setGraph.addNewLine(GUID, dbGraph[i].unitName)
      end
    end

    for graphName, dbGraph in pairs(db.uptimeGraphs["buffs"]) do
      local name = dbGraph.name or GetSpellInfo(graphName) or graphName
      local setGraph = set.addAura(graphName, name, "buffs", dbGraph.count or 0, CT.colors.blue)

      for i = 1, #dbGraph do
        local GUID = dbGraph[i].unitName .. random(1, 1000000)
        setGraph.addNewLine(GUID, dbGraph[i].unitName)
      end
    end

    for graphName, dbGraph in pairs(db.uptimeGraphs["debuffs"]) do
      local name = dbGraph.name or GetSpellInfo(graphName) or graphName
      local setGraph = set.addAura(graphName, name, "debuffs", dbGraph.count or 0, CT.colors.blue)

      for i = 1, #dbGraph do
        local GUID = dbGraph[i].unitName .. random(1, 1000000)
        setGraph.addNewLine(GUID, dbGraph[i].unitName)
      end
    end

    for graphName, dbGraph in pairs(db.uptimeGraphs["misc"]) do
      local name = dbGraph.name or GetSpellInfo(graphName) or graphName
      local setGraph = set.addMisc(graphName, CT.colors.orange)

      for i = 1, #dbGraph do
        local GUID = dbGraph[i].unitName .. random(1, 1000000)
        setGraph.addNewLine(GUID, dbGraph[i].unitName)
      end
    end
  end

  if CT.graphFrame then
    CT.loadDefaultGraphs()
    CT.finalizeGraphLength("line")
  end

  if CT.uptimeGraphFrame then
    CT.loadDefaultUptimeGraph()
    CT.finalizeGraphLength("uptime")
  end

  return set, db
end

function CT.loadActiveSet()
  if not CT.current then return end

  CT.displayed = CT.current
  CT.displayedDB = CT.currentDB

  CT.loadDefaultGraphs()
  CT.loadDefaultUptimeGraph()

  debug("Loading active set.")

  CT.forceUpdate = true
end
