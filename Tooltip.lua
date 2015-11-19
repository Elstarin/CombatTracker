local addonName, CombatTracker = ...

if not CombatTracker then return end
if CombatTracker.profile then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
local debug = CT.debug

function CT:getParser()
  local parser, LT1, LT2, LT3, RT1, RT2, RT3

  if not CT.parser then
    CT.parser = CreateFrame("GameTooltip")
    parser = CT.parser
    parser:SetOwner(UIParent, "ANCHOR_NONE")

    LT1 = parser:CreateFontString()
    RT1 = parser:CreateFontString()
    parser:AddFontStrings(LT1, RT1)

    LT2 = parser:CreateFontString()
    RT2 = parser:CreateFontString()
    parser:AddFontStrings(LT2, RT2)

    LT3 = parser:CreateFontString()
    RT3 = parser:CreateFontString()
    parser:AddFontStrings(LT3, RT3)
  end

  return parser, LT1, LT2, LT3, RT1, RT2, RT3
end

local tooltip
function CT.updateTooltip(titleValue, textValue) -- Quick access for setting new title/text
  if offsetX and not titleValue then
    titleValue = offsetX
  end
  
  if not tooltip then CT.setTooltip() end
  
  if titleValue or textValue then
    tooltip.titleString = titleValue
    tooltip.textString = textValue
  end
  
  return tooltip, tooltip.title, tooltip.text
end

function CT.setTooltip(relativeTo, offsetX, offsetY, titleString, textString)
  local width, height = 200, 100
  local r, g, b, a = 0.075, 0.075, 0.075, 1.0
  
  local arrowOffset = 15
  local textOffset = 5
  local animationDuration = 0.1
  
  local f = CT.mainTooltip
  if not f then
    f = CreateFrame("Frame", "CombatTracker_Tooltip_Base", UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetPoint("CENTER")
    f:SetSize(width, height)
    f.width = width
    f.height = height
    
    function f:scaling(remaining)
      local newValue
      
      if self.direction == "IN" then
        local percent = 100 - ((remaining / animationDuration) * 100)
        newValue = percent / 100
        
        if 0 >= remaining then
          self.animating = false
          self:SetScale(1)
          self:updateSize()
          return
        end
      elseif self.direction == "OUT" then
        local percent = (remaining / animationDuration) * 100
        newValue = percent / 100
        
        if 0 >= remaining then
          self.animating = false
          self:Hide()
          self:SetScale(1)
          self:updateSize()
          return
        end
      end
      
      if newValue > 1 then newValue = 1 end
      if 0 >= newValue then newValue = 0.001 end
      
      self:SetScale(newValue)
      self:updateSize()
    end
    
    function f:updateSize()
      local textWidth, textHeight = self.text:GetSize()
      local titleWidth, titleHeight = self.title:GetSize()
      
      local longest = max(titleWidth, textWidth) + 20
      local combinedHeight = max((textHeight + titleHeight) + textOffset, 40) + 20
      self:SetSize(longest, combinedHeight)
      
      self.width = longest
      self.height = combinedHeight
    end
    
    function f:onUpdateFunc(elapsed)
      local cTime = GetTime()
      
      if self.animating then
        self:scaling(self.animating - cTime)
      end
      
      if self.titleString or self.textString then
        f:SetAlpha(1)
        
        if self.textString then -- Any time textString is set, chop it up for proper sizing
          for i = 1, #f.text do f.text[i] = nil end -- Wipe the array that holds the chopped strings
          
          local string = self.textString:gsub("(|c)(%x%x%x%x%x%x%x%x.+)(|r)", "##%2~~") -- Sub any color sequences to make them normally visible
          
          local length = min(60, #string)
          local position, pattern = 1, nil
          for i = 1, #string, length do
            local str = string:sub(position, position + (length))
            
            if #str <= length then
              pattern = ".+"
            else
              pattern = "(.+)%s"
            end
            
            for capture in str:gmatch(pattern) do
              f.text[#f.text + 1] = capture
              
              position = position + #capture + 1
            end
          end
          
          local str = table.concat(f.text, "\n")
          str = str:gsub("##", "|c") -- Rebuild color sequences
          str = str:gsub("~~", "|r") -- Rebuild color sequences
          
          self.textString = str
        end
        
        self.title:SetText(self.titleString)
        self.text:SetText(self.textString)
        
        self.titleString = nil
        self.textString = nil
        
        self:updateSize()
      end
      
      -- local textWidth, textHeight = self.text:GetSize()
      -- local titleWidth, titleHeight = self.title:GetSize()
      --
      -- if (titleWidth > self.width) or (textWidth > self.width) then
      --   debug("Too long!")
      --
      --   local longest = max(titleWidth, textWidth) + 20
      --
      --   self:SetWidth(longest)
      --   self.width = longest
      -- end
      --
      -- if (titleHeight + textHeight) > self.height then
      --   debug("Text too tall!")
      --
      --   local combinedHeight = max((textHeight + titleHeight) + textOffset, 100) + 20
      --   self:SetHeight(combinedHeight)
      --
      --   self.height = combinedHeight
      -- end
    end
    
    f:SetScript("OnUpdate", f.onUpdateFunc)
    
    tooltip = f
    CT.mainTooltip = f
    f:Hide()
  end
  
  local bg = CT.createRoundedBackground(f, r, g, b, a)

  local arrow = f.arrow
  if not arrow then
    local w, h = 40, 40
    arrow = CreateFrame("Frame", "CombatTracker_Tooltip_Arrow", f)
    arrow:SetPoint("TOP", f, 0, -10)
    arrow:SetPoint("BOTTOM", f, 0, 10)
    arrow:SetSize(w, h)
    arrow:SetFrameLevel(0)
    
    local a = arrow:CreateTexture("CombatTracker_Tooltip_Arrow_Top_Texture", "BACKGROUND", nil, -8)
    a:SetTexture("Interface\\addons\\CombatTracker\\Media\\triangle.tga")
    a:SetSize(w, h)
    a:SetPoint("TOP", arrow, 0, 0)
    a:SetPoint("BOTTOM", arrow, "CENTER", 0, 0)
    a:SetPoint("RIGHT", arrow, 0, 0)
    a:SetPoint("LEFT", arrow, 0, 0)
    a:SetVertexColor(r, g, b, a)
    arrow[1] = a
    
    local a = arrow:CreateTexture("CombatTracker_Tooltip_Arrow_Bottom_Texture", "BACKGROUND", nil, -8)
    a:SetTexture("Interface\\addons\\CombatTracker\\Media\\triangle.tga")
    a:SetSize(w, h)
    a:SetPoint("TOP", arrow, "CENTER", 0, 0)
    a:SetPoint("BOTTOM", arrow, 0, 0)
    a:SetPoint("RIGHT", arrow, 0, 0)
    a:SetPoint("LEFT", arrow, 0, 0)
    a:SetVertexColor(r, g, b, a)
    a:SetTexCoord(0.25, 0.5, 0.75, 0.5)
    arrow[2] = a
    
    f.arrow = arrow
  end
  
  local title = f.title
  if not title then
    title = f:CreateFontString(nil, "ARTWORK", nil, 7)
    title:SetPoint("TOPLEFT", f, 10, -5)
    title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    title:SetTextColor(0.95, 0.95, 1.0, 1)
    title:SetJustifyH("LEFT")
    title:SetShadowOffset(1, -1)
    title:SetText("Title Text")
  
    f.title = title
  end
  
  local text = f.text
  if not text then
    text = f:CreateFontString(nil, "ARTWORK", nil, 7)
    text:SetPoint("LEFT", f, 10, 0)
    text:SetPoint("TOP", title, "BOTTOM", 0, -textOffset)
    text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    text:SetTextColor(0.95, 0.95, 1.0, 1)
    text:SetJustifyH("LEFT")
    text:SetShadowOffset(1, -1)
    text:SetText("Sub text.")
  
    f.text = text
  end
  
  do -- Basic resizing stuff
    arrow:SetPoint("RIGHT", f, "LEFT", arrowOffset, 0)
  end
  
  do -- Handle text
    f.titleString = titleString
    f.textString = textString
    
    if relativeTo and (not titleString and not textString) then
      f.title:SetText(nil)
      f:SetAlpha(0)
      
      f.text:SetText(nil)
      f:SetAlpha(0)
    end
  end
  
  if not f.fadeGroup then -- Gather up everything to be faded in/out in an array for convenience
    f.fadeGroup = {
      f.background,
      f.background.corners[1],
      f.background.corners[2],
      f.background.corners[3],
      f.background.corners[4],
      f.fill1,
      f.fill2,
      f.arrow,
      f.title,
      f.text,
    }
  end
  
  if relativeTo then
    local offsetX, offsetY = offsetX or 0, offsetY or 0
    
    f:ClearAllPoints()
    f:SetPoint("LEFT", relativeTo, "RIGHT", arrowOffset + offsetX, 0 + offsetY)
    f.direction = "IN"
    f.animating = GetTime() + animationDuration
    f:SetScale(0.001)
    f:Show()
  else
    f.direction = "OUT"
    f.animating = GetTime() + animationDuration
  end
  
  -- f:onUpdateFunc() -- Force an instant update NOTE: Does this do anything different?
end

local function adjustTooltipSize()
  local f = CT.infoTooltip
  local parent = f.parent
  local text = f.info:GetText()
  if not text then return end

  f:SetSize(200, 200)

  local height = f.info:GetStringHeight() + 34
  local width = f.info:GetStringWidth()
  if width > 400 then width = 400 end
  if width < 150 then width = 150 end

  f:SetSize(f.info:GetWrappedWidth() + 50, height)
end

function CT.createInfoTooltip(parent, title, icon, func, textTable)
  local f = CT.infoTooltip
  local created

  if not f then
    CT.infoTooltip = CreateFrame("Frame", "CT_InfoTooltip", CT.base)
    f = CT.infoTooltip
    f:SetFrameStrata("TOOLTIP")
    created = true

    f.resize = adjustTooltipSize
    f.text = textTable or {}

    do -- Create Tooltip Borders
      f.border = {}

      for i = 1, 4 do
        local border = f:CreateTexture(nil, "BORDER")
        f.border[i] = border
        border:SetTexture(0.2, 0.2, 0.2, 1.0)
        border:SetSize(2, 2)

        if i == 1 then
          border:SetPoint("TOPRIGHT", f, 0, 0)
          border:SetPoint("TOPLEFT", f, 0, 0)
        elseif i == 2 then
          border:SetPoint("BOTTOMRIGHT", f, 0, 0)
          border:SetPoint("BOTTOMLEFT", f, 0, 0)
        elseif i == 3 then
          border:SetPoint("TOPLEFT", f, 0, 0)
          border:SetPoint("BOTTOMLEFT", f, 0, 0)
        else
          border:SetPoint("TOPRIGHT", f, 0, 0)
          border:SetPoint("BOTTOMRIGHT", f, 0, 0)
        end
      end
    end

    do -- Background and Icon
      f.background = f:CreateTexture(nil, "BACKGROUND")
      f.background:SetTexture(0.075, 0.075, 0.075, 1.00)
      f.background:SetAllPoints()

      f.icon = f:CreateTexture(nil, "ARTWORK")
      f.icon:SetAlpha(0.9)
      f.icon:SetSize(40, 40)
      -- f.icon:SetPoint("TOPLEFT", f, 5, -5)
      f.icon:SetPoint("TOPRIGHT", f, -5, -5)
    end

    do -- Text
      f.title = f:CreateFontString(nil, "ARTWORK")
      f.title:SetHeight(20)
      f.title:SetPoint("TOPLEFT", f, 5, -2)
      f.title:SetPoint("TOPRIGHT", f, -2, -2)
      -- f.title:SetPoint("LEFT", f.icon, "RIGHT", 4, 0)
      -- f.title:SetPoint("TOPRIGHT", f, -2, -2)
      f.title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
      f.title:SetTextColor(1, 1, 0, 1)
      f.title:SetJustifyH("LEFT")
      f.title:SetText("Title")

      f.infoFrame = CreateFrame("Frame", nil, f)
      f.infoFrame:SetSize(100, 10)
      f.infoFrame:SetPoint("BOTTOM", f.title, "TOP")
      f.infoFrame:SetPoint("BOTTOM", f)
      f.infoFrame:SetPoint("LEFT", f)
      f.infoFrame:SetPoint("RIGHT", f)
      -- f.infoFrame:SetPoint("BOTTOM", f.icon, "TOP")
      f.info = f.infoFrame:CreateFontString(nil, "ARTWORK")
      -- f.info:SetHeight(20)
      f.info:SetPoint("BOTTOMLEFT", f.infoFrame, 5, 10)

      -- f.info:SetPoint("BOTTOM", f.infoFrame, 0, 10)

      -- f.info:SetPoint("TOPLEFT", f.title, 0, -20)
      -- f.info:SetPoint("TOPRIGHT", f, 0, -20)
      -- f.info:SetPoint("BOTTOMRIGHT", f, 0, 0)

      f.info:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
      f.info:SetTextColor(1, 1, 1, 1)
      f.info:SetJustifyH("LEFT")
      -- f.info:SetJustifyV("TOP")
      f.info:SetText("Info text.")

      C_Timer.After(0.01, function()
        f.resize()
      end)
    end

    do -- Fade in/out animation
      f.fadeIn = f:CreateAnimationGroup()
      f.fadeIn.fade = f.fadeIn:CreateAnimation("Alpha")
      f.fadeIn.fade:SetToAlpha(1)
      f.fadeIn.fade:SetDuration(0.2)
      f.fadeIn.fade:SetSmoothing("IN")

      f.fadeOut = f:CreateAnimationGroup()
      f.fadeOut.fade = f.fadeOut:CreateAnimation("Alpha")
      f.fadeOut.fade:SetFromAlpha(1)
      f.fadeOut.fade:SetDuration(0.2)
      f.fadeOut.fade:SetSmoothing("OUT")

      f.fadeOut:SetScript("OnFinished", function(self, requested)
        f:Hide()
      end)
    end

    C_Timer.After(0.1, f.resize) -- Without this, it gets screwed up the first time it shows

    local oldNumLines
    local timer = 0
    local delay = 0.05
    local UIScale = UIParent:GetEffectiveScale()
    f:SetScript("OnUpdate", function(self, elapsed)
      local mouseX, mouseY = GetCursorPosition()
      local mouseX = (mouseX / UIScale)
      local mouseY = (mouseY / UIScale)

      self:SetPoint("BOTTOMLEFT", UIParent, mouseX + 30, mouseY)

      timer = timer + elapsed

      if timer >= delay then
        if f.func then
          f.func(f.info, f.text)
        elseif f.parent.info then
          f.info:SetText(f.parent.info)
        end

        if f.parent.tooltipTitle then
          f.title:SetText(f.parent.tooltipTitle)
        end

        local numLines = f.info:GetNumLines()

        if oldNumLines and oldNumLines ~= numLines then
          f.resize()
        end

        oldNumLines = numLines
        timer = 0
      end
    end)
  end

  if not parent then
    f.fadeIn:Stop()
    f.fadeOut:Play()
    return
  else
    f:Show()
    f.fadeOut:Stop()
    f.fadeIn:Play()
  end

  -- f:SetParent(parent)
  f.parent = parent
  f:SetPoint("BOTTOMLEFT", parent, "TOPRIGHT", -25, 5)

  if title then
    f.title:SetText(title)

    if func then
      func(f.info, f.text)
    elseif parent.info then
      f.info:SetText(parent.info)
    end
  end

  f.func = func
  f.icon:SetTexture(icon)

  if icon then
    SetPortraitToTexture(f.icon, f.icon:GetTexture())
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- f.title:ClearAllPoints()
    -- f.title:SetPoint("LEFT", f.icon, "RIGHT", 4, 0)
    -- f.title:SetPoint("TOPRIGHT", f, -2, -2)
  else
    f.title:ClearAllPoints()
    f.title:SetPoint("TOPLEFT", f, 5, -2)
    f.title:SetPoint("TOPRIGHT", f, -2, -2)
  end

  f:resize()

  -- f.info:SetHeight(f.info:GetNumLines() * 12)
  --
  -- local width = f.info:GetStringWidth()
  -- if width > 400 then width = 400 end
  -- if width < 250 then width = 250 end
  -- f:SetWidth(width)
  --
  -- f:SetHeight(20)
  -- f:SetHeight(1)

  -- C_Timer.After(0.01, function()
  --   f.info:SetHeight(f.info:GetNumLines() * 12)
  --
  --   local width = f.info:GetStringWidth()
  --   if width > 400 then width = 400 end
  --   if width < 250 then width = 250 end
  --   f:SetWidth(width)
  --
  --   local strHeight = f.info:GetStringHeight()
  --   local height = max(f.title:GetHeight() + f.info:GetHeight() + 14, 50)
  --   f:SetHeight(height)
  -- end)

  -- debug(width, height, f.info:GetNumLines())
end

function CT.createInfoTooltip_BACKUP(parent, title, icon, func, textTable)
  local f = CT.infoTooltip
  local created

  if not f then
    CT.infoTooltip = CreateFrame("Frame", "CT_InfoTooltip", CT.base)
    f = CT.infoTooltip
    f:SetFrameStrata("TOOLTIP")
    created = true

    f.resize = adjustTooltipSize
    f.text = textTable or {}

    do -- Create Tooltip Borders
      f.border = {}

      for i = 1, 4 do
        local border = f:CreateTexture(nil, "BORDER")
        f.border[i] = border
        border:SetTexture(0.2, 0.2, 0.2, 1.0)
        border:SetSize(2, 2)

        if i == 1 then
          border:SetPoint("TOPRIGHT", f, 0, 0)
          border:SetPoint("TOPLEFT", f, 0, 0)
        elseif i == 2 then
          border:SetPoint("BOTTOMRIGHT", f, 0, 0)
          border:SetPoint("BOTTOMLEFT", f, 0, 0)
        elseif i == 3 then
          border:SetPoint("TOPLEFT", f, 0, 0)
          border:SetPoint("BOTTOMLEFT", f, 0, 0)
        else
          border:SetPoint("TOPRIGHT", f, 0, 0)
          border:SetPoint("BOTTOMRIGHT", f, 0, 0)
        end
      end
    end

    do -- Background and Icon
      f.background = f:CreateTexture(nil, "BACKGROUND")
      f.background:SetTexture(0.075, 0.075, 0.075, 1.00)
      f.background:SetAllPoints()

      f.icon = f:CreateTexture(nil, "ARTWORK")
      f.icon:SetAlpha(0.9)
      f.icon:SetSize(40, 40)
      -- f.icon:SetPoint("TOPLEFT", f, 5, -5)
      f.icon:SetPoint("TOPRIGHT", f, -5, -5)
    end

    do -- Text
      f.title = f:CreateFontString(nil, "ARTWORK")
      f.title:SetHeight(20)
      f.title:SetPoint("TOPLEFT", f, 5, -2)
      f.title:SetPoint("TOPRIGHT", f, -2, -2)
      -- f.title:SetPoint("LEFT", f.icon, "RIGHT", 4, 0)
      -- f.title:SetPoint("TOPRIGHT", f, -2, -2)
      f.title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
      f.title:SetTextColor(1, 1, 0, 1)
      f.title:SetJustifyH("LEFT")
      f.title:SetText("Title")

      f.infoFrame = CreateFrame("Frame", nil, f)
      f.infoFrame:SetSize(100, 10)
      f.infoFrame:SetPoint("BOTTOM", f.title, "TOP")
      f.infoFrame:SetPoint("BOTTOM", f)
      f.infoFrame:SetPoint("LEFT", f)
      f.infoFrame:SetPoint("RIGHT", f)
      -- f.infoFrame:SetPoint("BOTTOM", f.icon, "TOP")
      f.info = f.infoFrame:CreateFontString(nil, "ARTWORK")
      -- f.info:SetHeight(20)
      f.info:SetPoint("BOTTOMLEFT", f.infoFrame, 5, 10)

      -- f.info:SetPoint("BOTTOM", f.infoFrame, 0, 10)

      -- f.info:SetPoint("TOPLEFT", f.title, 0, -20)
      -- f.info:SetPoint("TOPRIGHT", f, 0, -20)
      -- f.info:SetPoint("BOTTOMRIGHT", f, 0, 0)

      f.info:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
      f.info:SetTextColor(1, 1, 1, 1)
      f.info:SetJustifyH("LEFT")
      -- f.info:SetJustifyV("TOP")
      f.info:SetText("Info text.")

      C_Timer.After(0.01, function()
        f.resize()
      end)
    end

    do -- Fade in/out animation
      f.fadeIn = f:CreateAnimationGroup()
      f.fadeIn.fade = f.fadeIn:CreateAnimation("Alpha")
      f.fadeIn.fade:SetToAlpha(1)
      f.fadeIn.fade:SetDuration(0.2)
      f.fadeIn.fade:SetSmoothing("IN")

      f.fadeOut = f:CreateAnimationGroup()
      f.fadeOut.fade = f.fadeOut:CreateAnimation("Alpha")
      f.fadeOut.fade:SetFromAlpha(1)
      f.fadeOut.fade:SetDuration(0.2)
      f.fadeOut.fade:SetSmoothing("OUT")

      f.fadeOut:SetScript("OnFinished", function(self, requested)
        f:Hide()
      end)
    end

    C_Timer.After(0.1, f.resize) -- Without this, it gets screwed up the first time it shows

    local oldNumLines
    local timer = 0
    local delay = 0.05
    f:SetScript("OnUpdate", function(self, elapsed)
      timer = timer + elapsed

      if timer >= delay then
        if f.func then
          f.func(f.info, f.text)
        elseif f.parent.info then
          f.info:SetText(f.parent.info)
        end

        local numLines = f.info:GetNumLines()

        if oldNumLines and oldNumLines ~= numLines then
          f.resize()
        end

        oldNumLines = numLines
        timer = 0
      end
    end)
  end

  if not parent then
    f.fadeIn:Stop()
    f.fadeOut:Play()
    return
  else
    f:Show()
    f.fadeOut:Stop()
    f.fadeIn:Play()
  end

  -- f:SetParent(parent)
  f.parent = parent
  f:SetPoint("BOTTOMLEFT", parent, "TOPRIGHT", -25, 5)

  if title then
    f.title:SetText(title)

    if func then
      func(f.info, f.text)
    elseif parent.info then
      f.info:SetText(parent.info)
    end
  end

  f.func = func
  f.icon:SetTexture(icon)

  if icon then
    SetPortraitToTexture(f.icon, f.icon:GetTexture())
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- f.title:ClearAllPoints()
    -- f.title:SetPoint("LEFT", f.icon, "RIGHT", 4, 0)
    -- f.title:SetPoint("TOPRIGHT", f, -2, -2)
  else
    f.title:ClearAllPoints()
    f.title:SetPoint("TOPLEFT", f, 5, -2)
    f.title:SetPoint("TOPRIGHT", f, -2, -2)
  end

  f:resize()

  -- f.info:SetHeight(f.info:GetNumLines() * 12)
  --
  -- local width = f.info:GetStringWidth()
  -- if width > 400 then width = 400 end
  -- if width < 250 then width = 250 end
  -- f:SetWidth(width)
  --
  -- f:SetHeight(20)
  -- f:SetHeight(1)

  -- C_Timer.After(0.01, function()
  --   f.info:SetHeight(f.info:GetNumLines() * 12)
  --
  --   local width = f.info:GetStringWidth()
  --   if width > 400 then width = 400 end
  --   if width < 250 then width = 250 end
  --   f:SetWidth(width)
  --
  --   local strHeight = f.info:GetStringHeight()
  --   local height = max(f.title:GetHeight() + f.info:GetHeight() + 14, 50)
  --   f:SetHeight(height)
  -- end)

  -- debug(width, height, f.info:GetNumLines())
end
