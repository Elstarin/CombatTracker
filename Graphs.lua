if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals, Frames, and Tables
--------------------------------------------------------------------------------
local CT = CombatTracker
local graphFunctions = {}

local formatTimer = CT.formatTimer
local colorText = CT.colorText

local infinity = math.huge

local TAXIROUTE_LINEFACTOR = 128 / 126 -- Multiplying factor for texture coordinates
local TAXIROUTE_LINEFACTOR_2 = TAXIROUTE_LINEFACTOR / 2 -- Half of that

CT.uptimeCategories = {
  "cooldowns",
  "buffs",
  "debuffs",
  "misc",
}

local SetTexCoord, SetPoint, SetTexture, SetVertexColor =
        SetTexCoord, SetPoint, SetTexture, SetVertexColor
local SetPoint, SetSize, SetVertexColor, SetTexCoords, CreateTexture =
        SetPoint, SetSize, SetVertexColor, SetTexCoords, CreateTexture
local debug, colors, GetTime, round, after, newTicker =
        CT.debug, CT.colors, GetTime, CT.round, C_Timer.After, C_Timer.NewTicker
local wrap, yield, after =
        coroutine.wrap, coroutine.yield, C_Timer.After
--------------------------------------------------------------------------------
-- Graph Plot Functions
--------------------------------------------------------------------------------
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
          debug("No graph update category for:", self.name)
        end

        if (value == infinity) or (value == -infinity) then value = 0 end

        local num = #self.data
        self.data[num + 1] = timer
        self.data[num + 2] = value

        if (num % graphs.splitAmount) == 0 then
          if not self.splitCount then
            debug("Missing split count for:", self.name)
          end

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

  for i = 1, #CT.uptimeCategories do -- Run through each type of uptime graph (ex: "buffs")
    for graphIndex, setGraph in ipairs(uptimeGraphs[CT.uptimeCategories[i]]) do -- Run every graph in that type (ex: "Illuminated Healing")
      for index = 1, #setGraph do -- Run every line for that graph (ex: Illuminated Healing uptime on Elstari, then on Valastari, etc)
        local self = setGraph[index]

        if timer > self.XMax then
          local dbGraph = getmetatable(self)

          if dbGraph then
            dbGraph.XMax = self.XMax + max(timer - self.XMax, self.startX)
          else
            debug("No dbGraph for", setGraph.name .. "!") -- Happened once, no idea how or why...
          end

          if setGraph.frame then
            setGraph:refresh(true)
          end
        end

        if setGraph.frame and self.lastLine then
          local width = setGraph.frame.bg:GetWidth() * (timer - self.data[#self.data]) / self.XMax
          if width < 1 then width = 1 end

          self.lastLine:SetWidth(width)
        end
      end
    end
  end
end
--------------------------------------------------------------------------------
-- General Graph Functions
--------------------------------------------------------------------------------
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

function CT.finalizeGraphLength(graphType)
  if not CT.displayed then return end

  local timer = ((CT.displayedDB.stop or GetTime()) - CT.displayedDB.start) or 0

  if not graphType or (graphType and (graphType == "line" or graphType == "normal")) then
    local graphs = CT.displayed.graphs
    for i = 1, #CT.graphList do -- Finalize line graphs
      local setGraph = graphs[CT.graphList[i]]
      local dbGraph = setGraph.__index

      dbGraph.XMax = timer

      if setGraph.frame then
        if not setGraph.updating then setGraph:refresh(true) end
      end
    end

    if graphType then return end
  end

  if not graphType or (graphType and graphType == "uptime") then
    local uptimeGraphs = CT.displayed.uptimeGraphs
    for i = 1, #CT.uptimeCategories do -- Finalize uptime graphs
      local category = CT.uptimeCategories[i]

      for index, setGraph in ipairs(uptimeGraphs[category]) do -- Run every graph in this category
        for i = 1, #setGraph do -- Run every line for this graph
          local graph = setGraph[i]
          local dbGraph = setGraph.__index

          dbGraph.XMax = timer

          if setGraph.frame and setGraph.shown then
            setGraph:refresh(true)

            if graph.lastLine then
              local width = setGraph.frame.bg:GetWidth() * (timer - graph.data[#graph.data]) / graph.XMax
              if width < 1 then width = 1 end

              graph.lastLine:SetWidth(width)
            end
          end
        end
      end
    end
  end
end

local function handleGraphData(set, db, graph, data, name, timer, value, prev)
  if (value == infinity) or (value == -infinity) then value = 0 end

  local num = #data + 1

  -- if prev or graph.prev then
  --   local prevDataY = data[-(num - 1)]
  --
  --   if prevDataY then
  --     debug(prev, prevDataY)
  --
  --     data[num] = timer -- X coords
  --     data[-num] = prevDataY -- Y coords
  --
  --     timer = timer + 0.00000001 -- Just making sure they don't match
  --     num = #data + 1
  --   end
  --
  --   graph.prev = false
  -- end

  data[num] = timer -- X coords
  data[-num] = value -- Y coords

  if CT.base then -- These updates should only need to happen if it's actually visible
    if graph.frame and graph.frame.zoomed then return end -- Refreshing when zoomed makes it look weird, but we still need to let it create data points if it's active

    local refresh

    -- if value >= graph.YMax and CT.base.expander.shown then
    --   db.graphs[name].YMax = graph.YMax + max(value - graph.YMax, 5)
    --   refresh = true
    -- end

    -- if timer > graph.XMax and CT.base.expander and CT.base.expander.shown and graph.frame and not graph.frame.zoomed then
    --   db.graphs[name].XMax = graph.XMax + max(timer - graph.XMax, graph.startX * graph.splitCount)
    --   refresh = true
    -- end

    if graph.shown then
      if not graph.updating then
        graph.lastUpdate = timer
        graph:refresh(refresh)
      end
    end
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

      -- if value == 100 then
      --   graph.prev = true
      -- end
    end

    -- graph.data[1] = 0
    -- graph.data[-1] = graph.XMax

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

function CT:toggleUptimeGraph(command)
  if not CT.uptimeGraphFrame then return debug("Tried to toggle an uptime graph before uptime graph frame was loaded.", self.name) end

  local frame = self.frame or CT.uptimeGraphFrame

  if frame.displayed then -- First remove the displayed graph
    frame:SetHeight(frame.defaultHeight)
    local self = frame.displayed
    local dbGraph = getmetatable(self)

    frame.displayed = nil
    self.frame = nil
    dbGraph.shown = false

    if self.checkButton then
      self.checkButton:SetChecked(false)
    end

    for index = 1, #self do
      local self = self[index] -- One full graph line

      if self.nameText then
        self.nameText:Hide()
      end

      for i = 1, #self.lines do -- Hide each line
        self.lines[i]:Hide()
      end
    end
  end

  if command == "clear" then -- Just remove the current and return
    return
  end

  if command ~= "hide" then -- Show graph
    -- debug("Showing:", self.name .. ".")

    local dbGraph = getmetatable(self)

    frame.displayed = self
    self.frame = frame
    dbGraph.shown = true

    self:refresh(true) -- Create/update lines

    if self.checkButton then
      self.checkButton:SetChecked(true)
    end

    for index = 1, #self do
      local self = self[index] -- One full graph line

      if self.nameText then
        self.nameText:Show()
      end

      for i = 1, #self.lines do -- Show each line
        self.lines[i]:Show()
      end
    end
  end
end

function CT:refreshUptimeGraph(reset)
  if not self.shown then return end
  if not self.frame then return end
  if not CT.uptimeGraphFrame then return debug("Tried to refresh uptime graph before CT.uptimeGraphFrame was created.") end
  if self[1] and not self[1].lines then return debug("Tried to refresh uptime graph without any line table.") end
  if not self.shown then return debug("Tried to refresh uptime graph while self (" .. (self.name or "UNKNOWN") .. ") was not shown.") end
  -- if not CT.uptimeGraphFrame.displayed[1] then return debug("Tried to refresh uptime graph without any displayed.") end

  local frame = CT.uptimeGraphFrame
  local frameWidth, frameHeight = frame.bg:GetSize()
  local numLines = #self
  local setGraph = self
  -- local dbGraph = getmetatable(self)

  for index = 1, numLines do
    local self = self[index] -- One full graph line, which is made up small lines

    self.endNum = (reset and 1) or self.endNum
    local num = #self.data
    local lines = self.lines
    local data = self.data

    local c1 = self.color[1] or 1
    local c2 = self.color[2] or 1
    local c3 = self.color[3] or 1
    local c4 = self.color[4] or 1

    for i = self.endNum, num do
      local line = lines[i]

      if not line then
        lines[i] = frame.anchor:CreateTexture("CT_Uptime_Line_" .. i, "ARTWORK")
        line = lines[i]

        line:SetSize(1, 5)
        line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        self.lastLine = line

        if (i % 2) == 0 then -- NOTE: Maybe reverse this to avoid the requirement of an instant refresh?
          if setGraph.flags and setGraph.flags.color and setGraph.flags.color[i] then
            line:SetVertexColor(unpack(setGraph.flags.color[i]))
          else
            line:SetVertexColor(c1, c2, c3, c4)
          end
        else
          -- line:SetVertexColor(0.5, 0.5, 0.5, 1)
          line:SetVertexColor(0, 0, 0, 0)
        end
      end

      if data[i - 1] and data[i - 1] > data[i] then
        data[i] = data[i - 1]
      end

      line:SetPoint("TOPLEFT", frame.bg, (frameWidth * data[i]) / self.XMax, self.Y - 10)

      if lines[i - 1] then
        lines[i - 1]:SetPoint("RIGHT", line, "LEFT", 0, 0)
      end

      self.endNum = i + 1
    end
  end

  local newHeight = frame.defaultHeight + ((#self - 1) * 10)
  if newHeight > frameHeight then -- Should mean a new line was added
    frame:SetHeight(newHeight)
  end

  if numLines > (self.numNamesCreated or 1) then -- Create name tags when there are multiple lines
    for index = 1, numLines do
      local self = self[index]
      local nameText = self.nameText

      if not nameText then
        nameText = frame.anchor:CreateFontString(nil, "OVERLAY")
        nameText:SetPoint("LEFT", frame.anchor, 0, 0)
        nameText:SetPoint("BOTTOM", self.lines[1], "TOP", 0, 0)
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 10)
        nameText:SetJustifyH("LEFT")
        nameText:SetTextColor(0.93, 0.86, 0.01, 1.0)

        self.nameText = nameText
      end

      nameText:SetText(self.unitName)
    end

    self.numNamesCreated = numLines
  end
end

local function addUptimeGraphDropDownButtons(parent)
  local text
  local count = 0
  local height = 0
  local uptimeGraphs = CT.displayed.uptimeGraphs
  if not parent.buttonIndex then parent.buttonIndex = {} end

  for i = 1, #CT.uptimeCategories do -- Run through each type of uptime graph (ex: "buffs")
    local category = CT.uptimeCategories[i]

    local texture = parent[category]
    if not texture and #uptimeGraphs[category] > 0 then
      parent[category] = parent:CreateTexture(nil, "ARTWORK")
      texture = parent[category]
      texture:SetTexture(0.1, 0.1, 0.1, 1.0)

      if not parent.prevTexture then
        texture:SetPoint("TOP", parent, 0, 0)
      else
        texture:SetPoint("TOP", parent.prevTexture, "BOTTOM", 0, 0)
      end

      if category == "cooldowns" then
        text = "Cooldown:"
      elseif category == "buffs" then
        text = "Buffs:"
      elseif category == "debuffs" then
        text = "Debuffs:"
      elseif category == "misc" then
        text = "Misc:"
      else
        text = "NO NAME FOUND!"
      end

      texture.title = parent:CreateFontString(nil, "OVERLAY")
      texture.title:SetPoint("TOP", texture, 0, -1)
      texture.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
      texture.title:SetTextColor(1, 1, 1, 1)
      texture.title:SetText(text)

      parent.height = (parent.height or 0) + 25
      parent.prevTexture = texture
    end

    for i, setGraph in ipairs(uptimeGraphs[category]) do -- Run every graph in that type (ex: "Illuminated Healing")
      count = count + 1

      local self = setGraph

      if not texture[i] then
        texture[i] = CreateFrame("CheckButton", nil, parent)
        local b = texture[i]
        b:SetSize(parent:GetWidth() - 5, 20)
        b:SetPoint("TOP", texture, 0, i * -20)
        texture[i].height = (texture[i].height or 0) + 20
        parent.height = (parent.height or 0) + b:GetHeight()

        parent.buttonIndex[#parent.buttonIndex + 1] = b

        do -- Set Textures and Text
          b.normal = b:CreateTexture(nil, "BACKGROUND")
          b.normal:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
          b.normal:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
          b.normal:SetAllPoints(b)
          b:SetNormalTexture(b.normal)

          b.highlight = b:CreateTexture(nil, "BACKGROUND")
          b.highlight:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
          b.highlight:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
          b.highlight:SetVertexColor(0.7, 0.7, 0.7, 1.0)
          b.highlight:SetAllPoints(b)
          b:SetHighlightTexture(b.highlight)

          b.pushed = b:CreateTexture(nil, "BACKGROUND")
          b.pushed:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
          b.pushed:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
          b.pushed:SetAllPoints(b)
          b:SetPushedTexture(b.pushed)

          b.checked = b:CreateTexture(nil, "BACKGROUND")
          b.checked:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
          b.checked:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
          b.checked:SetAllPoints(b)
          b:SetCheckedTexture(b.checked)

          b.disabled = b:CreateTexture(nil, "BACKGROUND")
          b.disabled:SetTexture("Interface\\PetBattles\\PetJournal")
          b.disabled:SetTexCoord(0.49804688, 0.90625000, 0.12792969, 0.17285156)
          b.disabled:SetAllPoints(b)
          b:SetDisabledTexture(b.disabled)

          b.title = b:CreateFontString(nil, "ARTWORK")
          b.title:SetPoint("CENTER", 0, 0)
          b.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
          b.title:SetText(self.name)

          b.graph = self
          self.checkButton = b
        end

        b:SetScript("OnClick", function(button)
          if button:GetChecked() then
            self:toggle("show")
            parent:Hide() -- Selected a new uptime graph, so hide the popup
          else
            self:toggle("hide")
          end
        end)
      end

      if self.frame and self.shown then
        texture[i]:SetChecked(true)
      else
        texture[i]:SetChecked(false)
      end

      if self[1] and self[1].color then
        texture[i].title:SetTextColor(self[1].color[1], self[1].color[2], self[1].color[3], self[1].color[4])
      end
    end

    local numButtons = #uptimeGraphs[category]

    if texture and numButtons == 0 then
      for i = 1, #texture do -- Hides all buttons in this category
        texture[i]:Hide()
      end

      texture.title:Hide()
      -- texture:Hide()
      texture:SetHeight(0.01)
    elseif texture then
      for i = 1, #texture do -- Show all buttons in this category
        texture[i]:Show()
      end

      texture:SetSize(parent:GetWidth(), (numButtons * 20) + 25)
      -- texture:Show()
      texture.title:Show()
      height = height + (numButtons * 20) + 25
    end
  end

  -- debug(#parent.buttonIndex, count)
  -- if #parent.buttonIndex > count + 1 then -- Should mean there are extra buttons shown
  --   for i = count + 1, #parent.buttonIndex do
  --     debug("Hiding", i)
  --     parent.buttonIndex[i]:Hide()
  --   end
  -- end

  -- parent:SetHeight(parent.height or 0)
  parent:SetHeight(height)
end

function CT.loadDefaultUptimeGraph()
  local set = CT.displayed
  local db = CT.displayedDB

  if CT.current and CT.displayed and CT.current ~= CT.displayed then -- If there is an active set that is not displayed, try to mimic its graph for easy comparisons
    for i = 1, #CT.uptimeCategories do
      local category = CT.uptimeCategories[i]

      for graphName, setGraph in pairs(CT.current.uptimeGraphs[CT.uptimeCategories[i]]) do
        if setGraph.shown then
          return setGraph:toggle("show")
        end
      end
    end
  end

  if set and CT.base and CT.base.expander and CT.base.expander.currentButton then -- Didn't find any to mimic, try to match name
    local name = CT.base.expander.currentButton.name
    local spellID = CT.base.expander.currentButton.spellID or select(7, GetSpellInfo(name))

    if name or spellID then -- A button is currently selected, so see if there's a graph with that name/spellID
      for i = 1, #CT.uptimeCategories do
        local category = CT.uptimeCategories[i]

        if set.uptimeGraphs[category][spellID] then
          return set.uptimeGraphs[category][spellID]:toggle("show")
        elseif set.uptimeGraphs[category][name] then
          return set.uptimeGraphs[category][name]:toggle("show")
        end
      end
    end
  end

  if db and set and db.uptimeGraphs then -- Couldn't match the name, so check if any in the db are marked as shown
    for i = 1, #CT.uptimeCategories do
      local category = CT.uptimeCategories[i]

      for graphName, dbGraph in pairs(db.uptimeGraphs[category]) do
        if dbGraph.shown then
          return set.uptimeGraphs[category][graphName]:toggle("show")
        end
      end
    end
  end

  if set then -- Still nothing, so try to load Activity as default
    local name = "Activity"

    for i = 1, #CT.uptimeCategories do
      local category = CT.uptimeCategories[i]

      if set.uptimeGraphs[category][name] then
        return set.uptimeGraphs[category][name]:toggle("show")
      end
    end
  end

  return -- debug("Failed to find any uptime graph to load.")
end

function CT:buildUptimeGraph(relativeFrame)
  local graphHeight = 15
  local graphWidth = 200
  local graphFrame, mouseOver, highlightLine, button

  do -- Create the basic graph frame
    graphFrame = CreateFrame("ScrollFrame", nil, self)

    graphFrame.anchor = CreateFrame("Frame", nil, self)
    graphFrame:SetScrollChild(graphFrame.anchor)
    graphFrame.anchor:SetSize(100, 100)
    graphFrame.anchor:SetAllPoints(graphFrame)

    graphFrame.bg = graphFrame:CreateTexture(nil, "BACKGROUND")
    graphFrame.bg:SetTexture(0.07, 0.07, 0.07, 1.0)
    graphFrame.bg:SetAllPoints()

    CT.uptimeGraphFrame = graphFrame
    -- CT.uptimeGraphFrame.displayed = {}
    graphFrame.text = {}
  end

  -- do -- Create the dropdown menu button
  --   graphFrame.button = CreateFrame("Button", nil, graphFrame)
  --   button = graphFrame.button
  --   button:SetSize(40, 20)
  --   -- button:SetPoint("TOPRIGHT", graphFrame, -3, -3)
  --   button:SetPoint("TOPRIGHT", graphFrame, "BOTTOMRIGHT", 0, 0)
  --
  --   button.normal = button:CreateTexture(nil, "BACKGROUND")
  --   button.normal:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
  --   button.normal:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
  --   button.normal:SetAllPoints(button)
  --   button:SetNormalTexture(button.normal)
  --
  --   button.highlight = button:CreateTexture(nil, "BACKGROUND")
  --   button.highlight:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
  --   button.highlight:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
  --   button.highlight:SetVertexColor(0.7, 0.7, 0.7, 1.0)
  --   button.highlight:SetAllPoints(button)
  --   button:SetHighlightTexture(button.highlight)
  --
  --   button.disabled = button:CreateTexture(nil, "BACKGROUND")
  --   button.disabled:SetTexture("Interface\\PetBattles\\PetJournal")
  --   button.disabled:SetTexCoord(0.49804688, 0.90625000, 0.12792969, 0.17285156)
  --   button.disabled:SetAllPoints(button)
  --   button:SetDisabledTexture(button.disabled)
  --
  --   button.pushed = button:CreateTexture(nil, "BACKGROUND")
  --   button.pushed:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
  --   button.pushed:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
  --   button.pushed:SetAllPoints(button)
  --   button:SetPushedTexture(button.pushed)
  --
  --   button.title = button:CreateFontString(nil, "ARTWORK")
  --   button.title:SetPoint("CENTER", 0, 0)
  --   button.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
  --   button.title:SetTextColor(0.93, 0.86, 0.01, 1.0)
  --   button.title:SetText("Select")
  --
  --   button:Hide()
  -- end

  do -- Create Graph Borders
    graphFrame.border = {}

    local width, height, anchor1, anchor2, pointX, pointY

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

  do -- Mouseover Line
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

  do -- Highlight Line
    graphFrame.highlightLine = CreateFrame("Frame", nil, graphFrame)
    highlightLine = graphFrame.highlightLine
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

    local setGraph = graphFrame.displayed
    if not setGraph then return end

    local graph = setGraph[1]
    local data = graph.data

    for i = 1, #graph.lines do
      line = graph.lines[i]

      if line and line:GetRight() > mouseX then
        num = i
        break
      end
    end

    if line then
      local timer = ((CT.displayedDB.stop or GetTime()) - CT.displayedDB.start) or 0
      local startX = data[num] or data[#data]
      local stopX = num and data[num + 1] or timer

      if line:GetAlpha() > 0 then -- Handle shown lines
        highlightLine:Show()
        highlightLine:SetAllPoints(line)
        highlightLine:SetAlpha(1)
        text = ("Time: %s%s - %s\n|r%s: %s%.2f"):format(YELLOW, formatTimer(startX), formatTimer(stopX), "Active", YELLOW, stopX - startX)
      else -- Handle hidden lines
        highlightLine:Show()
        highlightLine:SetAllPoints(line)
        highlightLine:SetAlpha(0.3)
        text = ("Time: %s%s - %s\n|rGap: %s%.2f"):format(YELLOW, formatTimer(startX), formatTimer(stopX), YELLOW, stopX - startX)
      end
    end

    if setGraph.flags then
      local flags = setGraph.flags
      num = num or #data

      if flags.spellName and flags.spellName[num] then
        text = text .. "|r\nCast: " .. YELLOW .. flags.spellName[num]
      end

      if flags.unitName and flags.unitName[num] then
        text = text .. "|r\nName: " .. YELLOW .. flags.unitName[num]
      end

      local casts = flags.logCasts and flags.logCasts[num]
      if casts then
        local t = wipe(graphFrame.text) and graphFrame.text

        for timer, spellID in pairs(casts) do
          if timer ~= "start" then
            t[#t + 1] = timer
          end
        end

        if t[1] then
          sort(t, function(a, b)
            if a < b then
              return true
            end
          end)

          for i = 1, #t do
            local time = t[i]
            local name = GetSpellInfo(casts[time]) or "|cFFFF0000UNKNOWN|r"

            t[i] = ("\n(|cFF4B6CD7%s|r) |cFFFFFF00%s|r"):format(formatTimer(time), name)
          end

          local string = "\n\n|cFFFFFFFFCasts while active:|r\n"
          tinsert(t, 1, string)

          text = text .. table.concat(t)
        end
      end
    end

    mouseOver.info = text
  end)

  graphFrame:SetScript("OnEnter", function(self)
    CT.mouseFrameBorder(self.bg)
    mouseOver:Show()
    CT.createInfoTooltip(mouseOver, (self.displayed and self.displayed.name) or "Uptime Graph")
  end)

  graphFrame:SetScript("OnLeave", function(self)
    CT.mouseFrameBorder()
    mouseOver:Hide()
    highlightLine:Hide()
    CT.createInfoTooltip()
  end)

  graphFrame:SetScript("OnMouseUp", function(self, button)
    if GetTime() >= (self.lastClickTime or 0) then
      if button == "LeftButton" then
        if self.popup and self.popup:IsShown() then
          self.popup:Hide()
        end
      elseif button == "RightButton" then
        if not self.popup then
          self.popup = CreateFrame("Frame", nil, self)
          self.popup:SetFrameStrata("HIGH")
          self.popup:SetSize(150, 20)
          self.popup.bg = self.popup:CreateTexture(nil, "BACKGROUND")
          self.popup.bg:SetAllPoints()
          self.popup.bg:SetTexture(0.05, 0.05, 0.05, 1.0)
          self.popup:Hide()

          self.popup:SetScript("OnEnter", function() -- This is just so it doesn't pass the OnEnter to the lower frame. TODO: Better way?

          end)

          self.popup:SetScript("OnShow", function()
            self.popup.exitTime = GetTime() + 1

            if not self.popup.ticker then
              self.popup.ticker = C_Timer.NewTicker(0.1, function(ticker)
                if not MouseIsOver(self.popup) and not MouseIsOver(self) then
                  if GetTime() > self.popup.exitTime then
                    ticker:Cancel()
                    self.popup:Hide()
                    self.popup.ticker = nil
                  end
                else
                  self.popup.exitTime = GetTime() + 1
                end
              end)
            end
          end)
        end

        if self.popup:IsShown() then
          self.popup:Hide()
        else
          addUptimeGraphDropDownButtons(self.popup)

          local mouseX, mouseY = GetCursorPosition()
          local mouseX = (mouseX / UIScale)
          local mouseY = (mouseY / UIScale)

          self.popup:SetPoint("BOTTOMLEFT", UIParent, mouseX + 10, mouseY - (self.popup:GetHeight()))

          self.popup:Show()
        end
      end

      self.lastClickTime = GetTime() + 0.2
    end
  end)

  self.uptimeGraphCreated = true

  return graphFrame
end
--------------------------------------------------------------------------------
-- Normal Graphs
--------------------------------------------------------------------------------
function CT:toggleNormalGraph(command)
  if not CT.graphFrame then return debug("Tried to toggle a graph before graph frame was loaded.", self.name) end

  local frame = CT.graphFrame
  local found = nil
  local dbGraph = CT.displayedDB and CT.displayedDB.graphs[self.name]

  for i = 1, #frame.displayed do
    local graph = frame.displayed[i]
    if graph == self then -- Graph is currently displayed
      found = i
    elseif graph.anchor then -- Reset them all to background
      graph.anchor:SetDrawLayer("BACKGROUND")
    end

    graph.drawLayer = "BACKGROUND"
    if graph.bars then graph.bars.alpha = 0.2 end
  end

  if found or (command and command == "hide") then -- Hide graph
    -- debug("Hiding:", self.name)

    if self.anchor then
      self.anchor:ClearAllPoints()
    end

    tremove(frame.displayed, found) -- Remove it from list
    self.frame = nil
    dbGraph.shown = false

    local lines, bars, triangles = self.lines, self.bars, self.triangles
    for i = 1, #self.data do -- Hide all the lines
      if lines[i] then
        lines[i]:Hide()
      end

      if bars and bars[i] then
        bars[i]:Hide()

        self.status = "hidden"
      end

      if triangles and triangles[i] then
        triangles[i]:Hide()
      end
    end
  elseif not dbGraph.shown and not found or (command and command == "show") then -- Show graph
    -- debug("Showing:", self.name)

    if not self.anchor then
      self.anchor = frame:CreateTexture("CT_Graph_Frame_Anchor_" .. self.name, "OVERLAY")
    end

    tinsert(frame.displayed, 1, self) -- Add it to list
    self.frame = frame
    self.anchor:SetAllPoints(frame.anchor)
    self.anchor:SetDrawLayer("OVERLAY")
    self.drawLayer = "OVERLAY"
    dbGraph.shown = true

    if self.bars then self.bars.alpha = 0.5 end

    if not self.updating then self:refresh(true) end -- Create/update lines
  end

  for index = 1, #frame.displayed do
    local graph = frame.displayed[index]
    local lines, bars, triangles = graph.lines, graph.bars, graph.triangles
    local layer = graph.drawLayer
    local alpha = graph.bars and graph.bars.alpha

    for i = 1, #graph.data do -- Show all the lines
      if lines[i] then
        lines[i]:Show()
        lines[i]:SetDrawLayer(layer)
      end

      if bars and bars[i] then
        bars[i]:Show()
        bars[i]:SetAlpha(alpha)
        bars[i]:SetDrawLayer(layer)

        graph.status = "shown"
      end

      if triangles and triangles[i] then
        triangles[i]:Show()
        triangles[i]:SetAlpha(alpha)
        triangles[i]:SetDrawLayer(layer)
      end
    end
  end
end

-- do -- Coroutine test
--   local frame = CreateFrame("Frame", "TestGraphFrame", UIParent)
--   frame:SetPoint("CENTER")
--   frame:SetSize(1400, 800)
--   frame.bg = frame:CreateTexture("Background", "BACKGROUND")
--   frame.bg:SetTexture(0.1, 0.1, 0.1, 1)
--   frame.bg:SetAllPoints()
--
--   local function refreshNormalGraph(self, reset, routine)
--     local num = #self.data
--     local graphWidth, graphHeight = self.frame:GetSize()
--
--     if not self.frame.zoomed then -- Make sure graph is in bounds, if it isn't zoomed
--       local startX = graphWidth * (self.data[1] - self.XMin) / (self.XMax - self.XMin)
--       local startY = graphHeight * (self.data[-(num - 1)] - self.YMin) / (self.YMax - self.YMin)
--
--       local stopX = graphWidth * (self.data[num] - self.XMin) / (self.XMax - self.XMin)
--       local stopY = graphHeight * (self.data[-num] - self.YMin) / (self.YMax - self.YMin)
--
--       if 0 > startY then -- Graph is too short, raise it
--         self.YMin = (self.YMin + startY) - 20
--         reset = true
--       end
--
--       if stopX > graphWidth then -- Graph is too long, squish it
--         self.XMax = self.XMax + (self.XMax * 0.333) -- 75%
--         reset = true
--       end
--
--       if stopY > graphHeight then -- Graph is too tall, squish it
--         self.YMax = self.YMax + (self.YMax * 0.12) -- 90%
--         reset = true
--       end
--     end
--
--     if reset then
--       self.endNum = 2
--
--       if num > 500 then -- The comparison number is after how many lines do we want to switch to a coroutine (default 500)
--         self.refresh = coroutine.wrap(refreshNormalGraph)
--
--         return self:refresh(nil, true) -- Call it again, but now as a coroutine
--       end
--     end
--
--     if self.fill then -- Make sure the tables exist
--       if not self.bars then self.bars = {} end
--       if not self.triangles then self.triangles = {} end
--     end
--
--     local start = GetTime()
--     local maxX = self.XMax
--     local minX = self.XMin
--     local maxY = self.YMax
--     local minY = self.YMin
--     local data = self.data
--     local lines = self.lines
--     local bars = self.bars
--     local triangles = self.triangles
--     local frame = self.frame
--     local anchor = self.frame.bg or self.frame
--
--     local c1, c2, c3, c4 = 0.0, 0.0, 1.0, 1.0 -- Default to blue
--     if self.color then c1, c2, c3, c4 = self.color[1], self.color[2], self.color[3], self.color[4] end
--
--     for i = self.endNum or 2, num do
--       local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX)
--       local startY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)
--
--       local stopX = graphWidth * (data[i] - minX) / (maxX - minX)
--       local stopY = graphHeight * (data[-i] - minY) / (maxY - minY)
--
--       if startX ~= stopX then -- If they match, this can break
--         -- NOTE: is it if they match and if the y points are the same? Then it would be drawing a point that doesn't take any space
--         local w = 32
--         local dx, dy = stopX - startX, stopY - startY
--         local cx, cy = (startX + stopX) / 2, (startY + stopY) / 2
--
--         if (dx < 0) then -- Normalize direction if necessary
--           dx, dy = -dx, -dy
--         end
--
--         local l = sqrt((dx * dx) + (dy * dy)) -- Calculate actual length of line
--
--         local s, c = -dy / l, dx / l -- Sin and Cosine of rotation, and combination (for later)
--         local sc = s * c
--
--         local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy -- Calculate bounding box size and texture coordinates
--         if dy >= 0 then
--           Bwid = ((l * c) - (w * s)) * TAXIROUTE_LINEFACTOR_2
--           Bhgt = ((w * c) - (l * s)) * TAXIROUTE_LINEFACTOR_2
--           BLx, BLy, BRy = (w / l) * sc, s * s, (l / w) * sc
--           BRx, TLx, TLy, TRx = 1 - BLy, BLy, 1 - BRy, 1 - BLx
--           TRy = BRx
--         else
--           Bwid = ((l * c) + (w * s)) * TAXIROUTE_LINEFACTOR_2
--           Bhgt = ((w * c) + (l * s)) * TAXIROUTE_LINEFACTOR_2
--           BLx, BLy, BRx = s * s, -(l / w) * sc, 1 + (w / l) * sc
--           BRy, TLx, TLy, TRy = BLx, 1 - BRx, 1 - BLx, 1 - BLy
--           TRx = TLy
--         end
--
--         if TLx > 10000 then TLx = 10000 elseif TLx < -10000 then TLx = -10000 end
--         if TLy > 10000 then TLy = 10000 elseif TLy < -10000 then TLy = -10000 end
--         if BLx > 10000 then BLx = 10000 elseif BLx < -10000 then BLx = -10000 end
--         if BLy > 10000 then BLy = 10000 elseif BLy < -10000 then BLy = -10000 end
--         if TRx > 10000 then TRx = 10000 elseif TRx < -10000 then TRx = -10000 end
--         if TRy > 10000 then TRy = 10000 elseif TRy < -10000 then TRy = -10000 end
--         if BRx > 10000 then BRx = 10000 elseif BRx < -10000 then BRx = -10000 end
--         if BRy > 10000 then BRy = 10000 elseif BRy < -10000 then BRy = -10000 end
--
--         local line = lines[i]
--         if not line then
--           lines[i] = frame:CreateTexture("Test_Graph_Line_" .. i, "ARTWORK")
--           line = lines[i]
--           line:SetTexture("Interface\\addons\\CombatTracker\\Media\\line.tga")
--
--           line:SetVertexColor(c1, c2, c3, c4)
--         end
--
--         line:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
--         line:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", cx + Bwid, cy + Bhgt)
--         line:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", cx - Bwid, cy - Bhgt)
--       end
--
--       if bars then
--         if self.fill then -- Draw bars if fill is true
--           if startX > stopX then -- Want startX <= stopX, if not then flip them
--             startX, stopX = stopX, startX
--             startY, stopY = stopY, startY
--           end
--
--           local bar, tri = bars[i], triangles[i]
--           if not bar then
--             bar = frame:CreateTexture(nil, "ARTWORK")
--             tri = frame:CreateTexture(nil, "ARTWORK")
--
--             bar:SetTexture(1, 1, 1, 1)
--             tri:SetTexture("Interface\\Addons\\CombatTracker\\Media\\triangle")
--
--             bar:SetVertexColor(c1, c2, c3, 0.3)
--             tri:SetVertexColor(c1, c2, c3, 0.3)
--
--             bars[i] = bar
--             triangles[i] = tri
--           end
--
--           local minY, maxY
--           if startY < stopY then
--             tri:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
--             minY = startY
--             maxY = stopY
--           else
--             tri:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
--             minY = stopY
--             maxY = startY
--           end
--
--           if 1 > minY then minY = 1 end -- Has to be at least 1 wide
--
--           bar:SetPoint("BOTTOMLEFT", anchor, startX, 0)
--
--           local width = stopX - startX
--           if width < 1 then width = 1 end
--           bar:SetSize(width, minY)
--
--           if (maxY - minY) >= 1 then
--             tri:SetPoint("BOTTOMLEFT", anchor, startX, minY)
--             tri:SetSize(width, maxY - minY)
--             tri:Show()
--           else
--             tri:Hide()
--           end
--
--           if self.status ~= "shown" then -- Make sure they are all visible
--             for i = 1, #bars do
--               bars[i]:Show()
--               tri[i]:Show()
--             end
--           end
--
--           self.status = "shown"
--         elseif self.status and self.status ~= "hidden" then -- Don't fill, so remove the line if they are shown
--           print("Hiding graph filling")
--
--           for i = 1, #bars do
--             bars[i]:Hide()
--             tri[i]:Hide()
--           end
--
--           self.status = "hidden"
--         end
--       end
--
--       if i == num then
--         -- debug("Done running refresh:", GetTime() - start)
--         self.refresh = refreshNormalGraph
--         self.endNum = i
--         self.updating = false
--       elseif routine and (i % 250) == 0 then -- The modulo of i is how many lines it will run before calling back, if it's in a coroutine
--         C_Timer.After(0.03, self.refresh)
--         self.updating = true
--         coroutine.yield()
--       end
--     end
--   end
--
--   local graph = {}
--   do -- Graph setup
--     graph.name = "Test Graph"
--     graph.data = {}
--     graph.lines = {}
--     graph.bars = {}
--     graph.triangles = {}
--     graph.frame = frame
--     graph.XMax = 100
--     graph.XMin = 0
--     graph.YMax = 100
--     graph.YMin = 0
--     graph.endNum = 2
--     graph.fill = true
--     graph.refresh = refreshNormalGraph
--     graph.color = {0.0, 0.0, 1.0, 1.0} -- Blue
--     -- graph.color = {1.0, 0.0, 0.0, 1.0} -- Red
--     -- graph.color = {0.0, 1.0, 0.5, 1.0} -- Green
--   end
--
--   local function generateData(num, command)
--     local gapX = 100 / num
--
--     if command and command == "add" then
--       graph.XMax = graph.XMax + num
--       local dataNum = #graph.data
--
--       for i = dataNum, num + dataNum do
--         local prev = graph.data[-(i - 1)] or random(25, 75)
--
--         graph.data[i] = i * gapX
--         graph.data[-i] = random(prev - 1, prev + 1)
--       end
--     else
--       wipe(graph.data)
--
--       graph.data[1] = 0
--       graph.data[-1] = random(25, 75)
--
--       for i = 2, num do
--         local prev = graph.data[-(i - 1)]
--
--         graph.data[i] = i * gapX
--         graph.data[-i] = random(prev - 3, prev + 3)
--
--         if 0 > graph.data[-i] then
--           graph.data[-i] = 0
--         elseif graph.XMax < graph.data[-i] then
--           graph.data[-i] = graph.XMax
--         end
--       end
--     end
--   end
--
--   local counter = 0
--   local function update(self, elapsed)
--     counter = counter + 1
--
--     if counter % 2 == 0 then
--       generateData(500)
--       graph:refresh(true)
--     else
--       graph:refresh()
--     end
--   end
--
--   graph.data[1] = 0
--   graph.data[-1] = random(25, 75)
--
--   C_Timer.NewTicker(0.1, function(ticker)
--     local i = #graph.data + 1
--
--     local prev = graph.data[-(i - 1)]
--
--     graph.data[i] = i * 1
--     graph.data[-i] = random(prev - 3, prev + 3)
--
--     if not graph.updating then graph:refresh() end
--   end)
-- end

function CT:refreshNormalGraph(reset, routine)
  local num = #self.data
  local graphWidth, graphHeight = self.frame:GetSize()

  if not self.frame.zoomed and num > 1 then -- Make sure graph is in bounds, if it isn't zoomed
    local dbGraph = self.__index

    local startX = graphWidth * (dbGraph.data[1] - dbGraph.XMin) / (dbGraph.XMax - dbGraph.XMin)
    local startY = graphHeight * (dbGraph.data[-(num - 1)] - dbGraph.YMin) / (dbGraph.YMax - dbGraph.YMin)

    local stopX = graphWidth * (dbGraph.data[num] - dbGraph.XMin) / (dbGraph.XMax - dbGraph.XMin)
    local stopY = graphHeight * (dbGraph.data[-num] - dbGraph.YMin) / (dbGraph.YMax - dbGraph.YMin)

    if 0 > startY then -- Graph is too short, raise it
      dbGraph.YMin = (dbGraph.YMin + startY) - 20
      reset = true
    end

    if stopX > graphWidth then -- Graph is too long, squish it
      dbGraph.XMax = dbGraph.XMax + (dbGraph.XMax * 0.333) -- 75%
      reset = true
    end

    if stopY > graphHeight then -- Graph is too tall, squish it
      dbGraph.YMax = dbGraph.YMax + (dbGraph.YMax * 0.12) -- 90%
      reset = true
    end
  end

  if reset then
    self.endNum = 2

    if (self.totalLines or 0) >= 500 then -- The comparison number is after how many lines do we want to switch to a coroutine (default 500)
      self.refresh = wrap(CT.refreshNormalGraph)

      return self:refresh(nil, true) -- Call it again, but now as a coroutine
    end
  end

  if self.fill then -- Make sure the tables exist
    if not self.bars then self.bars = {} end
    if not self.triangles then self.triangles = {} end
  end

  local start = debugprofilestop()
  local maxX = self.XMax
  local minX = self.XMin
  local maxY = self.YMax
  local minY = self.YMin
  local data = self.data
  local lines = self.lines
  local bars = self.bars
  local triangles = self.triangles
  local frame = self.frame.anchor or self.frame
  local anchor = self.anchor or self.frame.anchor or self.frame

  local c1, c2, c3, c4 = 0.0, 0.0, 1.0, 1.0 -- Default to blue
  if self.color then c1, c2, c3, c4 = self.color[1], self.color[2], self.color[3], self.color[4] end

  for i = (self.endNum or 2), num do
    local lastLine

    local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX)
    local startY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)

    local stopX = graphWidth * (data[i] - minX) / (maxX - minX)
    local stopY = graphHeight * (data[-i] - minY) / (maxY - minY)

    local w = 32
    local dx, dy = stopX - startX, stopY - startY -- This is about the change
    local cx, cy = (startX + stopX) / 2, (startY + stopY) / 2 -- This is about the total

    if startX ~= stopX then -- If they match, this can break
      -- NOTE: is it if they match and if the y points are the same? Then it would be drawing a point that doesn't take any space
      local line = lines[i]

      if self.prevDY and dy == self.prevDY then
        local lastIndex

        if lines[i - 1] then
          lastLine = lines[i - 1]
          lastIndex = i - 1
        elseif lines[i - 2] then
          lastLine = lines[i - 2]
          lastIndex = i - 2
        else
          for index = (i - 2), 1, -1 do
            if lines[index] then
              lastIndex = index
              lastLine = lines[index]
              break
            end
          end
        end

        startX = graphWidth * (data[(lastIndex or 2) - 1] - minX) / (maxX - minX)
        line = lastLine or lines[2] -- NOTE: or line
        dx, dy = stopX - startX, stopY - startY
        cx, cy = (startX + stopX) / 2, (startY + stopY) / 2
      end

      if (dx < 0) then -- Normalize direction if necessary
        dx, dy = -dx, -dy
      end

      local l = sqrt((dx * dx) + (dy * dy)) -- Calculate actual length of line

      local s, c = -dy / l, dx / l -- Sin and Cosine of rotation, and combination (for later)
      local sc = s * c

      local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy -- Calculate bounding box size and texture coordinates
      if dy >= 0 then
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

      if not line then
        line = frame:CreateTexture("CT_Graph_Line" .. i, self.drawLayer or "ARTWORK")
        line:SetTexture("Interface\\addons\\CombatTracker\\Media\\line.tga")
        line:SetVertexColor(c1, c2, c3, c4)

        lastLine = line
        self.lastLine = line -- Easy access to most recent
        self.totalLines = (self.totalLines or 0) + 1

        lines[i] = line
      end

      line:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
      line:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", cx + Bwid, cy + Bhgt)
      line:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", cx - Bwid, cy - Bhgt)
    end

    if bars then
      if self.fill then -- and (stopX - startX) > 1 -- Draw bars if fill is true
        if startX > stopX then -- Want startX <= stopX, if not then flip them
          startX, stopX = stopX, startX
          startY, stopY = stopY, startY
        end

        local minY, maxY
        if startY < stopY then
          minY = startY
          maxY = stopY
        else
          minY = stopY
          maxY = startY
        end

        local width = stopX - startX

        if width < 1 then width = 1 end
        if 1 > minY then minY = 1 end -- Has to be at least 1 wide

        do -- Handle the bar
          local bar = bars[i]

          if not bar and (not self.prevDY or dy ~= self.prevDY) then
            bar = frame:CreateTexture("CT_Graph_Frame_Bar_" .. i, self.drawLayer or "ARTWORK")
            bar:SetTexture(1, 1, 1, 1)
            bar:SetVertexColor(c1, c2, c3, bars.alpha or 0.3)
            bar:SetBlendMode("ADD")

            bars.lastBar = bar

            self.totalBars = (self.totalBars or 0) + 1

            bars[i] = bar
          end

          if bar then
            bar:SetPoint("BOTTOMLEFT", anchor, startX, 0)
            bar:SetSize(width, minY)
          end

          if self.prevDY and dy == self.prevDY then
            if bars[i - 1] then
              bars[i - 1]:SetPoint("RIGHT", lastLine, 0, 0)
            else
              for index = (i - 2), 1, -1 do
                if bars[index] then
                  bars[index]:SetPoint("RIGHT", lastLine, 0, 0)
                  break
                end
              end
            end
          elseif bar then
            if bars[i - 1] then
              bars[i - 1]:SetPoint("RIGHT", bar, "LEFT", 0, 0)
            else
              for index = (i - 2), 1, -1 do
                if bars[index] then
                  bars[index]:SetPoint("RIGHT", bar, "LEFT", 0, 0)
                  break
                end
              end
            end
          else
            debug(i, "No bar, but does need to anchor!")
          end
        end

        do -- Handle triangle stuff
          local tri = triangles[i]
          if not tri and (maxY - minY) >= 1 then
            tri = frame:CreateTexture("CT_Graph_Frame_Triangle_" .. i, self.drawLayer or "ARTWORK")
            tri:SetTexture("Interface\\Addons\\CombatTracker\\Media\\triangle")
            tri:SetVertexColor(c1, c2, c3, triangles.alpha or bars.alpha or 0.3)
            tri:SetBlendMode("ADD")

            if startY < stopY then
              tri:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
            else
              tri:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
            end

            self.totalTriangles = (self.totalTriangles or 0) + 1

            triangles[i] = tri
          end

          if tri and (maxY - minY) >= 1 then
            tri:SetPoint("BOTTOMLEFT", anchor, startX, minY)
            tri:SetSize(width, maxY - minY)
            tri:Show()
            -- print("Showing", i)
          elseif tri then
            -- print("Hiding", i)
            tri:Hide()
          else
            -- print("Didn't create one", i)
          end
        end

        if self.status and self.status ~= "shown" then
          debug("Showing graph filling.")
          for i = 1, num do
            if bars[i] then
              bars[i]:Show()
            end

            if triangles[i] then
              triangles[i]:Show()
            end
          end

          self.status = "shown"
        end
      elseif not self.fill and self.status and self.status ~= "hidden" then -- Don't fill, so remove the line if they are shown
        print("Hiding graph filling")

        for i = 1, num do
          if bars[i] then
            bars[i]:Hide()
          end

          if triangles[i] then
            triangles[i]:Hide()
          end
        end

        self.status = "hidden"
      end
    end

    self.prevDY = dy

    if i == num then -- Done running the graph update
      -- debug("Done running refresh:", debugprofilestop() - start)
      self.refresh = CT.refreshNormalGraph
      self.endNum = i + 1
      self.updating = false
      self.lastLine = lastLine or self.lastLine

      -- debug("[DELAY: 5] TOTALS:", self.totalLines or 0, self.totalBars or 0, self.totalTriangles or 0, i)

      if self.frame.zoomed then
        local firstLine, lastLine = nil, nil

        for i = 1, num do
          if self.lines[i] then
            firstLine = self.lines[i]
            break
          end
        end

        for i = num, 1, -1 do
          if self.lines[i] then
            lastLine = self.lines[i]
            break
          end
        end

        local minimum = firstLine:GetLeft() - self.frame:GetLeft()
        local maximum = lastLine:GetRight() - self.frame:GetRight()

        if 0 < minimum then minimum = 0 end
        if 0 > maximum then maximum = 0 end
        self.frame.slider:SetMinMaxValues(minimum, maximum)
        self.frame.slider:SetValue(0)
      end
    elseif routine and (i % 250) == 0 then -- The modulo of i is how many lines it will run before calling back, if it's in a coroutine
      after(0.03, self.refresh)
      self.updating = true
      yield()
    end
  end
end

function CT:refreshNormalGraph_BACKUP_2(reset, routine)
  if self.updating then return debug("Graph update called while still updating, returning") end

  local num = #self.data
  local graphWidth, graphHeight = self.frame:GetSize()

  if not self.frame.zoomed and num > 1 then -- Make sure graph is in bounds, if it isn't zoomed
    local startX = graphWidth * (self.data[1] - self.XMin) / (self.XMax - self.XMin)
    local startY = graphHeight * (self.data[-(num - 1)] - self.YMin) / (self.YMax - self.YMin)

    local stopX = graphWidth * (self.data[num] - self.XMin) / (self.XMax - self.XMin)
    local stopY = graphHeight * (self.data[-num] - self.YMin) / (self.YMax - self.YMin)

    if 0 > startY then -- Graph is too short, raise it
      self.YMin = (self.YMin + startY) - 20
      reset = true
    end

    if stopX > graphWidth then -- Graph is too long, squish it
      self.XMax = self.XMax + (self.XMax * 0.333) -- 75%
      reset = true
    end

    if stopY > graphHeight then -- Graph is too tall, squish it
      self.YMax = self.YMax + (self.YMax * 0.12) -- 90%
      reset = true
    end
  end

  if reset then
    self.endNum = 2

    if self.fill and num > 3000 then -- The cut off for when to stop allowing bars to save textures
      self.fill = false
    end

    if num > 500 then -- The comparison number is after how many lines do we want to switch to a coroutine (default 500)
      self.refresh = wrap(CT.refreshNormalGraph)

      return self:refresh(nil, true) -- Call it again, but now as a coroutine
    end
  end

  if self.fill then -- Make sure the tables exist
    if not self.bars then self.bars = {} end
    if not self.triangles then self.triangles = {} end
  end

  local start = GetTime()
  local maxX = self.XMax
  local minX = self.XMin
  local maxY = self.YMax
  local minY = self.YMin
  local data = self.data
  local lines = self.lines
  local bars = self.bars
  local triangles = self.triangles
  local frame = self.frame.anchor or self.frame
  local anchor = self.frame.bg or self.frame

  local c1, c2, c3, c4 = 0.0, 0.0, 1.0, 1.0 -- Default to blue
  if self.color then c1, c2, c3, c4 = self.color[1], self.color[2], self.color[3], self.color[4] end

  for i = self.endNum or 2, num do
    local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX)
    local startY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)

    local stopX = graphWidth * (data[i] - minX) / (maxX - minX)
    local stopY = graphHeight * (data[-i] - minY) / (maxY - minY)

    if startX ~= stopX then -- If they match, this can break
      -- NOTE: is it if they match and if the y points are the same? Then it would be drawing a point that doesn't take any space
      local w = 32
      local dx, dy = stopX - startX, stopY - startY
      local cx, cy = (startX + stopX) / 2, (startY + stopY) / 2

      if (dx < 0) then -- Normalize direction if necessary
        dx, dy = -dx, -dy
      end

      local l = sqrt((dx * dx) + (dy * dy)) -- Calculate actual length of line

      local s, c = -dy / l, dx / l -- Sin and Cosine of rotation, and combination (for later)
      local sc = s * c

      local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy -- Calculate bounding box size and texture coordinates
      if dy >= 0 then
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

      local line = lines[i]
      if not line then
        line = frame:CreateTexture("CT_Graph_Line" .. i, "ARTWORK")
        line:SetTexture("Interface\\addons\\CombatTracker\\Media\\line.tga")
        line:SetVertexColor(c1, c2, c3, c4)

        self.lastLine = line -- Easy access to most recent
        lines[i] = line
      end

      line:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
      line:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", cx + Bwid, cy + Bhgt)
      line:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", cx - Bwid, cy - Bhgt)
    end

    if bars then
      if self.fill and (stopX - startX) > 1 then -- Draw bars if fill is true
        if startX > stopX then -- Want startX <= stopX, if not then flip them
          startX, stopX = stopX, startX
          startY, stopY = stopY, startY
        end

        local bar, tri = bars[i], triangles[i]
        if not bar then
          bar = frame:CreateTexture(nil, "ARTWORK")
          tri = frame:CreateTexture(nil, "ARTWORK")

          bar:SetTexture(1, 1, 1, 1)
          tri:SetTexture("Interface\\Addons\\CombatTracker\\Media\\triangle")

          bar:SetVertexColor(c1, c2, c3, 0.3)
          tri:SetVertexColor(c1, c2, c3, 0.3)

          bars[i] = bar
          triangles[i] = tri
        end

        local minY, maxY
        if startY < stopY then
          tri:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
          minY = startY
          maxY = stopY
        else
          tri:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
          minY = stopY
          maxY = startY
        end

        if 1 > minY then minY = 1 end -- Has to be at least 1 wide

        bar:SetPoint("BOTTOMLEFT", anchor, startX, 0)

        local width = stopX - startX
        if width < 1 then width = 1 end
        bar:SetSize(width, minY)
        bar:Show()

        if (maxY - minY) >= 1 then
          tri:SetPoint("BOTTOMLEFT", anchor, startX, minY)
          tri:SetSize(width, maxY - minY)
          tri:Show()
        else
          tri:Hide()
        end

        -- if self.status ~= "shown" then -- Make sure they are all visible
        --   for i = 1, #bars do
        --     if bars[i] and triangles[i] then
        --       bars[i]:Show()
        --       triangles[i]:Show()
        --     end
        --   end
        -- end

        self.status = "shown"
      elseif not self.fill and self.status and self.status ~= "hidden" then -- Don't fill, so remove the line if they are shown
        print("Hiding graph filling")

        for i = 1, #bars do
          if bars[i] and triangles[i] then
            bars[i]:Hide()
            triangles[i]:Hide()
          end
        end

        self.status = "hidden"
      elseif bars[i] and triangles[i] then
        bars[i]:Hide()
        triangles[i]:Hide()

        if bars[i - 1] then
          bars[i - 1]:SetWidth(5)
        end
      end
    end

    if i == num then
      -- debug("Done running refresh:", GetTime() - start)
      self.refresh = CT.refreshNormalGraph
      self.endNum = i
      self.updating = false

      if self.frame.zoomed then
        self.frame.slider:SetMinMaxValues(self.lines[4]:GetLeft() - self.frame:GetLeft(), self.lastLine:GetRight() - self.frame:GetRight())
        self.frame.slider:SetValue(0)
      end
    elseif routine and (i % 250) == 0 then -- The modulo of i is how many lines it will run before calling back, if it's in a coroutine
      after(0.03, self.refresh)
      self.updating = true
      yield()
    end
  end
end

function CT:refreshNormalGraph_BACKUP(reset)
  if not self.frame then debug("Tried to refresh graph without a frame set!") return end

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

    if startX ~= stopX then -- If they match, this can break
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
    end

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

function CT.loadDefaultGraphs()
  local set = CT.displayed
  local db = CT.displayedDB
  local success

  if CT.graphFrame then CT.graphFrame:hideAllGraphs() end

  if CT.current and CT.displayed and CT.current ~= CT.displayed then -- If there is an active set that is not displayed, try to mimic its graphs for easy comparisons
    for index, name in ipairs(CT.graphList) do
      local setGraph = set.graphs[name]

      if setGraph and setGraph.shown then
        setGraph:toggle("show")
        success = true
      end
    end

    if success then return end -- Found at least one
  end

  if db and set and db.graphs then -- Didn't find any to mimic, so check if the set has any set to shown
    for graphName, dbGraph in pairs(db.graphs) do
      if dbGraph.shown then
        set.graphs[graphName]:toggle("show")
        success = true
      end
    end

    if success then return end -- Found at least one
  end

  if set and CT.base and CT.base.expander and CT.base.expander.currentButton then -- Didn't find that were previously shown in the displayed set, try to match name
    local name = CT.base.expander.currentButton.name

    if name and set.graphs[name] then -- A button is currently selected, so see if there's a graph with that name
      return set.graphs[name]:toggle("show")
    end
  end

  if set and set.role then -- Still nothing, so load defaults based on spec
    local name

    if set.role == "HEALER" then
      name = "Healing"
    elseif set.role == "DAMAGER" then
      name = "Damage"
    elseif set.role == "TANK" then
      name = "Damage"
    end

    -- name = "Mana" -- NOTE: Testing only
    name = "Holy Power" -- NOTE: Testing only

    if name and set.graphs[name] then
      return set.graphs[name]:toggle("show")
    end
  end

  return debug("Failed to find any graph to load.")
end

local function addGraphDropDownButtons(parent)
  if not parent then return end

  local text
  local graphs = CT.displayed.graphs

  if not parent.title then
    parent.title = parent:CreateFontString(nil, "OVERLAY")
    parent.title:SetPoint("TOP", 0, -1)
    parent.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
    parent.title:SetTextColor(1, 1, 1, 1)
    parent.title:SetText("Line Graphs:")

    parent.height = (parent.height or 0) + 25
  end

  for i, name in ipairs(CT.graphList) do
    local self = graphs[name]

    local b = parent[i]

    if not b then
      parent[i] = CreateFrame("CheckButton", "CT_GraphFrame_Popup_Menu_Button_" .. i, parent)
      b = parent[i]
      b:SetSize(parent:GetWidth() - 5, 20)
      b:SetPoint("TOP", 0, i * -20)
      parent.height = (parent.height or 0) + b:GetHeight()

      do -- Set Textures and Text
        b.normal = b:CreateTexture(nil, "BACKGROUND")
        b.normal:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
        b.normal:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
        b.normal:SetAllPoints(b)
        b:SetNormalTexture(b.normal)

        b.highlight = b:CreateTexture(nil, "BACKGROUND")
        b.highlight:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
        b.highlight:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
        b.highlight:SetVertexColor(0.7, 0.7, 0.7, 1.0)
        b.highlight:SetAllPoints(b)
        b:SetHighlightTexture(b.highlight)

        b.pushed = b:CreateTexture(nil, "BACKGROUND")
        b.pushed:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
        b.pushed:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
        b.pushed:SetAllPoints(b)
        b:SetPushedTexture(b.pushed)

        b.checked = b:CreateTexture(nil, "BACKGROUND")
        b.checked:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
        b.checked:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
        b.checked:SetAllPoints(b)
        b:SetCheckedTexture(b.checked)

        b.disabled = b:CreateTexture(nil, "BACKGROUND")
        b.disabled:SetTexture("Interface\\PetBattles\\PetJournal")
        b.disabled:SetTexCoord(0.49804688, 0.90625000, 0.12792969, 0.17285156)
        b.disabled:SetAllPoints(b)
        b:SetDisabledTexture(b.disabled)

        b.title = b:CreateFontString(nil, "ARTWORK")
        b.title:SetPoint("CENTER", 0, 0)
        b.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
      end

      b:SetScript("OnClick", function(button)
        if button:GetChecked() then -- Show graph
          self:toggle("show")
        else -- Hide graph
          self:toggle("hide")
        end
      end)
    end

    if self.shown then
      parent[i]:SetChecked(true)
    else
      parent[i]:SetChecked(false)
    end

    if self.color then
      b.title:SetTextColor(self.color[1], self.color[2], self.color[3], self.color[4])
    else
      b.title:SetTextColor(0.93, 0.86, 0.01, 1.0)
    end

    b.title:SetText(self.name)

    if self.hideButton and parent[i]:IsShown() then
      parent[i]:Hide()
      parent.height = parent.height - 20
    elseif not parent[i]:IsShown() then
      parent[i]:Show()
      parent.height = (parent.height or 0) + 20
    end
  end

  parent:SetHeight(parent.height or 0)
end

function CT:buildGraph()
  local graph, mouseOver, dot, dragOverlay, slider, button
  local graphHeight = 100
  local graphWidth = 200

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
    graphFrame.hideAllGraphs = function(self)
      for i, graph in ipairs(self.displayed) do
        graph:toggle("hide")
      end
    end
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
    slider:SetPoint("TOPLEFT", graphFrame, 5, -3)
    slider:SetPoint("TOPRIGHT", graphFrame, -5, -3)

    slider:SetBackdrop({
      bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
      edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 8,})
    slider:SetBackdropColor(0.15, 0.15, 0.15, 0)
    slider:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.5)

    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(0, 0)
    slider:SetValue(0)

    slider:SetScript("OnValueChanged", function(self, value)
      graphFrame.anchor:SetSize(graphFrame:GetSize())
      graphFrame:SetHorizontalScroll(value)
    end)

    slider.scrollMultiplier = 5

    if not slider.mouseWheelFunc then
      function slider.mouseWheelFunc(self, value)
        if graphFrame.zoomed then
          local current = slider:GetValue()
          local minimum, maximum = slider:GetMinMaxValues()

          local onePercent = (maximum - minimum) / 100
          local percent = (current - minimum) / (maximum - minimum) * 100

          if value < 0 and current < maximum then
            current = min(maximum, current + (onePercent * slider.scrollMultiplier))
          elseif value > 0 and current > minimum then
            current = max(minimum, current - (onePercent * slider.scrollMultiplier))
          end

          slider:SetValue(current)
        end
      end
    end

    slider:SetScript("OnMouseWheel", slider.mouseWheelFunc)
    graphFrame:SetScript("OnMouseWheel", slider.mouseWheelFunc)
    graphFrame:EnableMouseWheel(false) -- Default to false, but is enabled while zoomed

    slider:Hide()
  end

  local UIScale = UIParent:GetEffectiveScale()
  local YELLOW = "|cFFFFFF00"
  local mouseLines = {}

  -- mouseOver:SetScript("OnUpdate", function(mouseOver, elapsed)
  --   local mouseX, mouseY = GetCursorPosition()
  --   local mouseX = (mouseX / UIScale)
  --   local mouseY = (mouseY / UIScale)
  --   local line, num, text
  --
  --   mouseOver:SetPoint("LEFT", UIParent, mouseX, 0)
  --
  --   if not graphFrame.displayed[1] then return end -- No displayed graphs
  --
  --   local active1 = graphFrame.displayed[1]
  --
  --   local count = 0
  --   local mouseOverCenter = mouseOver:GetCenter()
  --
  --   wipe(mouseLines)
  --   for i = 1, #active1.lines do
  --     line = active1.lines[i]
  --
  --     if line then
  --       if line:GetRight() > mouseX then
  --         if line:GetLeft() < mouseX then
  --           count = count + 1
  --           mouseLines[i] = line
  --         elseif count > 0 then
  --           break
  --         end
  --       end
  --     end
  --   end
  --
  --   local num, line = nearestValue(mouseLines, mouseOverCenter)
  --
  --   if num and active1.data[num] then
  --     local startX = active1.data[num]
  --     local startY = active1.data[-num]
  --
  --     local text = "Time: " .. YELLOW .. formatTimer(startX) .. "|r\n"
  --
  --     for i = 1, #graphFrame.displayed do
  --       local graph = graphFrame.displayed[i]
  --       local startY = graph.data[-num]
  --
  --       graph.displayText[5] = floor(startY)
  --       text = text .. table.concat(graph.displayText)
  --     end
  --
  --     mouseOver.info = text
  --   elseif not num then
  --     mouseOver.info = ""
  --   end
  -- end)

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
    for i = 1, #active1.data do -- Has to be data, lines isn't indexed
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

    if num and active1.data[-num] then -- Handle the dot's position
      local y = graphFrame:GetHeight() * (active1.data[-num] - active1.YMin) / (active1.YMax - active1.YMin)

      dot:Show()
      dot:SetPoint("BOTTOM", mouseOver, 0, y - 5)
    else
      dot:Hide()
    end

    if num and active1.data[num] then
      local startX = active1.data[num]
      local startY = active1.data[-num]

      local timer = (CT.displayedDB.stop or GetTime()) - CT.displayedDB.start
      if active1.frame and active1.frame.zoomed then
        timer = active1.frame.zoomed
      elseif not active1.frame then
        debug("[DELAY: 0.3]", "No frame for", active1.name)
      end

      local current = mouseOverCenter - active1.lines[2]:GetLeft()
      local total = active1.lastLine:GetRight() - active1.lines[2]:GetLeft()

      local displayTimer = floor(timer * (current / total))

      local text = "Time: " .. YELLOW .. formatTimer(displayTimer) .. "|r\n"

      for i = 1, #graphFrame.displayed do
        local graph = graphFrame.displayed[i]
        local startY = graph.data[-num]

        graph.displayText[5] = floor(startY)
        text = text .. table.concat(graph.displayText)
      end

      mouseOver.info = text
    elseif not num then
      mouseOver.info = ""
    end
  end)

  graphFrame:SetScript("OnEnter", function(self)
    CT.mouseFrameBorder(self.bg)

    mouseOver:Show()
    CT.createInfoTooltip(mouseOver, "Graph")
  end)

  graphFrame:SetScript("OnLeave", function(graphFrame)
    CT.mouseFrameBorder()
    mouseOver:Hide()
    CT.createInfoTooltip()
  end)

  graphFrame:SetScript("OnMouseDown", function(self, button)
    if not CT.displayed then return end

    local graphFrame = self

    if button == "LeftButton" and not graphFrame.zoomed then
      if self.popup and self.popup:IsShown() then
        -- Don't hide it here, wait for the OnMouseUp to be consistent, just stop it from drawing the overlay
      else
        local mouseOverLeft = mouseOver:GetLeft() - graphFrame:GetLeft()

        graphFrame.dragOverlay:Show()
        graphFrame.dragOverlay:SetPoint("LEFT", mouseOverLeft, 0)
        graphFrame.dragOverlay:SetPoint("RIGHT", mouseOver, 0, 0)

        graphFrame.mouseOverLeft = mouseOverLeft
      end
    end
  end)

  graphFrame:SetScript("OnMouseUp", function(self, button)
    if not CT.displayed then return end

    local graphFrame = self

    local graphs = CT.displayed.graphs

    if GetTime() >= (self.lastClickTime or 0) then
      if button == "LeftButton" then -- Zooming in
        if not graphFrame.zoomed then
          graphFrame:EnableMouseWheel(true) -- Catch mousewheel while over graph

          if self.popup and self.popup:IsShown() then
            self.popup:Hide()
          else
            local mouseOverRight = mouseOver:GetRight()
            local graphWidth = graphFrame:GetWidth()
            local graphLeft = graphFrame:GetLeft()

            graphFrame.zoomed = (CT.displayedDB.stop or GetTime()) - CT.displayedDB.start
            graphFrame.dragOverlay:Hide()
            graphFrame.slider:Show()

            for i, graph in ipairs(graphFrame.displayed) do
              local dbGraph = graph.__index

              dbGraph.XMin = (graphFrame.mouseOverLeft / graphWidth) * graph.XMax
              dbGraph.XMax = ((mouseOverRight - graphLeft) / graphWidth) * graph.XMax
              if not graph.updating then
                graph:refresh(true)
              else
                debug("Couldn't refresh graph in zoom, it was updating.")
              end
            end
          end
        end
      elseif button == "RightButton" then -- Remove the zoom
        if graphFrame.zoomed then
          graphFrame:EnableMouseWheel(false) -- Stop catching mousewheel, let it work for normal scrolling

          local timer = (CT.displayedDB.stop or GetTime()) - CT.displayedDB.start

          graphFrame.zoomed = false
          graphFrame.dragOverlay:Hide()
          graphFrame.slider:Hide()
          mouseOver.dot:Hide()
          slider:SetValue(0)

          for i, graph in ipairs(graphFrame.displayed) do
            local dbGraph = CT.displayedDB.graphs[graph.name]

            dbGraph.XMin = 0

            if timer > graph.XMax then
              -- graph.XMax = graph.XMax + max(timer - graph.XMax, graph.startX)
              dbGraph.XMax = graph.XMax + (timer - graph.XMax)
            end

            graph:refresh(true)
          end
        else -- Graph is not zoomed in
          if not self.popup then
            self.popup = CreateFrame("Frame", nil, self)
            self.popup:SetFrameStrata("HIGH")
            self.popup:SetSize(150, 20)
            self.popup.bg = self.popup:CreateTexture(nil, "BACKGROUND")
            self.popup.bg:SetAllPoints()
            self.popup.bg:SetTexture(0.1, 0.1, 0.1, 1.0)
            self.popup:Hide()

            self.popup:SetScript("OnEnter", function() -- This is just so it doesn't pass the OnEnter to the lower frame. TODO: Find better way?

            end)

            self.popup:SetScript("OnShow", function()
              self.popup.exitTime = GetTime() + 1

              if not self.popup.ticker then
                self.popup.ticker = C_Timer.NewTicker(0.1, function(ticker)
                  if not MouseIsOver(self.popup) and not MouseIsOver(self) then
                    if GetTime() > self.popup.exitTime then
                      ticker:Cancel()
                      self.popup:Hide()
                      self.popup.ticker = nil
                    end
                  else
                    self.popup.exitTime = GetTime() + 1
                  end
                end)
              end
            end)
          end

          if self.popup:IsShown() then
            self.popup:Hide()
          else
            addGraphDropDownButtons(self.popup)

            local mouseX, mouseY = GetCursorPosition()
            local mouseX = (mouseX / UIScale)
            local mouseY = (mouseY / UIScale)

            self.popup:SetPoint("BOTTOMLEFT", UIParent, mouseX + 10, mouseY - self.popup:GetHeight())

            self.popup:Show()
          end

          self.lastClickTime = GetTime() + 0.2
        end
      end
    end
  end)

  self.graphCreated = true
  return graphFrame
end
