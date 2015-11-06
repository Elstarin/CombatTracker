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

local SetTexCoord, SetPoint, SetTexture, SetVertexColor
      = SetTexCoord, SetPoint, SetTexture, SetVertexColor
local SetPoint, SetSize, SetVertexColor, SetTexCoords, CreateTexture
      = SetPoint, SetSize, SetVertexColor, SetTexCoords, CreateTexture
local debug, colors, GetTime, round, after, newTicker
      = CT.debug, CT.colors, GetTime, CT.round, C_Timer.After, C_Timer.NewTicker
local wrap, yield, after
      = coroutine.wrap, coroutine.yield, C_Timer.After
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

-- NOTE: May want to floor Y points for better filtering
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

  if CT.base and CT.base.shown and CT.base.expander and CT.base.expander.shown then -- These updates should only need to happen if it's actually visible
    if graph.shown and (graph.frame and not graph.frame.zoomed) then -- Refreshing when zoomed makes it look weird, but we still need to let it create data points if it's active
      if not graph.updating then
        graph:refresh()
      end
    end
  end
end

function CT.getGraphUpdateFunc(graph, set, db, name)
  if name == "Healing" then
    local function func(graph, timer)
      local value = (set.healing.total or 0) / timer

      handleGraphData(set, db, graph, graph.data, name, timer, value)
    end

    local color = CT.colors.green
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
      colorString,
      name,
      "|r ",
      "",
      " HPS",
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
      colorString,
      name,
      "|r ",
      "",
      " DPS",
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
      colorString,
      name,
      "|r ",
      "",
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
      colorString,
      name,
      "|r ",
      "",
      " Damage",
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
      colorString,
      name,
      "|r ",
      "",
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
      colorString,
      name,
      "|r: ",
      "",
    }
    
    graph.displayText.math = "/ 20"

    return func, color
  elseif name == "Shadow Orbs" then -- TODO: Set up
    local function func(graph, timer)

    end

    local color = CT.colors.shadowOrbs
    local colorString = CT.convertColor(color[1], color[2], color[3])

    graph.displayText = {
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
    local dbGraph = self.__index or getmetatable(self)

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
          self.popup = CreateFrame("Frame", nil, CT.base)
          self.popup:SetFrameStrata("TOOLTIP")
          self.popup:SetSize(150, 20)
          self.popup.bg = self.popup:CreateTexture(nil, "BACKGROUND")
          self.popup.bg:SetAllPoints()
          self.popup.bg:SetTexture(0.05, 0.05, 0.05, 1.0)
          self.popup:Hide()
          self.popup:EnableMouse(true) -- This is just so it doesn't pass the OnEnter to the lower frame.

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

  return graphFrame
end
--------------------------------------------------------------------------------
-- Normal Graphs
--------------------------------------------------------------------------------
function CT:toggleNormalGraph(command, frame)
  if not CT.graphFrame then return debug("Tried to toggle a graph before graph frame was loaded.", self.name) end

  local frame = frame or CT.graphFrame
  local found = nil
  local dbGraph = self.__index

  for i = 1, #frame.displayed do
    if frame.displayed[i] == self then -- Graph is currently displayed
      found = i -- The index for removal
    end
  end

  if found or (command and command == "hide") then -- Hide graph
    -- debug("Hiding:", self.name)

    tremove(frame.displayed, found) -- Remove it from list
    self.frame = nil
    dbGraph.shown = false

    local lines, bars, triangles = self.lines, self.bars, self.triangles
    for i = 1, #self.data do
      if lines and lines[i] then lines[i]:Hide() end
      if bars and bars[i] then bars[i]:Hide() end
      if triangles and triangles[i] then triangles[i]:Hide() end
    end
  elseif not dbGraph.shown and not found or (command and command == "show") then -- Show graph
    -- debug("Showing:", self.name)

    tinsert(frame.displayed, 1, self) -- Add it to list
    self.frame = frame
    dbGraph.shown = true

    if self.bars then self.bars.alpha = 0.5 end
    
    local lines, bars, triangles = self.lines, self.bars, self.triangles
    for i = 1, #self.data do
      if lines and lines[i] then lines[i]:Show() end
      if bars and bars[i] then bars[i]:Show() end
      if triangles and triangles[i] then triangles[i]:Show() end
    end

    if not self.updating then self:refresh(true) end -- Create/update lines
  end
end

local badPoints = {}
local newData = {}
local criticalPoints = {}
local startPoint, stopPoint
local countSlope = 0
local function filterUselessPoints(data, first, last, tolerance)
  wipe(newData)
  wipe(badPoints)
  wipe(criticalPoints)
  
  for i = first, last do
    if data[i - 1] and data[i + 1] then
      local pX, pY = data[i - 1], data[-(i - 1)] -- Previous
      local cX, cY = data[i], data[-i] -- Current
      local nX, nY = data[i + 1], data[-(i + 1)] -- Next
      
      local prevSlope = (pY - cY) / (pX - cX)
      local nextSlope = (nY - cY) / (nX - cX)
      
      if (prevSlope > 0) and (nextSlope < 0) then -- Peak
        -- criticalPoints[i] = true
      elseif (prevSlope < 0) and (nextSlope > 0) then -- Valley
        -- criticalPoints[i] = true
      else
        badPoints[i] = true -- Flagged for removal
        countSlope = countSlope + 1
      end
    end
  end
  
  for i = first, last do
    if (not badPoints[i]) then -- The point was not flagged to be removed
      local num = #newData + 1
      newData[num] = data[i]
      newData[-num] = data[-i]
    end
  end
  
  debug("Removed", #data - #newData, "out of", #data, "Remaining:", #newData, "Slope count:", countSlope)
  
  for i = first, last do
    if newData[i] then -- Reconstruct the data table
      data[i] = newData[i]
      data[-i] = newData[-i]
    elseif data[i] then -- I assume this is cheaper than calling wipe(data) first, since I'm already doing the loop anyway
      data[i] = nil
      data[-i] = nil
    end
  end
end

local badPoints = {}
local newData = {}
local startPoint, stopPoint
local countSlope = 0
local countNormal = 0
local function smoothingAlgorithm(data, first, last, tolerance, callback)
  -- Credit to Quang Le who wrote what this is originally based on. The source code can be found at:
  -- https://quangnle.wordpress.com/2012/12/30/corona-sdk-curve-fitting-1-implementation-of-ramer-douglas-peucker-algorithm-to-reduce-points-of-a-curve/
  
  if not callback then -- True the first time it is called, not when it calls itself
    wipe(badPoints)
    
    startPoint, stopPoint = first, last -- When it matches these values again, it *should* be done running
  end
  
  local maxD = 0
  local farthestIndex = 0
  
  for i = first, last do
    if not badPoints[i] then
      local x1, y1 = data[i], data[-i]
      local x2, y2 = data[first], data[-first]
      local x3, y3 = data[last], data[-last]
  
      local area = abs(0.5 * ((x2 * y3) + (x3 * y1) + (x1 * y2) - (x3 * y2) - (x1 * y3) - (x2 * y1))) -- Get area of triangle
      local bottom = sqrt((x2 - x3) ^ 2 + (y2 - y3) ^ 2) -- Calculates the length of the bottom edge
      local distance = area / bottom -- This is the triangle's height, which is also the distance found
  
      if distance > maxD then
        maxD = distance
        farthestIndex = i
      end
    end
  end
  
  if maxD > tolerance and farthestIndex ~= 1 then
    if not badPoints[farthestIndex] then
      badPoints[farthestIndex] = true -- Flagged for removal
      countNormal = countNormal + 1
    end
  
    smoothingAlgorithm(data, first, farthestIndex, tolerance, true)
    smoothingAlgorithm(data, farthestIndex, last, tolerance, true)
  end
  
  if first == startPoint and last == stopPoint then -- Should mean it's done running
    wipe(newData)
    
    for i = startPoint, stopPoint do
      if (not badPoints[i]) then -- The point was not flagged to be removed
        local num = #newData + 1
        newData[num] = data[i]
        newData[-num] = data[-i]
      end
    end
    
    debug("Removed", #data - #newData, "out of", #data, "Remaining:", #newData)
    debug("Normal count:", countNormal, "Slope count:", countSlope)
    
    for i = startPoint, stopPoint do
      if newData[i] then -- Reconstruct the data table
        data[i] = newData[i]
        data[-i] = newData[-i]
      elseif data[i] then -- I assume this is cheaper than calling wipe(data) first, since I'm already doing the loop anyway
        data[i] = nil
        data[-i] = nil
      end
    end
  end
end

local badPoints = {}
local newData = {}
local function filteringUselessPoints(data, first, last, maxPoints)
  if 1 > (last - first) then return debug("Cancelling filter!") end -- Don't let it through if it was only called for 1, it will just remove it
  
  wipe(newData)
  wipe(badPoints)
  
  local countSlope = 0
  local countValley = 0
  local countPeak = 0
  local removed = 0
  
  for i = last, first, -1 do
    -- if i == (data.filterStop or 0) then debug("Breaking loop") end
    
    local pX, pY = data[i + 1], data[-(i + 1)] -- Previous
    local cX, cY = data[i], data[-i] -- Current
    local nX, nY = data[i - 1], data[-(i - 1)] -- Next
    
    if pX and nX then
      local prevSlope = (pY - cY) / (pX - cX)
      local nextSlope = (nY - cY) / (nX - cX)
      
      if (prevSlope > 0) and (nextSlope < 0) then -- Peak NOTE: Can error, point can be nil
        badPoints[i] = nil
      elseif (prevSlope < 0) and (nextSlope > 0) then -- Valley
        badPoints[i] = nil
      elseif (prevSlope == nextSlope) then -- Not a peak or valley
        countSlope = countSlope + 1
        badPoints[i] = true -- Flagged for removal
        removed = removed + 1
      else
        local percent = (nextSlope / prevSlope) * 100
        
        if (percent > 99) or (-99 > percent) then
          countSlope = countSlope + 1
          badPoints[i] = true -- Flagged for removal
          removed = removed + 1
        end
      end
    end
  end
  
  local startNum = #data
  
  if removed > 0 then
    for i = first, last do
      if (not badPoints[i]) then -- The point was not flagged to be removed
        local num = #newData + 1
        newData[num] = data[i]
        newData[-num] = data[-i]
      end
    end
    
    local num = first - 1
    for i = 1, #data do
      data[i + num] = newData[i]
      data[-(i + num)] = newData[-i]
    end

    debug("Removed", startNum - #data, "out of", startNum, "Remaining:", #data, "Slope count:", countSlope, "Valley count:", countValley, "Peak count:", countPeak)
    
    if #data > maxPoints then
      -- filteringAlgorithm(data, first, last, maxPoints)
    end
    
    data.filterStop = #data
  else
    debug("Didn't remove any points")
  end
end

local badPoints = {}
local newData = {}
local function filteringAlgorithmNoLoss(data, first, last) -- Filtering points with no accuracy loss
  if 1 > (last - first) then return debug("Cancelling filter!") end -- Don't let it through if it was only called for 1, it will just remove it
  
  wipe(newData)
  wipe(badPoints)
  
  local countSlope = 0
  local countValley = 0
  local countPeak = 0
  local countPercent = 0
  local removed = 0
  
  for i = first, last do
    local pX, pY = data[i - 1], data[-(i - 1)] -- Previous
    local cX, cY = data[i], data[-i] -- Current
    local nX, nY = data[i + 1], data[-(i + 1)] -- Next
    
    if pX and nX then
      local prevSlope = (pY - cY) / (pX - cX)
      local nextSlope = (nY - cY) / (nX - cX)
      local combined = (nY - pY) / (nX - pX)
      if 0 > combined then combined = -combined end
      
      if (prevSlope > 0) and (nextSlope < 0) then -- Peak NOTE: Can error, point can be nil
        badPoints[i] = nil
      elseif (prevSlope < 0) and (nextSlope > 0) then -- Valley
        badPoints[i] = nil
      elseif combined > 0 and 5 > combined then
        countPercent = countPercent + 1
        badPoints[i] = true -- Flagged for removal
        removed = removed + 1
      elseif (prevSlope == nextSlope) then -- Not a peak or valley
        countSlope = countSlope + 1
        removed = removed + 1
        badPoints[i] = true -- Flagged for removal
      else
        -- local percent = 100 - (nextSlope / prevSlope) * 100
        
        local percent = (nextSlope / prevSlope) * 100
        if 0 >= percent then percent = -percent end
        
        if (percent > 99) then
          countPercent = countPercent + 1
          badPoints[i] = true -- Flagged for removal
          removed = removed + 1
        else
          -- print(i, percent)
        end
      end
    end
  end
  
  local startNum = #data
  
  if removed > 0 then
    for i = first, last do
      if (not badPoints[i]) then -- The point was not flagged to be removed
        local num = #newData + 1
        newData[num] = data[i]
        newData[-num] = data[-i]
      end
    end
    
    local num = first - 1
    for i = 1, #data do
      data[i + num] = newData[i]
      data[-(i + num)] = newData[-i]
    end

    local percent = (#data / startNum) * 100 .. "%"
    debug("Removed", percent, "Remaining:", #data, "Slope:", countSlope, "Percent:", countPercent, "Valley:", countValley, "Peak:", countPeak)
    
    data.filterStop = #data
  else
    debug("Didn't remove any points")
  end
end

local badPoints = {}
local newData = {}
local countSlope = 0
local countValley = 0
local countPeak = 0
local countPercent = 0
local safetyNet = 0
local function filteringAlgorithm(data, first, last) -- Filtering points with no accuracy loss
  if 1 > (last - first) then return debug("Cancelling filter!") end -- Don't let it through if it was only called for 1, it will just remove it
  
  wipe(newData)
  wipe(badPoints)
  
  local removed = 0
  
  for i = first, last do
    local pX, pY = data[i - 1], data[-(i - 1)] -- Previous
    local cX, cY = data[i], data[-i] -- Current
    local nX, nY = data[i + 1], data[-(i + 1)] -- Next
    
    if pX and nX then
      local prevSlope = (pY - cY) / (pX - cX)
      local nextSlope = (nY - cY) / (nX - cX)
      
      if (prevSlope > 0) and (nextSlope < 0) then -- Peak
        badPoints[i] = nil
      elseif (prevSlope < 0) and (nextSlope > 0) then -- Valley
        badPoints[i] = nil
      elseif (prevSlope == nextSlope) then -- Not a peak or valley
        countSlope = countSlope + 1
        removed = removed + 1
        badPoints[i] = true -- Flagged for removal
      else
        local percent = (nextSlope / prevSlope) * 100
        if 0 >= percent then percent = -percent end
        
        -- if 0 > combined then combined = -combined end
        -- if 0 > nextSlope then nextSlope = -nextSlope end
        -- if 0 > prevSlope then prevSlope = -prevSlope end
        
        -- local area = abs(0.5 * ((pX * nY) + (nX * cY) + (cX * pY) - (nX * pY) - (cX * nY) - (pX * cY))) -- Get area of triangle
        -- local bottom = sqrt((pX - nX) ^ 2 + (pY - nY) ^ 2) -- Calculates the length of the bottom edge
        -- local distance = area / bottom -- This is the triangle's height, which is also the distance found
        
        -- if 0 > change then change = -change end
        
        local area = pX * (cY - nY) + cX * (nY - pY) + nX * (pY - cY)
        local prevDist = sqrt((cX - pX)^2 + (cY - pY)^2)
        local nextDist = sqrt((nX - cX)^2 + (nY - cY)^2)
        local bottDist = sqrt((nX - pX)^2 + (nY - pY)^2)
        print(i, bottDist)
        
        local total = prevDist + nextDist + bottDist
        local diff = total - ((prevDist + nextDist) - bottDist)
        
        local change = (prevDist + nextDist) - bottDist
        local percent = 100 - ((change / total) * 100)

        if (percent > 97) then
          countPercent = countPercent + 1
          badPoints[i] = true -- Flagged for removal
          removed = removed + 1
        else
          -- print("Keeping", i, percent)
        end
      end
    end
  end
  
  if removed > 0 then
    for i = first, last do
      if (not badPoints[i]) then -- The point was not flagged to be removed
        local num = #newData + 1
        newData[num] = data[i]
        newData[-num] = data[-i]
      end
    end
    
    local num = first - 1
    for i = 1, #data do
      data[i + num] = newData[i]
      data[-(i + num)] = newData[-i]
    end
  end
  
  local startNum = (last - first + 1)
  local percent = ((removed / startNum) * 100)
  
  -- if percent > 5 and (5 > safetyNet) then -- Still too high, try again
  --   debug(percent)
  --   filteringAlgorithm(data, first, last)
  --   safetyNet = safetyNet + 1
  -- else
    debug(percent, "Done.", #data, "remaining. Slope:", countSlope, "Percent:", countPercent, "Valley:", countValley, "Peak:", countPeak)
  --
  --   local countSlope = 0
  --   local countValley = 0
  --   local countPeak = 0
  --   local countPercent = 0
  --   local safetyNet = 0
  -- end
end

local badPoints = {}
local newData = {}
local function filteringAlgorithm(data, first, last)
  if 1 > (last - first) then return debug("Cancelling filter!") end -- Don't let it through if it was only called for 1, it will just remove it
  
  wipe(newData)
  wipe(badPoints)
  
  local removed = 0
  
  for i = first, last do
    local pX, pY = data[i - 1], data[-(i - 1)] -- Previous
    local cX, cY = data[i], data[-i] -- Current
    local nX, nY = data[i + 1], data[-(i + 1)] -- Next
    
    if pX and nX then
      -- local prevSlope = (pY - cY) / (pX - cX)
      local prevSlope = (cY - pY) / (cX - pX)
      local nextSlope = (nY - cY) / (nX - cX)
      -- local nextSlope = (nY - cY) / (nX - cX)
      
      if (prevSlope > 0) and (nextSlope < 0) then -- Peak
        print(i, prevSlope, nextSlope)
        badPoints[i] = nil
      elseif (prevSlope < 0) and (nextSlope > 0) then -- Valley
        badPoints[i] = nil
      elseif (prevSlope == nextSlope) then -- Not a peak or valley
        removed = removed + 1
        badPoints[i] = true -- Flagged for removal
      else
        local angleR = math.atan((prevSlope - nextSlope) / (1 + (prevSlope * nextSlope)))
        local angleD = 180 - math.deg(angleR)
        
        if (angleD > 140) then
          badPoints[i] = true -- Flagged for removal
          removed = removed + 1
        end
        
        -- local prevDist = sqrt((cX - pX)^2 + (cY - pY)^2)
        -- local nextDist = sqrt((nX - cX)^2 + (nY - cY)^2)
        -- local hypotenuse = sqrt((nX - pX)^2 + (nY - pY)^2)
        --
        -- local total = prevDist + nextDist + hypotenuse
        --
        -- local change = (prevDist + nextDist) - hypotenuse
        -- local percent = 100 - ((change / total) * 100)
        --
        -- if (percent > 97) then
        --   badPoints[i] = true -- Flagged for removal
        --   removed = removed + 1
        -- end
      end
    end
  end
  
  if removed > 0 then
    for i = first, last do
      if (not badPoints[i]) then -- The point was not flagged to be removed
        local num = #newData + 1
        newData[num] = data[i]
        newData[-num] = data[-i]
      end
    end
    
    local num = first - 1
    for i = 1, #data do
      data[i + num] = newData[i]
      data[-(i + num)] = newData[-i]
    end
  end
end

if false then -- Backup
  local badPoints = {}
  local newData = {}
  local function filteringAlgorithm(data, first, last, maxPoints)
    if 1 > (last - first) then return debug("Cancelling filter!") end -- Don't let it through if it was only called for 1, it will just remove it
    
    wipe(newData)
    wipe(badPoints)
    
    local countSlope = 0
    local countValley = 0
    local countPeak = 0
    
    -- for i = first, last do
    for i = last, first, -1 do
      if i == (data.filterStop or 0) then debug("Breaking loop") end
      
      -- local pX, pY = data[i - 1], data[-(i - 1)] -- Previous
      -- local cX, cY = data[i], data[-i] -- Current
      -- local nX, nY = data[i + 1], data[-(i + 1)] -- Next
      
      local pX, pY = data[i - 1], data[-(i - 1)] -- Previous
      local cX, cY = data[i], data[-i] -- Current
      local nX, nY = data[i + 1], data[-(i + 1)] -- Next
      
      if pX and nX then
        local prevSlope = (pY - cY) / (pX - cX)
        local nextSlope = (nY - cY) / (nX - cX)
        
        if (prevSlope > 0) and (nextSlope < 0) then -- Peak NOTE: Can error, point can be nil
          badPoints[i] = nil
          local index = i + 1
          
          local pX, pY = data[index - 1], data[-(index - 1)] -- Previous
          local cX, cY = data[index], data[-index] -- Current
          local nX, nY = data[index + 1] or 0, data[-(index + 1)] or 0 -- Next
          
          local prev = (pY - cY) / (pX - cX)
          -- local prev = (nY - cY) / (nX - cX)
          local next = nextSlope
          
          while (prev == next) and (index < last) do -- Run backwards checking which points have the same slope
            if not badPoints[index] then
              badPoints[index] = true -- Flagged for removal
              countPeak = countPeak + 1
            end
            
            local pX, pY = data[index - 1], data[-(index - 1)] -- Previous
            local cX, cY = data[index], data[-index] -- Current
            local nX, nY = data[index + 1], data[-(index + 1)] -- Next
            
            -- prev = (pY - cY) / (pX - cX)
            prev = (nY - cY) / (nX - cX)
            -- next = (nY - cY) / (nX - cX)
          
            -- next = (data[-(index + 1)] - data[-index]) / (data[index + 1] - data[index])
            index = index + 1
          end
        elseif (prevSlope < 0) and (nextSlope > 0) then -- Valley
          badPoints[i] = nil
          --  and (not badPoints[index])
          -- local prev = prevSlope
          -- local index = i - 1
          -- while (prev == prevSlope) and (index > first) do -- Run backwards checking which points have the same slope
          --   if not badPoints[index] then
          --     badPoints[index] = true -- Flagged for removal
          --     countValley = countValley + 1
          --   end
          --
          --   prev = (data[-(index - 1)] - data[-index]) / (data[index - 1] - data[index])
          --   index = index - 1
          -- end
        elseif (prevSlope == nextSlope) then -- Not a peak or valley
          if (prevSlope == nextSlope) then
            if not badPoints[i] then
              countSlope = countSlope + 1
              badPoints[i] = true -- Flagged for removal
            end
          end
        else
          local percent = (nextSlope / prevSlope) * 100
          
          if (percent > 99) or (-99 > percent) then
            if not badPoints[i] then
              countSlope = countSlope + 1
              badPoints[i] = true -- Flagged for removal
            end
          end
        end
      end
    end
    
    local startNum = #data
    
    -- for i = last, first, -1 do
    for i = first, last do
      if (not badPoints[i]) then -- The point was not flagged to be removed
        local num = #newData + 1
        newData[num] = data[i]
        newData[-num] = data[-i]
      end
    end
    
    local num = first - 1
    for i = 1, #data do
      data[i + num] = newData[i]
      data[-(i + num)] = newData[-i]
    end
  
    debug("Removed", startNum - #data, "out of", startNum, "Remaining:", #data, "Slope count:", countSlope, "Valley count:", countValley, "Peak count:", countPeak)
    
    if #data > maxPoints then
      -- filteringAlgorithm(data, first, last, maxPoints)
    end
    
    data.filterStop = #data
  end
  
  local function filteringAlgorithm(data, first, last, maxPoints)
    if 1 > (last - first) then return debug("Cancelling filter!") end -- Don't let it through if it was only called for 1, it will just remove it
    
    wipe(newData)
    wipe(badPoints)
    
    local countSlope = 0
    local countValley = 0
    local countPeak = 0
    
    -- for i = first, last do
    for i = last, first, -1 do
      if i == (data.filterStop or 0) then debug("Breaking loop") end
      
      -- local pX, pY = data[i - 1], data[-(i - 1)] -- Previous
      -- local cX, cY = data[i], data[-i] -- Current
      -- local nX, nY = data[i + 1], data[-(i + 1)] -- Next
      
      local pX, pY = data[i + 1], data[-(i + 1)] -- Previous
      local cX, cY = data[i], data[-i] -- Current
      local nX, nY = data[i - 1], data[-(i - 1)] -- Next
      
      if pX and nX then
        local prevSlope = (pY - cY) / (pX - cX)
        local nextSlope = (nY - cY) / (nX - cX)
        
        if (prevSlope > 0) and (nextSlope < 0) then -- Peak NOTE: Can error, point can be nil
          badPoints[i] = nil
          
          -- local next = prevSlope
          -- local index = i + 1
          -- while (next == nextSlope) and (last > index) do -- Run backwards checking which points have the same slope
          --   if not badPoints[index] then
          --     badPoints[index] = true -- Flagged for removal
          --     countPeak = countPeak + 1
          --   end
          --
          --   next = (data[-(index + 1)] - data[-index]) / (data[index + 1] - data[index])
          --   index = index + 1
          -- end
        elseif (prevSlope < 0) and (nextSlope > 0) then -- Valley
          badPoints[i] = nil
          --  and (not badPoints[index])
          -- local prev = prevSlope
          -- local index = i - 1
          -- while (prev == prevSlope) and (index > first) do -- Run backwards checking which points have the same slope
          --   if not badPoints[index] then
          --     badPoints[index] = true -- Flagged for removal
          --     countValley = countValley + 1
          --   end
          --
          --   prev = (data[-(index - 1)] - data[-index]) / (data[index - 1] - data[index])
          --   index = index - 1
          -- end
        elseif (prevSlope == nextSlope) then -- Not a peak or valley
          if not badPoints[i] then
            countSlope = countSlope + 1
            badPoints[i] = true -- Flagged for removal
          end
        else
          local percent = (nextSlope / prevSlope) * 100
          
          if (percent > 99) or (-99 > percent) then
            if not badPoints[i] then
              countSlope = countSlope + 1
              badPoints[i] = true -- Flagged for removal
            end
          end
        end
      end
    end
    
    local startNum = #data
    
    -- for i = last, first, -1 do
    for i = first, last do
      if (not badPoints[i]) then -- The point was not flagged to be removed
        local num = #newData + 1
        newData[num] = data[i]
        newData[-num] = data[-i]
      end
    end
    
    local num = first - 1
    for i = 1, #data do
      data[i + num] = newData[i]
      data[-(i + num)] = newData[-i]
    end
  
    debug("Removed", startNum - #data, "out of", startNum, "Remaining:", #data, "Slope count:", countSlope, "Valley count:", countValley, "Peak count:", countPeak)
    
    if #data > maxPoints then
      -- filteringAlgorithm(data, first, last, maxPoints)
    end
    
    data.filterStop = #data
  end
  
  badPoints[i] = nil
  --  and (not badPoints[index])
  local prev = prevSlope
  local index = i - 1
  while (prev == prevSlope) and (index > first) do -- Run backwards checking which points have the same slope
    if not badPoints[index] then
      badPoints[index] = true -- Flagged for removal
      countValley = countValley + 1
    end
    
    prev = (data[-(index - 1)] - data[-index]) / (data[index - 1] - data[index])
    index = index - 1
  end
end

if false then -- Coroutine test
  local frame = CreateFrame("Frame", "TestGraphFrame", UIParent)
  do -- Set up frame
    frame:SetPoint("CENTER", 0, 100)
    frame:SetSize(1400, 600)
    -- frame:SetSize(1200, 800)
    frame.bg = frame:CreateTexture("Background", "BACKGROUND")
    frame.bg:SetTexture(0.1, 0.1, 0.1, 1)
    frame.bg:SetAllPoints()
  end

  local function refreshNormalGraph(self, reset, routine, offSet)
    local num = #self.data
    if self.endNum > num then error("self.endNum > num!") num = self.endNum end

    local graphWidth, graphHeight = self.frame:GetSize()

    local stopX = graphWidth * (self.data[num] - self.XMin) / (self.XMax - self.XMin)
    if stopX > graphWidth then -- Graph is too long, squish it
      self.XMax = self.XMax * (stopX / graphWidth) * 1.05
      -- self.XMax = maxX * (blockedX / graphWidth) * 1.333 -- 75%
      reset = true
    end

    if reset then
      self.endNum = 2

      if num > (1000) then -- The comparison number is after how many points do we want to switch to a coroutine (default 2000)
        self.refresh = wrap(refreshNormalGraph)

        return self:refresh(nil, true, offSet) -- Call it again, but now as a coroutine
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
    local zoomed = self.frame.zoomed
    local blocked, blockedY = nil, 0, 0

    local c1, c2, c3, c4 = 0.0, 0.0, 1.0, 1.0 -- Default to blue
    if self.color then c1, c2, c3, c4 = self.color[1], self.color[2], self.color[3], self.overrideAlpha or self.color[4] end

    -- if self.endNum ~= 2 and self.endNum > num then -- Generally, this should mean it was called without adding new data points from last time, redraw the last line
    --   local startX = graphWidth * (data[num - 1] - minX) / (maxX - minX)
    --   local startY = graphHeight * (data[-(num - 1)] - minY) / (maxY - minY)
    --
    --   local stopX = graphWidth * (data[num] - minX) / (maxX - minX)
    --   local stopY = graphHeight * (data[-num] - minY) / (maxY - minY)
    --
    --   local lastIndex, lastLine = nil, nil
    --
    --   for i = num, 2, -1 do -- Find most recent line, searching backwards
    --     if lines[i] then
    --       lastIndex = i
    --       lastLine = lines[i]
    --       break
    --     end
    --   end
    --
    --   return debug("Greater, returning")
    -- end

    -- if not reset and self.totalLines and self.totalLines > (self.lastSmoothing or 0) and (self.totalLines % 30) == 0 then -- and (self.endNum % 30) == 0
    --   local difference = (num - self.endNum)
    --
    --   local v1, v2, v3 = smoothingAlgorithm(self, self.data, max(num - 50, 1), num, 0.1)
    --
    --   num = #self.data
    --   self.lastSmoothing = self.totalLines
    --   -- self.endNum = num - difference
    -- end

    for i = (self.endNum or 2), num do
      local stopY = graphHeight * ((data[-i] + offSet) - minY) / (maxY - minY)

      if not zoomed then -- Update maxX and maxY values if necessary, just not while zoomed
        if stopY > graphHeight then -- Graph is too tall
          blocked = true

          if (stopY / graphHeight) > blockedY then
            blockedY = stopY
          end
        end
      end

      if not blocked then -- If out of bounds, finish looping to find the most out of bounds point, but don't waste time calculating everything
        local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX) -- Start isn't needed for bounds check
        local startY = graphHeight * ((data[-(i - 1)] + offSet) - minY) / (maxY - minY)

        local stopX = graphWidth * (data[i] - minX) / (maxX - minX)

        local lastLine
        local line = lines[i]
        local w = 32
        local dx, dy = stopX - startX, stopY - startY -- This is about the change
        local cx, cy = (startX + stopX) / 2, (startY + stopY) / 2 -- This is about the total

        if (dx < 0) then -- Normalize direction if necessary
          dx, dy = -dx, -dy
        end

        local l = sqrt((dx * dx) + (dy * dy)) -- Calculate actual length of line

        if (startX == stopX) and (startY == stopY) then
          debug(i, "Tried to draw point that takes no space!", self.name)
        end

        if startX ~= stopX then -- If they match, this can break
          local s, c = -dy / l, dx / l -- Sin and Cosine of rotation, and combination (for later)
          local sc = s * c

          if (i > 2) and self.lastLine then -- Without this, it can fall into an infinite loop
            local passed = nil

            do -- Check if any smoothing should be applied
              local diffDX = dx - (self.lastDX or 0)
              if 0 > diffDX then diffDX = -diffDX end

              local diffDY = dy - (self.lastDY or 0)
              if 0 > diffDY then diffDY = -diffDY end

              local diffS = s - (self.lastSine or 0)
              if 0 > diffS then diffS = -diffS end

              local level = self.smoothingOverride or CT.settings.graphSmoothing -- How much smoothing should happen, 0 to mostly disable
              local level = 10

              if not level or level == 0 then -- Smoothing disabled, only do horizontal and vertical lines. This usually uses about 70% - 80% of the points, but can vary a ton
                if (diffDX == 0) or (diffDY == 0) then
                  passed = true
                end
              elseif level == 1 then -- Very little smoothing, this will probably gradually increase the number of textures, roughly uses around 50% of the points
                if (0 >= diffDX) or (0 >= diffDY) or (diffS > 0.999) or (0.001 > diffS) then
                  passed = true
                end
              elseif level == 2 then -- Medium, should be default, this tries to maintain a somewhat steady amount of textures, roughly around 400 - 600
                if (0.001 > diffDX) or (0.001 > diffDY) or (diffS > 0.99) or (0.01 > diffS) then
                  passed = true
                end
              elseif level == 3 then -- Lots of smoothing, roughly around 200 - 300 textures most of the time
                if (0.01 > diffDX) or (0.01 > diffDY) or (diffS > 0.95) or (0.05 > diffS) then
                  passed = true
                end
              elseif level == 4 then -- Probably too much smoothing, roughly around 140 - 200 textures
                if (0.1 > diffDX) or (0.1 > diffDY) or (diffS > 0.9) or (0.1 > diffS) then
                  passed = true
                end
              elseif level == 5 then -- Complete overkill, but whatever, it's usually less than 100 textures
                if (0.2 > diffDX) or (0.2 > diffDY) or (diffS > 0.8) or (0.2 > diffS) then
                  passed = true
                end
              end -- If you want to 100% disable smoothing, set the level higher than 5. I can't think of any reason to not extend straight lines though.
            end

            if passed then
              if line then -- If a line exists, recycle it to be used later, instead of throwing it away and creating a new one
                self.recycling[#self.recycling + 1] = line
                line:ClearAllPoints()
                line:Hide()
                lines[i] = nil
              end

              local index = i - 1
              while not lines[index] and (index > 0) do -- Find the most recent line
                index = index - 1
              end

              line = lines[index] -- Now this is used, instead of creating a brand new one

              startX = graphWidth * ((data[index - 1] + offSet) - minX) / (maxX - minX)
              startY = graphHeight * ((data[-(i - 1)] + offSet) - minY) / (maxY - minY)

              dx, dy = stopX - startX, stopY - startY -- Redo all these calculations with the new start points
              cx, cy = (startX + stopX) / 2, (startY + stopY) / 2

              if (dx < 0) then
                dx, dy = -dx, -dy
              end

              l = sqrt((dx * dx) + (dy * dy))

              s, c = -dy / l, dx / l
              sc = s * c
            end
          end

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

          if not line then
            if self.recycling[1] then -- First try to recycle an old line, if it has at least one
              line = tremove(self.recycling) -- Take the last one
              line:Show()
            else -- Nothing to recycle, create a new one
              local name = format("CT_%s_Graph_Line_%d", self.name:gsub("%s", "_"), i)
              line = frame:CreateTexture(name, (self.drawLayer or "ARTWORK"))
              line:SetTexture("Interface\\addons\\CombatTracker\\Media\\line.tga")
              self.totalLines = (self.totalLines or 0) + 1
            end

            line:SetVertexColor(c1, c2, c3, c4)

            lastLine = line
            self.lastIndex = i
            self.lastLine = line -- Easy access to most recent

            lines[i] = line
          end

          self.lastSine = s
          self.lastDX = dx
          self.lastDY = dy

          line:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
          line:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", cx + Bwid, cy + Bhgt)
          line:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", cx - Bwid, cy - Bhgt)
        end

        if bars then
          if self.fill then -- Draw bars if fill is true
            -- local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX) -- Start isn't needed for bounds check
            -- local startY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)
            --
            -- local stopX = graphWidth * (data[i] - minX) / (maxX - minX)
            -- local stopY = graphHeight * (data[-i] - minY) / (maxY - minY)

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

            local bar = bars[i]

            do -- Handle the bar
              if (i > 2) and (self.prevDY and dy == self.prevDY) then --  or (3 > width)
                if bar then -- If a bar exists, recycle it to be used later, instead of throwing it away and creating a new one
                  if not self.barRecycling then self.barRecycling = {} end

                  self.barRecycling[#self.barRecycling + 1] = bar
                  bar:ClearAllPoints()
                  bar:Hide()
                  bars[i] = nil
                end

                local index = i - 1
                while not bars[index] and (index > 0) do -- Find the most recent bar
                  index = index - 1
                end

                bar = bars[index] -- Now this is used, instead of creating a brand new one
              end

              if not bar then
                if self.barRecycling and self.barRecycling[1] then -- First try to recycle an old bar, if it has at least one
                  bar = tremove(self.barRecycling) -- Take the last one
                  bar:Show()
                else -- Nothing to recycle, create a new one
                  bar = frame:CreateTexture("CT_Graph_Frame_Bar_" .. i, self.drawLayer or "ARTWORK")
                  bar:SetTexture(1, 1, 1, 1)
                  bar:SetVertexColor(c1, c2, c3, bars.alpha or 0.3)
                  -- bar:SetBlendMode("ADD")

                  self.totalBars = (self.totalBars or 0) + 1
                end

                bars.lastBar = bar

                bars[i] = bar
              end

              if bar then
                -- bar:ClearAllPoints()
                bar:SetPoint("BOTTOMLEFT", anchor, startX, 0)
                bar:SetSize(width, minY)
              end

              if self.prevDY and (dy == self.prevDY) then -- Same height as before
                if bar then
                  -- debug("First")
                  bar:SetPoint("RIGHT", line, 0, 0)
                else
                  debug("Second")
                  local index = i - 1
                  while not bars[index] and (index > 0) do -- Find the most recent bar
                    index = index - 1
                  end

                  bar = bars[index] -- Now this is used, instead of creating a brand new one

                  if bar then
                    bar:SetPoint("RIGHT", line, 0, 0)
                  end
                end
              elseif bar then
                local index = i - 1
                local prevBar = bars[index]
                while ((not prevBar) or (prevBar == bar)) and (index > 0) do -- Find the most recent bar
                  index = index - 1
                  prevBar = bars[index]
                end

                if prevBar then
                  prevBar:SetPoint("RIGHT", bar, "LEFT", 0, 0)
                end
              else
                debug(i, "No bar, but does need to anchor!")
              end
            end

            --   if self.prevDY and dy == self.prevDY then
            --     if bars[i - 1] then
            --       bars[i - 1]:SetPoint("RIGHT", lastLine, 0, 0)
            --     else
            --       for index = (i - 2), 1, -1 do
            --         if bars[index] then
            --           bars[index]:SetPoint("RIGHT", lastLine, 0, 0)
            --           break
            --         end
            --       end
            --     end
            --   elseif bar then
            --     local index = i - 1
            --     local prevBar = bars[index]
            --     while ((not prevBar) or (prevBar == bar)) and (index > 0) do -- Find the most recent bar
            --       index = index - 1
            --       prevBar = bars[index]
            --     end
            --
            --     if prevBar then
            --       prevBar:SetPoint("RIGHT", bar, "LEFT", 0, 0)
            --     end
            --
            --     -- if bars[i - 1] then
            --     --   bars[i - 1]:SetPoint("RIGHT", bar, "LEFT", 0, 0)
            --     -- else
            --     --   for index = (i - 2), 1, -1 do
            --     --     if bars[index] then
            --     --       bars[index]:SetPoint("RIGHT", bar, "LEFT", 0, 0)
            --     --       break
            --     --     end
            --     --   end
            --     -- end
            --   else
            --     debug(i, "No bar, but does need to anchor!")
            --   end

            do -- Handle triangle stuff
              -- local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX) -- Start isn't needed for bounds check
              -- local startY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)
              --
              -- local stopX = graphWidth * (data[i] - minX) / (maxX - minX)
              -- local stopY = graphHeight * (data[-i] - minY) / (maxY - minY)

              if bar then
                local tri = triangles[i]
                if not tri and (maxY - minY) >= 1 then
                  tri = frame:CreateTexture("CT_Graph_Frame_Triangle_" .. i, self.drawLayer or "ARTWORK")
                  tri:SetTexture("Interface\\Addons\\CombatTracker\\Media\\triangle")
                  tri:SetVertexColor(c1, c2, c3, triangles.alpha or bars.alpha or 0.3)
                  -- tri:SetBlendMode("ADD")

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
          if routine then
            self.refresh = refreshNormalGraph
            self.updating = false
          end

          if reset or routine then
            local runTime = floor((debugprofilestop() - start) * 1000 + 0.5) / 1000
            local percent = floor(((self.totalLines or 0) / num) * 100)  .. "%"

            if routine then
              debug(percent, num, self.totalLines, #self.recycling, "Done refreshing (coroutine):", self.name, runTime, "MS")
            else
              debug(percent, num, self.totalLines, #self.recycling, "Done refreshing:", self.name, runTime, "MS")
            end
          end

          self.endNum = i + 1
          self.lastLine = lastLine or self.lastLine

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
        elseif routine and (i % 500) == 0 then -- The modulo of i is how many lines it will run before calling back, if it's in a coroutine
          local delay = random(-3, 3) / 100 + 0.05 -- The random number is to reduce the chances of multiple graphs refreshing at the exact same time
          after(delay, self.refresh)
          self.updating = true
          yield()
        end
      elseif blocked and i == num then -- It's done
        if routine then
          self.refresh = refreshNormalGraph
          self.updating = false
        end

        if blockedY > 0 then
          self.YMax = maxY * (blockedY / graphHeight) * 1.12 -- 90%
        end

        return self:refresh(true, nil, offSet) -- Run again with the new Y value
      end
    end
  end

  local graphs = {}

  local function createGraph(name, color)
    local graph = {}
    graph.name = name or "Test Graph"
    graph.data = {}
    graph.lines = {}
    graph.bars = {}
    graph.triangles = {}
    graph.recycling = {}
    graph.frame = frame
    graph.XMax = 10
    graph.XMin = 0
    graph.YMax = 100
    graph.YMin = 0
    graph.endNum = 2
    graph.fill = false
    graph.refresh = refreshNormalGraph
    graph.color = color or {0.0, 0.0, 1.0, 1.0} -- Blue
    graph.shown = true
    -- graph.color = {1.0, 0.0, 0.0, 1.0} -- Red
    -- graph.color = {0.0, 1.0, 0.5, 1.0} -- Green

    graphs[#graphs + 1] = graph

    return graph
  end

  local speed = 0.01
  
  local function createData(numPoints, variation, seed)
    local start, stop = 1, numPoints
    for index = 1, #graphs do
      if #graphs[index].data > start then
        start = #graphs[index].data + 1
        stop = start + stop - 1
      end
    end
    
    local prev = graphs[2].data[-(start - 1)] or seed or random(25, 75)
    for i = start, stop do
      local rNum = random(1, 3)
      if rNum == 3 then -- This is just so I can have the variation be a decimal, since random doesn't work with decimals
        y = prev + variation
      elseif rNum == 2 then
        y = prev
      else
        y = prev - variation
      end
      
      -- local var = random(-100, 100) / 100
      -- y = y + var
      -- local var = random(-100, 100) / 100
      -- y = y - var
      
      if 20 > y then y = 20 end
      if y > 80 then y = 80 end
      
      y = floor(y * 100) / 100

      for index = 1, #graphs do
        local data = graphs[index].data
        local num = #data + 1

        data[num] = i * 0.1
        data[-num] = y
      end
      
      prev = y
    end

    return data
  end
  
  createGraph("Test_Graph_1") -- {0.5, 0.5, 0.5, 1.0}
  createGraph("Test_Graph_2", {0.5, 0.5, 0.5, 1.0})
  -- createGraph("Test_Graph_3", {0.0, 1.0, 0.5, 1.0})

  createData(2000, 0.4)
  filteringAlgorithm(graphs[1].data, 1, #graphs[1].data, 1000)
  filteringAlgorithm(graphs[1].data, 1, #graphs[1].data, 1000)
  
  -- createData(1000, 0.5)
  -- debug("Second filter...")
  -- filteringAlgorithm(graphs[1].data, 1, #graphs[1].data, 1000)
  -- filteringAlgorithm(graphs[2].data, 1, #graphs[2].data)
  
  graphs[1]:refresh(nil, nil, 5)
  graphs[2]:refresh(nil, nil, 0)
  -- graphs[3]:refresh(nil, nil, -5)

  -- local start = GetTime() - (#graph.data * speed)
  --
  -- C_Timer.NewTicker(speed, function(ticker)
  --   local timer = GetTime() - start
  --
  --   local i = #graph.data + 1
  --
  --   local prev = graph.data[-(i - 1)] or 0
  --   if not prev then debug("No prev data!") end
  --   local y = random(prev - variation, prev + variation)
  --   if 0 >= y then y = 0 end
  --   if graph2 then
  --     if y > 80 then y = 80 end
  --   else
  --     if y > 100 then y = 100 end
  --   end
  --
  --   graph.data[i] = timer
  --   graph.data[-i] = y
  --   if graph2 then
  --     graph2.data[1] = timer
  --     graph2.data[-1] = y + 20
  --   end
  --
  --   if not graph.updating then graph:refresh() end
  --   if graph2 and not graph2.updating then graph2:refresh() end
  -- end)
end

function CT:refreshNormalGraph(reset, routine)
  if not CT.base.shown then return debug("Refresh got called when base was hidden!", self.name) end
  if not CT.base.expander then return debug("Refresh got called before the expander was created!", self.name) end
  if not CT.base.expander.shown then return debug("Refresh got called when the expander was not flagged as shown!", self.name) end
  if not self.shown then return debug("Refresh got called when graph was not flagged as shown!", self.name) end
  if not self.frame then return debug("Refresh got called when graph had no frame!", self.name) end -- Happened once, was related to loading a saved fight or returning from one
  if self.updating then return debug("Refresh got called when graph was flagged as updating!", self.name) end
  
  if not self.recycling then self.recycling = {} end

  local num = #self.data
  if 0 >= num then return end
  
  local graphWidth, graphHeight = self.frame:GetSize()
  local dbGraph = self.__index

  local stopX = graphWidth * ((dbGraph.data[num] - dbGraph.XMin) / (dbGraph.XMax - dbGraph.XMin))
  if dbGraph and stopX > graphWidth then -- Graph is too long, squish it
    -- dbGraph.XMax = dbGraph.XMax * (stopX / graphWidth) * 1.1
    dbGraph.XMax = dbGraph.XMax * (stopX / graphWidth) * 1.25 -- 75%
    reset = true
  end

  if reset then
    self.endNum = 2

    if num >= (1000) then -- The comparison number is after how many points do we want to switch to a coroutine (default 2000)
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
  local zoomed = self.frame.zoomed
  local blocked, blockedY = nil, 0, 0

  local c1, c2, c3, c4 = 0.0, 0.0, 1.0, 1.0 -- Default to blue
  if self.color then c1, c2, c3, c4 = self.color[1], self.color[2], self.color[3], self.overrideAlpha or self.color[4] end

  -- if self.endNum ~= 2 and self.endNum > num then -- Generally, this should mean it was called without adding new data points from last time, redraw the last line
  --   local startX = graphWidth * (data[num - 1] - minX) / (maxX - minX)
  --   local startY = graphHeight * (data[-(num - 1)] - minY) / (maxY - minY)
  --
  --   local stopX = graphWidth * (data[num] - minX) / (maxX - minX)
  --   local stopY = graphHeight * (data[-num] - minY) / (maxY - minY)
  --
  --   local lastIndex, lastLine = nil, nil
  --
  --   for i = num, 2, -1 do -- Find most recent line, searching backwards
  --     if lines[i] then
  --       lastIndex = i
  --       lastLine = lines[i]
  --       break
  --     end
  --   end
  --
  --   return debug("Greater, returning")
  -- end

  -- if not reset and self.totalLines and self.totalLines > (self.lastSmoothing or 0) and (self.totalLines % 30) == 0 then -- and (self.endNum % 30) == 0
  --   local difference = (num - self.endNum)
  --
  --   local v1, v2, v3 = smoothingAlgorithm(self, self.data, max(num - 50, 1), num, 0.1)
  --
  --   num = #self.data
  --   self.lastSmoothing = self.totalLines
  --   -- self.endNum = num - difference
  -- end

  for i = (self.endNum or 2), num do
    local stopY = graphHeight * (data[-i] - minY) / (maxY - minY)

    if not zoomed then -- Update maxX and maxY values if necessary, just not while zoomed
      if stopY > graphHeight then -- Graph is too tall
        blocked = true

        if (stopY / graphHeight) > blockedY then
          blockedY = stopY
        end
      end
    end

    if not blocked then -- If out of bounds, finish looping to find the most out of bounds point, but don't waste time calculating everything
      local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX) -- Start isn't needed for bounds check
      local startY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)

      local stopX = graphWidth * (data[i] - minX) / (maxX - minX)

      local lastLine
      local line = lines[i]
      local w = 32
      local dx, dy = stopX - startX, stopY - startY -- This is about the change
      local cx, cy = (startX + stopX) / 2, (startY + stopY) / 2 -- This is about the total

      if (dx < 0) then -- Normalize direction if necessary
        dx, dy = -dx, -dy
      end

      local l = sqrt((dx * dx) + (dy * dy)) -- Calculate actual length of line

      if (startX == stopX) and (startY == stopY) then
        debug("Tried to draw point that takes no space!")
      end

      if startX ~= stopX then -- If they match, this can break
        local s, c = -dy / l, dx / l -- Sin and Cosine of rotation, and combination (for later)
        local sc = s * c

        if (i > 2) and self.lastLine then -- Without this, it can fall into an infinite loop
          local passed = nil

          do -- Check if any smoothing should be applied
            local diffDX = dx - (self.lastDX or 0)
            if 0 > diffDX then diffDX = -diffDX end

            local diffDY = dy - (self.lastDY or 0)
            if 0 > diffDY then diffDY = -diffDY end

            local diffS = s - (self.lastSine or 0)
            if 0 > diffS then diffS = -diffS end

            local level = self.smoothingOverride or CT.settings.graphSmoothing -- How much smoothing should happen, 0 to mostly disable

            if not level or level == 0 then -- Smoothing disabled, only do horizontal and vertical lines. This usually uses about 70% - 80% of the points, but can vary a ton
              if (diffDX == 0) or (diffDY == 0) then
                passed = true
              end
            elseif level == 1 then -- Very little smoothing, this will probably gradually increase the number of textures, roughly uses around 50% of the points
              if (0 >= diffDX) or (0 >= diffDY) or (diffS > 0.999) or (0.001 > diffS) then
                passed = true
              end
            elseif level == 2 then -- Medium, should be default, this tries to maintain a somewhat steady amount of textures, roughly around 400 - 600
              if (0.001 > diffDX) or (0.001 > diffDY) or (diffS > 0.99) or (0.01 > diffS) then
                passed = true
              end
            elseif level == 3 then -- Lots of smoothing, roughly around 200 - 300 textures most of the time
              if (0.01 > diffDX) or (0.01 > diffDY) or (diffS > 0.95) or (0.05 > diffS) then
                passed = true
              end
            elseif level == 4 then -- Probably too much smoothing, roughly around 140 - 200 textures
              if (0.1 > diffDX) or (0.1 > diffDY) or (diffS > 0.9) or (0.1 > diffS) then
                passed = true
              end
            elseif level == 5 then -- Complete overkill, but whatever, it's usually less than 100 textures
              if (0.2 > diffDX) or (0.2 > diffDY) or (diffS > 0.8) or (0.2 > diffS) then
                passed = true
              end
            end -- If you want to 100% disable smoothing, set the level higher than 5. I can't think of any reason to not extend straight lines though.
          end

          if passed then
            if line then -- If a line exists, recycle it to be used later, instead of throwing it away and creating a new one
              self.recycling[#self.recycling + 1] = line
              line:ClearAllPoints()
              line:Hide()
              lines[i] = nil
            end

            local index = i - 1
            while not lines[index] and (index > 0) do -- Find the most recent line
              index = index - 1
            end

            line = lines[index] -- Now this is used, instead of creating a brand new one

            startX = graphWidth * (data[index - 1] - minX) / (maxX - minX)
            startY = graphHeight * (data[-(index - 1)] - minY) / (maxY - minY)

            dx, dy = stopX - startX, stopY - startY -- Redo all these calculations with the new start points
            cx, cy = (startX + stopX) / 2, (startY + stopY) / 2

            if (dx < 0) then
              dx, dy = -dx, -dy
            end

            l = sqrt((dx * dx) + (dy * dy))

            s, c = -dy / l, dx / l
            sc = s * c
          end
        end

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

        if not line then
          if self.recycling[1] then -- First try to recycle an old line, if it has at least one
            line = tremove(self.recycling) -- Take the last one
            line:Show()
          else -- Nothing to recycle, create a new one
            line = frame:CreateTexture(nil, (self.drawLayer or "ARTWORK"))
            line:SetTexture("Interface\\addons\\CombatTracker\\Media\\line.tga")
            self.totalLines = (self.totalLines or 0) + 1
          end

          line:SetVertexColor(c1, c2, c3, c4)

          lastLine = line
          self.lastIndex = i
          self.lastLine = line -- Easy access to most recent

          lines[i] = line
        end

        self.lastSine = s
        self.lastDX = dx
        self.lastDY = dy

        line:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
        line:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", cx + Bwid, cy + Bhgt)
        line:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", cx - Bwid, cy - Bhgt)
      end

      if bars then
        if self.fill then -- Draw bars if fill is true
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

          local bar = bars[i]

          do -- Handle the bar
            if (i > 2) and (self.prevDY and dy == self.prevDY) then --  or (3 > width)
              if bar then -- If a bar exists, recycle it to be used later, instead of throwing it away and creating a new one
                if not self.barRecycling then self.barRecycling = {} end

                self.barRecycling[#self.barRecycling + 1] = bar
                bar:ClearAllPoints()
                bar:Hide()
                bars[i] = nil
              end

              local index = i - 1
              while not bars[index] and (index > 0) do -- Find the most recent bar
                index = index - 1
              end

              bar = bars[index] -- Now this is used, instead of creating a brand new one
            end

            if not bar then
              if self.barRecycling and self.barRecycling[1] then -- First try to recycle an old bar, if it has at least one
                bar = tremove(self.barRecycling) -- Take the last one
                bar:Show()
              else -- Nothing to recycle, create a new one
                bar = frame:CreateTexture("CT_Graph_Frame_Bar_" .. i, self.drawLayer or "ARTWORK")
                bar:SetTexture(1, 1, 1, 1)
                bar:SetVertexColor(c1, c2, c3, bars.alpha or 0.3)
                -- bar:SetBlendMode("ADD")

                self.totalBars = (self.totalBars or 0) + 1
              end

              bars.lastBar = bar

              bars[i] = bar
            end

            if bar then
              -- bar:ClearAllPoints()
              bar:SetPoint("BOTTOMLEFT", anchor, startX, 0)
              bar:SetSize(width, minY)
            end

            if self.prevDY and (dy == self.prevDY) then -- Same height as before
              if bar then
                -- debug("First")
                bar:SetPoint("RIGHT", line, 0, 0)
              else
                debug("Second")
                local index = i - 1
                while not bars[index] and (index > 0) do -- Find the most recent bar
                  index = index - 1
                end

                bar = bars[index] -- Now this is used, instead of creating a brand new one

                if bar then
                  bar:SetPoint("RIGHT", line, 0, 0)
                end
              end
            elseif bar then
              local index = i - 1
              local prevBar = bars[index]
              while ((not prevBar) or (prevBar == bar)) and (index > 0) do -- Find the most recent bar
                index = index - 1
                prevBar = bars[index]
              end

              if prevBar then
                prevBar:SetPoint("RIGHT", bar, "LEFT", 0, 0)
              end
            else
              debug(i, "No bar, but does need to anchor!")
            end
          end

          --   if self.prevDY and dy == self.prevDY then
          --     if bars[i - 1] then
          --       bars[i - 1]:SetPoint("RIGHT", lastLine, 0, 0)
          --     else
          --       for index = (i - 2), 1, -1 do
          --         if bars[index] then
          --           bars[index]:SetPoint("RIGHT", lastLine, 0, 0)
          --           break
          --         end
          --       end
          --     end
          --   elseif bar then
          --     local index = i - 1
          --     local prevBar = bars[index]
          --     while ((not prevBar) or (prevBar == bar)) and (index > 0) do -- Find the most recent bar
          --       index = index - 1
          --       prevBar = bars[index]
          --     end
          --
          --     if prevBar then
          --       prevBar:SetPoint("RIGHT", bar, "LEFT", 0, 0)
          --     end
          --
          --     -- if bars[i - 1] then
          --     --   bars[i - 1]:SetPoint("RIGHT", bar, "LEFT", 0, 0)
          --     -- else
          --     --   for index = (i - 2), 1, -1 do
          --     --     if bars[index] then
          --     --       bars[index]:SetPoint("RIGHT", bar, "LEFT", 0, 0)
          --     --       break
          --     --     end
          --     --   end
          --     -- end
          --   else
          --     debug(i, "No bar, but does need to anchor!")
          --   end

          do -- Handle triangle stuff
            -- local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX) -- Start isn't needed for bounds check
            -- local startY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)
            --
            -- local stopX = graphWidth * (data[i] - minX) / (maxX - minX)
            -- local stopY = graphHeight * (data[-i] - minY) / (maxY - minY)

            if bar then
              local tri = triangles[i]
              if not tri and (maxY - minY) >= 1 then
                tri = frame:CreateTexture("CT_Graph_Frame_Triangle_" .. i, self.drawLayer or "ARTWORK")
                tri:SetTexture("Interface\\Addons\\CombatTracker\\Media\\triangle")
                tri:SetVertexColor(c1, c2, c3, triangles.alpha or bars.alpha or 0.3)
                -- tri:SetBlendMode("ADD")

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
        if routine then
          self.refresh = CT.refreshNormalGraph
          self.updating = false
        end
        
        if reset or routine then
          local runTime = floor((debugprofilestop() - start) * 1000 + 0.5) / 1000
          local percent = floor(((self.totalLines or 0) / num) * 100)  .. "%"
          
          if routine then
            debug(percent, num, self.totalLines, #self.recycling, "Done refreshing (coroutine):", self.name .. ".", runTime, "MS.")
          else
            debug(percent, num, self.totalLines, #self.recycling, "Done refreshing:", self.name .. ".", runTime, "MS.")
          end
        end

        self.endNum = i + 1
        self.lastLine = lastLine or self.lastLine

        -- debug("TOTALS:", self.totalLines or 0, self.totalBars or 0, self.totalTriangles or 0, i)

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
      elseif routine and (i % 500) == 0 then -- The modulo of i is how many lines it will run before calling back, if it's in a coroutine
        local delay = random(-3, 3) / 100 + 0.05 -- The random number is to reduce the chances of multiple graphs refreshing at the exact same time
        after(delay, self.refresh)
        self.updating = true
        yield()
      end
    elseif blocked and i == num then -- It's done
      if routine then
        self.refresh = CT.refreshNormalGraph
        self.updating = false
      end

      if blockedY > 0 then
        self.YMax = maxY * (blockedY / graphHeight) * 1.12 -- 90%
      end

      return self:refresh(true) -- Run again with the new Y value
    end
  end
end

function CT:refreshNormalGraph_BACKUP_2(reset, routine) -- NOTE: What about accessing the Y points directly for comparisons for smoothing?
  if not CT.base.shown then return debug("Refresh got called when base was hidden!", self.name) end
  if not CT.base.expander then return debug("Refresh got called before the expander was created!", self.name) end
  if not CT.base.expander.shown then return debug("Refresh got called when the expander was not flagged as shown!", self.name) end
  if not self.shown then return debug("Refresh got called when graph was not flagged as shown!", self.name) end
  if not self.frame then return debug("Refresh got called when graph had no frame!", self.name) end -- Happened once, was related to loading a saved fight or returning from one
  if self.updating then return debug("Refresh got called when graph was flagged as updating!", self.name) end
  
  local cTime = GetTime()
  local num = #self.data
  local graphWidth, graphHeight = self.frame:GetSize()

  if reset then
    self.endNum = 2
    self.lastRefresh = cTime

    if num >= (CT.settings.graphCoroutineNum or 2000) then -- The comparison number is after how many points do we want to switch to a coroutine (default 2000)
      self.refresh = wrap(CT.refreshNormalGraph)

      -- debug(num, self.totalLines, self.deletedCount, "Refreshing (coroutine):", self.name)
      return self:refresh(nil, true) -- Call it again, but now as a coroutine
    else
      -- debug(num, self.totalLines, self.deletedCount, "Refreshing:", self.name)
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
  local zoomed = self.frame.zoomed
  local blocked, blockedX, blockedY = nil, 0, 0

  local c1, c2, c3, c4 = 0.0, 0.0, 1.0, 1.0 -- Default to blue
  if self.color then c1, c2, c3, c4 = self.color[1], self.color[2], self.color[3], self.overrideAlpha or self.color[4] end
  
  -- if self.endNum and self.endNum ~= 2 and self.endNum > num then -- Generally, this should mean it was called without adding new data points from last time, redraw the last line
  --   local startX = graphWidth * (data[num - 1] - minX) / (maxX - minX)
  --   local startY = graphHeight * (data[-(num - 1)] - minY) / (maxY - minY)
  --
  --   local stopX = graphWidth * (data[num] - minX) / (maxX - minX)
  --   local stopY = graphHeight * (data[-num] - minY) / (maxY - minY)
  --
  --   local lastIndex, lastLine = nil, nil
  --
  --   for i = num, 2, -1 do -- Find most recent line, searching backwards
  --     if lines[i] then
  --       lastIndex = i
  --       lastLine = lines[i]
  --       break
  --     end
  --   end
  --
  --   return debug("Greater, returning")
  -- end

  for i = (self.endNum or 2), num do
    local stopX = graphWidth * (data[i] - minX) / (maxX - minX)
    local stopY = graphHeight * (data[-i] - minY) / (maxY - minY)
    
    if not zoomed then -- Update maxX and maxY values if necessary, just not while zoomed
      if stopX > graphWidth then -- Graph is too long
        blocked = true
        
        if (stopX / graphWidth) > blockedX then
          blockedX = stopX
        end
      end
  
      if stopY > graphHeight then -- Graph is too tall
        blocked = true
        
        if (stopY / graphHeight) > blockedY then
          blockedY = stopY
        end
      end
    end

    if not blocked then -- If out of bounds, finish looping to find the most out of bounds point, but don't waste time calculating everything
      local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX) -- start isn't needed for bounds check
      local startY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)
      
      local lastLine
      local w = 32
      local dx, dy = stopX - startX, stopY - startY -- This is about the change
      local cx, cy = (startX + stopX) / 2, (startY + stopY) / 2 -- This is about the total
      
      if (dx < 0) then -- Normalize direction if necessary
        dx, dy = -dx, -dy
      end
      
      if startX == stopX and startY == stopY then
        debug("Tried to draw point that takes no space!")
      end

      if startX ~= stopX then -- If they match, this can break
        -- NOTE: is it if they match and if the y points are the same? Then it would be drawing a point that doesn't take any space
        local line = lines[i]
        local lastIndex
        
        -- if i > 2 then
        --   local diffX = dx - (self.lastDX or 0)
        --   if 0 > diffX then diffX = -diffX end -- Make it positive
        --   if diffX > 0.001 then diffX = nil end
        --
        --   local diffY = dy - (self.lastDY or 0)
        --   if 0 > diffY then diffY = -diffY end -- Make it positive
        --   if diffY > 0.001 then diffY = nil end
        --
        --   if (diffX or diffY) or (dy == self.lastDY) then
        --     local diff = diffX or diffY
        --
        --     if reset and line then -- Recycle lines
        --       if not self.recycling then self.recycling = {} end
        --
        --       self.recycling[#self.recycling + 1] = line
        --       line:ClearAllPoints()
        --       line = nil
        --
        --       debug("Adding:", #self.recycling)
        --     end
        --
        --     if line then -- Recycle lines
        --       if not self.recycling then self.recycling = {} end
        --
        --       local index = i
        --       while lines[index] ~= line do
        --         index = index - 1
        --       end
        --
        --       self.recycling[#self.recycling + 1] = lines[index]
        --       lines[index]:ClearAllPoints()
        --       lines[index]:Hide()
        --
        --       lines[index] = nil
        --       -- debug("Adding:", #self.recycling)
        --     end
        --
        --     local index = i - 1
        --     if lines[2] then -- Shouldn't fail, but just to make sure it can't go infitely
        --       while not lines[index] do
        --         index = index - 1
        --       end
        --     end
        --
        --     line = lines[index]
        --
        --     startX = graphWidth * (data[index - 1] - minX) / (maxX - minX)
        --     startY = graphHeight * (data[-(index - 1)] - minY) / (maxY - minY)
        --
        --     dx, dy = stopX - startX, stopY - startY -- This is about the change
        --     cx, cy = (startX + stopX) / 2, (startY + stopY) / 2 -- This is about the total
        --
        --     if (dx < 0) then -- Normalize direction if necessary
        --       dx, dy = -dx, -dy
        --     end
        --   end
        -- end

        -- if self.prevDY and dy == self.prevDY then -- Same angle as the last one, no need to make a new line
        --   if lines[i - 1] then -- Try to find the most recent line
        --     lastLine = lines[i - 1]
        --     lastIndex = i - 1
        --   elseif lines[i - 2] then
        --     lastLine = lines[i - 2]
        --     lastIndex = i - 2
        --   else -- Couldn't find it efficiently, so start searching backwards
        --     for index = (i - 2), 1, -1 do
        --       if lines[index] then
        --         lastIndex = index
        --         lastLine = lines[index]
        --         break
        --       end
        --     end
        --   end
        --
        --   startX = graphWidth * (data[(lastIndex or 2) - 1] - minX) / (maxX - minX)
        --   line = lastLine or lines[2] -- NOTE: or line
        --   dx, dy = stopX - startX, stopY - startY
        --   cx, cy = (startX + stopX) / 2, (startY + stopY) / 2
        -- end

        local l = sqrt((dx * dx) + (dy * dy)) -- Calculate actual length of line

        local s, c = -dy / l, dx / l -- Sin and Cosine of rotation, and combination (for later)
        local sc = s * c
        
        if i > 2 then
          local diff = l - (self.lastLength or 0)
          if 0 > diff then diff = -diff end -- Make it positive
        
          if (0.001 > diff) or (dy == (self.lastDY or 0)) then
            if line then -- Recycle lines
              if not self.recycling then self.recycling = {} end
        
              self.recycling[#self.recycling + 1] = line
              line:ClearAllPoints()
              lines[i] = nil
        
              -- debug("Adding:", #self.recycling)
            end
            
            local index = i
            while not lines[index] do
              index = index - 1
              if index < 2 then debug("Breaking") break end
            end
            
            line = lines[index]
            
            -- if (0.001 > diff) and (dy == self.lastDY or 0) then
            --   debug(self.totalLines, "Too short and same DY")
            -- elseif (0.001 > diff) then
            --   debug(self.totalLines, "Too short")
            -- elseif (dy == self.lastDY or 0) then
            --   debug(self.totalLines, "Same DY")
            -- end
        
            -- debug(i, index, diff)
        
            startX = graphWidth * (data[index - 1] - minX) / (maxX - minX)
            startY = graphHeight * (data[-(index - 1)] - minY) / (maxY - minY)
        
            dx, dy = stopX - startX, stopY - startY -- This is about the change
            cx, cy = (startX + stopX) / 2, (startY + stopY) / 2 -- This is about the total
        
            if (dx < 0) then -- Normalize direction if necessary
              dx, dy = -dx, -dy
            end
        
            l = sqrt((dx * dx) + (dy * dy)) -- Calculate actual length of line
        
            s, c = -dy / l, dx / l -- Sin and Cosine of rotation, and combination (for later)
            sc = s * c
          end
        end
        
        -- if reset and line and not lastIndex then -- There is a line, try to find out if it's actually needed
        --   local diff = sc - (self.lastSC or 0)
        --   if 0 > diff then diff = -diff end -- Make it positive
        --
        --   if diff > 0 and diff < 0.001 then
        --     -- line:Hide()
        --     line:SetTexture(nil)
        --     line = nil
        --     lines[i] = nil
        --
        --     self.totalLines = (self.totalLines or 0) - 1
        --
        --     self.deletedCount = (self.deletedCount or 0) + 1
        --
        --     -- debug(i, diff)
        --     local lineNum = nil
        --
        --     for index = i, 2, -1 do
        --       if lines[index] then
        --         line = lines[index]
        --         lineNum = index
        --         break
        --       end
        --     end
        --
        --     startX = graphWidth * (data[lineNum - 1] - minX) / (maxX - minX)
        --     startY = graphHeight * (data[-(lineNum - 1)] - minY) / (maxY - minY)
        --
        --     dx, dy = stopX - startX, stopY - startY -- This is about the change
        --     cx, cy = (startX + stopX) / 2, (startY + stopY) / 2 -- This is about the total
        --
        --     if (dx < 0) then -- Normalize direction if necessary
        --       dx, dy = -dx, -dy
        --     end
        --
        --     l = sqrt((dx * dx) + (dy * dy)) -- Calculate actual length of line
        --
        --     s, c = -dy / l, dx / l -- Sin and Cosine of rotation, and combination (for later)
        --     sc = s * c
        --   end
        -- end

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
          if self.recycling and self.recycling[1] then -- First try to recycle an old line
            line = self.recycling[#self.recycling]
            self.recycling[#self.recycling] = nil
            
            line:Show()

            -- debug("Recycling:", #self.recycling)
            self.deletedCount = (self.deletedCount or 0) + 1
          else
            line = frame:CreateTexture("CT_Graph_Line" .. i, self.drawLayer or "ARTWORK")
            line:SetTexture("Interface\\addons\\CombatTracker\\Media\\line.tga")
            self.totalLines = (self.totalLines or 0) + 1
          end
          
          line:SetVertexColor(c1, c2, c3, c4)

          lastLine = line
          self.lastIndex = i
          self.lastLine = line -- Easy access to most recent

          lines[i] = line
        end
        
        self.lastSC = sc
        self.lastLength = l
        self.lastDX = dx
        self.lastDY = dy
        self.lastTRx = TRx

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
        if routine then
          self.refresh = CT.refreshNormalGraph
          self.updating = false
        end
        
        self.endNum = i + 1
        self.lastLine = lastLine or self.lastLine

        -- debug("TOTALS:", self.totalLines or 0, self.totalBars or 0, self.totalTriangles or 0, i)

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
      elseif routine and (i % 1000) == 0 then -- The modulo of i is how many lines it will run before calling back, if it's in a coroutine
        local delay = random(-3, 3) / 100 + 0.05 -- The random number is to reduce the chances of multiple graphs refreshing at the exact same time
        after(delay, self.refresh)
        self.updating = true
        yield()
      end
    elseif blocked and i == num then -- It's done
      if routine then
        self.refresh = CT.refreshNormalGraph
        self.updating = false
      end
      
      local dbGraph = self.__index
      
      if blockedX > 0 then
        dbGraph.XMax = maxX * (blockedX / graphWidth) * 1.333 -- 75%
      end
      
      if blockedY > 0 then
        dbGraph.YMax = maxY * (blockedY / graphHeight) * 1.12 -- 90%
      end
      
      return self:refresh(true) -- Run agian with the new X/Y value
    end
  end
end

function CT:refreshNormalGraph_BACKUP(reset, routine)
  if not CT.base.shown then return debug("Refresh got called when base was hidden!", self.name) end
  if not CT.base.expander then return debug("Refresh got called before the expander was created!", self.name) end
  if not CT.base.expander.shown then return debug("Refresh got called when the expander was not flagged as shown!", self.name) end
  if not self.shown then return debug("Refresh got called when graph was not flagged as shown!", self.name) end
  if not self.frame then return debug("Refresh got called when graph had no frame!", self.name) end -- Happened once, was related to loading a saved fight or returning from one
  if self.updating then return debug("Refresh got called when graph was flagged as updating!", self.name) end
  
  local cTime = GetTime()
  local num = #self.data
  local graphWidth, graphHeight = self.frame:GetSize()

  if reset then
    self.endNum = 2
    self.lastRefresh = cTime

    if num >= (CT.settings.graphCoroutineNum or 2000) then -- The comparison number is after how many points do we want to switch to a coroutine (default 2000)
      self.refresh = wrap(CT.refreshNormalGraph)

      debug(num, self.totalLines, "Refreshing with coroutine:", self.name)
      return self:refresh(nil, true) -- Call it again, but now as a coroutine
    else
      debug(num, self.totalLines, "Refreshing:", self.name)
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
  local zoomed = self.frame.zoomed
  local blocked, blockedX, blockedY = nil, 0, 0

  local c1, c2, c3, c4 = 0.0, 0.0, 1.0, 1.0 -- Default to blue
  if self.color then c1, c2, c3, c4 = self.color[1], self.color[2], self.color[3], self.overrideAlpha or self.color[4] end

  for i = (self.endNum or 2), num do
    local stopX = graphWidth * (data[i] - minX) / (maxX - minX)
    local stopY = graphHeight * (data[-i] - minY) / (maxY - minY)
    
    if not zoomed then -- Update maxX and maxY values if necessary, just not while zoomed
      if stopX > graphWidth then -- Graph is too long
        blocked = true
        
        if (stopX / graphWidth) > blockedX then
          blockedX = stopX
        end
      end
  
      if stopY > graphHeight then -- Graph is too tall
        blocked = true
        
        if (stopY / graphHeight) > blockedY then
          blockedY = stopY
        end
      end
    end

    if not blocked then -- If out of bounds, finish looping to find the most out of bounds point, but don't waste time calculating everything
      local startX = graphWidth * (data[i - 1] - minX) / (maxX - minX) -- startX and startY aren't needed of out of bounds check
      local startY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)
      
      local lastLine
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
        if routine then
          self.refresh = CT.refreshNormalGraph
          self.updating = false
        end
        
        self.endNum = i + 1
        self.lastLine = lastLine or self.lastLine

        -- debug("TOTALS:", self.totalLines or 0, self.totalBars or 0, self.totalTriangles or 0, i)

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
      elseif routine and (i % 1000) == 0 then -- The modulo of i is how many lines it will run before calling back, if it's in a coroutine
        local delay = random(-3, 3) / 100 + 0.05 -- The random number is to reduce the chances of multiple graphs refreshing at the exact same time
        after(delay, self.refresh)
        self.updating = true
        yield()
      end
    elseif blocked and i == num then -- It's done
      if routine then
        self.refresh = CT.refreshNormalGraph
        self.updating = false
      end
      
      local dbGraph = self.__index
      
      if blockedX > 0 then
        dbGraph.XMax = maxX * (blockedX / graphWidth) * 1.333 -- 75%
      end
      
      if blockedY > 0 then
        dbGraph.YMax = maxY * (blockedY / graphHeight) * 1.12 -- 90%
      end
      
      return self:refresh(true) -- Run agian with the new X/Y value
    end
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

    name = "Mana" -- NOTE: Testing only
    -- name = "Holy Power" -- NOTE: Testing only

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

      b:SetScript("OnClick", function(button, click)
        if button:GetChecked() then -- Show graph
          if IsShiftKeyDown() then -- Create a new graph frame to display it on
            debug("Shift is down, adding new window.")
            local graphFrame = CT.base.expander.addNormalGraph()
            CT.base.expander.resetAnchors()

            self:toggle("show", graphFrame)
          else
            self:toggle("show")
          end
        else -- Hide graph
          if IsShiftKeyDown() then -- Hide the graph frame as well as the graph
            debug("Shift is down, removing new window.")
            local graphFrame = CT.base.expander.removeNormalGraph()
            CT.base.expander.resetAnchors()
            self:toggle("hide", graphFrame)
          else
            self:toggle("hide")
          end
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
  do -- Create graph frame and background and set basic values
    graphFrame = CreateFrame("ScrollFrame", nil, self)
    graphFrame.anchor = CreateFrame("Frame", nil, self)
    graphFrame:SetScrollChild(graphFrame.anchor)
    graphFrame.anchor:SetSize(100, 100)
    graphFrame.anchor:SetAllPoints(graphFrame)

    graphFrame.bg = graphFrame:CreateTexture(nil, "BACKGROUND")
    graphFrame.bg:SetTexture(0.07, 0.07, 0.07, 1.0)
    graphFrame.bg:SetAllPoints()

    graphFrame.displayed = {} -- Holds every currently displayed graph
    graphFrame.hideAllGraphs = function(self)
      for i, graph in ipairs(self.displayed) do
        graph:toggle("hide")
      end
    end

    self.graphFrame = graphFrame
    if not CT.graphFrame then
      CT.graphFrame = graphFrame
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

  local YELLOW = "|cFFFFFF00"

  mouseOver:SetScript("OnUpdate", function(self, elapsed)
    local UIScale = UIParent:GetEffectiveScale()
    local mouseX, mouseY = GetCursorPosition()
    local mouseX = (mouseX / UIScale)
    local mouseY = (mouseY / UIScale)

    self:SetPoint("LEFT", UIParent, mouseX, 0)

    local anchorLeft = graphFrame.anchor:GetLeft()

    if (self.lastMouseX or 0) == mouseX -- Check if it needs to be updated
    and (self.lastMouseY or 0) == mouseY
    and (self.zoomedStatus) == (graphFrame.zoomed) -- If it doesn't match, then graph was zoomed in or out since last update
    and (self.lastAnchorLeft or 0) == anchorLeft -- This is to see if the graph has been scrolled right/left
    then return end -- If none of the checks failed, it shouldn't need to update

    if not graphFrame.displayed[1] then -- No displayed graphs, reset values and return
      mouseOver.info = ""
      mouseOver.tooltipTitle = ""
      dot:Hide()
      CT.infoTooltip:Hide()
      return
    end

    local graphWidth, graphHeight = graphFrame:GetSize()
    local fromGraphLeft = mouseX - anchorLeft

    local graph, num, line, lineIndex = nil, nil, nil, nil
    local startX, startY, stopX, stopY = nil, nil, nil, nil
    local closest = 1000000 -- Just make this start high to make sure it's higher than graph values, doesn't really matter what it is set to

    for index = 1, #graphFrame.displayed do -- Run through every graph that is displayed on this frame
      local g = graphFrame.displayed[index]
      local data = g.data
      local lines = g.lines
      local maxX = g.XMax
      local minX = g.XMin
      local maxY = g.YMax
      local minY = g.YMin
      local lastLine, foundX = nil, nil

      local a = max((g.color[4] or 1) - 0.3, 0.5) -- Reduce alpha by 0.3, but don't let it go below 0.5
      g.overrideAlpha = a

      for i = 1, #data do
        if lines[i] then
          lines[i]:SetAlpha(a) -- Fade it

          if not foundX then -- Store the most recent line and its index unit we find the X point
            lastLine = lines[i]
            lineIndex = i
          end
        end

        if data[i - 1] and (not foundX) then -- foundX check stops it from wasting time with this while it's finishing updating the alpha
          local tempStartX = graphWidth * (data[i - 1] - minX) / (maxX - minX)
          local tempStartY = graphHeight * (data[-(i - 1)] - minY) / (maxY - minY)

          local tempStopX = graphWidth * (data[i] - minX) / (maxX - minX)
          local tempStopY = graphHeight * (data[-i] - minY) / (maxY - minY)

          if ((fromGraphLeft > tempStartX) and (fromGraphLeft <= tempStopX)) and lastLine then -- First find the closest data point on the X axis
            foundX = true

            local _, lineY = lastLine:GetCenter()

            local distance = mouseY - lineY
            if 0 > distance then distance = -distance end -- Make sure it's positive, so right at the line will be 0 and it will get higher in either direction

            if closest > distance then -- The graph with the distance closest to 0 is the one we want
              closest = distance
              graph = g
              num = i
              line = lastLine

              startX = tempStartX
              startY = tempStartY

              stopX = tempStopX
              stopY = tempStopY
            end
          end
        end
      end
    end

    if not graph then -- Mouse is past the graph, or something went wrong. Either way, hide stuff and return
      mouseOver.info = nil
      mouseOver.tooltipTitle = nil
      dot:Hide()
      CT.infoTooltip:Hide()
      return
    else
      dot:Show()
      CT.infoTooltip:Show()
    end

    do -- Now that a graph is selected, return it to its full opacity, leaving the others faded
      graph.overrideAlpha = nil
      local a = graph.color[4] or 1
      local lines = graph.lines

      for i = 1, #graph.data do
        if lines[i] then
          lines[i]:SetAlpha(a)
        end
      end
    end

    do -- Handle the dot's Y point
      dot:SetPoint("BOTTOM", mouseOver, 0, stopY - 3) -- The - 3 seems to work okay, but it's arbitrary, and I'd love it if I could get rid of it...
    end

    do -- Calculate timer and set it as the tooltip's title
      local timer = graphFrame.zoomed or ((CT.displayedDB.stop or GetTime()) - CT.displayedDB.start) -- grapheFrame.zoomed is storing the timer from when zoom began
      local current = mouseX - graph.lines[2]:GetLeft()
      local total = graph.lastLine:GetRight() - graph.lines[2]:GetLeft()
      local displayTimer = floor(timer * (current / total) + 0.5)

      mouseOver.tooltipTitle = YELLOW .. formatTimer(displayTimer) .. "|r\n"
    end

    if graph.displayText then -- Set the tooltip text
      local value = graph.data[-num]
      
      if graph.displayText.math then
        local operator, number = strmatch(graph.displayText.math, "(.+)%s(%d+)")
        number = tonumber(number)
        
        if operator == "+" then
          value = value + number
        elseif operator == "-" then
          value = value - number
        elseif operator == "/" then
          value = value / number
        elseif operator == "*" then
          value = value * number
        elseif operator == "^" then
          value = value ^ number
        elseif operator == "%" then
          value = value % number
        elseif operator == "_" then -- Use underscore to mean it should be negative
          value = -value
        end
      end
      
      if graph.displayText.round then
        
      end
      
      graph.displayText[4] = floor(value)
      
      mouseOver.info = table.concat(graph.displayText)
    end

    self.lastMouseX = mouseX
    self.lastMouseY = mouseY
    self.zoomedStatus = graphFrame.zoomed
    self.lastAnchorLeft = anchorLeft
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

    for index = 1, #graphFrame.displayed do -- Set them all back to their default alpha
      local graph = graphFrame.displayed[index]
      local lines = graph.lines
      graph.overrideAlpha = nil
      local a = graph.color[4] or 1

      if lines[2] and lines[2]:GetAlpha() ~= a then -- Only bother with this if they don't match
        for i = 1, #graph.data do
          if lines[i] then
            lines[i]:SetAlpha(a)
          end
        end
      end
    end
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
            -- graphFrame.slider:Show()

            for i, graph in ipairs(graphFrame.displayed) do
              local dbGraph = graph.__index
              
              graph.preZoomMinX = dbGraph.XMin
              graph.preZoomMaxX = dbGraph.XMax
              
              graph.preZoomMinY = dbGraph.YMin
              graph.preZoomMaxY = dbGraph.YMax

              dbGraph.XMin = (graphFrame.mouseOverLeft / graphWidth) * dbGraph.XMax
              dbGraph.XMax = ((mouseOverRight - graphLeft) / graphWidth) * dbGraph.XMax
              
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
          -- graphFrame.slider:Hide()
          mouseOver.dot:Hide()
          slider:SetValue(0)

          for i, graph in ipairs(graphFrame.displayed) do
            
            if graph.preZoomMinX then
              local dbGraph = graph.__index
              
              dbGraph.XMin = graph.preZoomMinX
              dbGraph.XMax = graph.preZoomMaxX
              
              dbGraph.YMin = graph.preZoomMinY
              dbGraph.YMax = graph.preZoomMaxY
              
              graph.preZoomMinX = nil
              graph.preZoomMaxX = nil
              
              graph.preZoomMinY = nil
              graph.preZoomMaxY = nil
              
              graph:refresh(true)
            end

            -- dbGraph.XMin = 0
          end
        else -- Graph is not zoomed in
          if not self.popup then
            self.popup = CreateFrame("Frame", nil, CT.base)
            self.popup:SetFrameStrata("TOOLTIP")
            self.popup:SetSize(150, 20)
            self.popup.bg = self.popup:CreateTexture(nil, "BACKGROUND")
            self.popup.bg:SetAllPoints()
            self.popup.bg:SetTexture(0.1, 0.1, 0.1, 1.0)
            self.popup:Hide()
            self.popup:EnableMouse(true) -- This is just so it doesn't pass the OnEnter to the lower frame.

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

            local UIScale = UIParent:GetEffectiveScale()
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
--   for i = 1, #active1.data do -- Has to be data, lines isn't indexed
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
--   if num and active1.data[-num] then -- Handle the dot's position
--     local y = graphFrame:GetHeight() * (active1.data[-num] - active1.YMin) / (active1.YMax - active1.YMin)
--
--     dot:Show()
--     dot:SetPoint("BOTTOM", mouseOver, 0, y - 5)
--   else
--     dot:Hide()
--   end
--
--   if num and active1.data[num] then
--     local startX = active1.data[num]
--     local startY = active1.data[-num]
--
--     local timer = (CT.displayedDB.stop or GetTime()) - CT.displayedDB.start
--     if active1.frame and active1.frame.zoomed then
--       timer = active1.frame.zoomed
--     elseif not active1.frame then
--       debug("[DELAY: 0.3]", "No frame for", active1.name)
--     end
--
--     local current = mouseOverCenter - active1.lines[2]:GetLeft()
--     local total = active1.lastLine:GetRight() - active1.lines[2]:GetLeft()
--
--     local displayTimer = floor(timer * (current / total))
--
--     local text = "Time: " .. YELLOW .. formatTimer(displayTimer) .. "|r\n"
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
