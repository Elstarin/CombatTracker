if not CombatTracker then return end

local CT = CombatTracker
local data = CT.data
CT.updateFunctions = {}
local func = CT.updateFunctions

local round = CT.round
local formatTimer = CT.formatTimer
local colorText = CT.colorText

function func:activity(time)
  local timer = time - CT.TimeSinceLogIn
  local inactivity = timer - data.activity.total
  local activity = round(100 - ((inactivity / timer) * 100), 1)
  self.value:SetText(activity .. "%")
  colorText(self.value, activity, "percent")

  if self.expanded then
    self.text[1]:SetText(formatTimer(timer))

    local activity = round(data.activity.total, 1)
    self.text[2]:SetText(formatTimer(activity))

    local inactivity = round(timer - data.activity.total, 1)
    if self.text[3] then
      self.text[3]:SetText(formatTimer(inactivity))
    end
  end

  if self.graph and time > self.graphUpdateDelay then

    self.graphUpdateDelay = time + 5 -- Plot graph points every X seconds
  end
end

function func:resource2(time)
  local timer = time - CT.TimeSinceLogIn
  local powerType = data.power[2]
  local power = data.power[data.power[2]]
  local value = round(100 - ((power.wasted / power.total) * 100), 0)

  self.value:SetText(value .. "%")

  -- Add a new line to left side if necessary
  if self.dropDownCreated and power.numSpells and power.addLine then
    for k,v in pairs(power.spells) do
      if not v.addedLine then
        self:type1AddLeft(power.spells[k].name)
        v.addedLine = true
        power.addLine = false
      end

      local dropDown = self.button.dropDown
      local expander = self.button.expander

      if self.expanded then
        dropDown:SetHeight(dropDown.dropHeight + 3)
        expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
        expander.height = expander:GetHeight()
      end
    end
  end

  -- Add a new line to right side if necessary
  if self.dropDownCreated and power.numSpellsCost and power.addCostLine then
    for k,v in pairs(power.spellCosts) do
      if not v.addedLine then
        self:type1AddRight(power.spellCosts[k].name)
        v.addedLine = true
        power.addCostLine = false
      end

      local dropDown = self.button.dropDown
      local expander = self.button.expander

      if self.expanded then
        dropDown:SetHeight(dropDown.dropHeight + 3)
        expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
        expander.height = expander:GetHeight()
      end
    end
  end

  if self.dropDownCreated and self.expanded then
    self.text[1].left:SetText(power.effective)
    self.text[1].right:SetText(power.wasted)

    local count = 1
    for k,v in pairs(power.spells) do
      count = count + 1

      local line = self.text[count].left
      local spell = power.spells[k]
      local totalPercent = round((spell.effective / power.effective) * 100, 0)

      if totalPercent < 0 then
        line[1]:SetText(0 .. "%")
      else
        line[1]:SetText(totalPercent .. "%")
      end

      line[2]:SetText("Gain: " .. (spell.effective or 0))
      line[3]:SetText("Loss: " .. (spell.wasted or 0))
    end

    local countCost = 1
    for k,v in pairs(power.spellCosts) do
      countCost = countCost + 1

      local line = self.text[countCost].right
      local spell = power.spellCosts[k]
      local totalPercent = round((spell.total / power.totalCost) * 100, 0)

      if totalPercent < 0 then
        line[1]:SetText(0 .. "%")
      else
        line[1]:SetText(totalPercent .. "%")
      end




      line[2]:SetText("Spent: " .. (spell.total or 0))
      line[3]:SetText("Avg: " .. (round(spell.average, 1) or 0))
    end
  end

  if self.graph and time > self.graphUpdateDelay then
    local percent = (power.currentPower / power.maxPower) * 100
    
    if not self.graphData then
      self.graphData = {}
      CT.registerGraphs[#CT.registerGraphs + 1] = self
    end
    
    self.graphData[#self.graphData + 1] = {}
    local data = self.graphData[#self.graphData]
    data[1] = timer
    data[2] = percent
    data.lastCast = power.lastCast
    data.lastCost = power.lastCost

    -- Add new plot point and extends the graph when necessary
    if self.graphFrame and not self.graphFrame.zoomed and not (timer <= self.graph.XMax) then
      self.graph.XMin = 0
      self.graph.XMax = self.graph.XMax + max(timer - self.graph.XMax, 10)
    end
    
    if self.expanded then
      self.graph:RefreshGraph()
      self:updateGraphTables()
    end

    self.graphUpdateDelay = time + 1 -- Plot graph points every X seconds
  end
end

function func:resource3(time)
  local powerType = data.power[3]
  local power = data.power[data.power[3]]
  local value = round(100 - ((power.wasted / power.total) * 100), 0)

  self.value:SetText(value .. "%")

  if self.dropDownCreated and self.expanded then
    local line1 = self.text[1]
    line1.count:SetText(power.total)
    line1.value:SetText(nil)
    line1.timer:SetText(nil)

    local line2 = self.text[2]
    line2.count:SetText(power.effective)
    line2.value:SetText(nil)
    line2.timer:SetText(nil)

    local line3 = self.text[3]
    line3.count:SetText(power.wasted)
    line3.value:SetText(nil)
    line3.timer:SetText(nil)
  end

  if self.graph and time > self.graphUpdateDelay then

    self.graphUpdateDelay = time + 5 -- Plot graph points every X seconds
  end
end

function func:shortCD(time)
  local spell = data.spells[self.spellID]

  if spell then
    local timer = time - CT.TimeSinceLogIn
    local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    local value = round(100 - ((timer - totalCD) / timer) * 100, 1)
    self.value:SetText(value .. "%")
    colorText(self.value, value, "percent")

    if self.dropDownCreated and self.expanded then
      self.text[1]:SetText(formatTimer(timer))
      self.text[2]:SetText(formatTimer(timer - totalCD))
      self.text[3]:SetText(round((timer - totalCD) / (spell.casts or 0), 2))

      if self.text[4] then
        self.text[4]:SetText("resets " .. random(1, 3))
      end
    end

    -- Update Graph
    if self.graph and time > self.graphUpdateDelay then
      if self.graphFrame then
        local graph = self.graph

        if not (timer <= graph.XMax) then
          graph.XMin = 0
          graph.XMax = graph.XMax + max(timer - graph.XMax, 10)

          if self.expanded then
            graph:RefreshGraph()
            self:hideUptimeLines()
          end
        end
      end

      self.graphUpdateDelay = time + 1 -- Check to extend graph every X seconds
    end
  else
    self.value:SetText(0 .. "%")
  end
end

function func:longCD(time)
  if not self.oldDelay then self.oldDelay = 0 end
  local spell = data.spells[self.spellID]

  if spell then
    local timer = time - CT.TimeSinceLogIn
    local castCount = spell.casts or 0
    local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    local value = round(100 - ((timer - totalCD) / timer) * 100, 1)

    self.value:SetText(value .. "%")

    if self.dropDownCreated and (castCount + 1) > self.button.dropDown.numLines then
      self:type3AddLine()

      if self.expanded then
        local dropDown = self.button.dropDown
        local expander = self.button.expander

        dropDown:SetHeight(dropDown.dropHeight + 3)
        expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
        expander.height = expander:GetHeight()
      end

      local delay = timer - totalCD
      local text = self.text[#self.text]
      text:SetText(round(delay - self.oldDelay, 2))

      self.oldDelay = delay
    end

    -- Update Graph
    if self.graph and time > self.graphUpdateDelay then
      if self.graphFrame then
        local graph = self.graph

        if not (timer <= graph.XMax) then
          graph.XMin = 0
          graph.XMax = graph.XMax + max(timer - graph.XMax, 10)

          if self.expanded then
            graph:RefreshGraph()
            self:hideUptimeLines()
          end
        end
      end

      self.graphUpdateDelay = time + 1 -- Check to extend graph every X seconds
    end
  else
    self.value:SetText(0 .. "%")
  end
end

function func:mana(time)
  local timer = time - CT.TimeSinceLogIn
  local powerType = data.power[1]
  local power = data.power[data.power[1]]
  local value = round(100 - ((power.wasted / power.total) * 100), 0)

  self.value:SetText(value .. "%")

  -- NOTE: Make power.addLine contain a number referencing how many lines
  -- To add. I can probably do away with the pairs() function then and
  -- Avoid potential screw ups

  -- Add a new line to left side if necessary
  if self.dropDownCreated and power.numSpells and power.addLine then
    for k,v in pairs(power.spells) do
      if not v.addedLine then
        self:type1AddLeft(power.spells[k].name)
        v.addedLine = true
        power.addLine = false
      end

      if self.expanded then
        local dropDown = self.button.dropDown
        local expander = self.button.expander

        dropDown:SetHeight(dropDown.dropHeight)
        expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
        expander.height = expander:GetHeight()
      end
    end
  end

  -- Add a new line to right side if necessary
  if self.dropDownCreated and power.numSpellsCost and power.addCostLine then
    for k,v in pairs(power.spellCosts) do
      if not v.addedLine then
        self:type1AddRight(power.spellCosts[k].name)
        v.addedLine = true
        power.addCostLine = false
      end

      if self.expanded then
        local dropDown = self.button.dropDown
        local expander = self.button.expander

        dropDown:SetHeight(dropDown.dropHeight)
        expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
        expander.height = expander:GetHeight()
      end
    end
  end

  if self.dropDownCreated and self.expanded then
    self.text[1].left:SetText(power.effective)
    self.text[1].right:SetText(power.wasted)

    local count = 1
    for k,v in pairs(power.spells) do
      count = count + 1

      local line = self.text[count].left
      local spell = power.spells[k]
      local totalPercent = round((spell.effective / power.effective) * 100, 0)
      line[1]:SetText(totalPercent .. "%")
      line[2]:SetText("Gain: " .. (spell.effective or 0))
      line[3]:SetText("Loss: " .. (spell.wasted or 0))
    end

    local countCost = 1
    for k,v in pairs(power.spellCosts) do
      countCost = countCost + 1

      local line = self.text[countCost].right
      local spell = power.spellCosts[k]
      local totalPercent = round((spell.total / power.totalCost) * 100, 0)
      line[1]:SetText(totalPercent .. "%")
      line[2]:SetText("Spent: " .. (spell.total or 0))
      line[3]:SetText(nil)
    end
  end
  
  if self.graph and time > self.graphUpdateDelay then
    local percent = (power.currentPower / power.maxPower) * 100
    
    if not self.graphData then
      self.graphData = {}
      CT.registerGraphs[#CT.registerGraphs + 1] = self
    end
    
    self.graphData[#self.graphData + 1] = {}
    local data = self.graphData[#self.graphData]
    
    data[1] = timer
    data[2] = percent

    if self.graphFrame and not self.graphFrame.zoomed and not (timer <= self.graph.XMax) then
      self.graph.XMin = 0
      self.graph.XMax = self.graph.XMax + max(timer - self.graph.XMax, 10)
    end
    
    if self.expanded then
      self.graph:RefreshGraph()
      self:updateGraphTables()
    end

    self.graphUpdateDelay = time + 1 -- Plot graph points every X seconds
  end
end

function func:dispel(time)
  local timer = GetTime() - CT.TimeSinceLogIn
  local inactivity = timer - data.activity.total
  local activity = round(100 - ((inactivity / timer) * 100), 1) .. "%"
  self.value:SetText(activity)

  if self.dropDownCreated and self.expanded then
    local line1 = self.text[1]
    line1.count:SetText(random(0, 10))
    line1.value:SetText(random(0, 100))
    line1.timer:SetText((formatTimer(timer)))

    local activity = round(data.activity.total, 1)
    local line2 = self.text[2]
    line2.count:SetText(random(20, 30))
    line2.value:SetText(random(0, 100))
    line2.timer:SetText((formatTimer(activity)))
  end
end

function func:allCasts(time)
  local spell = data.spells

  if spell and spell.needsUpdate then
    spell.needsUpdate = false

    for k,v in pairs(spell) do
      if type(k) == "number" then
        if v.name and not v.allCastsLineCreated then
          self:type4(v.name)
          v.allCastsLineCreated = true

          if self.expanded then
            local dropDown = self.button.dropDown
            local expander = self.button.expander

            dropDown:SetHeight(dropDown.dropHeight + 3)
            expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
            expander.height = expander:GetHeight()
          end
        end
      end
    end

    -- local timer = time - CT.TimeSinceLogIn
    -- local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    -- local value = round(100 - ((timer - totalCD) / timer) * 100, 1)
    -- self.value:SetText(value .. "%")
    --
    -- if self.dropDownCreated and self.expanded then
    --   local delay = (timer - totalCD) + 0
    --   local count = (spell.casts or 0) + 0
    --
    --   self.text[1]:SetText(formatTimer(timer))
    --
    --   self.text[2]:SetText(formatTimer(delay))
    --
    --   self.text[3]:SetText(round(delay / count, 3))
    --
    --   if self.text[4] then
    --     self.text[4]:SetText("resets " .. random(1, 3))
    --   end
    -- end

    if self.dropDownCreated and self.graph and time > self.graphUpdateDelay then

      self.graphUpdateDelay = time + 5
    end

  else
    self.value:SetText(0 .. "%")
  end
end

-- function func:mana(time)
--   local timer = time - CT.TimeSinceLogIn
--   local powerType = data.power[1]
--   local power = data.power[data.power[1]]
--   local value = round(100 - ((power.wasted / power.total) * 100), 0)
--
--   if value < 0 then
--     self.value:SetText(0 .. "%")
--   else
--     self.value:SetText(value .. "%")
--   end
--
--   -- Add a new line to left side if necessary
--   if self.dropDownCreated and power.numSpells and power.addLine then
--     for k,v in pairs(power.spells) do
--       if not v.addedLine then
--         self:type1AddLeft(power.spells[k].name)
--         v.addedLine = true
--         power.addLine = false
--       end
--
--       if self.expanded then
--         local dropDown = self.button.dropDown
--         local expander = self.button.expander
--
--         dropDown:SetHeight(dropDown.dropHeight)
--         expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
--         expander.height = expander:GetHeight()
--       end
--     end
--   end
--
--   -- Add a new line to right side if necessary
--   if self.dropDownCreated and power.numSpellsCost and power.addCostLine then
--     for k,v in pairs(power.spellCosts) do
--       if not v.addedLine then
--         self:type1AddRight(power.spellCosts[k].name)
--         v.addedLine = true
--         power.addCostLine = false
--       end
--
--       if self.expanded then
--         local dropDown = self.button.dropDown
--         local expander = self.button.expander
--
--         dropDown:SetHeight(dropDown.dropHeight)
--         expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
--         expander.height = expander:GetHeight()
--       end
--     end
--   end
--
--   if self.dropDownCreated and self.expanded then
--     self.text[1].left:SetText(power.effective)
--     self.text[1].right:SetText(power.wasted)
--
--     local count = 1
--     for k,v in pairs(power.spells) do
--       count = count + 1
--
--       local line = self.text[count].left
--       local spell = power.spells[k]
--       local totalPercent = round((spell.effective / power.effective) * 100, 0)
--       line[1]:SetText(totalPercent .. "%")
--       line[2]:SetText("Gain: " .. (spell.effective or 0))
--       line[3]:SetText("Loss: " .. (spell.wasted or 0))
--     end
--
--     local countCost = 1
--     for k,v in pairs(power.spellCosts) do
--       countCost = countCost + 1
--
--       local line = self.text[countCost].right
--       local spell = power.spellCosts[k]
--       local totalPercent = round((spell.total / power.totalCost) * 100, 0)
--       line[1]:SetText(totalPercent .. "%")
--       line[2]:SetText("Spent: " .. (spell.total or 0))
--       line[3]:SetText(nil)
--     end
--   end
--
--   -- Update Graph
--   if self.graph and time > self.graphUpdateDelay then
--     local percent = (power.currentPower / power.maxPower) * 100
--
--     if self.graphFrame then
--       local graphFrame = self.graphFrame
--       local graph = self.graph
--
--       -- Add new plot point and extends the graph when necessary
--       self.graphData[#self.graphData + 1] = {self.graphPlotX, percent}
--
--       if not graphFrame.zoomed and not (self.graphPlotX <= graph.XMax) then
--         graph:SetXAxis(0, graph.XMax + graph.XGridInterval)
--       end
--
--       self.graphPlotX = (self.graphPlotX or 0) + self.graphPlotDistance
--
--       if self.dropDownCreated and self.expanded then
--         -- Every X number of updates, create a font string
--         -- NOTE: Returning some weird values at first, causing some spam
--         -- local modNum = mod(self.graphPlotX, graph.XGridInterval * graphFrame.textInterval)
--         -- if modNum == 0 then
--         --   self:addGraphText()
--         -- end
--
--         graph:RefreshGraph()
--         self:updateGraphTables()
--       end
--     else -- Not self.graphFrame
--       if not self.graphData then
--         self.graphData = {}
--         self.graphPlotX = 0
--         self.graphPlotDistance = 1
--       end
--
--       self.graphData[#self.graphData + 1] = {self.graphPlotX, percent}
--       self.graphPlotX = self.graphPlotX + self.graphPlotDistance
--     end
--
--     self.graphUpdateDelay = time + 2 -- Plot graph points every X seconds
--   end
-- end


-- local lastDataNum = #self.graph.Data[1].Points
-- local sx = self.graph.Data[1].Points[lastDataNum][1]
-- local sy = self.graph.Data[1].Points[lastDataNum][2]
-- local ex = graphFrame.start
-- local ey = percent
-- local w = 32
-- local color = self.graph.Data[1].Color

-- graph:DrawLine(graph, sx, sy, ex, ey, w, color)
