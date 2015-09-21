if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker

--------------------------------------------------------------------------------
-- DropDown Menu Types
--------------------------------------------------------------------------------
function CT:type1(lineTable)
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  dropDown.lineHeight = 43
  dropDown.linePadding = 3
  dropDown.numLines = 1

  dropDown.middleBar = CreateFrame("Frame", "DropDownFrameMiddleBar", dropDown)
  dropDown.middleBar:SetSize(1, 1)
  dropDown.middleBar:SetPoint("TOP", 0, 0)
  dropDown.middleBar:SetPoint("BOTTOM", 0, 0)

  dropDown.line = {}
  dropDown.line[1] = CreateFrame("Frame", "DropDownFrameAnchor" .. 1, dropDown)
  local line = dropDown.line[1]

  line:SetSize(80, 40)
  line:SetPoint("TOPRIGHT", dropDown, -3, -3)
  line:SetPoint("TOPLEFT", dropDown, 3, -3)

  dropDown.dropHeight = (dropDown.dropHeight or 0) + 43

  do -- left
    line.left = CreateFrame("Frame", "DropDownHeaderFrameLeft" .. 1, line)
    local lineSide = line.left
    dropDown.left = {line.left}

    lineSide:SetSize(80, 40)
    lineSide:SetPoint("TOPRIGHT", dropDown.middleBar, -1.5, -3)
    lineSide:SetPoint("TOPLEFT", dropDown, 3, -3)

    lineSide.background = lineSide:CreateTexture(nil, "BACKGROUND")
    lineSide.background:SetAllPoints()
    lineSide.background:SetTexture(0.7, 0.7, 0.7, 0.1)

    lineSide.title = lineSide:CreateFontString("title", "ARTWORK")
    lineSide.title:SetPoint("LEFT", 2, 0)
    lineSide.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
    lineSide.title:SetTextColor(1, 1, 1, 1)
    lineSide.title:SetText(lineTable[1])

    lineSide.value = lineSide:CreateFontString("value", "ARTWORK")
    lineSide.value:SetPoint("RIGHT", -10, 0)
    lineSide.value:SetFont("Fonts\\FRIZQT__.TTF", 30)
    lineSide.value:SetTextColor(1, 1, 0, 1)
    lineSide.value:SetText(random(70, 100) .. "%")
  end

  do -- right
    line.right = CreateFrame("Frame", "DropDownHeaderFrameRight" .. 1, line)
    local lineSide = line.right
    dropDown.right = {line.right}

    lineSide:SetSize(80, 40)
    lineSide:SetPoint("TOPLEFT", dropDown.middleBar, 1.5, -3)
    lineSide:SetPoint("TOPRIGHT", dropDown, -3, -3)

    lineSide.background = lineSide:CreateTexture(nil, "BACKGROUND")
    lineSide.background:SetAllPoints()
    lineSide.background:SetTexture(0.7, 0.7, 0.7, 0.1)

    lineSide.title = lineSide:CreateFontString("title", "ARTWORK")
    lineSide.title:SetPoint("LEFT", 2, 0)
    lineSide.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
    lineSide.title:SetTextColor(1, 1, 1, 1)
    lineSide.title:SetText(lineTable[2])

    lineSide.value = lineSide:CreateFontString("value", "ARTWORK")
    lineSide.value:SetPoint("RIGHT", -10, 0)
    lineSide.value:SetFont("Fonts\\FRIZQT__.TTF", 30)
    lineSide.value:SetTextColor(1, 1, 0, 1)
    lineSide.value:SetText(random(70, 100) .. "%")
  end

  self.text[1] = {}
  self.text[1].left = line.left.value
  self.text[1].right = line.right.value

  if self.graph and not self.graphCreated then
    self:graph(100, 100)

    local graph = self.graph
    graph:ClearAllPoints()
    graph:SetParent(self.button.dropDown)
    graph:SetPoint("LEFT", 0, 3)
    graph:SetPoint("RIGHT", 0, 3)
    graph:SetPoint("BOTTOM", 0, 0)

    dropDown.dropHeight = (dropDown.dropHeight or 0) + 100 + 6
  end
end

function CT:type1AddLeft(spellName)
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  local lineNum = #dropDown.line
  local num = #dropDown.left
  local line, lineSide

  if num == lineNum then
    dropDown.line[lineNum + 1] = CreateFrame("Frame", "DropDownFrameAnchor" .. lineNum + 1, dropDown)
    line = dropDown.line[lineNum + 1]

    line:SetSize(80, 40)
    line:SetPoint("RIGHT", dropDown, -3, -3)
    line:SetPoint("LEFT", dropDown, 3, -3)
    line:SetPoint("TOP", dropDown.line[lineNum], "BOTTOM", 0, -3)

    dropDown.numLines = dropDown.numLines + 1
    dropDown.dropHeight = (dropDown.dropHeight or 0) + 43
  else
    line = dropDown.line[num + 1]
  end

  -- Add left
  line.left = CreateFrame("Frame", "DropDownFrameLeft" .. num + 1, line)
  local lineSide = line.left
  dropDown.left[#dropDown.left + 1] = {line.left}

  lineSide:SetSize(80, 40)
  lineSide:SetPoint("RIGHT", dropDown.middleBar, -1.5, -3)
  lineSide:SetPoint("LEFT", dropDown, 3, -3)
  lineSide:SetPoint("TOP", dropDown.line[num].left, "BOTTOM", 0, -3)

  lineSide.background = lineSide:CreateTexture(nil, "BACKGROUND")
  lineSide.background:SetAllPoints()
  lineSide.background:SetTexture(0.7, 0.7, 0.7, 0.1)

  lineSide.icon = lineSide:CreateTexture(nil, "BACKGROUND")
  lineSide.icon:SetSize(36, 36)
  lineSide.icon:SetPoint("LEFT", 2, 0)
  lineSide.icon:SetTexture(GetSpellTexture(spellName))

  SetPortraitToTexture(lineSide.icon, lineSide.icon:GetTexture())
  lineSide.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  lineSide.icon:SetAlpha(0.9)

  lineSide.value1 = lineSide:CreateFontString(nil, "ARTWORK")
  lineSide.value1:SetPoint("LEFT", lineSide.icon, "RIGHT", 3, 0)
  lineSide.value1:SetFont("Fonts\\FRIZQT__.TTF", 20)
  lineSide.value1:SetTextColor(1, 1, 0, 1)
  lineSide.value1:SetText(random(1, 50) .. "%")

  lineSide.value2 = lineSide:CreateFontString(nil, "ARTWORK")
  lineSide.value2:SetPoint("TOPRIGHT", -3, -2)
  lineSide.value2:SetFont("Fonts\\FRIZQT__.TTF", 13)
  lineSide.value2:SetTextColor(1, 1, 0, 1)
  lineSide.value2:SetText("Gain: " .. random(1, 50))

  lineSide.value3 = lineSide:CreateFontString(nil, "ARTWORK")
  lineSide.value3:SetPoint("BOTTOMRIGHT", -3, 4)
  lineSide.value3:SetFont("Fonts\\FRIZQT__.TTF", 13)
  lineSide.value3:SetTextColor(1, 1, 0, 1)
  lineSide.value3:SetText("Loss: " .. random(1, 30))

  if not self.text[num + 1] then self.text[num + 1] = {} end
  self.text[num + 1].left = {lineSide.value1, lineSide.value2, lineSide.value3}
end

function CT:type1AddRight(spellName)
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  local lineNum = #dropDown.line
  local num = #dropDown.right
  local line, lineSide

  if num == lineNum then
    dropDown.line[lineNum + 1] = CreateFrame("Frame", "DropDownFrameAnchor" .. lineNum + 1, dropDown)
    line = dropDown.line[lineNum + 1]

    line:SetSize(80, 40)
    line:SetPoint("RIGHT", dropDown, -3, -3)
    line:SetPoint("LEFT", dropDown, 3, -3)
    line:SetPoint("TOP", dropDown.line[lineNum], "BOTTOM", 0, -3)

    dropDown.numLines = dropDown.numLines + 1
    dropDown.dropHeight = (dropDown.dropHeight or 0) + 43
  else
    line = dropDown.line[num + 1]
  end

     -- Add right
  line.right = CreateFrame("Frame", "DropDownFrameRight" .. num + 1, line)
  local lineSide = line.right
  dropDown.right[#dropDown.right + 1] = {line.right}

  lineSide:SetSize(80, 40)
  lineSide:SetPoint("LEFT", dropDown.middleBar, 1.5, -3)
  lineSide:SetPoint("RIGHT", dropDown, -3, -3)
  lineSide:SetPoint("TOP", dropDown.line[num].right, "BOTTOM", 0, -3)

  lineSide.background = lineSide:CreateTexture(nil, "BACKGROUND")
  lineSide.background:SetAllPoints()
  lineSide.background:SetTexture(0.7, 0.7, 0.7, 0.1)

  lineSide.icon = lineSide:CreateTexture(nil, "BACKGROUND")
  lineSide.icon:SetSize(36, 36)
  lineSide.icon:SetPoint("LEFT", 2, 0)
  lineSide.icon:SetTexture(GetSpellTexture(spellName))

  SetPortraitToTexture(lineSide.icon, lineSide.icon:GetTexture())
  lineSide.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  lineSide.icon:SetAlpha(0.9)

  lineSide.value1 = lineSide:CreateFontString(nil, "ARTWORK")
  lineSide.value1:SetPoint("LEFT", lineSide.icon, "RIGHT", 3, 0)
  lineSide.value1:SetFont("Fonts\\FRIZQT__.TTF", 20)
  lineSide.value1:SetTextColor(1, 1, 0, 1)
  lineSide.value1:SetText(random(1, 50) .. "%")

  lineSide.value2 = lineSide:CreateFontString(nil, "ARTWORK")
  lineSide.value2:SetPoint("TOPRIGHT", -3, -2)
  lineSide.value2:SetFont("Fonts\\FRIZQT__.TTF", 13)
  lineSide.value2:SetTextColor(1, 1, 0, 1)
  lineSide.value2:SetText("Gain: " .. random(1, 50))

  lineSide.value3 = lineSide:CreateFontString(nil, "ARTWORK")
  lineSide.value3:SetPoint("BOTTOMRIGHT", -3, 4)
  lineSide.value3:SetFont("Fonts\\FRIZQT__.TTF", 13)
  lineSide.value3:SetTextColor(1, 1, 0, 1)
  lineSide.value3:SetText("Loss: " .. random(1, 30))

  if not self.text[num + 1] then self.text[num + 1] = {} end
  self.text[num + 1].right = {lineSide.value1, lineSide.value2, lineSide.value3}
end

function CT:type2(lineTable)
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  dropDown.lineHeight = 43
  dropDown.linePadding = 3

  if not dropDown.line then dropDown.line = {} end

  for i = 1, #lineTable do
    dropDown.dropHeight = (dropDown.dropHeight or 0) + 43
    dropDown.numLines = dropDown.numLines + 1

    local prevLine = #dropDown.line
    local lineNum = prevLine + 1

    dropDown.line[lineNum] = CreateFrame("Frame", "DropDownFrame" .. lineNum, dropDown)
    local line = dropDown.line[lineNum]

    line:SetSize(80, 40)

    line:SetPoint("LEFT", dropDown, 3, -3)
    line:SetPoint("RIGHT", dropDown, -3, -3)
    line:SetPoint("BOTTOM", dropDown, "TOP", 0, -(i * dropDown.lineHeight))

    line.background = line:CreateTexture(nil, "BACKGROUND")
    line.background:SetAllPoints()
    line.background:SetTexture(0.7, 0.7, 0.7, 0.1)

    line.title = line:CreateFontString("title", "ARTWORK")
    line.title:SetPoint("LEFT", 20, 0)
    line.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
    line.title:SetTextColor(1, 1, 1, 1)
    line.title:SetText(lineTable[i])

    line.value = line:CreateFontString("value", "ARTWORK")
    line.value:SetPoint("RIGHT", -20, 0)
    line.value:SetFont("Fonts\\FRIZQT__.TTF", 30)
    line.value:SetTextColor(1, 1, 0, 1)
    line.value:SetText(random(1, 50))

    self.text[i] = line.value
  end

  if self.graph and not self.graphCreated then
    self:graph()

    local graph = self.graph
    graph:ClearAllPoints()
    graph:SetParent(self.button.dropDown)
    graph:SetPoint("LEFT", 0, 3)
    graph:SetPoint("RIGHT", 0, 3)
    graph:SetPoint("BOTTOM", 0, 0)
  end
end

function CT:type3(lineTable)
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  dropDown.lineHeight = 23
  dropDown.linePadding = 23
  dropDown.numLines = 1

  dropDown.middleBar = CreateFrame("Frame", "DropDownFrameMiddleBar", dropDown)
  dropDown.middleBar:SetSize(1, 1)
  dropDown.middleBar:SetPoint("TOP", 0, 0)
  dropDown.middleBar:SetPoint("BOTTOM", 0, 0)

  if not dropDown.line then dropDown.line = {} end

  dropDown.line[1] = CreateFrame("Frame", "DropDownFrame" .. 1, dropDown)
  local line = dropDown.line[1]

  line:SetSize(80, 40)
  line:SetPoint("TOPRIGHT", dropDown, -3, -3)
  line:SetPoint("TOPLEFT", dropDown, 3, -3)

  dropDown.dropHeight = (dropDown.dropHeight or 0) + 43

  for i = 1, 2 do
    line[i] = CreateFrame("Frame", "DropDownHeaderFrame" .. i, dropDown.middleBar)
    line[i]:SetSize(80, 40)

    if i == 1 then
      line[i]:SetPoint("TOPRIGHT", -1.5, -3)
      line[i]:SetPoint("TOPLEFT", dropDown, 3, -3)
    elseif i == 2 then
      line[i]:SetPoint("TOPLEFT", 1.5, -3)
      line[i]:SetPoint("TOPRIGHT", dropDown, -3, -3)
    end

    line[i].background = line[i]:CreateTexture(nil, "BACKGROUND")
    line[i].background:SetAllPoints()
    line[i].background:SetTexture(0.7, 0.7, 0.7, 0.1)

    line[i].title = line[i]:CreateFontString("title", "ARTWORK")
    line[i].title:SetPoint("LEFT", 2, 0)
    line[i].title:SetFont("Fonts\\FRIZQT__.TTF", 12)
    line[i].title:SetTextColor(1, 1, 1, 1)
    line[i].title:SetText(lineTable[i])

    line[i].value = line[i]:CreateFontString("value", "ARTWORK")
    line[i].value:SetPoint("RIGHT", -1, 0)
    line[i].value:SetFont("Fonts\\FRIZQT__.TTF", 25)
    line[i].value:SetTextColor(1, 1, 0, 1)
    line[i].value:SetText(random(70, 100) .. "%")
  end

  self.text[1] = {line[1].value, line[2].value}

  if self.graph then
    self:graph()

    local graph = self.graph
    graph:ClearAllPoints()
    graph:SetParent(self.button.dropDown)
    graph:SetPoint("LEFT", 0, 3)
    graph:SetPoint("RIGHT", 0, 3)
    graph:SetPoint("BOTTOM", 0, 0)
  end
end

function CT:type3AddLine()
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  dropDown.numLines = dropDown.numLines + 1

  local lineNum = #dropDown.line + 1

  dropDown.line[lineNum] = CreateFrame("Frame", "DropDownFrame" .. lineNum, dropDown)
  local line = dropDown.line[lineNum]

  line:SetSize(80, 20)
  dropDown.dropHeight = (dropDown.dropHeight or 0) + 23

  line:SetPoint("LEFT", dropDown, 3, -3)
  line:SetPoint("RIGHT", dropDown, -3, -3)

  if dropDown.linePadding > 3 then
    line:SetPoint("BOTTOM", dropDown, "TOP", 0, -(lineNum * dropDown.lineHeight + (dropDown.linePadding - 3)))
  else
    line:SetPoint("BOTTOM", dropDown, "TOP", 0, -(lineNum * dropDown.lineHeight))
  end

  line.background = line:CreateTexture(nil, "BACKGROUND")
  line.background:SetAllPoints()
  line.background:SetTexture(0.7, 0.7, 0.7, 0.1)

  line.title = line:CreateFontString("title", "ARTWORK")
  line.title:SetPoint("LEFT", 20, 0)
  line.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
  line.title:SetTextColor(1, 1, 1, 1)
  line.title:SetText(self.lineTable[3]:format(lineNum - 1))

  line.value = line:CreateFontString("value", "ARTWORK")
  line.value:SetPoint("RIGHT", -20, 0)
  line.value:SetFont("Fonts\\FRIZQT__.TTF", 15)
  line.value:SetTextColor(1, 1, 0, 1)
  line.value:SetText(random(1, 50))

  self.text[lineNum] = line.value
end

function CT:type4(spellName)
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  if not dropDown.line then
    dropDown.line = {}

    local width = dropDown:GetWidth() / 5

    dropDown.anchorBarLeft = CreateFrame("Frame", "DropDownFrameAnchorBarLeft", dropDown)
    dropDown.anchorBarLeft:SetSize(1, 1)
    dropDown.anchorBarLeft:SetPoint("TOP", -width, 0)
    dropDown.anchorBarLeft:SetPoint("BOTTOM", -width, 0)

    dropDown.anchorBarRight = CreateFrame("Frame", "DropDownFrameAnchorBarRight", dropDown)
    dropDown.anchorBarRight:SetSize(10, 1)
    dropDown.anchorBarRight:SetPoint("TOP", width, 0)
    dropDown.anchorBarRight:SetPoint("BOTTOM", width, 0)
  end

  local line, lineSide, lineSideExtra

  for i = 1, 100 do
    if dropDown.line[i] then
      line = dropDown.line[i]

      if not dropDown.line[i].left then
        lineSide = "left"
        break
      elseif not dropDown.line[i].center then
        lineSide = "center"
        break
      elseif not dropDown.line[i].right then
        lineSide = "right"
        break
      end
    else
      dropDown.line[i] = CreateFrame("Frame", "DropDownFrameAnchor" .. i, dropDown)
      line = dropDown.line[i]

      line:SetSize(80, 40)
      line:SetPoint("RIGHT", dropDown, -3, -3)
      line:SetPoint("LEFT", dropDown, 3, -3)

      if dropDown.line[i - 1] then
        line:SetPoint("TOP", dropDown.line[i - 1], "BOTTOM", 0, -3)
      else
        line:SetPoint("TOP", dropDown, 0, -3)
      end

      dropDown.numLines = dropDown.numLines + 1
      dropDown.dropHeight = (dropDown.dropHeight or 0) + 40 + 3
      lineSide = "left"
      break
    end
  end

  if spellName and type(spellName) ~= "table" then
    local lineNum = #dropDown.line

    line[lineSide] = CreateFrame("Button", nil, line)
    local lineSideExtra = lineSide
    local lineSide = line[lineSide]

    local dropDownWidth = (dropDown:GetWidth() / 3)
    lineSide:SetSize(dropDownWidth - 3, 40)

    if lineSideExtra == "left" then
      lineSide:SetPoint("TOPLEFT", dropDown.line[lineNum], 0, 0)
    elseif lineSideExtra == "center" then
      lineSide:SetPoint("TOP", dropDown.line[lineNum], 0, 0)
    elseif lineSideExtra == "right" then
      lineSide:SetPoint("TOPRIGHT", dropDown.line[lineNum], 0, 0)
    end

    lineSide.normal = lineSide:CreateTexture(nil, "BACKGROUND")
    lineSide.normal:SetAllPoints()
    lineSide.normal:SetTexture(0.7, 0.7, 0.7, 0.1)
    lineSide:SetNormalTexture(lineSide.normal)

    lineSide.highlight = lineSide:CreateTexture(nil, "BACKGROUND")
    lineSide.highlight:SetAllPoints()
    lineSide.highlight:SetTexture(0.7, 0.7, 0.7, 0.1)
    lineSide:SetHighlightTexture(lineSide.highlight)

    lineSide.icon = lineSide:CreateTexture(nil, "BACKGROUND")
    lineSide.icon:SetSize(36, 36)
    lineSide.icon:SetPoint("LEFT", 2, 0)
    lineSide.icon:SetTexture(GetSpellTexture(spellName))

    SetPortraitToTexture(lineSide.icon, lineSide.icon:GetTexture())
    lineSide.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    lineSide.icon:SetAlpha(0.9)

    lineSide.value1 = lineSide:CreateFontString(nil, "ARTWORK")
    lineSide.value1:SetPoint("LEFT", lineSide.icon, "RIGHT", 3, 0)
    lineSide.value1:SetFont("Fonts\\FRIZQT__.TTF", 20)
    lineSide.value1:SetTextColor(1, 1, 0, 1)
    lineSide.value1:SetText(random(1, 50) .. "%")

    if not self.text[lineNum] then self.text[lineNum] = {} end

    self.text[lineNum].left = {lineSide.value1, lineSide.value2, lineSide.value3}
  end

  if self.graph then
    self:graph(200)

    local graph = self.graph
    graph:ClearAllPoints()
    graph:SetParent(self.button.dropDown)
    graph:SetPoint("LEFT", 0, 3)
    graph:SetPoint("RIGHT", 0, 3)
    graph:SetPoint("BOTTOM", 0, 0)
  end
end
--------------------------------------------------------------------------------
-- DropDown Menu Functions
--------------------------------------------------------------------------------
function CT:expanderToggle(click)
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  if click == "LeftButton" then
    if not CT.base.expander then
      CT:expanderFrame()
    end

    if CT.base.expander.shown then
      if CT.base.expander.last then CT.base.expander.last.expanded = false end

      if CT.base.expander.last ~= self then
        self:expandedMenu()
      else
        CT:expanderFrame()
      end

      self.expanded = true
    else
      if CT.base.expander.last ~= self then
        self:expandedMenu()
      end

      CT:expanderFrame()
    end
  elseif click == "RightButton" then
    if not self.expandedDown and (dropDown.dropHeight or 1) > 0 then -- Expand drop down
      self.button:UnlockHighlight()

      if not self.dropDownCreated then
        self:dropDownFunc(self.lineTable)
        self.dropDownCreated = true
      end

      if dropDown.numLines ~= 0 then
        expander.expanded = true
        self.expandedDown = true

        dropDown:Show()

        self:update(GetTime())

        if self.graph then
          if self.graphRefresh then
            self.graph:refresh()
          end
        end

        self:dropAnimationDown()

        expander.defaultHeight = self.button:GetHeight()
        expander.expandedHeight = expander.defaultHeight + dropDown.dropHeight
        CT.updateButtonList()
        CT.scrollFrameUpdate()
      end
    elseif self.expandedDown == true then -- Collapse drop down
      self.button:UnlockHighlight()
      expander.expanded = false
      self.expandedDown = false

      self:dropAnimationUp()

      expander.defaultHeight = self.button:GetHeight()
      expander.expandedHeight = expander.defaultHeight + dropDown.dropHeight
      CT.updateButtonList()
      CT.scrollFrameUpdate()
    end
  end
end

function CT:dropAnimationDown()
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  if not dropDown.animationDown then
    dropDown.animationDown = dropDown:CreateAnimationGroup()
    dropDown.animationDown.translation = dropDown.animationDown:CreateAnimation("Translation")
    dropDown.animationDown.translation:SetDuration(0.1)
  end

  local dropDownHeight = dropDown.dropHeight
  local lineHeight = dropDown.lineHeight
  local shownLinesOld = 0

  dropDown.animationDown:SetScript("OnUpdate", function(frame, elapsed)
    local progress = dropDown.animationDown:GetProgress()

    dropDown:SetHeight(dropDownHeight * dropDown.animationDown:GetProgress())
    expander:SetHeight(expander.height + (dropDown.dropHeight * progress))

    local shownLines = floor(((dropDownHeight * progress) / lineHeight) + 0.01)

    if shownLines > shownLinesOld and dropDown.line[shownLines] then
      dropDown.line[shownLines]:Show()
    end

    shownLinesOld = shownLines
  end)

  dropDown.animationDown:SetScript("OnFinished", function()
    dropDown:SetHeight(dropDown.dropHeight + 3)
    expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
    expander.height = expander:GetHeight()

    -- Sometimes they don't show, this just makes sure
    -- Though it does cause a noticeable flash when it expands...
    for k,v in pairs(dropDown.line) do
      v:Show()
    end

    if self.graph then
      self.graph:Show()
    end
  end)

  for k,v in pairs(dropDown.line) do
    v:Hide()
  end

  if self.graph then
    self.graph:Hide()
  end

  dropDown.animationDown:Play()
end

function CT:dropAnimationUp()
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  if not dropDown.animationUp then
    dropDown.animationUp = dropDown:CreateAnimationGroup()
    dropDown.animationUp.translation = dropDown.animationUp:CreateAnimation("Translation")
    dropDown.animationUp.translation:SetDuration(0.1)
  end

  local dropDownHeight = dropDown.dropHeight
  local lineHeight = dropDown.lineHeight
  local numLines = dropDown.numLines
  local shownLinesOld = 0

  dropDown.animationUp:SetScript("OnUpdate", function(frame, elapsed)
    local progress = dropDown.animationUp:GetProgress()
    local height = abs((dropDownHeight * progress) - dropDown.dropHeight)

    dropDown:SetHeight(height)
    expander:SetHeight(expander.defaultHeight + height)

    local shownLines = abs((floor(((dropDownHeight * progress) / lineHeight) - 0.01)) - numLines)

    if (shownLines ~= shownLinesOld) and (shownLines > 0) and dropDown.line[shownLines] then
         dropDown.line[shownLines]:Hide()
    end

    shownLinesOld = shownLines
  end)

  dropDown.animationUp:SetScript("OnFinished", function()
    dropDown:SetHeight(dropDown.dropHeight + 3)
    expander:SetHeight(expander.defaultHeight)
    expander.height = expander:GetHeight()
    dropDown:Hide()
  end)

  if self.graph then
    self.graph:Hide()
  end

  dropDown.animationUp:Play()
end
