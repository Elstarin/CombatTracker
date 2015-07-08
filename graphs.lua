if not CombatTracker then return end

local CT = CombatTracker
local graphLib = LibStub:GetLibrary("LibGraph-2.0")
local graphFunctions = {}

local round = CT.round
local formatTimer = CT.formatTimer
local colorText = CT.colorText

function CT:updateGraphTables()
  local graphFrame = self.graphFrame
  local graph = self.graph
  local textFrame = graph.TextFrame

  if not self.graphLines then
    self.graphLines = {}
    self.graphLines.vertical = {}
    self.graphLines.horizontal = {}
    self.graphLines.dataLines = {}
  end

  local horizontal = self.graphLines.horizontal
  local vertical = self.graphLines.vertical
  local dataLines = self.graphLines.dataLines

  wipe(vertical)
  wipe(horizontal)
  wipe(dataLines)

  local graphWidth, graphHeight = graph:GetSize()

  for i,v in ipairs(graph.GraphLib_Lines_Used) do
    local lineWidth, lineHeight = v:GetSize()

    if (lineWidth + 1) > graphWidth then
      horizontal[#horizontal + 1] = v
      v.num = i
    elseif lineHeight > (graphHeight - 5) then
      vertical[#vertical + 1] = v
      v.num = i
    elseif lineHeight < 50 then
      local x, y = v:GetCenter()
      dataLines[#dataLines + 1] = v
      v.coordsX = x
      v.coordsY = y
      v.width = lineWidth
      v.num = i
    else
      -- print("FAILED TO GO IN ANY TABLE")
    end
  end

  self.oldGraphNum = #graph.GraphLib_Lines_Used

  graphFrame.dataLines = dataLines
end

function CT:hideUptimeLines()
  local graphWidth, graphHeight = self.graph:GetSize()

  local count = 0
  for i = 1, #self.graph.GraphLib_Lines_Used do
    local line = self.graph.GraphLib_Lines_Used[i]

    line:SetAlpha(0)

    count = count + 1
    if count == 1 then
      line:SetAlpha(1)
    elseif count == 2 then
      count = 0
    end
  end
end

function CT:uptimeGraphUpdate(spell, time)
  if not self.graphData then
    self.graphData = {}
  end

  local timer = (time or GetTime()) - CT.TimeSinceLogIn
  local data = self.graphData
  local num = #data + 1

  if spell.graphCooldownStart then
    if data[num - 1] then -- This is necessary to stop it from screwing up
      local prevTimer = data[num - 1][1]

      if prevTimer >= timer then
        timer = prevTimer + 0.00001
      end
    end

    data[num] = {}
    data[num][1] = timer
    data[num][2] = 5
    data[num]["start"] = true
    data[num]["num"] = spell.casts

    spell.graphCooldownStart = false
  elseif spell.graphCooldownEnd then
    data[num] = {}
    data[num][1] = timer
    data[num][2] = 5
    data[num]["end"] = true
    data[num]["num"] = spell.casts

    if self.expanded then
      self.graph:RefreshGraph()
      self:hideUptimeLines()
    end

    spell.graphCooldownEnd = false
  end
end

local function uptimeGraphOnUpdate(self, mouseOver, UIScale)
  local mouseX, mouseY = GetCursorPosition()
  local mouseX = (mouseX / UIScale)
  local mouseY = (mouseY / UIScale)
  local alpha, line, num, lineRight, lineLeft
  local graph = self.graph
  local YELLOW = "FFFFFF00"

  mouseOver:SetPoint("LEFT", UIParent, mouseX, 0)

  for i = 2, #graph.GraphLib_Lines_Used do
    line = graph.GraphLib_Lines_Used[i]
    lineRight = line:GetRight()

    if lineRight > mouseX then
      lineLeft = line:GetLeft()
      alpha = line:GetAlpha()
      num = i - 1
      break
    end
  end

  if (num == 1) or (num == 2 and lineLeft > mouseX) then
    local dataX = self.graphData[num - 1] or self.graphData[num]
    local data = ("Time: |c%s0:00 - %s\n|rGap: |c%s%.3f"):format(YELLOW, formatTimer(dataX[1]), YELLOW, dataX[1])
    CT.graphTooltip:SetText(data, 1, 1, 1, 1)
  elseif num then
    if alpha == 0 then
      local dataX = self.graphData[num][1]
      local prevDataX = self.graphData[num - 1][1]

      local data = ("Time: |c%s%s - %s\n|rGap: |c%s%.3f"):format(YELLOW, formatTimer(prevDataX), formatTimer(dataX), YELLOW, dataX - prevDataX)
      CT.graphTooltip:SetText(data, 1, 1, 1, 1)
    else
      local dataX = self.graphData[num][1]
      local prevDataX = self.graphData[num - 1][1]
      local data = ("Time: |c%s%s - %s\n|rCD: |c%s%.3f"):format(YELLOW, formatTimer(prevDataX), formatTimer(dataX), YELLOW, dataX - prevDataX)
      CT.graphTooltip:SetText(data, 1, 1, 1, 1)
    end
  else
    local graphDataNum, prevDataX, dataX = #self.graphData

    if graphDataNum > 1 then
      if not self.graphData[graphDataNum].start then
        dataX = GetTime() - CT.TimeSinceLogIn
        prevDataX = self.graphData[graphDataNum][1]
      else
        dataX = self.graphData[graphDataNum][1]
        prevDataX = self.graphData[graphDataNum - 1][1]
      end

      local data = ("Time: |c%s%s - %s\n|rGap: |c%s%.3f"):format(YELLOW, formatTimer(prevDataX), formatTimer(dataX), YELLOW, dataX - prevDataX)
      CT.graphTooltip:SetText(data, 1, 1, 1, 1)
    end
  end
end

local function normalGraphOnUpdate(self, mouseOver, dot, UIScale)
  local mouseX, mouseY = GetCursorPosition()
  local mouseX = (mouseX / UIScale)
  local mouseY = (mouseY / UIScale)

  mouseOver:SetPoint("LEFT", UIParent, mouseX, 0)

  local lineNum, line, nextLine

  if self.graphFrame.dataLines then
    for i = 1, #self.graphFrame.dataLines do
      local dataLines = self.graphFrame.dataLines[i]
      local dataRight = dataLines:GetRight()

      if dataRight > mouseX then
        lineNum = i
        line = dataLines

        nextLine = self.graphFrame.dataLines[i + 1]
        break
      end
    end
  end

  if line then
    dot:Show()
    local x, y = line:GetCenter()
    local height = line:GetHeight() / 2
    local bottom = line:GetBottom() + (height / 2)
    local top = line:GetTop() - height

    local dataX = self.graphData[lineNum + 1][1] or self.graphData[lineNum][1]
    local dataY = self.graphData[lineNum + 1][2] or self.graphData[lineNum][2]
    local offSetY = (self.graphFrame:GetHeight() / self.graphFrame.YMax) * dataY

    dot:SetPoint("BOTTOM", mouseOver, 0, dataY)
    -- dot:SetPoint("CENTER", line, 0, 0)

    local data = formatTimer(dataX) .. ": " .. round(dataY, 1) .. "%"
    CT.graphTooltip:SetText(data, 1, 1, 1, 1)
    CT.graphTooltip:SetAlpha(1)
  else
    dot:Hide()
    CT.graphTooltip:SetAlpha(0)
  end
end

function CT:buildUptimeGraph()
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander
  local graphHeight = 10
  local mouseOver, dragOverlay, zoomedButton

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

  if not self.graphFrame then
    self.graphFrame = CreateFrame("Frame", "graphFrame", dropDown)
    self.graphFrame:SetSize(dropDown:GetWidth() - 6, graphHeight)
    self.graphFrame:SetPoint("LEFT", 0, 3)
    self.graphFrame:SetPoint("RIGHT", 0, 3)
    self.graphFrame:SetPoint("BOTTOM", 0, 0)
    self.graphFrame.background = self.graphFrame:CreateTexture(nil, "BACKGROUND")
    self.graphFrame.background:SetAllPoints()
    self.graphFrame.background:SetTexture(0.07, 0.07, 0.07, 1.0)

    do -- MouseoverLine
      self.graphFrame.mouseOverLine = CreateFrame("Frame", nil, self.graphFrame)
      mouseOver = self.graphFrame.mouseOverLine
      mouseOver:SetSize(2, graphHeight)
      mouseOver:SetPoint("TOP", 0, 0)
      mouseOver:SetPoint("BOTTOM", 0, 0)
      mouseOver.texture = mouseOver:CreateTexture(nil, "OVERLAY")
      mouseOver.texture:SetTexture(1.0, 1.0, 1.0, 1.0)
      mouseOver.texture:SetAllPoints()
      mouseOver:Hide()
    end

    local UIScale = UIParent:GetEffectiveScale()

    self.graphFrame.mouseOverLine:SetScript("OnUpdate", function(mouseOver, elapsed)
      uptimeGraphOnUpdate(self, self.graphFrame.mouseOverLine, UIScale)
    end)
    self.graphFrame:SetScript("OnEnter", function(graphFrame)
      self.graphFrame.mouseOverLine:Show()
      CT.graphTooltip:SetOwner(self.graphFrame.mouseOverLine, "ANCHOR_TOPLEFT", 25, 8)
      CT.graphTooltip:SetCurrencyToken(1)
      CT.graphTooltip:SetBackdropColor(0.1, 0.1, 0.1, 1.0)
      CT.graphTooltip:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.4)
    end)
    self.graphFrame:SetScript("OnLeave", function(graphFrame)
      self.graphFrame.mouseOverLine:Hide()
      CT.graphTooltip:Hide()
    end)
    self.graphFrame:SetScript("OnMouseDown", function(graphFrame, button)
    end)
    self.graphFrame:SetScript("OnMouseUp", function(graphFrame, button)
    end)
  end

  do
    local graph = graphLib:CreateGraphLine(nil, self.graphFrame, "CENTER", "CENTER", 0, 0, self.graphFrame:GetWidth(), graphHeight)
    self.graph = graph
    graph.XMin = 0
    graph.XMax = 10
    graph.YMin = 0
    graph.YMax = graphHeight
    graph.XGridInterval = 10000
    graph.YGridInterval = 10000
    graph.GridColor = {0, 0, 0, 0}
    graph.XAxisDrawn = false
    graph.YAxisDrawn = false
    graph:SetAllPoints()
    graph.graphType = "uptime"

    if not self.graphData then
      self.graphData = {}
    end

    if not graph.GraphLib_Lines_Used then graph.GraphLib_Lines_Used = {} end

    graph:AddDataSeries(self.graphData, {0.25, 0.25, 1.0, 1.0})

    dropDown.dropHeight = (dropDown.dropHeight or 0) + graphHeight
  end
end

function CT:buildGraph(height, yAxis, graphType)
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander
  local mouseOver, dot, dragOverlay, zoomedButton

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

  if not self.graphFrame then
    self.graphFrame = CreateFrame("Frame", "graphFrame", dropDown)
    self.graphFrame:SetSize(dropDown:GetWidth() - 6, height)
    self.graphFrame:SetPoint("LEFT", 0, 3)
    self.graphFrame:SetPoint("RIGHT", 0, 3)
    self.graphFrame:SetPoint("BOTTOM", 0, 0)
    self.graphFrame.background = self.graphFrame:CreateTexture(nil, "BACKGROUND")
    self.graphFrame.background:SetAllPoints()
    self.graphFrame.background:SetTexture(0.07, 0.07, 0.07, 1.0)

    do -- MouseoverLine
      self.graphFrame.mouseOverLine = CreateFrame("Frame", nil, self.graphFrame)
      mouseOver = self.graphFrame.mouseOverLine
      mouseOver:SetSize(2, height)
      mouseOver:SetPoint("TOP", 0, 0)
      mouseOver:SetPoint("BOTTOM", 0, 0)
      mouseOver.texture = mouseOver:CreateTexture(nil, "OVERLAY")
      mouseOver.texture:SetTexture(1.0, 1.0, 1.0, 1.0)
      mouseOver.texture:SetAllPoints()
      mouseOver:Hide()
    end

    do -- Dot
      self.graphFrame.mouseOverLine.dot = CreateFrame("Frame", nil, self.graphFrame.mouseOverLine)
      dot = self.graphFrame.mouseOverLine.dot
      dot:SetSize(10, 10)
      dot:SetPoint("CENTER", 0, 0)
      dot:Hide()

      dot.texture = dot:CreateTexture(nil, "OVERLAY")
      dot.texture:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
      dot.texture:SetAllPoints()
    end

    do -- Drag Overlay
      self.graphFrame.dragOverlay = CreateFrame("Frame", nil, self.graphFrame)
      dragOverlay = self.graphFrame.dragOverlay
      dragOverlay:SetSize(60, height)
      dragOverlay:SetPoint("TOP", 0, 0)
      dragOverlay:SetPoint("BOTTOM", 0, 0)
      dragOverlay.texture = dragOverlay:CreateTexture(nil, "OVERLAY")
      dragOverlay.texture:SetTexture(0.3, 0.3, 0.3, 0.4)
      dragOverlay.texture:SetAllPoints()
      dragOverlay:Hide()
    end

    do -- Zoom Button
      self.graphFrame.zoomedButton = CreateFrame("Button", nil, self.graphFrame)
      zoomedButton = self.graphFrame.zoomedButton
      zoomedButton:SetSize(90, 20)
      zoomedButton:SetPoint("BOTTOMLEFT", 0, 0)

      local backdrop = {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
      }

      zoomedButton:SetBackdrop(backdrop)
      zoomedButton:SetBackdropColor(0.15, 0.15, 0.15, 1.0)
      zoomedButton:SetBackdropBorderColor(0.7, 0.7, 0.7, 1.0)

      zoomedButton.highlight = zoomedButton:CreateTexture(nil, "OVERLAY")
      zoomedButton.highlight:SetTexture(0.2, 0.2, 0.2, 0.3)
      zoomedButton.highlight:SetAllPoints()
      zoomedButton:SetHighlightTexture(zoomedButton.highlight)

      zoomedButton.text = zoomedButton:CreateFontString(nil, "OVERLAY")
      zoomedButton.text:SetFont("Fonts\\FRIZQT__.TTF", 13)
      zoomedButton.text:SetTextColor(1, 1, 1)
      zoomedButton.text:SetPoint("CENTER")
      zoomedButton.text:SetText("Reset Zoom")
      zoomedButton:Hide()
    end

    local UIScale = UIParent:GetEffectiveScale()

    self.graphFrame.mouseOverLine:SetScript("OnUpdate", function(mouseOver, elapsed)
      local mouseOver = self.graphFrame.mouseOverLine
      local dot = self.graphFrame.mouseOverLine.dot

      self.graph.updateFunc(self, mouseOver, dot, UIScale)
    end)
    self.graphFrame:SetScript("OnEnter", function(graphFrame)
      local mouseOver = self.graphFrame.mouseOverLine
      local dot = self.graphFrame.mouseOverLine.dot

      mouseOver:Show()
      CT.graphTooltip:SetOwner(dot, "ANCHOR_TOPLEFT", 25, 8)
      CT.graphTooltip:SetCurrencyToken(1)
      CT.graphTooltip:SetBackdropColor(0.1, 0.1, 0.1, 1.0)
      CT.graphTooltip:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.4)
    end)
    self.graphFrame:SetScript("OnLeave", function(graphFrame)
      local mouseOver = self.graphFrame.mouseOverLine

      mouseOver:Hide()
      CT.graphTooltip:Hide()
    end)
    self.graphFrame:SetScript("OnMouseDown", function(graphFrame, button)
      local graph = self.graph
      local dragOverlay = self.graphFrame.dragOverlay
      local mouseOver = self.graphFrame.mouseOverLine
      local zoomedButton = self.graphFrame.zoomedButton

      if not graphFrame.zoomed then
        local graphLeft = graphFrame:GetLeft()
        local mouseOverLeft = mouseOver:GetLeft() - graphLeft

        dragOverlay:Show()
        dragOverlay:SetPoint("LEFT", mouseOverLeft, 0)
        dragOverlay:SetPoint("RIGHT", mouseOver, 0, 0)

        graphFrame.mouseOverLeft = mouseOverLeft
      end
    end)
    self.graphFrame:SetScript("OnMouseUp", function(graphFrame, button)
      local graph = graphFrame.graph
      local dragOverlay = self.graphFrame.dragOverlay
      local mouseOver = self.graphFrame.mouseOverLine
      local zoomedButton = self.graphFrame.zoomedButton

      if not graphFrame.zoomed then
        local graphLeft = graphFrame:GetLeft()
        local graphRight = graphFrame:GetRight()
        local mouseOverRight = mouseOver:GetRight()
        local graphWidth = graphFrame:GetWidth()

        local startX = ((graphFrame.mouseOverLeft / graph.XMax))
        local endX = (((mouseOverRight - graphLeft) / graph.XMax))

        local startX = (graphFrame.mouseOverLeft / graphWidth) * graph.XMax
        local endX = ((mouseOverRight - graphLeft) / graphWidth) * graph.XMax

        dragOverlay:Hide()
        dragOverlay:SetPoint("RIGHT", mouseOverRight - graphRight, 0)

        graphFrame.oldXMax = graph.XMax
        graphFrame.zoomed = true

        graph.XMin = startX
        graph.XMax = endX
        graph:RefreshGraph()

        if graph.graphType == "uptime" then
          self:hideUptimeLines()
        end

        zoomedButton:Show()
      end
    end)
    self.graphFrame.zoomedButton:SetScript("OnClick", function(zoomedButton, button)
      local graphFrame = self.graphFrame
      local graph = self.graph

      if graphFrame.zoomed then
        graphFrame.zoomed = false
        graph.XMin = 0
        graph.XMax = graphFrame.oldXMax
        graph:RefreshGraph()

        if graph.graphType == "uptime" then
          self:hideUptimeLines()
        end

        self.graphFrame.dragOverlay:Hide()
        self.graphFrame.zoomedButton:Hide()
        self.graphFrame.mouseOverLine.dot:Hide()
      end
    end)
  end

  do
    local graph = graphLib:CreateGraphLine(nil, self.graphFrame, "CENTER", "CENTER", 0, 0, self.graphFrame:GetWidth(), height)
    self.graph = graph
    graph.XMin = 0
    graph.XMax = 10
    graph.YMin = 0
    graph.YMax = yAxis
    graph:SetGridSpacing(10, 10)
    graph:SetGridColor({0.5, 0.5, 0.5, 0.1})
    graph:SetAxisDrawing(false, false)
    graph:SetPoint("LEFT", 0, 3)
    graph:SetPoint("RIGHT", 0, 3)
    graph.graphType = "normal"
    graph.updateFunc = normalGraphOnUpdate

    if not self.graphData then
      self.graphData = {}
      CT.registerGraphs[#CT.registerGraphs + 1] = self
    end

    if not graph.GraphLib_Lines_Used then graph.GraphLib_Lines_Used = {} end

    graph:AddDataSeries(self.graphData, {0.25, 0.25, 1.0, 1.0})
    self.graphFrame.YMax = graph.YMax

    return self.graphFrame
  end
end

function CT:buildPieChart(height)
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  if not self.graphFrame then
    self.graphFrame = CreateFrame("Frame", "graphFrame", dropDown)
    self.graphFrame:SetSize(dropDown:GetWidth() - 6, height)
    self.graphFrame:SetPoint("LEFT", 0, 3)
    self.graphFrame:SetPoint("RIGHT", 0, 3)
    self.graphFrame:SetPoint("BOTTOM", 0, 0)
    self.graphFrame.background = self.graphFrame:CreateTexture(nil, "BACKGROUND")
    self.graphFrame.background:SetAllPoints()
    self.graphFrame.background:SetTexture(0.07, 0.07, 0.07, 1.0)
  end

  do
    local graph = graphLib:CreateGraphPieChart(nil, self.graphFrame, "CENTER", "CENTER", -45, -45, 75, 75)
    self.graph = graph
    graph:SetAllPoints()
    graph:AddPie(35, {1.0, 0.0, 0.0})
       graph:AddPie(21, {0.0, 1.0, 0.0})
       graph:AddPie(10, {1.0, 1.0, 1.0})
       graph:CompletePie({0.2, 0.2, 1.0})

    graph.graphType = "pie" -- Mmmm

    if not self.graphData then
      self.graphData = {}
    end

    -- if not graph.GraphLib_Lines_Used then graph.GraphLib_Lines_Used = {} end
    --
    -- graph:AddDataSeries(self.graphData, {0.25, 0.25, 1.0, 1.0})
    -- self.graphFrame.YMax = graph.YMax

    return self.graphFrame
  end
end


-- -- Should pass if it's part of the plot line, not part of the graph structure
-- if lineHeight ~= graphHeight and (lineWidth + 1) < graphWidth then
  -- self.graphPlotLines[#self.graphPlotLines + 1] = line
  -- count = count + 1
  --
  -- if count == 1 then
  --   line:SetAlpha(1)
  -- elseif count == 2 then
  --   count = 0
  -- end
-- end

-- local string = "Time: |c%s%s - %s\n|rGap: |c%s%s"
-- -- string:format(YELLOW, formatTimer(prevDataX), formatTimer(dataX), YELLOW, round(dataX - prevDataX, 3))
--
-- local dataX, prevDataX
-- if alpha == 0 then
--   if self.graphData[lineNum + 1] then
--     dataX = self.graphData[lineNum + 1][1]
--     prevDataX = self.graphData[lineNum][1]
--   else
--     dataX = self.graphData[lineNum][1]
--     prevDataX = self.graphData[lineNum - 1][1]
--   end
--
--   -- local data = "Time: |cFFFFFF00" .. formatTimer(prevDataX) .. " - " .. formatTimer(dataX) .. "\n" .. "|rGap: |cFFFFFF00" .. round(dataX - prevDataX, 3)
--   local data = ("Time: |c%s%s - %s\n|rGap: |c%s%s"):format(YELLOW, formatTimer(prevDataX), formatTimer(dataX), YELLOW, round(dataX - prevDataX, 3))
--   CT.graphTooltip:SetText(data, 1, 1, 1, 1)
-- elseif lineNum and alpha > 0 then
--   local data
--
--   if lineLeft > mouseX then
--     dataX = self.graphData[lineNum][1]
--     prevDataX = 0
--     -- data = "Time: |cFFFFFF00" .. "0:00 - " .. formatTimer(dataX) .. "\n" .. "|rGap: |cFFFFFF00" .. round(dataX - prevDataX, 3)
--     data = string:format(YELLOW, "0:00", formatTimer(dataX), YELLOW, round(dataX - prevDataX, 3))
--   elseif self.graphData[lineNum + 1] then
--     dataX = self.graphData[lineNum + 1][1]
--     prevDataX = self.graphData[lineNum][1]
--     data = ("Time: |c%s%s - %s\n|rCD: |c%s%s"):format(YELLOW, formatTimer(prevDataX), formatTimer(dataX), YELLOW, round(dataX - prevDataX, 3))
--   else
--     dataX = self.graphData[lineNum][1]
--     prevDataX = self.graphData[lineNum - 1][1]
--     data = ("Time: |c%s%s - %s"):format(YELLOW, formatTimer(prevDataX), formatTimer(dataX))
--   end
--
--   CT.graphTooltip:SetText(data, 1, 1, 1, 1)
-- else
--   local graphDataNum = #self.graphData
--
--   if graphDataNum > 1 then
--     if not self.graphData[graphDataNum].start then
--       dataX = GetTime() - CT.TimeSinceLogIn
--       prevDataX = self.graphData[graphDataNum][1]
--     else
--       dataX = self.graphData[graphDataNum][1]
--       prevDataX = self.graphData[graphDataNum - 1][1]
--     end
--
--     -- local data = "Time: |cFFFFFF00" .. formatTimer(prevDataX) .. " - " .. formatTimer(dataX) .. "\n" .. "|rGap: |cFFFFFF00" .. round(dataX - prevDataX, 3)
--     local data = string:format(YELLOW, formatTimer(prevDataX), formatTimer(dataX), YELLOW, round(dataX - prevDataX, 3))
--     CT.graphTooltip:SetText(data, 1, 1, 1, 1)
--   end
-- end
