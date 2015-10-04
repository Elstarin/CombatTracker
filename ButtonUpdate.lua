if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
-- local data = CT.displayed
CT.updateFunctions = {}
local func = CT.updateFunctions

local round = CT.round
local formatTimer = CT.formatTimer
local shortenNumbers = CT.shortenNumbers
local colorText = CT.colorText
local colorPercentText = CT.colorPercentText
local colorPercentText2 = CT.colorPercentText2
local max = math.max
local YELLOW = "|cFFFFFF00"
local anchorTable = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
local debug = CT.debug
--------------------------------------------------------------------------------
-- Dropdown Update Functions
--------------------------------------------------------------------------------
function func:shortCD(time, timer)
  local spell = CT.displayed.spells[self.spellID]

  if spell then
    local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    local value = round(100 - ((timer - totalCD) / timer) * 100, 1)
    if value > 100 then value = 100 end
    if value > 0 then
      self.value:SetText(value .. "%")
      colorText(self.value, value, "percent")
    else
      self.value:SetText()
    end

    if self.dropDownCreated and self.expandedDown then
      self.text[1]:SetText(formatTimer(timer))
      self.text[2]:SetText(formatTimer(timer - totalCD))
      self.text[3]:SetText(round((timer - totalCD) / (spell.casts or 0), 2))

      if self.text[4] then
        self.text[4]:SetText("resets " .. random(1, 3))
      end
    end

    -- Update Graph
    if self.graph and self.expandedDown then
      if timer > self.graph.XMax then
        self.graph.XMin = 0
        self.graph.XMax = self.graph.XMax + max(timer - self.graph.XMax, 10)

        self:graphRefresh(timer)
      elseif spell.graphUpdate.addingUptimeLine then
        local width = self.graph:GetWidth() * (timer - self.graph[#self.graph].startX) / self.graph.XMax
        if width < 1 then width = 1 end

        self.graph[#self.graph]:SetWidth(width)
      end
    end
  end
end

function func:healing(time, timer)
end

function func:activity(time, timer)
  local inactivity = timer - (CT.displayed.activity.total or 0)
  local activityPercent = round(100 - ((inactivity / timer) * 100), 1)
  if activityPercent > 0 then
    self.value:SetText(activityPercent .. "%")
    colorText(self.value, activityPercent, "percent")
  else
    self.value:SetText()
  end

  if self.expandedDown then
    self.text[1]:SetText(formatTimer(timer))

    local activity = round(CT.displayed.activity.total, 1)
    self.text[2]:SetText(formatTimer(activityPercent))

    local inactivity = round(timer - CT.displayed.activity.total, 1)
    if self.text[3] then
      self.text[3]:SetText(formatTimer(inactivity))
    end
  end
end

function func:resource1(time, timer)
  local power = CT.displayed.power[1]
  local value = round(100 - (((power.wasted or 0) / (power.total or 0)) * 100), 0)

  if value > 0 then
    self.value:SetText(value .. "%")
  else
    self.value:SetText()
  end

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

      if self.expandedDown then
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

      if self.expandedDown then
        local dropDown = self.button.dropDown
        local expander = self.button.expander

        dropDown:SetHeight(dropDown.dropHeight)
        expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
        expander.height = expander:GetHeight()
      end
    end
  end

  if self.dropDownCreated and self.expandedDown then
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
end

function func:resource2(time, timer)
  local power = CT.displayed.power[2]
  local value = round(100 - (((power.wasted or 0) / (power.total or 0)) * 100), 0)

  if value > 0 then
    self.value:SetText(value .. "%")
  else
    self.value:SetText()
  end

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

      if self.expandedDown then
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

      if self.expandedDown then
        dropDown:SetHeight(dropDown.dropHeight + 3)
        expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
        expander.height = expander:GetHeight()
      end
    end
  end

  if self.dropDownCreated and self.expandedDown then
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
      line[3]:SetText("Avg: " .. (round(spell.average, 1) or 0))
    end
  end
end

function func:resource3(time, timer)
  local powerType = CT.displayed.power[3]
  local power = CT.displayed.power[data.power[3]]
  local value = round(100 - ((power.wasted / power.total) * 100), 0)

  self.value:SetText(value .. "%")

  if self.dropDownCreated and self.expandedDown then
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

function func:longCD(time, timer)
  if not self.oldDelay then self.oldDelay = 0 end
  local spell = CT.displayed.spells[self.spellID]

  if spell then
    local castCount = spell.casts or 0
    local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    if value > 0 then
      local value = round(100 - ((timer - totalCD) / timer) * 100, 1)
    end

    self.value:SetText(value .. "%")

    if self.dropDownCreated and (castCount + 1) > self.button.dropDown.numLines then
      self:type3AddLine()

      if self.expandedDown then
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
    if self.graph and self.expandedDown then
      if timer > self.graph.XMax then
        self.graph.XMin = 0
        self.graph.XMax = self.graph.XMax + max(timer - self.graph.XMax, 10)

        self:graphRefresh(timer)
      elseif spell.graphUpdate.addingUptimeLine then
        local width = self.graph:GetWidth() * (timer - self.graph[#self.graph].startX) / self.graph.XMax
        if width < 1 then width = 1 end

        self.graph[#self.graph]:SetWidth(width)
      end
    end
  end
end

function func:auraUptime(time, timer)
  local aura = CT.displayed.auras[self.spellID]

  if aura then
    local totalUptime = (aura.totalUptime or 0) + (aura.timer or 0)
    if totalUptime < 0 then totalUptime = 0 end
    local value = round(100 - ((timer - totalUptime) / timer) * 100, 1)
    if value > 100 then value = 100 end
    if value > 0 then
      self.value:SetText(value .. "%")
      colorText(self.value, value, "percent")
    else
      self.value:SetText()
    end

    if self.dropDownCreated and self.expandedDown then
      self.text[1]:SetText((aura.totalCount or 0))
      self.text[2]:SetText((aura.appliedCount or 0) .. "/" .. (aura.refreshedCount or 0))
      self.text[3]:SetText(round(aura.expiredEarly or 0, 2))
    end

    -- Update Graph
    if self.graph and self.expandedDown then
      if timer > self.graph.XMax then
        self.graph.XMin = 0
        self.graph.XMax = self.graph.XMax + max(timer - self.graph.XMax, 10)

        self:graphRefresh(timer)
      elseif aura.graphUpdate.addingUptimeLine then
        local width = self.graph:GetWidth() * (timer - self.graph[#self.graph].startX) / self.graph.XMax
        if width < 1 then width = 1 end

        self.graph[#self.graph]:SetWidth(width)
      end
    end
  end
end

function func:dispel(time, timer)
  local inactivity = timer - (CT.displayed.activity.total or 0)
  local activity = round(100 - ((inactivity / timer) * 100), 1)
  if activity > 0 then
    self.value:SetText(activity .. "%")
  else
    self.value:SetText()
  end

  if self.dropDownCreated and self.expandedDown then

  end
end

function func:allCasts(time, timer)
  local spell = CT.displayed.spells

  if spell and spell.needsUpdate then
    spell.needsUpdate = false

    for k,v in pairs(spell) do
      if type(k) == "number" then
        if v.name and not v.allCastsLineCreated then
          self:type4(v.name)
          v.allCastsLineCreated = true

          if self.expandedDown then
            local dropDown = self.button.dropDown
            local expander = self.button.expander

            dropDown:SetHeight(dropDown.dropHeight + 3)
            expander:SetHeight(expander.defaultHeight + dropDown.dropHeight + 3)
            expander.height = expander:GetHeight()
          end
        end
      end
    end

    -- local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    -- local value = round(100 - ((timer - totalCD) / timer) * 100, 1)
    -- self.value:SetText(value .. "%")
    --
    -- if self.dropDownCreated and self.expandedDown then
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
  end
end

function func:expanderStance(time, timer)
end

function func:stance(time, timer)
end

function func:damage(time, timer)
end

function func:execute(time, timer)
end
--------------------------------------------------------------------------------
-- General Expander Functions
--------------------------------------------------------------------------------
local function updateResourceTooltip(fontString, text)
  local power = text.power
  local spell = text.spell

  local string = "%s spent on all spells: %s%s|r\n\n%s spent on %s: %s%s|r\n\n%s was %s%.1f%%|r of total"
  local percent = (spell.totalCost or 0) / (power.totalCost or 0) * 100
  local pName = power.name
  local sName = spell.name

  fontString:SetFormattedText(string, pName, YELLOW, power.totalCost or 0, pName, sName, YELLOW, spell.totalCost or 0, sName, YELLOW, percent)
end

local function addResourceSpell(frameNum, power)
  local dataFrame = CT.base.expander.dataFrames[frameNum]
  if not dataFrame.costFrames then dataFrame.costFrames = {} end

  local width, height = dataFrame:GetSize()
  local width = width / 3
  local listNum = min(#power.spellList, 3)
  local fHeight = height / 3
  local iconSize = fHeight - (fHeight / 3)
  local startHeight = 0
  local newFrame

  if dataFrame.costFrames[1] then
    startHeight = dataFrame.costFrames[1]:GetHeight()
  end

  if power.spellList then
    for i = 1, #power.spellList do
      local spell = power.spellList[i]

      local f = spell.costFrame
      if not f then
        local num = #dataFrame.costFrames + 1

        dataFrame.costFrames[num] = CreateFrame("Button", "CostFrame_" .. spell.name, CT.base.expander)
        f = dataFrame.costFrames[num]
        f:SetSize(width, fHeight)
        spell.costFrame = f
        power.costFrames[#power.costFrames + 1] = f

        do -- Background and highlight
          f.background = f:CreateTexture(nil, "BACKGROUND")
          f.background:SetTexture(0.075, 0.075, 0.075, 1.00)
          f.background:SetPoint("TOP", 0, -2)
          f.background:SetPoint("BOTTOM", 0, 2)
          f.background:SetPoint("LEFT", 2, 0)
          f.background:SetPoint("RIGHT", -2, 0)

          f.highlight = f:CreateTexture(nil, "BACKGROUND")
          f.highlight:SetTexture(0.09, 0.09, 0.09, 1.00)
          f.highlight:SetAllPoints(f.background)
          f:SetHighlightTexture(f.highlight)
        end

        do -- Icon and Icon Dot
          f.icon = f:CreateTexture(nil, "ARTWORK")
          f.icon:SetTexture(spell.icon)
          SetPortraitToTexture(f.icon, f.icon:GetTexture())
          f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
          f.icon:SetAlpha(0.9)
          f.icon:SetSize(iconSize, iconSize)
          f.icon:SetPoint("LEFT", f, 3, 0)

          f.icon.dot = f:CreateTexture(nil, "OVERLAY")
          f.icon.dot:SetSize(iconSize / 1.2, iconSize / 1.2)
          f.icon.dot:SetPoint("TOPLEFT", f, -3, 3)
          f.icon.dot:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
          f.icon.dot:SetVertexColor(0, 0, 0, 0.8)
        end

        do -- Text: Count, Total, Percent
          f.count = f:CreateFontString(nil, "OVERLAY")
          f.count:SetPoint("CENTER", f.icon.dot, 0, 0)
          f.count:SetFont("Fonts\\FRIZQT__.TTF", iconSize / 1.5, "OUTLINE")
          f.count:SetTextColor(1.00, 1.00, 0.00, 1.00)
          f.count:SetJustifyH("CENTER")

          f.total = f:CreateFontString(nil, "ARTWORK")
          f.total:SetHeight(fHeight / 2)
          f.total:SetPoint("LEFT", f.icon, "RIGHT", 0, 0)
          f.total:SetPoint("TOPRIGHT", f, 0, 0)
          f.total:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")
          f.total:SetTextColor(1, 1, 0, 1)
          f.total:SetJustifyH("CENTER")

          f.percent = f:CreateFontString(nil, "ARTWORK")
          f.percent:SetHeight(fHeight / 2)
          f.percent:SetPoint("LEFT", f.icon, "RIGHT", 0, 0)
          f.percent:SetPoint("BOTTOMRIGHT", f, 0, 0)
          f.percent:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")
          f.percent:SetTextColor(1, 1, 0, 1)
          f.percent:SetJustifyH("CENTER")
        end

        f:SetScript("OnEnter", function()
          local text
          if not CT.infoTooltip then
            text = {}
          else
            text = CT.infoTooltip.text
          end

          text.power = power
          text.spell = spell

          CT.createInfoTooltip(f, spell.name, spell.icon, updateResourceTooltip, text)
        end)

        f:SetScript("OnLeave", function()
          CT.createInfoTooltip()
        end)
      end

      do -- Calculate each frame's size and position
        local mod = i % 9
        if mod == 0 then
          mod = 9
          newFrame = true
        end

        f:ClearAllPoints()
        f:SetPoint(anchorTable[mod], dataFrame, 0, 0)

        if (startHeight - 1) > fHeight then -- Adjust icon, dot, and text size
          f:SetSize(width, fHeight)

          f.icon:SetSize(iconSize, iconSize)
          f.icon:SetPoint("LEFT", f, 3, 0)

          f.icon.dot:SetSize(iconSize / 1.2, iconSize / 1.2)
          f.count:SetFont("Fonts\\FRIZQT__.TTF", iconSize / 1.5, "OUTLINE")

          f.total:SetHeight(fHeight / 2)
          f.total:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")

          f.percent:SetHeight(fHeight / 2)
          f.percent:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")
        end

        if newFrame then
          dataFrame = CT.base.expander.dataFrames[frameNum + 1]
          if not dataFrame.costFrames then dataFrame.costFrames = {} end
          width, height = dataFrame:GetSize()
          width = width / 3
          newFrame = false
        end
      end

      power.spellList.numAdded = i
    end
  end
end

local function updateResourceSpellText(power)
  for i = 1, #power.spellList do
    local spell = power.spellList[i]
    local f = spell.costFrame

    local total = (spell.totalCost or 0)
    if total ~= (f.total.text or 0) then
      f.total.text = total

      f.count:SetText(spell.casts or 0)
      f.total:SetFormattedText("%.1f%s", shortenNumbers(total))
    end

    local percent = ((spell.totalCost or 0) / (power.totalCost or 0)) * 100
    if percent ~= (f.percent.text or 0) then
      f.percent.text = percent

      f.percent:SetFormattedText("%.1f%%", percent)
    end
  end
end

local function updateAllCastsTooltip(fontString, text) -- TODO: This is very inefficient, creates loads of garbage... Can't think of a better way though
  local timer = (CT.combatStop or GetTime()) - CT.combatStart
  local spell = text.spell

  local s = ""

  if spell.totalDamage then
    s = s .. format("Total Damage Done: %.1f%s\n\n", shortenNumbers(spell.totalDamage))
  end

  if spell.totalHealing then
    s = s .. format("Total Healing Done: %.1f%s\n\n", shortenNumbers(spell.totalHealing))
  end

  if spell.overhealing then
    s = s .. format("Total Overhealing Done: %.1f%s\n\n", shortenNumbers(spell.overhealing))
  end

  if spell.targetCountTotal then
    s = s .. format("Average hits per cast: %.1f\n\n", (spell.targetCountTotal / spell.casts))
  end

  if spell.powerTable then
    s = s .. format("Total %s Cost: %.1f%s\n\n", spell.powerTable.name, shortenNumbers(spell.totalCost))
    s = s .. format("Average %s Cost: %.1f%s\n\n", spell.powerTable.name, shortenNumbers(spell.averageCost))
  end

  if spell.resetCount then
    s = s .. format("Reset Count: %s\n\n", spell.resetCount)
  end

  if spell.procCount then
    s = s .. format("Proc Count: %s\n\n", spell.procCount)
  end

  if spell.failedCasts then
    s = s .. format("Number of casts broken: %s\n\n", spell.failedCasts)
  end

  if spell.longestDelay then
    s = s .. format("Longest delay between casts: %.1f\n\n", spell.longestDelay)
  end

  if spell.totalCD or spell.CD then
    local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    local value = 100 - ((timer - totalCD) / timer) * 100
    if value == math.huge or value == -math.huge then value = 0 end

    s = s .. format("Percent of fight on CD: %.1f%%\n\n", value)
  end

  if s == "" then -- Failed to match any text
    local text = "It seems I haven't set any text that will display for this spell... Please let me know what kind of details you think would be helpful to know about this ability!"
    s = format("|cFF00FF00%s:|r |cFF4B6CD7%s|r", "BETA NOTE", text)
  end

  fontString:SetText(strtrim(s))
end

local function addAllCastsSpell(frameNum, spells)
  local spellFrames, showFrames = CT.base.expander.spellFrames
  local dataFrame = CT.base.expander.dataFrames[frameNum]

  local width, height = dataFrame:GetSize()
  local width = width / 3
  local listNum = min(#spells, 3)
  local fHeight = height / 3
  local iconSize = fHeight - (fHeight / 3)
  local startHeight = 0
  local newFrame

  if spellFrames[1] then
    startHeight = spellFrames[1]:GetHeight()
  end

  if spells then
    for i = 1, #spells do
      local spell = spells[i]
      local f = spellFrames[spell.ID]

      if not f then
        spellFrames[spell.ID] = CreateFrame("Button", "CT_SpellFrame_" .. i, CT.base.expander)
        f = spellFrames[spell.ID]
        f:SetSize(width, fHeight)
        -- power.costFrames[#power.castFrames + 1] = f

        do -- Background and highlight
          f.background = f:CreateTexture(nil, "BACKGROUND")
          f.background:SetTexture(0.075, 0.075, 0.075, 1.00)
          f.background:SetPoint("TOP", 0, -2)
          f.background:SetPoint("BOTTOM", 0, 2)
          f.background:SetPoint("LEFT", 2, 0)
          f.background:SetPoint("RIGHT", -2, 0)

          f.highlight = f:CreateTexture(nil, "BACKGROUND")
          f.highlight:SetTexture(0.09, 0.09, 0.09, 1.00)
          f.highlight:SetAllPoints(f.background)
          f:SetHighlightTexture(f.highlight)
        end

        do -- Icon and Icon Dot
          f.icon = f:CreateTexture(nil, "ARTWORK")
          f.icon:SetTexture(spell.icon)
          SetPortraitToTexture(f.icon, f.icon:GetTexture())
          f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
          f.icon:SetAlpha(0.9)
          f.icon:SetSize(iconSize, iconSize)
          f.icon:SetPoint("LEFT", f, 3, 0)

          f.icon.dot = f:CreateTexture(nil, "OVERLAY")
          f.icon.dot:SetSize(iconSize / 1.2, iconSize / 1.2)
          f.icon.dot:SetPoint("TOPLEFT", f, -3, 3)
          f.icon.dot:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
          f.icon.dot:SetVertexColor(0, 0, 0, 0.8)
        end

        do -- Text: Count, Total, Percent
          f.count = f:CreateFontString(nil, "OVERLAY")
          f.count:SetPoint("CENTER", f.icon.dot, 0, 0)
          f.count:SetFont("Fonts\\FRIZQT__.TTF", iconSize / 1.5, "OUTLINE")
          f.count:SetTextColor(1.00, 1.00, 0.00, 1.00)
          f.count:SetJustifyH("CENTER")

          f.total = f:CreateFontString(nil, "ARTWORK")
          f.total:SetHeight(fHeight / 2)
          f.total:SetPoint("LEFT", f.icon, "RIGHT", 0, 0)
          f.total:SetPoint("TOPRIGHT", f, 0, 0)
          f.total:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")
          f.total:SetTextColor(1, 1, 0, 1)
          f.total:SetJustifyH("CENTER")

          f.percent = f:CreateFontString(nil, "ARTWORK")
          f.percent:SetHeight(fHeight / 2)
          f.percent:SetPoint("LEFT", f.icon, "RIGHT", 0, 0)
          f.percent:SetPoint("BOTTOMRIGHT", f, 0, 0)
          f.percent:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")
          f.percent:SetTextColor(1, 1, 0, 1)
          f.percent:SetJustifyH("CENTER")
        end

        f:SetScript("OnEnter", function()
          local text
          if not CT.infoTooltip then
            text = {}
          else
            text = CT.infoTooltip.text
          end

          text.spell = spell

          CT.createInfoTooltip(f, spell.name, spell.icon, updateAllCastsTooltip, text)
        end)

        f:SetScript("OnLeave", function()
          CT.createInfoTooltip()
        end)
      end

      do -- Calculate each frame's size and position
        local mod = i % 9
        if mod == 0 then
          mod = 9
          newFrame = true
        end

        f:ClearAllPoints()
        f:SetPoint(anchorTable[mod], dataFrame, 0, 0)

        if (startHeight - 1) > fHeight then -- Adjust icon, dot, and text size
          f:SetSize(width, fHeight)

          f.icon:SetSize(iconSize, iconSize)
          f.icon:SetPoint("LEFT", f, 3, 0)

          f.icon.dot:SetSize(iconSize / 1.2, iconSize / 1.2)
          f.count:SetFont("Fonts\\FRIZQT__.TTF", iconSize / 1.5, "OUTLINE")

          f.total:SetHeight(fHeight / 2)
          f.total:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")

          f.percent:SetHeight(fHeight / 2)
          f.percent:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")
        end

        if newFrame then
          frameNum = frameNum + 1
          dataFrame = CT.base.expander.dataFrames[frameNum]
          width, height = dataFrame:GetSize()
          width = width / 3
          newFrame = false
        end
      end

      spells.numAdded = i
    end
  end
end

local function updateAllCastsSpellText(spells)
  for i = 1, #spells do
    local spell = spells[i]
    local f = CT.base.expander.spellFrames[spell.ID]

    if f then
      local casts = (spell.casts or 0)
      if casts ~= (f.count.text or 0) then
        f.count.text = casts

        f.count:SetText(casts)
        -- f.total:SetFormattedText("%.1f%s", shortenNumbers(total))
      end

      -- local percent = ((spell.totalCost or 0) / (power.totalCost or 0)) * 100
      -- if percent ~= (f.percent.text or 0) then
      --   f.percent.text = percent
      --
      --   f.percent:SetFormattedText("%.1f%%", percent)
      -- end
    end
  end
end

local function updateAllDamageTooltip(fontString, text) -- TODO: This is very inefficient, creates loads of garbage... Can't think of a better way though
  local timer = (CT.combatStop or GetTime()) - CT.combatStart
  local spell = text.spell

  local s = ""

  if spell.totalDamage then
    s = s .. format("Total damage done: %.1f%s\n\n", shortenNumbers(spell.totalDamage))
  end

  if spell.critDamage then
    s = s .. format("Number of critical hits: %s\n\n", spell.critDamage)
  end

  if spell.MSDamage then
    s = s .. format("Number of multistrikes: %s\n\n", spell.MSDamage)
  end

  if spell.targetCountTotal then
    s = s .. format("Average hits per cast: %.1f\n\n", (spell.targetCountTotal / spell.casts))
  end

  if spell.procCount then
    s = s .. format("Number of procs used: %s\n\n", spell.procCount)
  end

  if spell.failedCasts then
    s = s .. format("Number of casts broken: %s\n\n", spell.failedCasts)
  end

  if s == "" then
    s = "|cFF00FF00BETA NOTE:|r |cFF4B6CD7It seems I haven't set any text that will display for this spell..." ..
    "Please let me know what kind of details you think would be helpful to know about this ability!|r"
  end

  fontString:SetText(strtrim(s))
end

local function addAllDamageSpell(frameNum, spells)
  local spellFrames, showFrames = CT.base.expander.spellFrames
  local dataFrame = CT.base.expander.dataFrames[frameNum]

  local width, height = dataFrame:GetSize()
  local width = width / 3
  local listNum = min(#spells, 3)
  local fHeight = height / 3
  local iconSize = fHeight - (fHeight / 3)
  local startHeight = 0
  local newFrame

  if spellFrames[1] then
    startHeight = spellFrames[1]:GetHeight()
  end

  if spells then
    for i = 1, #spells do
      local spell = spells[i]
      local f = spellFrames[spell.ID]

      if not f then
        spellFrames[spell.ID] = CreateFrame("Button", "CT_SpellFrame_" .. i, CT.base.expander)
        f = spellFrames[spell.ID]
        f:SetSize(width, fHeight)

        do -- Background and highlight
          f.background = f:CreateTexture(nil, "BACKGROUND")
          f.background:SetTexture(0.075, 0.075, 0.075, 1.00)
          f.background:SetPoint("TOP", 0, -2)
          f.background:SetPoint("BOTTOM", 0, 2)
          f.background:SetPoint("LEFT", 2, 0)
          f.background:SetPoint("RIGHT", -2, 0)

          f.highlight = f:CreateTexture(nil, "BACKGROUND")
          f.highlight:SetTexture(0.09, 0.09, 0.09, 1.00)
          f.highlight:SetAllPoints(f.background)
          f:SetHighlightTexture(f.highlight)
        end

        do -- Icon and Icon Dot
          f.icon = f:CreateTexture(nil, "ARTWORK")
          f.icon:SetTexture(spell.icon)
          SetPortraitToTexture(f.icon, f.icon:GetTexture())
          f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
          f.icon:SetAlpha(0.9)
          f.icon:SetSize(iconSize, iconSize)
          f.icon:SetPoint("LEFT", f, 3, 0)

          f.icon.dot = f:CreateTexture(nil, "OVERLAY")
          f.icon.dot:SetSize(iconSize / 1.2, iconSize / 1.2)
          f.icon.dot:SetPoint("TOPLEFT", f, -3, 3)
          f.icon.dot:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
          f.icon.dot:SetVertexColor(0, 0, 0, 0.8)
        end

        do -- Text: Count, Total, Percent
          f.count = f:CreateFontString(nil, "OVERLAY")
          f.count:SetPoint("CENTER", f.icon.dot, 0, 0)
          f.count:SetFont("Fonts\\FRIZQT__.TTF", iconSize / 1.5, "OUTLINE")
          f.count:SetTextColor(1.00, 1.00, 0.00, 1.00)
          f.count:SetJustifyH("CENTER")

          f.total = f:CreateFontString(nil, "ARTWORK")
          f.total:SetHeight(fHeight / 2)
          f.total:SetPoint("LEFT", f.icon, "RIGHT", 0, 0)
          f.total:SetPoint("TOPRIGHT", f, 0, 0)
          f.total:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")
          f.total:SetTextColor(1, 1, 0, 1)
          f.total:SetJustifyH("CENTER")

          f.percent = f:CreateFontString(nil, "ARTWORK")
          f.percent:SetHeight(fHeight / 2)
          f.percent:SetPoint("LEFT", f.icon, "RIGHT", 0, 0)
          f.percent:SetPoint("BOTTOMRIGHT", f, 0, 0)
          f.percent:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")
          f.percent:SetTextColor(1, 1, 0, 1)
          f.percent:SetJustifyH("CENTER")
        end

        f:SetScript("OnEnter", function()
          local text
          if not CT.infoTooltip then
            text = {}
          else
            text = CT.infoTooltip.text
          end

          text.spell = spell

          CT.createInfoTooltip(f, spell.name, spell.icon, updateAllDamageTooltip, text)
        end)

        f:SetScript("OnLeave", function()
          CT.createInfoTooltip()
        end)
      end

      do -- Calculate each frame's size and position
        local mod = i % 9
        if mod == 0 then
          mod = 9
          newFrame = true
        end

        f:ClearAllPoints()
        f:SetPoint(anchorTable[mod], dataFrame, 0, 0)

        if (startHeight - 1) > fHeight then -- Adjust icon, dot, and text size
          f:SetSize(width, fHeight)

          f.icon:SetSize(iconSize, iconSize)
          f.icon:SetPoint("LEFT", f, 3, 0)

          f.icon.dot:SetSize(iconSize / 1.2, iconSize / 1.2)
          f.count:SetFont("Fonts\\FRIZQT__.TTF", iconSize / 1.5, "OUTLINE")

          f.total:SetHeight(fHeight / 2)
          f.total:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")

          f.percent:SetHeight(fHeight / 2)
          f.percent:SetFont("Fonts\\FRIZQT__.TTF", fHeight / 2.5, "OUTLINE")
        end

        if newFrame then
          frameNum = frameNum + 1
          dataFrame = CT.base.expander.dataFrames[frameNum]
          width, height = dataFrame:GetSize()
          width = width / 3
          newFrame = false
        end
      end

      spells.numAdded = i
    end
  end
end

local function updateAllDamageSpellText(spells)
  for i = 1, #spells do
    local spell = spells[i]
    local f = CT.base.expander.spellFrames[spell.ID]

    if f then
      local casts = spell.casts or 0
      if casts ~= (f.count.text or 0) then
        f.count.text = casts

        f.count:SetText(spell.casts)
      end

      local total = spell.totalDamage or 0
      if percent ~= (f.total.text or 0) then
        f.total.text = percent

        f.total:SetFormattedText("%.0f%s", shortenNumbers(total))
      end

      local percent = ((spell.totalDamage or 0) / (CT.displayed.damage.total or 0)) * 100
      if percent ~= (f.percent.text or 0) then
        f.percent.text = percent

        f.percent:SetFormattedText("%.1f%%", percent)
      end
    end
  end
end
--------------------------------------------------------------------------------
-- Expander Update Functions
--------------------------------------------------------------------------------
function func:expanderAllCasts(time, timer)
  local spells = CT.displayed.spells

  if self.expanded then
    do -- Handle spellFrames list
      local sorted
      sort(spells, function(a, b)
        if (a.casts or 0) == (b.casts or 0) then
          return a.name > b.name
        elseif (a.casts or 0) > (b.casts or 0) then
          sorted = true
          return true
        end
      end)

      if not CT.displayed.casting then -- Spell table gets created when cast starts, but I don't want the frame popping up until it's done
        if sorted or (#spells > (spells.numAdded or 0)) then
          addAllCastsSpell(1, spells)
        end
      end

      updateAllCastsSpellText(spells)

      for k, v in pairs(CT.base.expander.spellFrames) do -- NOTE: This runs constantly...
        if spells[k] and spells[k].casts then
          v:Show()
        else
          v:Hide()
        end
      end
    end
  end
end

function func:expanderDamage(time, timer)
  local spells = CT.displayed.spells
  local damage = CT.displayed.damage

  local value, letter = shortenNumbers((damage.total or 0) / timer)
  if value > 0 then
    self.value:SetFormattedText("%.0f%s%s", value, letter, " DPS")
  else
    self.value:SetText()
  end

  if self.expanded then
    do -- Handle spellFrames list
      local sorted
      sort(spells, function(a, b)
        if a.name and b.name and (a.totalDamage or 0) == (b.totalDamage or 0) then
          return a.name > b.name
        elseif (a.totalDamage or 0) > (b.totalDamage or 0) then
          sorted = true
          return true
        end
      end)

      if not CT.displayed.casting then
        if sorted or (#spells > (spells.numAdded or 0)) then
          addAllDamageSpell(3, spells)
        end
      end

      updateAllDamageSpellText(spells)

      for k, v in pairs(CT.base.expander.spellFrames) do
        if spells[k].totalDamage then
          v:Show()
        else
          v:Hide()
        end
      end
    end

    local text = CT.base.expander.textData.value

    -- Group 1
    text[1]:SetFormattedText("%.1f%s", shortenNumbers(damage.total or 0))
    text[2]:SetFormattedText("%.1f%s", value, letter)
    -- text[3]:SetText()
    -- text[4]:SetText()

    -- Group 2
    -- text[5]:SetText(power.timesCapped or 0)
    -- text[6]:SetFormattedText("%.1f", secondsCapped)
    -- text[7]:SetText()
    -- text[8]:SetText()
  end
end

function func:expanderActivity(time, timer)
  local inactivity = timer - (CT.displayed.activity.total or 0)
  local activityPercent = round(100 - ((inactivity / timer) * 100), 1)
  if activityPercent > 0 then
    self.value:SetText(activityPercent .. "%")
    colorText(self.value, activityPercent, "percent")
  else
    self.value:SetText()
  end

  local text = CT.base.expander.textData.value

  local activity = (CT.displayed.activity.total or 0) + (CT.displayed.currentCastDuration or 0) + (CT.displayed.currentGCDDuration or 0)
  local timeCasting = (CT.displayed.activity.timeCasting or 0) + (CT.displayed.currentCastDuration or 0)
  local timeGCD = (CT.displayed.activity.totalGCD or 0) + (CT.displayed.currentGCDDuration or 0)

  -- Group 1
  text[1]:SetText(formatTimer(activity) .. "/" .. formatTimer(timer))
  text[2]:SetText(colorPercentText(activityPercent) .. "%")
  text[3]:SetFormattedText("%.2f", activity)
  text[4]:SetFormattedText("%.2f", timer)

  -- Group 2
  text[5]:SetFormattedText("%.1f", timeCasting)
  text[6]:SetFormattedText("%.2f", timeGCD)
  -- text[7]:SetText(CT.displayed.activity.totalCasts)
  -- text[8]:SetText(CT.displayed.activity.instantCasts)

  -- Group 3
  text[9]:SetText(CT.displayed.activity.totalCasts)
  text[10]:SetText(CT.displayed.activity.instantCasts)
  text[11]:SetText(CT.displayed.activity.hardCasts)
  -- text[12]:SetText()

  -- Group 4
  -- text[13]:SetText()
  -- text[14]:SetText()
  -- text[15]:SetText()
  -- text[16]:SetText()
end

function func:expanderResource1(time, timer)
  local power = CT.displayed.power[1]
  if power then
    self.hasDisplayedText = true

    self.powerNum = 1

    local value = round(100 - ((power.wasted / power.total) * 100), 0)
    if value > 100 then value = 100 end
    if value > 0 then
      self.value:SetText(value .. "%")
      colorText(self.value, value, "percent")
    else
      self.value:SetText()
    end

    if self.expanded then
      do -- Handle spell cost list
        local sorted
        sort(power.spellList, function(a,b)
          if a.totalCost > b.totalCost then
            sorted = true
            return a.totalCost > b.totalCost
          end
        end)

        if sorted or (#power.spellList > power.spellList.numAdded) then
          addResourceSpell(3, power)
        end

        updateResourceSpellText(power)
      end

      local text = CT.base.expander.textData.value

      local secondsCapped
      if power.capped then
        secondsCapped = (power.cappedTotal or 0) + (time - power.cappedTime)
      else
        secondsCapped = (power.cappedTotal or 0)
      end

      -- Group 1
      text[1]:SetFormattedText("%.1f%s", shortenNumbers(power.totalRegen or 0))
      text[2]:SetFormattedText("%.1f%s", shortenNumbers(secondsCapped * GetPowerRegen() + (power.wasted or 0)))
      -- text[3]:SetText()
      -- text[4]:SetText()

      -- Group 2
      text[5]:SetText(power.timesCapped or 0)
      text[6]:SetFormattedText("%.1f", secondsCapped)
      -- text[7]:SetText()
      -- text[8]:SetText()

      -- Group 3
      -- text[9]:SetText()
      -- text[10]:SetText()
      -- text[11]:SetText()
      -- text[12]:SetText()

      -- Group 4
      -- text[13]:SetText()
      -- text[14]:SetText()
      -- text[15]:SetText()
      -- text[16]:SetText()
    end
  elseif self.hasDisplayedText then -- No table, but text hasn't been wiped
    self.hasDisplayedText = false
    self.value:SetText()

    if self.expanded then
      local text = CT.base.expander.textData.value

      for i = 1, #text do -- Remove all the shown text
        text[i]:SetText()
      end
    end
  end
end

function func:expanderResource2(time, timer)
  local power = CT.displayed.power[2]
  if power then
    self.powerNum = 2

    local value = round(100 - ((power.wasted / power.total) * 100), 0)
    if value > 100 then value = 100 end
    if value > 0 then
      self.value:SetText(value .. "%")
      colorText(self.value, value, "percent")
    else
      self.value:SetText()
    end

    if self.expanded then
      do -- Handle spell cost list
        local sorted
        sort(power.spellList, function(a,b)
          if a.totalCost > b.totalCost then
            sorted = true
            return a.totalCost > b.totalCost
          end
        end)

        if sorted or (#power.spellList > power.spellList.numAdded) then
          addResourceSpell(3, power)
        end

        updateResourceSpellText(power)
      end

      local text = CT.base.expander.textData.value

      local secondsCapped
      if power.capped then
        secondsCapped = (power.cappedTotal or 0) + (time - power.cappedTime)
      else
        secondsCapped = (power.cappedTotal or 0)
      end

      -- Group 1
      text[1]:SetText((power.total or 0) - (power.wasted or 0))
      text[2]:SetText(power.wasted or 0)
      -- text[3]:SetText()
      -- text[4]:SetText()

      -- Group 2
      text[5]:SetText(power.timesCapped or 0)
      text[6]:SetFormattedText("%.1f", secondsCapped)
      -- text[7]:SetText()
      -- text[8]:SetText()

      -- Group 3
      -- text[9]:SetText()
      -- text[10]:SetText()
      -- text[11]:SetText()
      -- text[12]:SetText()

      -- Group 4
      -- text[13]:SetText()
      -- text[14]:SetText()
      -- text[15]:SetText()
      -- text[16]:SetText()
    end
  end
end

function func:expanderAuraUptime(time, timer)
  local aura = CT.displayed.auras[self.spellID]
  if aura then
    self.hasDisplayedText = true

    local totalUptime = (aura.totalUptime or 0) + (aura.timer or 0)
    if totalUptime < 0 then totalUptime = 0 end
    local value = round(100 - ((timer - totalUptime) / timer) * 100, 1)
    if value > 100 then value = 100 end
    if value > 0 then
      self.value:SetText(value .. "%")
      colorText(self.value, value, "percent")
    else
      self.value:SetText()
    end

    if self.expanded then
      local text = CT.base.expander.textData.value

      -- Group 1
      text[1]:SetFormattedText("%.1f", totalUptime)
      text[2]:SetFormattedText("%.1f", timer - totalUptime)
      text[3]:SetFormattedText("%.1f", (aura.totalGap or 0) / (aura.totalCount or 0))
      text[4]:SetFormattedText("%.1f", aura.longestGap or 0)

      -- Group 2
      text[5]:SetText(aura.totalCount or 0)
      text[6]:SetText(aura.refreshedCount or 0)
      text[7]:SetFormattedText("%.1f", abs(aura.expiredEarly or 0))
      -- text[8]:SetText()

      -- Group 3
      text[9]:SetFormattedText("%.0f", aura.totalAmount or 0)
      text[10]:SetFormattedText("%.0f", aura.removedAmount or 0)
      text[11]:SetFormattedText("%.0f", (aura.totalAmount or 0) / (aura.totalCount or 0))
      text[12]:SetFormattedText("%.0f", aura.maxAmount or 0)

      -- Group 4
      -- text[13]:SetText()
      -- text[14]:SetText()
      -- text[15]:SetText()
      -- text[16]:SetText()
    end
  elseif self.hasDisplayedText then -- No table, but text hasn't been wiped
    self.hasDisplayedText = false
    self.value:SetText()

    if self.expanded then
      local text = CT.base.expander.textData.value

      for i = 1, #text do -- Remove all the shown text
        text[i]:SetText()
      end
    end
  end
end

function func:expanderShortCD(time, timer)
  local spell = CT.displayed.spells[self.spellID]
  if spell then
    self.hasDisplayedText = true

    local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    local value = round(100 - ((timer - totalCD) / timer) * 100, 1)
    if value > 100 then value = 100 end
    if value > 0 then
      self.value:SetText(value .. "%")
      colorText(self.value, value, "percent")
    else
      self.value:SetText()
    end

    if self.expanded then
      local text = CT.base.expander.textData.value

      text[1]:SetFormattedText("%s%s%%", colorPercentText2(value), value)
      text[2]:SetFormattedText("%.2f", timer - totalCD)
      text[3]:SetFormattedText("%.2f", (timer - totalCD) / (spell.casts or 0))
      text[4]:SetText(spell.casts or 0)

      if (spell.wastedPower or 0) > 0 then
        text[5]:SetFormattedText("|cFFFF0000%s|r/%s", (spell.wastedPower or 0), (spell.effectiveGain or 0))
      else
        text[5]:SetText(spell.effectiveGain or 0)
      end

      if spell.powerSpent then
        text[6]:SetText(spell.powerSpent.total or 0)
      end

      text[7]:SetText(spell.resetCount or 0)
      text[8]:SetFormattedText("%.2f", spell.longestDelay or 0)
      text[9]:SetText(spell.procCount or 0)
    end
  elseif self.hasDisplayedText then -- No spell, but text hasn't been wiped
    self.hasDisplayedText = false
    self.value:SetText()

    if self.expanded then
      local text = CT.base.expander.textData.value

      for i = 1, #text do -- Remove all the shown text
        text[i]:SetText()
      end
    end
  end
end

function func:expanderExecute(time, timer)
  local spell = CT.displayed.spells[self.spellID]
  if spell then
    self.hasDisplayedText = true

    local totalUptime = (spell.totalUptime or 0) + (spell.uptime or 0)
    if totalUptime < 0 then totalUptime = 0 end
    local value = round(100 - ((timer - totalUptime) / timer) * 100, 1)
    self.value:SetText(value .. "%")
    colorText(self.value, value, "percent")

    if self.expanded then
      local text = CT.base.expander.textData.value

      -- Group 1
      -- text[1]:SetText()
      -- text[2]:SetText()
      -- text[3]:SetText()
      -- text[4]:SetText()

      -- Group 2
      -- text[5]:SetText()
      -- text[6]:SetText()
      -- text[7]:SetText()
      -- text[8]:SetText()

      -- Group 3
      -- text[9]:SetText()
      -- text[10]:SetText()
      -- text[11]:SetText()
      -- text[12]:SetText()

      -- Group 4
      -- text[13]:SetText()
      -- text[14]:SetText()
      -- text[15]:SetText()
      -- text[16]:SetText()
    end
  elseif self.hasDisplayedText then -- No table, but text hasn't been wiped
    self.hasDisplayedText = false
    self.value:SetText()

    if self.expanded then
      local text = CT.base.expander.textData.value

      for i = 1, #text do -- Remove all the shown text
        text[i]:SetText()
      end
    end
  end
end

function func:expanderBurstCD(time, timer)
  local spell = CT.displayed.spells[self.spellID]
  if spell then
    local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    local value = round(100 - ((timer - totalCD) / timer) * 100, 1)
    self.value:SetText(value .. "%")
    colorText(self.value, value, "percent")

    if self.expanded then
      local text = CT.base.expander.textData.value

      -- Group 1
      text[1]:SetText(colorPercentText(value) .. "%")
      text[2]:SetText(round(timer - totalCD, 2))
      text[3]:SetText(round((timer - totalCD) / (spell.casts or 0), 2))
      text[4]:SetText(round(spell.longestDelay or 0, 2))

      -- Group 2
      text[5]:SetText(spell.casts or 0)
      -- text[6]:SetText()
      -- text[7]:SetText()
      -- text[8]:SetText()

      -- Group 3
      -- text[9]:SetText()
      -- text[10]:SetText()
      -- text[11]:SetText()
      -- text[12]:SetText()

      -- Group 4
      -- text[13]:SetText()
      -- text[14]:SetText()
      -- text[15]:SetText()
      -- text[16]:SetText()
    end
  end
end

function func:expanderDefensives(time, timer)
  local spell = CT.displayed.spells[self.spellID]
  if spell then
    local totalCD = (spell.totalCD or 0) + (spell.CD or 0)
    local value = round(100 - ((timer - totalCD) / timer) * 100, 1)
    if value > 100 then value = 100 end
    if value > 0 then
      self.value:SetText(value .. "%")
      colorText(self.value, value, "percent")
    else
      self.value:SetText()
    end

    if self.expanded then
      local text = CT.base.expander.textData.value

      -- Group 1
      text[1]:SetText(colorPercentText(value) .. "%")
      text[2]:SetText(round(timer - totalCD, 2))
      text[3]:SetText(round((timer - totalCD) / (spell.casts or 0), 2))
      text[4]:SetText(round(spell.longestDelay or 0, 2))

      -- Group 2
      text[5]:SetText(spell.casts or 0)
      -- text[6]:SetText()
      -- text[7]:SetText()
      -- text[8]:SetText()

      -- Group 3
      -- text[9]:SetText()
      -- text[10]:SetText()
      -- text[11]:SetText()
      -- text[12]:SetText()

      -- Group 4
      -- text[13]:SetText()
      -- text[14]:SetText()
      -- text[15]:SetText()
      -- text[16]:SetText()
    end
  end
end

function func:expanderEnvenom(time, timer)
  local spell = CT.displayed.spells[self.spellID]
  if spell then
    self.hasDisplayedText = true

    local aura = CT.displayed.auras[self.spellID]

    local totalUptime = (aura.totalUptime or 0) + (aura.uptime or 0)
    if totalUptime < 0 then totalUptime = 0 end
    local value = round(100 - ((timer - totalUptime) / timer) * 100, 1)
    if value > 100 then value = 100 end
    if value > 0 then
      self.value:SetText(value .. "%")
      colorText(self.value, value, "percent")
    else
      self.value:SetText()
    end

    if self.expanded then
      local text = CT.base.expander.textData.value

      -- Group 1
      text[1]:SetFormattedText("%s%s%%", colorPercentText2(value), value)
      text[2]:SetFormattedText("%.2f", spell.longestDelay or 0)
      text[3]:SetFormattedText("%.1f", spell.resourceAverage or 0)
      text[4]:SetFormattedText("%.1f", spell.secondaryResourceAverage or 0)

      -- Group 2
      text[5]:SetText(spell.casts or 0)
      text[6]:SetText(aura.refreshedCount or 0)
      text[7]:SetFormattedText("%.1f", spell.wastedRefresh or 0)
      text[8]:SetFormattedText("%.1f", spell.wastedRefreshAverage or 0)

      -- Group 3
      -- text[9]:SetText()
      -- text[10]:SetText()
      -- text[11]:SetText()
      -- text[12]:SetText()

      -- Group 4
      -- text[13]:SetText()
      -- text[14]:SetText()
      -- text[15]:SetText()
      -- text[16]:SetText()
    end
  elseif self.hasDisplayedText then -- No table, but text hasn't been wiped
    self.hasDisplayedText = false
    self.value:SetText()

    if self.expanded then
      local text = CT.base.expander.textData.value

      for i = 1, #text do -- Remove all the shown text
        text[i]:SetText()
      end
    end
  end
end
