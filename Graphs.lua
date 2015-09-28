if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals, Frames, and Tables
--------------------------------------------------------------------------------
local CT = CombatTracker
local graphFunctions = {}

local round = CT.round
local formatTimer = CT.formatTimer
local colorText = CT.colorText
local colors = CT.colors

local SetTexCoord, SetPoint, SetTexture, SetVertexColor =
      SetTexCoord, SetPoint, SetTexture, SetVertexColor

local infinity = math.huge

local TAXIROUTE_LINEFACTOR = 128 / 126 -- Multiplying factor for texture coordinates
local TAXIROUTE_LINEFACTOR_2 = TAXIROUTE_LINEFACTOR / 2 -- Half of that

CT.uptimeCategories = {
  "cooldowns",
  "buffs",
  "debuffs",
  "misc",
}

--------------------------------------------------------------------------------
-- Graph Plot Functions
--------------------------------------------------------------------------------
function CT.graphUpdate(time, timer)
  if self.category == "Normal" then
    local value, refresh
    local name = self.name

    if name == "Mana" then
      value = (CT.current.power[1].accuratePower / CT.current.power[1].maxPower) * 100
    elseif name == "Focus" then
      value = (CT.current.power[1].accuratePower / CT.current.power[1].maxPower) * 100
    elseif name == "Energy" then
      value = (CT.current.power["Energy"].accuratePower / CT.current.power["Energy"].maxPower) * 100
    elseif name == "Demonic Fury" then
      value = (CT.current.power["Demonic Fury"].accuratePower / CT.current.power["Demonic Fury"].maxPower) * 100
    elseif name == "Burning Embers" then
      value = (CT.current.power["Burning Embers"].accuratePower)
    elseif name == "Soul Shards" then
      value = (CT.current.power["Soul Shards"].accuratePower)
    elseif name == "Combo Points" then
      if CT.current.auras[115189] then -- Anticipation (Rogue talent)
        value = (CT.current.power["Combo Points"].accuratePower) + (CT.current.auras[115189].currentStacks or 0)
      else
        value = (CT.current.power["Combo Points"].accuratePower)
      end
    elseif name == "Holy Power" then
      value = (CT.current.power[2].accuratePower / CT.current.power[2].maxPower) * 100
    elseif name == "Healing" then
      value = (CT.current.healing.total or 0) / timer
    elseif name == "Overhealing" then

    elseif name == "Total Damage" then
      value = ((CT.current.damage.total or 0) / timer) + ((CT.current.pet.damage.total or 0) / timer)
    elseif name == "Damage" then
      value = ((CT.current.damage.total or 0) / timer)
    elseif name == "Pet Damage" then
      value = ((CT.current.pet.damage.total or 0) / timer)
    elseif name == "Damage Taken" then
      value = ((CT.current.damageTaken.total or 0) / timer)
    elseif name == "Healing Taken" then

    elseif name == "Damage Done to" then

    elseif name == "Healing Done to" then

    else
      value = 0
      CT:Print("No graph update category for:", self.name)
    end

    if (value == infinity) or (value == -infinity) then value = 0 end

    local num = #self.data
    self.data[num + 1] = timer
    self.data[num + 2] = value

    if (num % graphs.splitAmount) == 0 then
      if not self.splitCount then CT:Print("Missing split count for:", self.name) end
      self.splitCount = self.splitCount + 1
    end

    if value >= self.YMax and CT.base.expander.shown then
      self.YMax = self.YMax + max(value - self.YMax, 5)
      refresh = true
    end

    if timer > self.XMax and CT.base.expander and CT.base.expander.shown and self.graphFrame and not self.graphFrame.zoomed then
      self.XMax = self.XMax + max(timer - self.XMax, self.startX * self.splitCount)
      refresh = true
    end

    self.needsRefresh = refresh
  end
end

function CT.mainUpdate.graphUpdate(time, timer)
  local graphs = CT.current.graphs

  for i = 1, #graphs do
    local self = graphs[i]

    if not self.ignore then
      if self.category == "Normal" then
        local value, refresh

        if self.name == "Mana" then
          value = (CT.current.power[1].accuratePower / CT.current.power[1].maxPower) * 100
        elseif self.name == "Focus" then
          value = (CT.current.power[1].accuratePower / CT.current.power[1].maxPower) * 100
        elseif self.name == "Energy" then
          value = (CT.current.power["Energy"].accuratePower / CT.current.power["Energy"].maxPower) * 100
        elseif self.name == "Demonic Fury" then
          value = (CT.current.power["Demonic Fury"].accuratePower / CT.current.power["Demonic Fury"].maxPower) * 100
        elseif self.name == "Burning Embers" then
          value = (CT.current.power["Burning Embers"].accuratePower)
        elseif self.name == "Soul Shards" then
          value = (CT.current.power["Soul Shards"].accuratePower)
        elseif self.name == "Combo Points" then
          if CT.current.auras[115189] then -- Anticipation (Rogue talent)
            value = (CT.current.power["Combo Points"].accuratePower) + (CT.current.auras[115189].currentStacks or 0)
          else
            value = (CT.current.power["Combo Points"].accuratePower)
          end
        elseif self.name == "Holy Power" then
          value = (CT.current.power[2].accuratePower / CT.current.power[2].maxPower) * 100
        elseif self.name == "Healing" then
          value = (CT.current.healing.total or 0) / timer
        elseif self.name == "Overhealing" then

        elseif self.name == "Total Damage" then
          value = ((CT.current.damage.total or 0) / timer) + ((CT.current.pet.damage.total or 0) / timer)
        elseif self.name == "Damage" then
          value = ((CT.current.damage.total or 0) / timer)
        elseif self.name == "Pet Damage" then
          value = ((CT.current.pet.damage.total or 0) / timer)
        elseif self.name == "Damage Taken" then
          value = ((CT.current.damageTaken.total or 0) / timer)
        elseif self.name == "Healing Taken" then

        elseif self.name == "Damage Done to" then

        elseif self.name == "Healing Done to" then

        else
          value = 0
          CT:Print("No graph update category for:", self.name)
        end

        if (value == infinity) or (value == -infinity) then value = 0 end

        local num = #self.data
        self.data[num + 1] = timer
        self.data[num + 2] = value

        if (num % graphs.splitAmount) == 0 then
          if not self.splitCount then CT:Print("Missing split count for:", self.name) end
          self.splitCount = self.splitCount + 1
        end

        if value >= self.YMax and CT.base.expander.shown then
          self.YMax = self.YMax + max(value - self.YMax, 5)
          refresh = true
        end

        if timer > self.XMax and CT.base.expander and CT.base.expander.shown and self.graphFrame and not self.graphFrame.zoomed then
          self.XMax = self.XMax + max(timer - self.XMax, self.startX * self.splitCount)
          refresh = true
        end

        self.needsRefresh = refresh
      end
    end
  end
end

-- TODO: Make activity line be a different color if the spell was broken early
function CT.mainUpdate.uptimeGraphsUpdate(time, timer)
  -- Graph of debuff/buff uptime
  -- - Maybe one line for each target?
  -- Graph of when stats are increased? Maybe one of each for mastery, haste, etc
  -- - Might be useful to use as a hidden line
  -- Store the damage/healing of each cast so that it can be displayed on the mouseover
  -- - For example, Holy Shock: 7,650 healing, 2,280 overhealing

  local uptimeGraphs = CT.current.uptimeGraphs

  for categoryName, category in pairs(uptimeGraphs) do
    for graphName, self in pairs(category) do
      if timer > self.XMax then
        local dbGraph = getmetatable(self)

        if dbGraph then
          dbGraph.XMax = self.XMax + max(timer - self.XMax, self.startX)
        else
          print("No dbGraph for", self.name .. "!")
        end

        if self.frame then
          self:refresh(true)
        end
      end

      if self.frame and self.lastLine then
        local width = self.frame.bg:GetWidth() * (timer - self.data[#self.data]) / self.XMax
        if width < 1 then width = 1 end

        self.lastLine:SetWidth(width)
      end
    end
  end
end
--------------------------------------------------------------------------------
-- General Graph Functions
--------------------------------------------------------------------------------
function CT.addLineGraph(name, valueTable, color, YMin, YMax)
  local graphs = CT.current.graphs

  if not graphs[name] then -- Create the graph in the current set
    graphs[name] = {}
    graphs[#graphs + 1] = graphs[name]
  end

  local t = graphs[name]

  if t.shown then
    for k, v in pairs(CT.graphLines[name]) do
      v:Hide()
    end
  end

  t.data = {}

  t.refresh = CT.refreshNormalGraph
  t.name = name
  t.category = "Normal"
  t.group = "r1"
  t.valueFormat = valueTable
  t.color = color

  t.XMin = 0
  t.XMax = 10
  t.YMin = YMin or -5
  t.YMax = YMax or 105
  t.startX = 10
  t.startY = YMax or t.YMax
  t.endNum = 4
  t.splitCount = 0

  if CT.graphLines[t.name] then -- This should mean the graph was previously created in another set
    for num, line in pairs(CT.graphLines[t.name]) do
      line:Hide()
    end

    wipe(CT.graphLines[t.name])
  else
    CT.graphLines[t.name] = {} -- Create a table that isn't tied to the current set to hold the lines
  end
end

function CT.addAuraGraph(spellID, spellName, auraType, count, color)
  if true then print("Blocking add aura graph. Name:", spellName .. ".", "Type:", auraType .. ".") return end
  if not CT.current then return end
  local uptimeGraphs = CT.current.uptimeGraphs

  if auraType == "Buff" then
    if not uptimeGraphs.buffs[spellID] then
      uptimeGraphs.buffs[spellID] = {}
      uptimeGraphs.buffs[#uptimeGraphs.buffs + 1] = uptimeGraphs.buffs[spellID]
    end
  elseif auraType == "Debuff" then
    if not uptimeGraphs.debuffs[spellID] then
      uptimeGraphs.debuffs[spellID] = {}
      uptimeGraphs.debuffs[#uptimeGraphs.debuffs + 1] = uptimeGraphs.debuffs[spellID]
    end
  end

  local t = uptimeGraphs.buffs[spellID] or uptimeGraphs.debuffs[spellID]

  if t.shown then
    if uptimeGraphs.shownList then
      uptimeGraphs.shownList[#uptimeGraphs.shownList + 1] = t
    else
      uptimeGraphs.shownList = {t}
    end

    CT.toggleUptimeGraph(t)
  end

  if t.data then wipe(t.data) else t.data = {} end
  -- if t.lines then wipe(t.lines) else t.lines = {} end
  if t.unitName then wipe(t.unitName) else t.unitName = {} end
  if t.targets then wipe(t.targets) else t.targets = {} end
  if t.targetData then wipe(t.targetData) else t.targetData = {} end

  t.data[1] = 0
  t.refresh = CT.refreshUptimeGraph
  t.spellID = spellID
  t.name = spellName
  t.category = auraType
  t.group = auraType
  t.color = color or colors.blue
  t.startX = 10
  t.XMin = 0
  t.XMax = 10
  t.YMin = 0
  t.YMax = 10
  t.endNum = 1

  CT.uptimeGraphLines[t.category][t.name] = {}

  if count and count > 0 then
    if t.stacks then wipe(t.stacks) else t.stacks = {} end
  end

  if CT.base.expander and CT.base.expander.uptimeGraphButton.popup and CT.base.expander.uptimeGraphButton.popup:IsShown() then
    addUptimeGraphDropDownButtons(CT.base.expander.uptimeGraphButton.popup)
  end
end

function CT.addCooldownGraph(spellID, spellName, color)
  if true then print("Blocking add cooldown graph. Name:", spellName .. ".") return end
  if not CT.current then return end
  local uptimeGraphs = CT.current.uptimeGraphs

  if not uptimeGraphs.cooldowns[spellID] then
    uptimeGraphs.cooldowns[spellID] = {}
    uptimeGraphs.cooldowns[#uptimeGraphs.cooldowns + 1] = uptimeGraphs.cooldowns[spellID] -- Create indexed reference
  end

  local t = uptimeGraphs.cooldowns[spellID]

  if t.shown then
    if uptimeGraphs.shownList then
      uptimeGraphs.shownList[#uptimeGraphs.shownList + 1] = t
    else
      uptimeGraphs.shownList = {t}
    end

    CT.toggleUptimeGraph(t)
  end

  if t.data then wipe(t.data) else t.data = {} end
  -- if t.lines then wipe(t.lines) else t.lines = {} end

  t.data[1] = 0
  t.refresh = CT.refreshUptimeGraph
  t.spellID = spellID
  t.name = spellName
  t.category = "Cooldown"
  t.group = "CD"
  t.color = color or colors.yellow
  t.startX = 10
  t.XMin = 0
  t.XMax = 10
  t.YMin = 0
  t.YMax = 10
  t.endNum = 1

  CT.uptimeGraphLines["Cooldown"][spellName] = {}

  if CT.base.expander and CT.base.expander.uptimeGraphButton.popup and CT.base.expander.uptimeGraphButton.popup:IsShown() then
    addUptimeGraphDropDownButtons(CT.base.expander.uptimeGraphButton.popup)
  end
end

local function createGraphTooltip()
  if not CT.graphTooltip then
    CT.graphTooltip = CreateFrame("GameTooltip", "CT.graphTooltip", CT.base, "GameTooltipTemplate")
    local tip = CT.graphTooltip
    tip:SetSize(40, 40)
    tip:SetOwner(CT.base, "ANCHOR_CURSOR", 0, 0)
    tip:SetAnchorType("ANCHOR_CURSOR", 0, 0)

    local backdrop = {
      bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 8,
      -- insets = {left = 11, right = 12, top = 12, bottom = 11}
    }

    tip:SetBackdrop(backdrop)
    tip:SetBackdropColor(0.1, 0.1, 0.1, 1.0)
    tip:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.4)
  end
end

local function nearestValue(table, number)
  local smallestSoFar, smallestIndex
  for k, v in pairs(table) do
    if not smallestSoFar or (math.abs(number - v:GetCenter()) < smallestSoFar) then
      smallestSoFar = math.abs(number - v:GetCenter())
      smallestIndex = k
    end
  end
  return smallestIndex, table[smallestIndex]
end

function CT.finalizeGraphLength()
  if true then print("Blocking finalize graph length function.") return end
  if not CT.tracking then return end

  local graphs = CT.current.graphs
  local uptimeGraphs = CT.current.uptimeGraphs
  local timer = (CT.combatStop or GetTime()) - CT.combatStart

  for i = 1, #graphs do -- Finalize line graphs
    local self = graphs[i]

    if CT.combatStop then
      self.XMax = timer
    end

    if self.graphFrame and CT.base.expander.shown then
      self:refresh(true)
    end
  end

  for i, v in ipairs(uptimeGraphs.categories) do -- Finalize uptime graphs
    for i = 1, #v do
      local self = v[i]

      if CT.combatStop then
        self.XMax = timer
      end

      if self.graphFrame and CT.base.expander.shown then
        self:refresh(true)
      end

      if self.graphFrame and (#self.lines % 2) == 0 then
        self.ignore = true
        local width = self.graphFrame:GetWidth() * (timer - self.data[#self.data]) / self.XMax
        if width < 1 then width = 1 end

        self.lines[#self.lines]:SetWidth(width)
      end
    end
  end
end

local function handleGraphData(set, db, graph, data, name, timer, value)
  if (value == infinity) or (value == -infinity) then value = 0 end

  local num = #data + 1
  data[num] = timer -- X coords
  data[-num] = value -- Y coords

  local refresh

  if (num % set.graphs.splitAmount) == 0 then
    graph.splitCount = graph.splitCount + 1
  end

  if value >= graph.YMax and CT.base.expander.shown then
    db.graphs[name].YMax = graph.YMax + max(value - graph.YMax, 5)
    refresh = true
  end

  if timer > graph.XMax and CT.base.expander and CT.base.expander.shown and graph.frame and not graph.frame.zoomed then
    db.graphs[name].XMax = graph.XMax + max(timer - graph.XMax, graph.startX * graph.splitCount)
    refresh = true
  end

  if graph.shown then
    graph:refresh(refresh)
  end
end

function CT.getGraphUpdateFunc(graph, set, db, name)
  if name == "Healing" then
    local function func(graph, timer)
      local value = (set.healing.total or 0) / timer
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.green
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Damage" then
    local function func(graph, timer)
      local value = ((set.damage.total or 0) / timer)
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.orange
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Damage Taken" then
    local function func(graph, timer)
      local value = ((set.damageTaken.total or 0) / timer)
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.red
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Total Damage" then
    local function func(graph, timer)
      local value = ((set.damage.total or 0) / timer) + ((set.pet.damage.total or 0) / timer)
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.orange
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Pet Damage" then
    local function func(graph, timer)
      local value = ((set.pet.damage.total or 0) / timer)
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.lightgrey
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Mana" then
    local function func(graph, timer)
      local value = ((set.power[name].accuratePower or 0) / (set.power[name].maxPower or 0)) * 100

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.mana
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Focus" then
    local function func(graph, timer)
      local value = (set.power[name].accuratePower / set.power[name].maxPower) * 100
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.focus
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Rage" then -- TODO: Set up
    local function func(graph, timer)

    end

    local color = CT.colors.rage
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Demonic Fury" then
    local function func(graph, timer)
      local value = (set.power[name].accuratePower / set.power[name].maxPower) * 100
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.demonicFury
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Energy" then
    local function func(graph, timer)
      local value = (set.power[name].accuratePower / set.power[name].maxPower) * 100
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.energy
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Runic Power" then -- TODO: Set up
    local function func(graph, timer)

    end

    local color = CT.colors.runicPower
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Holy Power" then
    local function func(graph, timer)
      local value = ((set.power[2].accuratePower or 0) / (set.power[2].maxPower or 0)) * 100
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.holyPower
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Shadow Orbs" then -- TODO: Set up
    local function func(graph, timer)

    end

    local color = CT.colors.shadowOrbs
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Combo Points" then
    local function func(graph, timer)
      local value

      if set.auras[115189] then -- Anticipation (Rogue talent)
        value = (set.power[name].accuratePower) + (set.auras[115189].currentStacks or 0)
      else
        value = (set.power[name].accuratePower)
      end

      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.comboPoints
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Chi" then
    local function func(graph, timer)
      local value = (set.power[name].accuratePower)
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.chi
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Soul Shards" then
    local function func(graph, timer)
      local value = (set.power[name].accuratePower)
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.soulShards
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  elseif name == "Burning Embers" then
    local function func(graph, timer)
      local value = (set.power[name].accuratePower)
      if (value == infinity) or (value == -infinity) then value = 0 end

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.burningEmbers
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      "\n",
      colorString,
      name,
      "|r ",
      "",
      "%",
    }

    return func, color
  end
end
--------------------------------------------------------------------------------
-- Uptime Graphs
--------------------------------------------------------------------------------
local function createUptimeGraphName(graphFrame, name)
  if graphFrame and not graphFrame.nameBox then
    graphFrame.nameBox = graphFrame:CreateTexture(nil, "ARTWORK")
    graphFrame.nameBox:SetTexture(0.1, 0.1, 0.1, 1.0)
    graphFrame.nameBox:SetWidth(80)

    graphFrame.name = graphFrame:CreateFontString(nil, "OVERLAY")
    graphFrame.name:SetPoint("TOPLEFT", graphFrame.nameBox, 0, 0)
    graphFrame.name:SetPoint("BOTTOMRIGHT", graphFrame.nameBox, 0, 0)
    graphFrame.name:SetFont("Fonts\\FRIZQT__.TTF", 10)
    graphFrame.name:SetJustifyH("LEFT")
    graphFrame.name:SetTextColor(1, 1, 1, 1)
  end

  graphFrame.name:SetText(name)
  graphFrame.nameBox.width = graphFrame.name:GetStringWidth()
end

local function setUptimeGraphNameWidth()
  local maxWidth = 0

  for i = 1, #CT.base.expander.uptimeGraph do
    local graphFrame = CT.base.expander.uptimeGraph[i]

    if graphFrame.nameBox and graphFrame.nameBox.width > maxWidth then
      maxWidth = graphFrame.nameBox.width
    end
  end

  for i = 1, #CT.base.expander.uptimeGraph do
    local graphFrame = CT.base.expander.uptimeGraph[i]

    if graphFrame.nameBox then
      local borderWidth = graphFrame.border[3]:GetWidth()
      graphFrame.nameBox:Show()
      graphFrame.name:Show()
      graphFrame.nameBox:SetWidth(maxWidth)
      graphFrame.nameBox:SetPoint("TOPLEFT", graphFrame.bg, -maxWidth, -borderWidth)
      graphFrame.nameBox:SetPoint("BOTTOMLEFT", graphFrame.bg, -maxWidth, borderWidth)
      graphFrame.bg:SetPoint("LEFT", graphFrame.anchorFrame, maxWidth + borderWidth, 0)
    end
  end
end

-- function CT.toggleUptimeGraph(self, refresh)
--   local uptimeGraphs = CT.current.uptimeGraphs
--
--   for index, v in ipairs(uptimeGraphs.categories) do
--     for i = 1, #v do
--       v[i].shown = false
--
--       if v[i] ~= self then
--         if v[i].checkButton then
--           v[i].checkButton:SetChecked(false)
--         end
--       end
--     end
--   end
--
--   if CT.base.expander.uptimeGraph then -- Run through all uptime graphs and hide them
--     local stopFunc
--
--     for i = 1, #CT.base.expander.uptimeGraph do
--       local graphFrame = CT.base.expander.uptimeGraph[i]
--       local graph = graphFrame.graph
--
--       if graphFrame.nameBox then
--         graphFrame.nameBox:Hide()
--         graphFrame.name:Hide()
--         graphFrame.bg:SetPoint("LEFT", graphFrame.anchorFrame, 0, 0)
--       end
--
--       if graph then
--         local lineTable = CT.uptimeGraphLines[graph.category][graph.name]
--         for k, v in pairs(lineTable) do
--           v:Hide()
--         end
--
--         if i > 1 then
--           CT.base.expander.uptimeGraphBG.height = CT.base.expander.uptimeGraphBG.height - graphFrame:GetHeight()
--           graphFrame:Hide()
--         end
--
--         -- If an already shown graph was clicked,
--         -- return it so that it doesn't add it back in
--         if not refresh and (self == graph) then
--           stopFunc = true
--         elseif not refresh and self.targetData and (self.targetData[i] == graph) then
--           stopFunc = true
--         end
--
--         graph.graphFrame = nil
--         graphFrame.graph = nil
--       end
--     end
--
--     CT.base.expander.uptimeGraph.titleText:SetText(CT.base.expander.uptimeGraph.titleText.default)
--
--     if stopFunc then
--       if self.checkButton then
--         self.checkButton:SetChecked(false)
--       end
--
--       CT.base.expander.uptimeGraphBG:SetHeight(CT.base.expander.uptimeGraphBG.height)
--
--       return
--     end
--   end
--
--   self.shown = true
--
--   if self.shown and self.targetData and #self.targetData > 1 then -- If uptime graph has multiple lines
--     self.graphFrame = CT.base.expander.uptimeGraph
--
--     for i = 1, #self.targetData do
--       local graphFrame = CT.base.expander.uptimeGraph[i]
--       if not graphFrame then
--         graphFrame = CT.buildUptimeGraph(CT.base.expander, CT.base.expander.uptimeGraphBG)
--       end
--
--       if not graphFrame:IsShown() then
--         CT.base.expander.uptimeGraphBG.height = CT.base.expander.uptimeGraphBG.height + graphFrame:GetHeight()
--         graphFrame:Show()
--       end
--
--       createUptimeGraphName(graphFrame, self.targetData[i].name)
--
--       graphFrame.graph = self.targetData[i]
--       self.targetData[i].graphFrame = graphFrame
--
--       for k, v in pairs(self.targetData[i].lines) do
--         v:Show()
--       end
--     end
--
--     setUptimeGraphNameWidth()
--
--     do -- Text
--       if not self.string then
--         self.convertedColor = CT.convertColor(self.color[1], self.color[2], self.color[3])
--         self.string = self.convertedColor .. self.name .. "|r, "
--       end
--
--       local string = CT.base.expander.uptimeGraph.titleText.default .. self.convertedColor .. self.name
--       CT.base.expander.uptimeGraph.titleText:SetText(string)
--     end
--
--     self:refresh(true)
--   elseif self.shown then -- Single line uptime graph
--     self.graphFrame = CT.base.expander.uptimeGraph
--     CT.base.expander.uptimeGraph.graph = self
--     CT.base.expander.uptimeGraph:Show()
--
--     do -- Text
--       if not self.string then
--         self.convertedColor = CT.convertColor(self.color[1], self.color[2], self.color[3])
--         self.string = self.convertedColor .. self.name .. "|r, "
--       end
--
--       local string = CT.base.expander.uptimeGraph.titleText.default .. self.convertedColor .. self.name
--       CT.base.expander.uptimeGraph.titleText:SetText(string)
--     end
--
--     local lineTable = CT.uptimeGraphLines[self.category][self.name]
--     for k, v in pairs(lineTable) do
--       v:Show()
--     end
--
--     self:refresh(true)
--   end
--
--   CT.base.expander.uptimeGraphBG:SetHeight(CT.base.expander.uptimeGraphBG.height)
-- end

function CT:toggleUptimeGraph(command)
  if not CT.uptimeGraphFrame then CT:Print("Tried to toggle an uptime graph before uptime graph frame was loaded.", self.name) return end

  local frame = CT.uptimeGraphFrame
  local found = nil
  local dbGraph = getmetatable(self)

  if not command then -- Don't bother running through if a show or hide command was sent
    for i = 1, #frame.displayed do
      if frame.displayed[i] == self then -- Graph is currently displayed
        found = i
        break
      end
    end
  end

  if found or (command and command == "hide") then -- Hide graph
    print("Hiding:", self.name .. ".")

    tremove(frame.displayed, found) -- Remove it from list
    self.frame = nil
    -- dbGraph.shown = false

    for i = 1, #self.lines do -- Hide all the lines
      if self.lines[i] then
        self.lines[i]:Hide()
      end
    end
  elseif not found or (command and command == "show") then -- Show graph
    print("Showing:", self.name .. ".")

    tinsert(frame.displayed, self) -- Add it to list
    self.frame = frame
    -- dbGraph.shown = true

    self:refresh(true) -- Create/update lines

    for i = 1, #self.lines do -- Show all the lines
      if self.lines[i] then
        self.lines[i]:Show()
      end
    end
  end
end

function CT:updateUptimeAnchors()
  local graphWidth = self:GetWidth()
  local timer = GetTime() - CT.combatStart
  local updateHeight

  local height = self[1]:GetHeight()
  if not ((height - 1) < self.lineHeight and (height + 1) > self.lineHeight) then
    updateHeight = true
  end

  for i = 1, #self do
    local line = self[i]
    local startX = self[i].startX
    local stopX = self[i].stopX

    line:SetPoint("LEFT", (self.relativeFrame or self), graphWidth * startX / self.XMax, 0)

    if stopX then
      line:SetWidth(graphWidth * (stopX - startX) / self.XMax)
    else
      line:SetWidth(graphWidth * (timer - startX) / self.XMax)
    end

    if updateHeight then
      line:SetHeight(32)
    end
  end
end

function CT:refreshUptimeGraph(reset)
  if not CT.uptimeGraphFrame then CT:Print("Tried to refresh uptime graph before CT.uptimeGraphFrame was created.") return end
  if not CT.uptimeGraphFrame.displayed[1] then CT:Print("Tried to refresh uptime graph without any displayed.") return end
  if not self.lines then CT:Print("Tried to refresh uptime graph without any line table.") return end

  local frame = CT.uptimeGraphFrame
  local frameWidth, frameHeight = frame.bg:GetSize()
  local setGraph = self
  local dbGraph = getmetatable(self)

  if reset then setGraph.endNum = 1 end

  for i = setGraph.endNum, #setGraph.data do
    local line = setGraph.lines[i]
    if not line then
      line = frame.anchor:CreateTexture(nil, "ARTWORK")
      line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
      line.startX = setGraph.data[i]

      setGraph.lines[i] = line
      setGraph.lastLine = line

      if (i % 2) == 0 then
        line:SetVertexColor(unpack(setGraph.color))
      else
        line:SetVertexColor(0.5, 0.5, 0.5, 1)
        -- line:SetVertexColor(0, 0, 0, 0)
      end
    end

    line:SetPoint("LEFT", frame.bg, frameWidth * setGraph.data[i] / setGraph.XMax, 0)
    line:SetSize(1, 8)

    if setGraph.lines[i - 1] then
      setGraph.lines[i - 1]:SetPoint("RIGHT", line)
    end

    setGraph.endNum = i + 1
  end
end

function CT:refreshUptimeGraph_BACKUP(reset, newHeight, visible)
  if not self.shown then return end

  for index = 1, #CT.base.expander.uptimeGraph do
    local graphFrame = CT.base.expander.uptimeGraph[index]
    local graphWidth, graphHeight = graphFrame.bg:GetSize()

    local graph = graphFrame.graph

    if graph then
      if reset then graph.endNum = 1 end

      local lineTable = CT.uptimeGraphLines[graph.category][graph.name]

      if graph.endNum > 1 then
        local numCheck = ((#lineTable + 1) - graph.endNum) % 2
        if numCheck ~= 0 then
          graph.data[#graph.data + 1] = graph.lastLine.stopX
          print("Uptime graph for " .. self.name .. " got out of sync!")
        end
      end

      for i = graph.endNum, #graph.data do
        local addedLine
        local offSetY = 0

        local line = lineTable[i]
        if not line then
          line = graphFrame.anchor:CreateTexture(nil, "ARTWORK")
          line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
          line.startX = graph.data[i]

          lineTable[i] = line
          graph.lastLine = line
          addedLine = true

          if visible then
            if graph.color then
              line:SetVertexColor(graph.color[1], graph.color[2], graph.color[3], graph.color[4])
            elseif self.colorChange and self.colorChange[i] then
              line:SetVertexColor(self.colorChange[i][1], self.colorChange[i][2], self.colorChange[i][3], self.colorChange[i][4])
            else
              line:SetVertexColor(self.color[1], self.color[2], self.color[3], self.color[4])
            end

            line.visible = true
          elseif not visible and (i % 2) == 0 then
            if graph.color then
              line:SetVertexColor(graph.color[1], graph.color[2], graph.color[3], graph.color[4])
            elseif self.colorChange and self.colorChange[i] then
              line:SetVertexColor(self.colorChange[i][1], self.colorChange[i][2], self.colorChange[i][3], self.colorChange[i][4])
            else
              line:SetVertexColor(self.color[1], self.color[2], self.color[3], self.color[4])
            end

            line.visible = true
          else
            line:SetVertexColor(0, 0, 0, 0)
          end
        end

        if self.stacks and self.stacks[i] then
          line:SetHeight(graphFrame.lineHeight * self.stacks[i])
          offSetY = self.stacks[i] + 0.5
          line.height = (graphFrame.lineHeight * self.stacks[i])

          if addedLine and line.height > (self.maxLineHeight or 0) then
            self.maxLineHeight = line.height
            self.graphFrame.anchorFrame:SetHeight(self.graphFrame.anchorFrame.height + line.height)
          end
        elseif addedLine then
          line:SetHeight(graphFrame.lineHeight)
          line.height = graphFrame.lineHeight
        end

        line:SetPoint("LEFT", graphFrame.bg, graphWidth * graph.data[i] / self.XMax, offSetY)
        line:SetWidth(1)

        if lineTable[i - 1] then
          local prevLine = lineTable[i - 1]
          prevLine.stopX = graph.data[i]

          if prevLine.startX >= graph.data[i] then -- Stops lines from begining before the new end point
            prevLine.startX = graph.data[i] - 0.01
          end

          prevLine:SetWidth(graphWidth * (prevLine.stopX - prevLine.startX) / self.XMax)
        end

        graph.endNum = i + 1
      end
    end
  end
end

function CT:buildUptimeGraph(relativeFrame)
  local graphHeight = 15
  local graphWidth = 200
  local graph, mouseOver, highlightLine

  do
    -- graph = CreateFrame("Frame", nil, self)
    graph = CreateFrame("ScrollFrame", nil, self)
    CT.uptimeGraphFrame = graph
    CT.uptimeGraphFrame.displayed = {}

    graph.anchor = CreateFrame("Frame", nil, self)
    graph:SetScrollChild(graph.anchor)

    -- CT.scrollChildFrameUptime = CreateFrame("Frame", nil, CT.base)
    -- graph:SetScrollChild(CT.scrollChildFrameUptime)
    -- graph:SetScrollChild(CT.scrollChildFrame)
    graph:SetHeight(graphHeight)

    if not self.uptimeGraph then
      self.uptimeGraph = graph
    end

    local num = #self.uptimeGraph + 1

    self.uptimeGraph[num] = graph
    graph.bg = graph:CreateTexture(nil, "BACKGROUND")
    graph.bg:SetTexture(0.07, 0.07, 0.07, 1.0)
    graph.bg:SetPoint("LEFT", 2, 0)
    graph.bg:SetPoint("RIGHT", -2, 0)
    graph.bg:SetPoint("TOP", 0, 0)
    graph.bg:SetPoint("BOTTOM", 0, 0)

    graph.startX = 10
    graph.XMin = 0
    graph.XMax = 10
    graph.YMin = 0
    graph.YMax = 10
    graph.anchorFrame = relativeFrame or CT.base.expander.uptimeGraphBG
    graph.lineHeight = 5

    graph:SetPoint("LEFT", graph.anchorFrame, 0, 0)
    graph:SetPoint("RIGHT", graph.anchorFrame, 0, 0)
    graph:SetPoint("TOP", graph.anchorFrame, 0, -graph.anchorFrame.height)

    graph.anchorFrame.height = graph.anchorFrame.height + graphHeight
    graph.anchorFrame:SetHeight(graph.anchorFrame.height)
  end

  do -- Create Graph Borders
    graph.border = {}

    local width, height, anchor1, anchor2, pointX, pointY

    for i = 1, 4 do
      local border = graph:CreateTexture(nil, "BORDER")
      graph.border[i] = border
      border:SetTexture(0.2, 0.2, 0.2, 1.0)
      border:SetSize(2, 2)

      if i == 1 then
        border:SetPoint("TOPRIGHT", graph, 0, 0)
        border:SetPoint("TOPLEFT", graph, 0, 0)
      elseif i == 2 then
        border:SetPoint("BOTTOMRIGHT", graph, 0, 0)
        border:SetPoint("BOTTOMLEFT", graph, 0, 0)
      elseif i == 3 then
        border:SetPoint("TOPLEFT", graph, 0, 0)
        border:SetPoint("BOTTOMLEFT", graph, 0, 0)
      else
        border:SetPoint("TOPRIGHT", graph, 0, 0)
        border:SetPoint("BOTTOMRIGHT", graph, 0, 0)
      end
    end
  end

  do -- Mouseover Line
    graph.mouseOverLine = CreateFrame("Frame", nil, graph)
    mouseOver = graph.mouseOverLine
    mouseOver:SetSize(2, graphHeight)
    mouseOver:SetPoint("TOP", 0, 0)
    mouseOver:SetPoint("BOTTOM", 0, 0)
    mouseOver.texture = mouseOver:CreateTexture(nil, "OVERLAY")
    mouseOver.texture:SetTexture(1.0, 1.0, 1.0, 1.0)
    mouseOver.texture:SetAllPoints()
    mouseOver:Hide()
  end

  do -- Highlight Line
    graph.highlightLine = CreateFrame("Frame", nil, graph)
    highlightLine = graph.highlightLine
    highlightLine:SetSize(1, 32)
    highlightLine:SetPoint("LEFT", 0, 0)
    highlightLine.texture = highlightLine:CreateTexture(nil, "ARTWORK")
    highlightLine.texture:SetAllPoints()
    highlightLine.texture:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    highlightLine.texture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
    highlightLine:Hide()
  end

  local UIScale = UIParent:GetEffectiveScale()
  local YELLOW = "|cFFFFFF00"

  mouseOver:SetScript("OnUpdate", function(mouseOver, elapsed)
    local mouseX, mouseY = GetCursorPosition()
    local mouseX = (mouseX / UIScale)
    local mouseY = (mouseY / UIScale)
    local line, num, text

    mouseOver:SetPoint("LEFT", UIParent, mouseX, 0)

    if not graph.graph then return end
    local graph = graph.graph
    local lineTable = CT.uptimeGraphLines[graph.category][graph.name]

    for i = 1, #lineTable do
      line = lineTable[i]

      if line and line:GetRight() > mouseX then
        num = i
        break
      end
    end

    if line.stopX then
      local startX = line.startX
      local stopX = line.stopX

      if line.visible then -- Normally shown line
        highlightLine:Show()
        highlightLine:SetAllPoints(line)
        highlightLine:SetAlpha(1)
        text = ("Time: %s%s - %s\n|r%s: %s%.2f"):format(YELLOW, formatTimer(startX), formatTimer(stopX), graph.group, YELLOW, stopX - startX)
        -- print("StopX and visible", text)
      else -- This will pass if mouse is over a hidden line that is not at the end
        highlightLine:Show()
        highlightLine:SetAllPoints(line)
        highlightLine:SetAlpha(0.3)
        text = ("Time: %s%s - %s\n|rGap: %s%.2f"):format(YELLOW, formatTimer(startX), formatTimer(stopX), YELLOW, stopX - startX)
        -- print("StopX and NOT visible", text)
      end
    else
      local startX = line.startX
      local stopX

      if CT.combatStart then
        stopX = (CT.combatStop or GetTime()) - CT.combatStart
      else
        stopX = 0
      end

      if line.visible then
        highlightLine:Show()
        highlightLine:SetAllPoints(line)
        highlightLine:SetAlpha(1)
        text = ("Time: %s%s - %s\n|r%s: %s%.2f"):format(YELLOW, formatTimer(startX), formatTimer(stopX), graph.group, YELLOW, stopX - startX)
        -- print("NOT StopX and visible", text)
      else -- This will pass if mouse is over the end of the graph, beyond any line
        highlightLine:Show()
        highlightLine:SetAllPoints(line)
        highlightLine:SetAlpha(0.3)
        text = ("Time: %s%s - %s\n|rGap: %s%.2f"):format(YELLOW, formatTimer(startX), formatTimer(stopX), YELLOW, stopX - startX)
        -- print("NOT StopX and NOT visible", text)
      end
    end

    if graph.spellName and graph.spellName[num] then
      text = text .. "|r\nCast: " .. YELLOW .. graph.spellName[num]
    end

    if graph.unitName and graph.unitName[num] then
      text = text .. "|r\nName: " .. YELLOW .. graph.unitName[num]
    end

    mouseOver.info = text
  end)
  graph:SetScript("OnEnter", function()
    mouseOver:Show()
    CT.createInfoTooltip(mouseOver, "Uptime Graph")

    -- if not CT.graphTooltip then
    --   createGraphTooltip()
    -- end
    --
    -- CT.graphTooltip:SetOwner(mouseOver, "ANCHOR_TOPLEFT", 25, 8)
    -- CT.graphTooltip:SetCurrencyToken(1)
    -- CT.graphTooltip:SetBackdropColor(0.1, 0.1, 0.1, 1.0)
    -- CT.graphTooltip:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.4)
  end)
  graph:SetScript("OnLeave", function()
    mouseOver:Hide()
    highlightLine:Hide()
    -- CT.graphTooltip:Hide()
    CT.createInfoTooltip()
  end)

  self.uptimeGraphCreated = true

  return graph
end
--------------------------------------------------------------------------------
-- Normal Graphs
--------------------------------------------------------------------------------
function CT.hideLineGraphs(self)
  local uptimeGraphs = CT.current.uptimeGraphs
  local graphs = CT.current.graphs

  if self and self.shown then -- A specific graph was passed, hide that only
    local lineTable = CT.graphLines[self.name]

    self.graphFrame = nil
    self.shown = false

    for i = 1, #CT.base.expander.graphFrame.active do
      if CT.base.expander.graphFrame.active[i] == self then
        tremove(CT.base.expander.graphFrame.active, i)
      end
    end

    for k, v in pairs(lineTable) do
      v:Hide()
    end

    local string = CT.base.expander.uptimeGraph.titleText.default
    for i = 1, #graphs do
      if graphs[i].graphFrame then
        string = string .. graphs[i].string
      end
    end
    CT.base.expander.graphFrame.titleText:SetText(string)

    return
  else -- No specific graph was passed, hide all
    for i = 1, #graphs do
      local self = graphs[i]

      if self.shown then -- Remove any graphs that are already displayed
        self.graphFrame = nil
        self.shown = false

        for i = 1, #CT.base.expander.graphFrame.active do
          if CT.base.expander.graphFrame.active[i] == self then
            tremove(CT.base.expander.graphFrame.active, i)
          end
        end

        local lineTable = CT.graphLines[self.name]
        for k, v in pairs(lineTable) do
          v:Hide()
        end

        local string = CT.base.expander.uptimeGraph.titleText.default
        for i = 1, #graphs do
          if graphs[i].graphFrame then
            string = string .. graphs[i].string
          end
        end
        CT.base.expander.graphFrame.titleText:SetText(string)
      end
    end
  end
end

function CT.showLineGraph(self, name)
  local uptimeGraphs = CT.current.uptimeGraphs
  local graphs = CT.current.graphs

  if self then -- Specific graph was passed, show it
    local lineTable = CT.graphLines[self.name]

    self.graphFrame = CT.base.expander.graph
    self.shown = true
    tinsert(CT.base.expander.graphFrame.active, self)

    for k, v in pairs(lineTable) do
      v:Show()
    end

    self:refresh(true)

    if not self.string then
      self.convertedColor = CT.convertColor(self.color[1], self.color[2], self.color[3])
      self.string = self.convertedColor .. self.name .. "|r, "
    end

    local string = CT.base.expander.graphFrame.titleText.default
    for i = 1, #graphs do
      if graphs[i].graphFrame then
        string = string .. graphs[i].string
      end
    end
    CT.base.expander.graphFrame.titleText:SetText(string)

    return
  else
    local lineMatch, lineDefault
    for i = 1, #graphs do
      local self = graphs[i]

      if name and self.name == name then
        lineMatch = self
      elseif graphs.default and self.name == graphs.default then
        lineDefault = self
      end
    end

    if lineMatch then
      CT.showLineGraph(lineMatch)
    elseif lineDefault then
      CT.showLineGraph(lineDefault)
    end
  end
end

function CT:toggleNormalGraph(command)
  if not CT.graphFrame then CT:Print("Tried to toggle a graph before graph frame was loaded.", self.name) return end

  local frame = CT.graphFrame
  local found = nil
  local dbGraph = CT.displayedDB and CT.displayedDB.graphs[self.name]

  if not command then -- Don't bother running through if a show or hide command was sent
    for i = 1, #frame.displayed do
      if frame.displayed[i] == self then -- Graph is currently displayed
        found = i
        break
      end
    end
  end

  if found or (command and command == "hide") then -- Hide graph
    print("Hiding:", self.name .. ".")

    tremove(frame.displayed, found) -- Remove it from list
    self.frame = nil
    dbGraph.shown = false

    for i = 1, #self.lines do -- Hide all the lines
      if self.lines[i] then
        self.lines[i]:Hide()
      end
    end
  elseif not dbGraph.shown and not found or (command and command == "show") then -- Show graph
    print("Showing:", self.name .. ".")

    tinsert(frame.displayed, self) -- Add it to list
    self.frame = frame
    dbGraph.shown = true

    self:refresh(true) -- Create/update lines

    for i = 1, #self.lines do -- Show all the lines
      if self.lines[i] then
        self.lines[i]:Show()
      end
    end
  end
end

function CT:refreshNormalGraph(reset)
  if not self.frame then print("Tried to refresh graph without a frame set!") return end

  local graphWidth, graphHeight = self.frame:GetSize()

  local maxX = self.XMax
  local minX = self.XMin
  local maxY = self.YMax
  local minY = self.YMin
  local num = #self.data
  local set = CT.displayed
  local callback

  if reset then
    self.endNum = 2

    if num > set.graphs.splitAmount then
      local extraNum = num
      local count = 1

      -- If there are more than 500 CT.current points, it starts to stagger out the refresh
      -- So if there are 1200, it'll do 500 then after a small delay, another 500
      -- then again after a delay, do the remaining 200
      -- With this, having 10,000 lines drawn (3 1 hour lines) there was no lag when they updated
      while extraNum > set.graphs.splitAmount do
        count = count + 1
        extraNum = extraNum - set.graphs.splitAmount
      end

      self.splitsLeft = count
      self.splitAmount = num / count
    end
  end

  if (self.splitsLeft or 0) > 0 then
    num = min(self.splitAmount + self.endNum, #self.data)
    callback = true
    self.splitsLeft = self.splitsLeft - 1
  end

  for i = (self.endNum or 2), num do
    local startX = graphWidth * (self.data[i - 1] - minX) / (maxX - minX)
    local startY = graphHeight * (self.data[-(i - 1)] - minY) / (maxY - minY)

    local stopX = graphWidth * (self.data[i] - minX) / (maxX - minX)
    local stopY = graphHeight * (self.data[-i] - minY) / (maxY - minY)

    if startX == stopX then return end -- Line took another data point without progressing, not sure how this happens, but it breaks it.

    local w = 32 -- self.lineHeight
    local dx, dy = stopX - startX, stopY - startY
    local cx, cy = (startX + stopX) / 2, (startY + stopY) / 2

    -- Normalize direction if necessary
    if (dx < 0) then
      dx, dy = -dx, -dy
    end

    -- Calculate actual length of line
    local l = sqrt((dx * dx) + (dy * dy))

    -- Sin and Cosine of rotation, and combination (for later)
    local s, c = -dy / l, dx / l
    local sc = s * c

    -- Calculate bounding box size and texture coordinates
    local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy
    if (dy >= 0) then
      Bwid = ((l * c) - (w * s)) * TAXIROUTE_LINEFACTOR_2
      Bhgt = ((w * c) - (l * s)) * TAXIROUTE_LINEFACTOR_2
      BLx, BLy, BRy = (w / l) * sc, s * s, (l / w) * sc
      BRx, TLx, TLy, TRx = 1 - BLy, BLy, 1 - BRy, 1 - BLx
      TRy = BRx
    else
      Bwid = ((l * c) + (w * s)) * TAXIROUTE_LINEFACTOR_2
      Bhgt = ((w * c) + (l * s)) * TAXIROUTE_LINEFACTOR_2
      BLx, BLy, BRx = s * s, -(l / w) * sc, 1 + (w / l) * sc
      BRy, TLx, TLy, TRy = BLx, 1 - BRx, 1 - BLx, 1 - BLy
      TRx = TLy
    end

    if TLx > 10000 then TLx = 10000 elseif TLx < -10000 then TLx = -10000 end
    if TLy > 10000 then TLy = 10000 elseif TLy < -10000 then TLy = -10000 end
    if BLx > 10000 then BLx = 10000 elseif BLx < -10000 then BLx = -10000 end
    if BLy > 10000 then BLy = 10000 elseif BLy < -10000 then BLy = -10000 end
    if TRx > 10000 then TRx = 10000 elseif TRx < -10000 then TRx = -10000 end
    if TRy > 10000 then TRy = 10000 elseif TRy < -10000 then TRy = -10000 end
    if BRx > 10000 then BRx = 10000 elseif BRx < -10000 then BRx = -10000 end
    if BRy > 10000 then BRy = 10000 elseif BRy < -10000 then BRy = -10000 end

    local line = self.lines[i]
    if not line then
      self.lines[i] = self.frame.anchor:CreateTexture("_Line_" .. i, "ARTWORK")
      line = self.lines[i]
      line:SetTexture("Interface\\addons\\CombatTracker\\Media\\line.tga")
      self.lastLine = line

      if self.color then
        line:SetVertexColor(self.color[1], self.color[2], self.color[3], self.color[4])
      else
        line:SetVertexColor(1.0, 1.0, 1.0, 1.0)
      end
    end

    line:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
    line:SetPoint("TOPRIGHT", self.frame.anchor, "BOTTOMLEFT", cx + Bwid, cy + Bhgt)
    line:SetPoint("BOTTOMLEFT", self.frame.anchor, "BOTTOMLEFT", cx - Bwid, cy - Bhgt)

    self.endNum = i
  end

  if callback then
    -- When multiple graphs are shown, I can reduce the chance of them updating
    -- at exactly the same time with this random number
    C_Timer.After((random(-3, 3) / 100) + 0.04, function()
      self:refresh()
    end)
  elseif self.frame.zoomed then
    self.frame.slider:SetMinMaxValues(self.lines[4]:GetLeft() - self.frame:GetLeft(), self.lastLine:GetRight() - self.frame:GetRight())
    self.frame.slider:SetValue(0)
  end
end

function CT:refreshNormalGraphBACKUP(reset)
  local graphWidth, graphHeight = self.graphFrame:GetSize()
  local maxX = self.XMax
  local minX = self.XMin
  local maxY = self.YMax
  local minY = self.YMin
  local num = #self.data
  local callback
  local lineTable = CT.graphLines[self.name]

  if reset then
    self.endNum = 4

    if num > CT.current.graphs.splitAmount then
      local extraNum = num
      local count = 1

      -- If there are more than 500 CT.current points, it starts to stagger out the refresh
      -- So if there are 1200, it'll do 500 then after a small delay, another 500
      -- then again after a delay, do the remaining 200
      -- With this, having 10,000 lines drawn (3 1 hour lines) there was no lag when they updated
      while extraNum > CT.current.graphs.splitAmount do
        count = count + 1
        extraNum = extraNum - CT.current.graphs.splitAmount
      end

      self.splitsLeft = count
      self.splitAmount = num / count
    end
  end

  if (self.splitsLeft or 0) > 0 then
    num = min(self.splitAmount + self.endNum, #self.data)
    callback = true
    self.splitsLeft = self.splitsLeft - 1
  end

  local counter = 0
  for i = self.endNum, num, 2 do
    counter = counter + 1

    if reset or callback or counter == 2 then
      local startX = graphWidth * (self.data[i - 3] - minX) / (maxX - minX)
      local startY = graphHeight * (self.data[i - 2] - minY) / (maxY - minY)

      local stopX = graphWidth * (self.data[i - 1] - minX) / (maxX - minX)
      local stopY = graphHeight * (self.data[i] - minY) / (maxY - minY)

      if startX == stopX then return end -- Line took another data point without progressing, not sure how this happens, but it breaks it.

      local w = 32 -- self.lineHeight
      local dx, dy = stopX - startX, stopY - startY
      local cx, cy = (startX + stopX) / 2, (startY + stopY) / 2

      -- Normalize direction if necessary
      if (dx < 0) then
        dx, dy = -dx, -dy
      end

      -- Calculate actual length of line
      local l = sqrt((dx * dx) + (dy * dy))

      -- Sin and Cosine of rotation, and combination (for later)
      local s, c = -dy / l, dx / l
      local sc = s * c

      -- Calculate bounding box size and texture coordinates
      local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy
      if (dy >= 0) then
        Bwid = ((l * c) - (w * s)) * TAXIROUTE_LINEFACTOR_2
        Bhgt = ((w * c) - (l * s)) * TAXIROUTE_LINEFACTOR_2
        BLx, BLy, BRy = (w / l) * sc, s * s, (l / w) * sc
        BRx, TLx, TLy, TRx = 1 - BLy, BLy, 1 - BRy, 1 - BLx
        TRy = BRx
      else
        Bwid = ((l * c) + (w * s)) * TAXIROUTE_LINEFACTOR_2
        Bhgt = ((w * c) + (l * s)) * TAXIROUTE_LINEFACTOR_2
        BLx, BLy, BRx = s * s, -(l / w) * sc, 1 + (w / l) * sc
        BRy, TLx, TLy, TRy = BLx, 1 - BRx, 1 - BLx, 1 - BLy
        TRx = TLy
      end

      if TLx > 10000 then TLx = 10000 elseif TLx < -10000 then TLx = -10000 end
      if TLy > 10000 then TLy = 10000 elseif TLy < -10000 then TLy = -10000 end
      if BLx > 10000 then BLx = 10000 elseif BLx < -10000 then BLx = -10000 end
      if BLy > 10000 then BLy = 10000 elseif BLy < -10000 then BLy = -10000 end
      if TRx > 10000 then TRx = 10000 elseif TRx < -10000 then TRx = -10000 end
      if TRy > 10000 then TRy = 10000 elseif TRy < -10000 then TRy = -10000 end
      if BRx > 10000 then BRx = 10000 elseif BRx < -10000 then BRx = -10000 end
      if BRy > 10000 then BRy = 10000 elseif BRy < -10000 then BRy = -10000 end

      local line = lineTable[i]
      if not line then
        lineTable[i] = self.graphFrame.anchor:CreateTexture("_Line_" .. i, "ARTWORK")
        line = lineTable[i]
        lineTable[i - 1] = line -- NOTE: Deal with this wastefulness
        line:SetTexture("Interface\\addons\\CombatTracker\\Media\\line.tga")
        self.lastLine = line

        if self.color then
          line:SetVertexColor(self.color[1], self.color[2], self.color[3], self.color[4])
        else
          line:SetVertexColor(1.0, 1.0, 1.0, 1.0)
        end
      end

      -- if not (TLx >= 0 and TLx <= 1) then
      --   -- print(TLx)
      --   -- self.endNum = 4
      --   return
      -- end

      line:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
      line:SetPoint("TOPRIGHT", self.graphFrame.anchor, "BOTTOMLEFT", cx + Bwid, cy + Bhgt)
      line:SetPoint("BOTTOMLEFT", self.graphFrame.anchor, "BOTTOMLEFT", cx - Bwid, cy - Bhgt)

      self.endNum = i
    end
  end

  if callback then
    -- When multiple graphs are shown, I can reduce the chance of them updating
    -- at exactly the same time with this random number
    C_Timer.After((random(-3, 3) / 100) + 0.04, function()
      self:refresh()
    end)
  elseif self.graphFrame.zoomed then
    self.graphFrame.slider:SetMinMaxValues(lineTable[4]:GetLeft() - self.graphFrame:GetLeft(), self.lastLine:GetRight() - self.graphFrame:GetRight())
    self.graphFrame.slider:SetValue(0)
  end
end

function CT.loadDefaultGraphs()
  if CT.displayedDB then -- Show the default graphs
    local set = CT.displayed
    local db = CT.displayedDB

    if db.graphs.defaults then
      for name in pairs(db.graphs.defaults) do
        set.graphs[name]:toggle()
      end
    else
      local default

      if set.role == "HEALER" then
        default = "Healing"
      elseif set.role == "DAMAGER" then
        default = "Damage"
      elseif set.role == "TANK" then
        default = "Damage"
      end

      default = "Holy Power" -- NOTE: Testing only

      db.graphs.defaults = {}
      db.graphs.defaults[default] = true

      set.graphs[default]:toggle("show")
    end
  end
end

local function hideAllGraphs(self)
  for i, graph in ipairs(self.displayed) do
    graph:toggle("hide")
  end
end

function CT:buildGraph()
  local graph, mouseOver, dot, dragOverlay, slider
  local graphHeight = 100
  local graphWidth = 200

  if not CT.graphTooltip then
    createGraphTooltip()
  end

  local graphFrame = self.graphFrame

  if not graphFrame then -- Create graph frame and background and set basic values
    self.graphFrame = CreateFrame("ScrollFrame", nil, self)
    graphFrame = self.graphFrame
    CT.graphFrame = graphFrame
    graphFrame.anchor = CreateFrame("Frame", nil, self)
    graphFrame:SetScrollChild(graphFrame.anchor)
    graphFrame.anchor:SetSize(100, 100)
    graphFrame.anchor:SetAllPoints(graphFrame)
    -- graphFrame.anchor:SetPoint("RIGHT", graphFrame)

    graphFrame.bg = graphFrame:CreateTexture(nil, "BACKGROUND")
    graphFrame.bg:SetTexture(0.07, 0.07, 0.07, 1.0)
    graphFrame.bg:SetAllPoints()

    graphFrame.displayed = {} -- Holds every currently displayed graph
    graphFrame.hideAllGraphs = hideAllGraphs
  end

  do -- Create Graph Borders
    graphFrame.border = {}

    for i = 1, 4 do
      local border = graphFrame:CreateTexture(nil, "BORDER")
      graphFrame.border[i] = border
      border:SetTexture(0.2, 0.2, 0.2, 1.0)
      border:SetSize(2, 2)

      if i == 1 then
        border:SetPoint("TOPRIGHT", graphFrame, 0, 0)
        border:SetPoint("TOPLEFT", graphFrame, 0, 0)
      elseif i == 2 then
        border:SetPoint("BOTTOMRIGHT", graphFrame, 0, 0)
        border:SetPoint("BOTTOMLEFT", graphFrame, 0, 0)
      elseif i == 3 then
        border:SetPoint("TOPLEFT", graphFrame, 0, 0)
        border:SetPoint("BOTTOMLEFT", graphFrame, 0, 0)
      else
        border:SetPoint("TOPRIGHT", graphFrame, 0, 0)
        border:SetPoint("BOTTOMRIGHT", graphFrame, 0, 0)
      end
    end
  end

  do -- MouseoverLine
    graphFrame.mouseOverLine = CreateFrame("Frame", nil, graphFrame)
    mouseOver = graphFrame.mouseOverLine
    mouseOver:SetSize(2, graphHeight)
    mouseOver:SetPoint("TOP", 0, 0)
    mouseOver:SetPoint("BOTTOM", 0, 0)
    mouseOver.texture = mouseOver:CreateTexture(nil, "OVERLAY")
    mouseOver.texture:SetTexture(1.0, 1.0, 1.0, 1.0)
    mouseOver.texture:SetAllPoints()
    mouseOver:Hide()
  end

  do -- Dot
    graphFrame.mouseOverLine.dot = CreateFrame("Frame", nil, graphFrame.mouseOverLine)
    dot = graphFrame.mouseOverLine.dot
    dot:SetSize(10, 10)
    dot:SetPoint("CENTER", 0, 0)
    dot.texture = dot:CreateTexture(nil, "OVERLAY")
    dot.texture:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
    dot.texture:SetAllPoints()
    dot:Hide()
  end

  do -- Drag Overlay
    graphFrame.dragOverlay = CreateFrame("Frame", nil, graphFrame)
    dragOverlay = graphFrame.dragOverlay
    dragOverlay:SetSize(60, graphHeight)
    dragOverlay:SetPoint("TOP", 0, 0)
    dragOverlay:SetPoint("BOTTOM", 0, 0)
    dragOverlay.texture = dragOverlay:CreateTexture(nil, "OVERLAY")
    dragOverlay.texture:SetTexture(0.3, 0.3, 0.3, 0.4)
    dragOverlay.texture:SetAllPoints()
    dragOverlay:Hide()
  end

  do -- Slider bar
    graphFrame.slider = CreateFrame("Slider", nil, graphFrame)
    slider = graphFrame.slider
    slider:SetSize(100, 20)
    slider:SetPoint("TOPLEFT", graphFrame, 0, 0)
    slider:SetPoint("TOPRIGHT", graphFrame, 0, 0)

    slider:SetBackdrop({
      bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
      edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 8,})
    slider:SetBackdropColor(0.15, 0.15, 0.15, 1.0)
    slider:SetBackdropBorderColor(0.7, 0.7, 0.7, 1.0)

    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(0, 0)
    slider:SetValue(50)
    -- slider:SetValueStep(25)

    slider:SetScript("OnValueChanged", function(self, value)
      graphFrame.anchor:SetSize(graphFrame:GetWidth(), graphFrame:GetHeight())
      graphFrame:SetHorizontalScroll(value)
    end)

    slider:Hide()
  end

  local UIScale = UIParent:GetEffectiveScale()
  local YELLOW = "|cFFFFFF00"
  local mouseLines = {}

  mouseOver:SetScript("OnUpdate", function(mouseOver, elapsed)
    local mouseX, mouseY = GetCursorPosition()
    local mouseX = (mouseX / UIScale)
    local mouseY = (mouseY / UIScale)
    local line, num, text

    mouseOver:SetPoint("LEFT", UIParent, mouseX, 0)

    if not graphFrame.displayed[1] then return end -- No displayed graphs

    local active1 = graphFrame.displayed[1]

    local count = 0
    local mouseOverCenter = mouseOver:GetCenter()

    wipe(mouseLines)
    for i = 1, #active1.lines do
      line = active1.lines[i]

      if line then
        if line:GetRight() > mouseX then
          if line:GetLeft() < mouseX then
            count = count + 1
            mouseLines[i] = line
          elseif count > 0 then
            break
          end
        end
      end
    end

    local num, line = nearestValue(mouseLines, mouseOverCenter)

    if num and active1.data[num] then
      local startX = active1.data[num]
      local startY = active1.data[-num]

      local text = "Time: " .. YELLOW .. formatTimer(startX) .. "|r\n"

      for i = 1, #graphFrame.displayed do
        local graph = graphFrame.displayed[i]
        local startY = graph.data[-num]

        graph.displayText[5] = floor(startY)
        text = text .. table.concat(graph.displayText)
      end

      CT.graphTooltip:SetText(text, 1, 1, 1, 1)
      CT.graphTooltip:SetAlpha(1)
    elseif not num then
      CT.graphTooltip:SetAlpha(0)
    end
  end)

  graphFrame:SetScript("OnEnter", function(graphFrame)
    mouseOver:Show()
    CT.graphTooltip:SetOwner(mouseOver.dot, "ANCHOR_TOPLEFT", 25, 8)
    CT.graphTooltip:SetCurrencyToken(1)
    CT.graphTooltip:SetBackdropColor(0.1, 0.1, 0.1, 1.0)
    CT.graphTooltip:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.4)
  end)

  graphFrame:SetScript("OnLeave", function(graphFrame)
    mouseOver:Hide()
    CT.graphTooltip:Hide()
  end)

  graphFrame:SetScript("OnMouseDown", function(graphFrame, button)
    if not CT.current then return end

    if button == "LeftButton" and not graphFrame.zoomed then
      local mouseOverLeft = mouseOver:GetLeft() - graphFrame:GetLeft()

      graphFrame.dragOverlay:Show()
      graphFrame.dragOverlay:SetPoint("LEFT", mouseOverLeft, 0)
      graphFrame.dragOverlay:SetPoint("RIGHT", mouseOver, 0, 0)

      graphFrame.mouseOverLeft = mouseOverLeft
    end
  end)

  graphFrame:SetScript("OnMouseUp", function(graphFrame, button)
    if not CT.current then return end

    local graphs = CT.current.graphs

    if button == "LeftButton" then
      if not graphFrame.zoomed then
        local mouseOverRight = mouseOver:GetRight()
        local graphWidth = graphFrame:GetWidth()
        local graphLeft = graphFrame:GetLeft()

        graphFrame.zoomed = true
        graphFrame.dragOverlay:Hide()
        graphFrame.slider:Show()

        for i, graph in ipairs(graphFrame.displayed) do
          local dbGraph = CT.currentDB.graphs[graph.name]

          dbGraph.XMin = (graphFrame.mouseOverLeft / graphWidth) * graph.XMax
          dbGraph.XMax = ((mouseOverRight - graphLeft) / graphWidth) * graph.XMax
          graph:refresh(true)
        end
      end
    elseif button == "RightButton" then -- Remove the zoom
      if graphFrame.zoomed then
        local timer = (CT.combatStop or GetTime()) - CT.combatStart

        graphFrame.zoomed = false
        graphFrame.dragOverlay:Hide()
        graphFrame.slider:Hide()
        mouseOver.dot:Hide()
        slider:SetValue(0)

        for i, graph in ipairs(graphFrame.displayed) do
          local dbGraph = CT.currentDB.graphs[graph.name]

          dbGraph.XMin = 0

          if (#graph.data % graphs.splitAmount) == 0 then
            graph.splitCount = graph.splitCount + 1
          end

          if timer > graph.XMax then
            -- graph.XMax = graph.XMax + max(timer - graph.XMax, graph.startX)
            dbGraph.XMax = graph.XMax + max(timer - graph.XMax, graph.startX * graph.splitCount)
          end

          graph:refresh(true)
        end
      end
    end
  end)

  CT.loadDefaultGraphs()

  self.graphCreated = true
  return graphFrame
end
