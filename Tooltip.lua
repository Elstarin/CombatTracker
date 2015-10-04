if not CombatTracker then return end
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

  f:SetParent(parent)
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
