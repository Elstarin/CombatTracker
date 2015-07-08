--[[ STUFF FOR LATER

Tooltip Scanning? TMW has section on it in DogTag Categories
local checks = {
     _G.UNITNAME_TITLE_CHARM:gsub("%%s", "(.+)"),
     _G.UNITNAME_TITLE_COMPANION:gsub("%%s", "(.+)"),
     _G.UNITNAME_TITLE_CREATION:gsub("%%s", "(.+)"),
     _G.UNITNAME_TITLE_GUARDIAN:gsub("%%s", "(.+)"),
     _G.UNITNAME_TITLE_MINION:gsub("%%s", "(.+)"),
     _G.UNITNAME_TITLE_PET:gsub("%%s", "(.+)")
}

  local tformat1 = "%d:%02d"
  local tformat2 = "%1.1f"
  local tformat3 = "%.0f"
  local function timeDetails(t)
    if t >= 3600 then -- > 1 hour
      local h = floor(t/3600)
      local m = t - (h*3600)
      return tformat1:format(h, m)
    elseif t >= 60 then -- 1 minute to 1 hour
      local m = floor(t/60)
      local s = t - (m*60)
      return tformat1:format(m, s)
    elseif t < 10 then -- 0 to 10 seconds
      return tformat2:format(t)
    else -- 10 seconds to one minute
      return tformat3:format(floor(t + .5))
    end
  end

  for k in next, normalAnchor.bars do
    if k ~= bar then
      plugin:SendMessage("BigWigs_SilenceOption", k:Get("bigwigs:option"), k.remaining + 0.3)
      k:Stop()
    end
  end

  local rearrangeBars
  do
       local function barSorter(a, b)
            return a.remaining < b.remaining and true or false
       end
       local tmp = {}
       rearrangeBars = function(anchor)
            if not anchor then return end
            if anchor == normalAnchor then -- only show the empupdater when there are bars on the normal anchor running
                 if next(anchor.bars) and db.emphasize then
                      empUpdate:Play()
                 else
                      empUpdate:Stop()
                 end
            end
            if not next(anchor.bars) then return end

            wipe(tmp)
            for bar in next, anchor.bars do
                 tmp[#tmp + 1] = bar
            end
            table.sort(tmp, barSorter)
            local lastDownBar, lastUpBar = nil, nil
            local up = nil
            if anchor == normalAnchor then up = db.growup else up = db.emphasizeGrowup end
            for i, bar in next, tmp do
                 local spacing = currentBarStyler.GetSpacing(bar) or 0
                 bar:ClearAllPoints()
                 if up or (db.emphasizeGrowup and bar:Get("bigwigs:emphasized")) then
                      if lastUpBar then -- Growing from a bar
                           bar:SetPoint("BOTTOMLEFT", lastUpBar, "TOPLEFT", 0, spacing)
                           bar:SetPoint("BOTTOMRIGHT", lastUpBar, "TOPRIGHT", 0, spacing)
                      else -- Growing from the anchor
                           bar:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 0)
                           bar:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
                      end
                      lastUpBar = bar
                 else
                      if lastDownBar then -- Growing from a bar
                           bar:SetPoint("TOPLEFT", lastDownBar, "BOTTOMLEFT", 0, -spacing)
                           bar:SetPoint("TOPRIGHT", lastDownBar, "BOTTOMRIGHT", 0, -spacing)
                      else -- Growing from the anchor
                           bar:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
                           bar:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
                      end
                      lastDownBar = bar
                 end
            end
       end
  end

  local function onDragHandleMouseDown(self) self:GetParent():StartSizing("BOTTOMRIGHT") end
  local function onDragHandleMouseUp(self, button) self:GetParent():StopMovingOrSizing() end
  local function onResize(self, width)
       db[self.w] = width
       rearrangeBars(self)
  end
  local function onDragStart(self) self:StartMoving() end
  local function onDragStop(self)
       self:StopMovingOrSizing()
       local s = self:GetEffectiveScale()
       db[self.x] = self:GetLeft() * s
       db[self.y] = self:GetTop() * s
       plugin:UpdateGUI() -- Update X/Y if GUI is open.
  end

  display:SetScript("OnSizeChanged", onResize)
  display:SetScript("OnDragStart", onDragStart)
  display:SetScript("OnDragStop", onDragStop)
  display:SetScript("OnMouseUp", function(self, button)
    if button ~= "LeftButton" then return end
    plugin:SendMessage("BigWigs_SetConfigureTarget", plugin)
  end)

]]--
--------------------------------------------------------------------------------
-- Notes and Changes
--------------------------------------------------------------------------------

-- Possibly make each main button updater a module and enable them based on what buttons are created
-- Prevent DropText from updating unless the DropDown is actually shown
-- Otherwise just make the text actually update when it gets expanded as there's
-- No reason to make it happen constantly. Should be more efficient.

-- Should restore saved settings OnInitialize instead of OnEnable
-- For sorting, store the old order in a table, and bring it back on a second press.

-- CT.SaveButton = CreateFrame("CheckButton", "SavesButton", CombatTrackerBase, "CombatTrackerSaveButtonTemplate")
-- CT.OptionsButton = CreateFrame("CheckButton", "OptionsButton", CombatTrackerBase, "CombatTrackerOptionsButtonTemplate")

-- Destruction definitely needs a good way to track ember use. Obviously wasted embers
-- but also things like chaos bolt usage. It might be good to calculate the base chaos bolt damage
-- and offer a comparison to the average damage done with it. Also track how many were casted
-- with buffs, and ideally, which buffs.

-- Mistweaver needs tracking of renewing mists overwritten.
-- It would be good if it could track how efficient uplift was. Is just tracking the average heal enough?

-- What about tracking mana from natural regen, including spirit? I might need to find a way to filter natural regen from bursts.

-- Tank stuff? Total damage reduced by taken and reduced by CDs? As soon as a defensive goes up, track damage taken and calculate the effectiveness of the CD.
-- I might have to scrape the tooltips of buffs to get the reduction percentage.

--  NOTE: Trackers to create:
--  Total mana: how much was started with and gained?
--  Track death knight runes
--  How resources were spent
--  If dispel was successful
--  Total buff/debuff uptime percentage (for DoTs)
-- NOTE: Some events to keep in mind: UNIT_ABSORB_AMOUNT_CHANGED, UNIT_COMBO_POINTS, LEARNED_SPELL_IN_TAB, UNIT_DISPLAYPOWER, UNIT_PET, UPDATE_SHAPESHIFT_FORM, UPDATE_STEALTH, RUNE_TYPE_UPDATE
-- RUNE_POWER_UPDATE, PLAYER_TOTEM_UPDATE, SPELL_UPDATE_CHARGES,

-- NOTE: For activity, test out using Blizzard timers combined with name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(116858)
-- Multiply castingTime by .001, then I can compare that to other things, start a timer, etc

-- Maybe use the talent spec buttons?
-- Move expander frame behind button?
-- Map ? mark button
-- Dungeon journal buttons?
-- - Also boss select button
-- Group finder premade group buttons
-- Ooh, arena and battleground buttons are better
-- And side buttons are nice in the PvP frame as well

-- f:RegisterEvent("UNIT_FLAGS") -- accurately detects changes to InCombatLockdown
-- f:SetScript("OnEvent", function(self, event)
--   isInCombatLockdown = InCombatLockdown()
-- end)

--[[ TODO:



]]

--------------------------------------------------------------------------------
-- Locals, Frames, and Tables
--------------------------------------------------------------------------------
CombatTracker = LibStub("AceAddon-3.0"):NewAddon("CombatTracker", "AceConsole-3.0")
local CT = CombatTracker
CT.loadSpellData = false
CT.__index = CT
CT.settings = {}
CT.settings.buttonSpacing = 2
CT.combatevents = {}
local combatevents = CT.combatevents
CT.player = {}
CT.altPower = {}
local temp = {}
CT.player.talents = {}
CT.mainButtons = {}
CT.shown = true
CT.tracking = true
CT.registeredGraphs = {}
CT.registerGraphs = {}
local lastMouseoverButton
--------------------------------------------------------------------------------
-- Upvalues
--------------------------------------------------------------------------------
local GetSpellCooldown, GetSpellInfo, GetSpellTexture, IsUsableSpell =
       GetSpellCooldown, GetSpellInfo, GetSpellTexture, IsUsableSpell
local InCombatLockdown, GetTalentInfo, GetActiveSpecGroup =
       InCombatLockdown, GetTalentInfo, GetActiveSpecGroup
local UnitPower, UnitClass, UnitName, UnitAura =
       UnitPower, UnitClass, UnitName, UnitAura
local IsInGuild, IsInGroup, IsInInstance =
       IsInGuild, IsInGroup, IsInInstance
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, rawset, assert, pcall, error, getmetatable, setmetatable, loadstring, unpack, debugstack =
       tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, rawset, assert, pcall, error, getmetatable, setmetatable, loadstring, unpack, debugstack
local strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, strjoin, max, ceil, floor, random =
       strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, strjoin, max, ceil, floor, random
local _G, coroutine, table, GetTime, CopyTable =
       _G, coroutine, table, GetTime, CopyTable
--------------------------------------------------------------------------------
-- Main Update Engine
--------------------------------------------------------------------------------
CT.update = {}
local timer = 0
CT.settings.updateDelay = 0.1
CT.mainUpdate = CreateFrame("Frame")
CT.mainUpdate:SetScript("OnUpdate", function(frame, elapsed)
  
  if CT.forceUpdate then
    local time = GetTime()

    for i = 1, #CT.update do
      CT.update[i]:update(time)
    end

    CT.forceUpdate = false

  elseif CT.shown and CT.tracking then
    timer = timer + elapsed

    if timer >= CT.settings.updateDelay then
      local time = GetTime()

      for i = 1, #CT.update do
        CT.update[i]:update(time)
      end

      timer = 0
    end
  end
end)
--------------------------------------------------------------------------------
-- On Initialize
--------------------------------------------------------------------------------
function CT:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("CombatTrackerDB")
  self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")

  CT.eventFrame = CreateFrame("Frame")
  local eventFrame = CT.eventFrame
  for k,v in pairs({
    "COMBAT_LOG_EVENT_UNFILTERED",
    "COMBAT_RATING_UPDATE",
    "PLAYER_LOGIN",
    "PLAYER_CONTROL_GAINED",
    "PLAYER_CONTROL_LOST",
    "PLAYER_ALIVE",
    "PLAYER_DEAD",
    "PLAYER_TALENT_UPDATE",
    "PLAYER_REGEN_ENABLED",
    "ENCOUNTER_START",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_STARTED_MOVING",
    "PLAYER_STOPPED_MOVING",
    "PLAYER_DAMAGE_DONE_MODS",
    "PET_ATTACK_START",
    "PET_ATTACK_STOP",
    "PLAYER_TOTEM_UPDATE",
    "UNIT_SPELLCAST_SENT",
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_FAILED_QUIET",
    "SPELL_UPDATE_COOLDOWN",
    "SPELL_UPDATE_USABLE",
    "SPELL_UPDATE_CHARGES",
    "PLAYER_SPECIALIZATION_CHANGED",
    "CURRENT_SPELL_CAST_CHANGED",
    "UNIT_HEALTH_FREQUENT",
    "UNIT_POWER_FREQUENT",
    "UNIT_ATTACK_POWER",
    "SPELL_POWER_CHANGED",
    "UNIT_RANGED_ATTACK_POWER",
    "UNIT_DISPLAYPOWER",
    "WEIGHTED_SPELL_UPDATED",
    "UNIT_PET",
    "UNIT_DEFENSE",
    "UNIT_ABSORB_AMOUNT_CHANGED",
  }) do eventFrame:RegisterEvent(v) end

  for k,v in pairs({
    "UNIT_HEALTH_FREQUENT",
    "UNIT_MAXHEALTH",
    "UNIT_MAXPOWER",
    "UNIT_POWER_FREQUENT",
    "UNIT_MAXPOWER",
    "UNIT_ATTACK_POWER",
    "SPELL_POWER_CHANGED",
    "UNIT_RANGED_ATTACK_POWER",
    "UNIT_DISPLAYPOWER",
    "WEIGHTED_SPELL_UPDATED",
    "UNIT_PET",
    "UNIT_DEFENSE",
    "UNIT_ABSORB_AMOUNT_CHANGED",
    "UNIT_STATS",
    "UNIT_SPELL_HASTE",
    "UNIT_SPELL_CRITICAL",
  }) do eventFrame:RegisterUnitEvent(v, "player") end

  eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
      local _, event = ...
      if combatevents[event] then
        combatevents[event](...)
      end
    elseif event == "PLAYER_LOGIN" then
      CT.TimeSinceLogIn = GetTime()
      CT.player.loggedIn = true
      CT.updatePowerTypes()
      eventFrame:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "ENCOUNTER_START" then
      local encounterID, encounterName, difficultyID, raidSize = ...

      CT.fightName = encounterName

      eventFrame:RegisterEvent("ENCOUNTER_END")
      eventFrame:UnregisterEvent("ENCOUNTER_START")
    elseif event == "ENCOUNTER_END" then
      eventFrame:RegisterEvent("ENCOUNTER_START")
      eventFrame:UnregisterEvent("ENCOUNTER_END")

      function CT:ENCOUNTER_END(eventName, ...)
        local encounterID, encounterName, difficultyID, raidSize, endStatus = ...
        CT.fightName = encounterName
        -- NOTE: encounterID
        --[[
          DIFFICULTY IDs:
          0 - None; not in an Instance.
          1 - 5-player Instance.
          2 - 5-player Heroic Instance.
          3 - 10-player Raid Instance.
          4 - 25-player Raid Instance.
          5 - 10-player Heroic Raid Instance.
          6 - 25-player Heroic Raid Instance.
          7 - Raid Finder Instance.
          8 - Challenge Mode Instance.
          9 - 40-player Raid Instance.
          10 - Not used.
          11 - Heroic Scenario Instance.
          12 - Scenario Instance.
          13 - Not used.
          14 - Flexible Raid.
          15 - Heroic Flexible Raid.
          END STATUS:
          0 - Wipe.
          1 - Success.
        ]]--
      end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
      if IsLoggedIn() then
        CT:Print(event)
        CT.cycleMainButtons()
      end
    elseif event == "PLAYER_REGEN_ENABLED" then
      eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
      eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")

      CT.player.combat = true
    elseif event == "PLAYER_REGEN_DISABLED" then
      eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
      eventFrame:UnregisterEvent("PLAYER_REGEN_DISABLED")

      CT.player.combat = false
    elseif event == "PLAYER_TALENT_UPDATE" then
      if IsLoggedIn() then
        CT.getPlayerDetails()
      end
    elseif event == "PLAYER_ALIVE" then
      CT.player.alive = true
    elseif event == "PLAYER_DEAD" then
      CT.player.alive = false
    else
      if combatevents[event] then
        combatevents[event](...)
      end
    end
  end)

  SLASH_CombatTracker1 = "/ct"
  function SlashCmdList.CombatTracker(msg, editbox)
    local direction, offSet = msg:match("([xXyY])([+-]?%d+)")
    if direction then direction = direction:lower() end
    local command, rest = msg:match("^(%S*)%s*(.-)$"):lower()

    if command == "toggle" or command == "" then
      if CT.base:IsVisible() then
        CT.base:Hide()
        -- CT:Disable()
      else
        CT.base:Show()
        -- CT:Enable()
      end
    elseif command == "show" then
      CT.base:Show()
    elseif command == "hide" then
      CT.base:Hide()
    elseif command == "reset" then
      CT.base:ClearAllPoints()
      CT.base:SetPoint("CENTER", "UIParent", 0, 0)
      CT:Print("Position reset.")
    elseif command == "cmd" or command == "commands" or command == "options" or command == "opt" or command == "help" then
      CT:Print("CT COMMANDS:\ntoggle - Toggles Show/Hide.\nshow - Shows CombatTracker.\nhide - Hides CombatTracker.\nreset - Moves CombatTracker frame to the center.\nxNUMBER - Adjusts X axis by number\nyNUMBER - Adjusts Y axis by number")
    elseif direction == "x" and offSet then
      local p1, p2, p3, p4, p5 = CombatTrackerBase:GetPoint()
      CT.base:ClearAllPoints()
      CT.base:SetPoint(p1, p2, p3, p4 + tonumber(offSet), p5)
    elseif direction == "y" and offSet then
      local p1, p2, p3, p4, p5 = CombatTrackerBase:GetPoint()
      CT.base:ClearAllPoints()
      CT.base:SetPoint(p1, p2, p3, p4, p5 + tonumber(offSet))
    end
  end
end

function CT:OnEnable()
  do
    CT.getPlayerDetails()

    for i = 1, #CT.specData do
      CT:newButton(CT.specData[i], i)
    end

    CT.totalNumButtons = #CT.specData
    CT.setButtonAnchors()
    CT.scrollFrameUpdate()
          CT.showLastFight()
  end

  -- if self.db.char[CT.player.spec] then
  --   CT.mainButtons = self.db.char[CT.player.spec].mainButtons
  -- end
end

function CT:OnDisable()
  -- CT:Print("CT Disable")
end
--------------------------------------------------------------------------------
-- Main Button Functions
--------------------------------------------------------------------------------
-- NOTE: For close button, look at DynamicElements.png OR
-- ReadyCheck-NotReady.png
do -- Create Base Frame
  CT.base = CreateFrame("Frame", "CT_Base", UIParent)
  local f = CT.base
  f:SetPoint("CENTER")
  f:SetSize(400, 600)

  local backdrop = {
  bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tileSize = 32,
  edgeSize = 16,
  insets = {left = 0, right = 0, top = 0, bottom = 0}}

  f:SetBackdrop(backdrop)
  f:SetBackdropColor(0.15, 0.15, 0.15, 1)
  f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)

  f:SetMovable(true)
  f:EnableMouse(true)
  f:EnableKeyboard(true)
  f:SetResizable(true)

  f:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
      self:StartMoving()
      self.isMoving = true
    end
  end)
  f:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
      self:StopMovingOrSizing()
      self.isMoving = false
      CT:updateButtonList()
    end
  end)
     f:SetScript("OnEnter", function(self)
          if lastMouseoverButton then
               lastMouseoverButton.dragger:SetAlpha(0)
               lastMouseoverButton.upArrow:SetAlpha(0)
               lastMouseoverButton.downArrow:SetAlpha(0)
               lastMouseoverButton:UnlockHighlight()
          end
     end)

  do -- Main size dragger
    f:SetMaxResize(550, 700)
    f:SetMinResize(400, 400)

    f.dragger = CreateFrame("Button", nil, f)
    f.dragger:SetSize(20, 20)
    f.dragger:SetPoint("BOTTOMRIGHT", -1, 2)
    f.dragger:SetNormalTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Up.png")
    f.dragger:SetPushedTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Down.png")
    f.dragger:SetHighlightTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Highlight.png")

          -- NOTE: Need to get resolution properly
    f.dragger:SetScript("OnMouseDown", function(self)
      CT.base:StartSizing()
               --
               -- local UIScale = UIParent:GetEffectiveScale()
               -- local startX, startY = GetCursorPosition()
               -- local startX = startX / UIScale
               -- local startY = startY / UIScale
               --
               -- local resolutionX = 1920
               -- local resolutionY = 1080
               --
               -- local startLeft, startBottom, startWidth, startHeight = CT.base:GetRect()
               -- local startScale = CT.base:GetScale()
               -- -- GetEffectiveScale()
               --
               -- self.ticker = C_Timer.NewTicker(0.001, function(ticker)
               --      local mouseX, mouseY = GetCursorPosition()
               --      local mouseX = (mouseX / UIScale)
               --      local mouseY = (mouseY / UIScale)
               --
               --      if (mouseX > startX) or (mouseY < startY) then -- Increasing Scale
               --           local valX = (mouseX - startX) / resolutionX
               --           local valY = (startY - mouseY) / resolutionY
               --
               --           local maxVal = max(valX, valY)
               --           local newScale = startScale + maxVal
               --
               --           CT.base:SetScale(newScale)
               --      else -- Decreasing Scale
               --           local valX = (mouseX - startX) / resolutionX
               --           local valY = (startY - mouseY) / resolutionY
               --
               --           local minVal = min(valX, valY)
               --           local newScale = startScale + minVal
               --
               --           CT.base:SetScale(newScale)
               --      end
               -- end)
    end)

    f.dragger:SetScript("OnMouseUp", function(self)
      CT.base:StopMovingOrSizing()

               -- self.ticker:Cancel()
    end)
  end

  do -- Scroll Frame, Main Content Frame, and Scroll Bar
    CT.scrollFrame = CreateFrame("ScrollFrame", "CT_ScrollFrame", CT.base)
    CT.scrollFrame:SetPoint("TOPLEFT", 25, -88)
    CT.scrollFrame:SetPoint("BOTTOMRIGHT", -25, 100)

    CT.scrollBar = CreateFrame("Slider", "CT_ScrollBar", CT.scrollFrame, "UIPanelScrollBarTemplate")
    CT.scrollBar:SetPoint("TOPRIGHT", CT.scrollFrame, 20, 0)
    CT.scrollBar:SetPoint("BOTTOMRIGHT", CT.scrollFrame, 20, 0)
          CT.scrollBar.background = CT.scrollBar:CreateTexture("CT_ScrollBarBackground", "BACKGROUND")
          CT.scrollBar.background:SetTexture("Interface\\addons\\CombatTracker\\ScrollBG")
          CT.scrollBar.background:SetAllPoints()
    CT.scrollBar.thumbTexture = CT.scrollBar:CreateTexture("CT_ScrollBarThumbTexture")
          CT.scrollBar.thumbTexture:SetTexture("Interface\\addons\\CombatTracker\\ThumbSlider.tga")
    CT.scrollBar.thumbTexture:SetSize(10, 32)
    CT.scrollBar:SetThumbTexture(CT.scrollBar.thumbTexture)

    CT.scrollBar.AG = CT.scrollBar:CreateAnimationGroup("ScrollHider")
    CT.scrollBar.AG.A = CT.scrollBar.AG:CreateAnimation("Alpha")
    CT.scrollBar.AG.A:SetChange(-1)
    CT.scrollBar.AG.A:SetDuration(1)
    CT.scrollBar.AG.A:SetStartDelay(1)
    CT.scrollBar.AG.A:SetSmoothing("OUT")
    local c1, c2 = CT.scrollBar:GetChildren()
      c1:Hide()
      c2:Hide()
    CT.scrollBar:SetAlpha(0)
    CT.scrollBar:SetValueStep(46)
    CT.scrollBar.scrollStep = 1
    CT.scrollBar:SetWidth(16)
    CT.scrollBar:SetScript("OnValueChanged", function(self, value)
      CT.scrollFrame:SetVerticalScroll(value)
    end)

    CT.scrollBar.AG:SetScript("OnFinished", function(self, requested)
      CT.scrollBar:SetAlpha(0)
    end)

    CT.contentFrame = CreateFrame("Frame", "CT_MainContent", CT.base)
    CT.contentFrame:SetSize(CT.scrollFrame:GetWidth(), CT.scrollFrame:GetHeight())
    CT.scrollFrame:SetScrollChild(CT.contentFrame)
    CT.contentFrame:SetPoint("TOPLEFT", CT.base, 25, -88)
    CT.contentFrame:SetPoint("BOTTOMRIGHT", CT.base, -25, 100)

          CT.scrollBar:SetScript("OnEnter", function(self, value)
               CT.scrollBar:SetAlpha(1)
          end)

          CT.scrollBar:SetScript("OnLeave", function(self, value)
               CT.scrollBar.AG:Stop()
               CT.scrollBar.AG:Play()
          end)

          CT.scrollBar:SetScript("OnMouseWheel", function(self, value)
               local cur_val = CT.scrollBar:GetValue()
               local min_val, max_val = CT.scrollBar:GetMinMaxValues()

               if value < 0 and cur_val < max_val then
                    cur_val = min(max_val, cur_val + 46)
                    CT.scrollBar:SetValue(cur_val)
               elseif value > 0 and cur_val > min_val then
                    cur_val = max(min_val, cur_val - 46)
                    CT.scrollBar:SetValue(cur_val)
               end
          end)

    CT.scrollFrame:SetScript("OnMouseWheel", function(self, value)
      CT.scrollBar:SetAlpha(1)

      local cur_val = CT.scrollBar:GetValue()
      local min_val, max_val = CT.scrollBar:GetMinMaxValues()

      if value < 0 and cur_val < max_val then
        cur_val = min(max_val, cur_val + 46)
        CT.scrollBar:SetValue(cur_val)
      elseif value > 0 and cur_val > min_val then
        cur_val = max(min_val, cur_val - 46)
        CT.scrollBar:SetValue(cur_val)
      end

      CT.scrollBar.AG:Stop()
      CT.scrollBar.AG:Play()
    end)
  end

  do -- Top, bottom, left, and right textures and gradients
    f.top = CreateFrame("Frame", nil, f)
    f.top:SetPoint("TOPLEFT", f, 5, -5)
    f.top:SetPoint("TOPRIGHT", f, -5, -5)
    f.top:SetPoint("BOTTOM", CT.scrollFrame, "TOP", 0, 15)
    f.top.texture = f.top:CreateTexture(nil, "BACKGROUND")
    f.top.texture:SetTexture(0.1, 0.1, 0.1, 1)
    f.top.texture:SetAllPoints()

    f.bottom = CreateFrame("Frame", nil, f)
    f.bottom:SetPoint("BOTTOMLEFT", f, 5, 5)
    f.bottom:SetPoint("BOTTOMRIGHT", f, -5, 5)
    f.bottom:SetPoint("TOP", CT.scrollFrame, "BOTTOM", 0, -15)
    f.bottom.texture = f.bottom:CreateTexture(nil, "BACKGROUND")
    f.bottom.texture:SetTexture(0.1, 0.1, 0.1, 1)
    f.bottom.texture:SetAllPoints()

          do -- Left Texture and Gradient
         f.left = CreateFrame("Frame", nil, f)
         f.left:SetPoint("TOPLEFT", f.top, "BOTTOMLEFT", 0, 0)
         f.left:SetPoint("BOTTOMLEFT", f.bottom, "TOPLEFT", 0, 0)
         f.left:SetPoint("RIGHT", CT.scrollFrame, "LEFT", -15, 0)
         f.left.texture = f.left:CreateTexture(nil, "BACKGROUND")
         f.left.texture:SetTexture(0.1, 0.1, 0.1, 1)
         f.left.texture:SetAllPoints()
         f.left.gradient = f.left:CreateTexture(nil, "ARTWORK")
         f.left.gradient:SetWidth(10)
         f.left.gradient:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
         f.left.gradient:SetGradientAlpha("HORIZONTAL", 0.1, 0.1, 0.1, 1, 0.1, 0.1, 0.1, 0)
         f.left.gradient:SetPoint("TOPLEFT", f.left, "TOPRIGHT", 0, 0)
         f.left.gradient:SetPoint("BOTTOMLEFT", f.left, "BOTTOMRIGHT", 0, 0)
          end

          do -- Right Texture and Gradient
         f.right = CreateFrame("Frame", nil, f)
         f.right:SetPoint("TOPRIGHT", f.top, "BOTTOMRIGHT", 0, 0)
         f.right:SetPoint("BOTTOMRIGHT", f.bottom, "TOPRIGHT", 0, 0)
         f.right:SetPoint("LEFT", CT.scrollFrame, "RIGHT", 15, 0)
         f.right.texture = f.right:CreateTexture(nil, "BACKGROUND")
         f.right.texture:SetTexture(0.1, 0.1, 0.1, 1)
         f.right.texture:SetAllPoints()
         f.right.gradient = f.right:CreateTexture(nil, "ARTWORK")
         f.right.gradient:SetWidth(10)
         f.right.gradient:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
         f.right.gradient:SetGradientAlpha("HORIZONTAL", 0.1, 0.1, 0.1, 0, 0.1, 0.1, 0.1, 1)
         f.right.gradient:SetPoint("TOPRIGHT", f.right, "TOPLEFT", 0, 0)
         f.right.gradient:SetPoint("BOTTOMRIGHT", f.right, "BOTTOMLEFT", 0, 0)
          end

    do -- Top and Bottom Gradients
      f.top.gradient = f.top:CreateTexture(nil, "BACKGROUND")
      f.top.gradient:SetHeight(10)
      f.top.gradient:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
      f.top.gradient:SetGradientAlpha("VERTICAL", 0.1, 0.1, 0.1, 0, 0.1, 0.1, 0.1, 1)
      f.top.gradient:SetPoint("TOPLEFT", f.left, "TOPRIGHT", 0, 0)
      f.top.gradient:SetPoint("TOPRIGHT", f.right, "TOPLEFT", 0, 0)

      f.bottom.gradient = f.bottom:CreateTexture(nil, "BACKGROUND")
      f.bottom.gradient:SetHeight(10)
      f.bottom.gradient:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
      f.bottom.gradient:SetGradientAlpha("VERTICAL", 0.1, 0.1, 0.1, 1, 0.1, 0.1, 0.1, 0)
      f.bottom.gradient:SetPoint("BOTTOMLEFT", f.left, "BOTTOMRIGHT", 0, 0)
      f.bottom.gradient:SetPoint("BOTTOMRIGHT", f.right, "BOTTOMLEFT", 0, 0)
    end

    do -- Button Container Frame and Button 1 and 2
      local width = f.left:GetWidth()
      f.bottom.buttonFrame = CreateFrame("Frame", nil, f.bottom)
      f.bottom.buttonFrame:SetPoint("TOPLEFT", width, 0)
      f.bottom.buttonFrame:SetPoint("TOPRIGHT", -width, 0)
      f.bottom.buttonFrame:SetPoint("BOTTOMLEFT", width, 5)
      f.bottom.buttonFrame:SetPoint("BOTTOMRIGHT", -width, 5)
      f.bottom.buttonFrame.texture = f.bottom.buttonFrame:CreateTexture(nil, "ARTWORK")
      f.bottom.buttonFrame.texture:SetAllPoints()
      f.bottom.buttonFrame.texture:SetTexture(0.05, 0.05, 0.05, 0)

               do -- Button 1
           f.bottom.buttonFrame.button1 = CreateFrame("Button", nil, f.bottom.buttonFrame)
           local b1 = f.bottom.buttonFrame.button1
           b1:SetSize(174, f.bottom.buttonFrame:GetHeight() - 10)
           b1:SetPoint("LEFT", 10, 0)
           b1.normal = b1:CreateTexture(nil, "BACKGROUND")
           b1.normal:SetTexture("Interface\\EncounterJournal\\UI-EncounterJournalTextures")
           b1.normal:SetTexCoord(0.00195313, 0.34179688, 0.42871094, 0.52246094)
           b1.normal:SetAllPoints()
           b1:SetNormalTexture(b1.normal)

           b1.highlight = b1:CreateTexture(nil, "BACKGROUND")
           b1.highlight:SetTexture("Interface\\EncounterJournal\\UI-EncounterJournalTextures")
           -- b1.highlight:SetTexCoord(0.34570313, 0.68554688, 0.33300781, 0.42675781)
           b1.highlight:SetTexCoord(0.00195313, 0.34179688, 0.42871094, 0.52246094)
           b1.highlight:SetVertexColor(0.5, 0.5, 0.5, 1)
           b1.highlight:SetAllPoints()
           b1:SetHighlightTexture(b1.highlight)

           b1.pushed = b1:CreateTexture(nil, "BACKGROUND")
           b1.pushed:SetTexture("Interface\\EncounterJournal\\UI-EncounterJournalTextures")
           b1.pushed:SetTexCoord(0.00195313, 0.34179688, 0.33300781, 0.42675781)
           b1.pushed:SetAllPoints()
           b1:SetPushedTexture(b1.pushed)

                    b1.title = b1:CreateFontString(nil, "ARTWORK")
                    b1.title:SetPoint("CENTER", 0, 0)
                    b1.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
                    b1.title:SetTextColor(0.8, 0.8, 0, 1)
                    b1.title:SetShadowOffset(3, -3)
                    b1.title:SetText("Reset Data")

                    b1:SetScript("OnClick", function(self, button)
                         CT.resetData()
                    end)
               end

               do -- Button 2
           f.bottom.buttonFrame.button2 = CreateFrame("Button", nil, f.bottom.buttonFrame)
           local b2 = f.bottom.buttonFrame.button2
           b2:SetSize(174, f.bottom.buttonFrame:GetHeight() - 10)
           b2:SetPoint("RIGHT", -10, 0)
           b2.normal = b2:CreateTexture(nil, "BACKGROUND")
           b2.normal:SetTexture("Interface\\EncounterJournal\\UI-EncounterJournalTextures")
           b2.normal:SetTexCoord(0.00195313, 0.34179688, 0.42871094, 0.52246094)
           b2.normal:SetAllPoints()
           b2:SetNormalTexture(b2.normal)

           b2.highlight = b2:CreateTexture(nil, "BACKGROUND")
           b2.highlight:SetTexture("Interface\\EncounterJournal\\UI-EncounterJournalTextures")
           -- b2.highlight:SetTexCoord(0.34570313, 0.68554688, 0.33300781, 0.42675781)
           b2.highlight:SetTexCoord(0.00195313, 0.34179688, 0.42871094, 0.52246094)
           b2.highlight:SetVertexColor(0.5, 0.5, 0.5, 1)
           b2.highlight:SetAllPoints()
           b2:SetHighlightTexture(b2.highlight)

           b2.pushed = b2:CreateTexture(nil, "BACKGROUND")
           b2.pushed:SetTexture("Interface\\EncounterJournal\\UI-EncounterJournalTextures")
           b2.pushed:SetTexCoord(0.00195313, 0.34179688, 0.33300781, 0.42675781)
           b2.pushed:SetAllPoints()
           b2:SetPushedTexture(b2.pushed)

                    b2.title = b2:CreateFontString(nil, "ARTWORK")
                    b2.title:SetPoint("CENTER", 0, 0)
                    b2.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
                    b2.title:SetTextColor(0.8, 0.8, 0, 1)
                    b2.title:SetShadowOffset(3, -3)
                    b2.title:SetText("Load Saved Fights")

                    --[[Local Time Indexes
                    100m
                    GetTime = 3.2
                    debugprofilestop = 3.7
                    IsSpellOverlayed = 5.8
                    GetFramerate = 6.56, 6.57
                    self.value = 1.844

                    10m
                    GetSpellCooldown = 5.4
                    GetSpellCharges = 1.55
                    IsSpellOverlayed = 0.54
                    IsHelpfulSpell = 7.6
                    IsHarmfulSpell = 7.8
                    IsCurrentSpell = 4.0
                    GetFramerate = 0.66
                    SetText = 20.1, 6.9 -- What the text is seems to matter a lot
                    SetPoint = 2.83
                    GetText = 1.556

                    1m
                    GetSpellTexture = 5.5
                    GetSpellInfo = 4.0
                    IsUsableSpell = 17.3
                    IsCurrentSpell = 0.36
                    SetPoint = 0.288
                    GetText = 0.146
                    ]]

                    --[[About tables
                    creating a local table = 0.67
                    non local table = 0.74
                    self[i] = {} -- 1.43 and 124.91 MB (0.000125 per)
                    self[i] = {"value"} -- 2.25 and 23.53 MB extra (0.000023 per)
                    self[i] = {["value"] = true} -- 2.51 no extra memory
                    self[i] = {[i] = true} -- 2.475 no extra memory
                    self[i] = {[i] = "value"} -- 2.437 no extra memory
                    self[i] = {[1] = "value", [2] = "value", [3] = "value", [4] = "value", [5] = "value",} -- 10.8 and 382.92 MB extra (0.000383 per)

                    self[i] = {[1] = "value"}
                    self[i][2] = "value"
                    self[i][3] = "value"
                    self[i][4] = "value"
                    self[i][5] = "value" -- 7.1 and 187.6 MB extra (0.000187 per)

                    Basically, don't assign lots of values when the table is created, assign them afterwards like this:
                    self[i] = {}
                    self[i][1], self[i][2], self[i][3], self[i][4], self[i][5] = i, i, i, i, i
                    That way uses half as much memory per table entry
                    ]]

                    local func = b2.title.SetText
                    b2:SetScript("OnClick", function(self, button)
                         local start = debugprofilestop() / 1000
                         for i = 1, 1000000 do
                              -- self[i] = {}
                              -- self[i][1], self[i][2], self[i][3], self[i][4], self[i][5] = i, i, i, i, i
                         end
                         print(debugprofilestop() / 1000 - start)
                    end)
               end
    end
  end

  do -- Combat Tracker Title Text
    f.top.title = f.top:CreateFontString(nil, "ARTWORK")
    f.top.title:SetPoint("LEFT", f.top, 15, 0)
    f.top.title:SetFont("Fonts\\FRIZQT__.TTF", 30)
    f.top.title:SetTextColor(0.8, 0.8, 0, 1)
    f.top.title:SetShadowOffset(3, -3)
    f.top.title:SetText("Combat \n  Tracker")
  end
end

function CT:newButton(button, num)
  local self = {}
  setmetatable(self, CT)
  self.button = CreateFrame("Button", "MainButton" .. num, CT.contentFrame)
  self.name = button.name
  self.num = num
  self.update = button.func
  self.dropDownFunc = button.dropDownFunc
  self.lineTable = button.lines
  self.spellID = button.spellID
  self.iconTexture = button.icon or GetSpellTexture(self.name)
  self.graph = button.graph
  self.graphColor = button.graphColor
  self.uptimeGraph = button.uptimeGraph
  self.graphUpdateDelay = 0
  self.text = {}
  self.expanded = false

  CT.mainButtons[num] = self.button
  self.button.name = name
  self.button.num = num

  local button = self.button

  do -- Create Button
    button:SetPoint("TOPLEFT", 0, 0)
    button:SetPoint("TOPRIGHT", 0, 0)
    button:SetSize(150, 44)

    button.background = button:CreateTexture(nil, "BACKGROUND")
    button.background:SetPoint("TOPLEFT", button, 4.5, -4)
    button.background:SetPoint("BOTTOMRIGHT", button, -4, 3)
    button.background:SetTexture(0.07, 0.07, 0.07, 1.0)

    button.normal = button:CreateTexture(nil, "BACKGROUND")
    button.normal:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
    button.normal:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
    button.normal:SetAllPoints(button)
    button:SetNormalTexture(button.normal)

    button.highlight = button:CreateTexture(nil, "BACKGROUND")
    button.highlight:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
    button.highlight:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
    button.highlight:SetVertexColor(0.7, 0.7, 0.7, 1.0)
    button.highlight:SetAllPoints(button)
    button:SetHighlightTexture(button.highlight)

    button.disabled = button:CreateTexture(nil, "BACKGROUND")
    button.disabled:SetTexture("Interface\\PetBattles\\PetJournal")
    button.disabled:SetTexCoord(0.49804688, 0.90625000, 0.12792969, 0.17285156)
    button.disabled:SetAllPoints(button)
    button:SetDisabledTexture(button.disabled)

    button.pushed = button:CreateTexture(nil, "BACKGROUND")
    button.pushed:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
    button.pushed:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
    button.pushed:SetAllPoints(button)
    button:SetPushedTexture(button.pushed)

    do -- Create Icon
      button.icon = button:CreateTexture(nil, "OVERLAY")
      button.icon:SetSize(32, 32)
      button.icon:SetPoint("LEFT", 30, 0)
      
      if self.iconTexture then
        button.icon:SetTexture(self.iconTexture)
      else
        button.icon:SetTexture(CT.player.specIcon)
      end
      
      SetPortraitToTexture(button.icon, button.icon:GetTexture())
      button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      button.icon:SetAlpha(0.9)
    end

    button.expander = button:CreateTexture(nil, "BACKGROUND")
    button.expander:SetSize(button:GetWidth(), button:GetHeight())
    button.expander:SetPoint("TOPLEFT")
    button.expander:SetPoint("TOPRIGHT")
    button.expander.defaultHeight = button:GetHeight()
    button.expander.height = button.expander:GetHeight()
    button.expander.expanded = false

    button.dropDown = CreateFrame("Frame", nil, button)
    button.dropDown.texture = button.dropDown:CreateTexture(nil, "BACKGROUND")
    button.dropDown:SetSize(button:GetWidth(), 70)
    button.dropDown:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 5, 2)
    button.dropDown:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", -5, 2)
    button.dropDown.texture:SetTexture(0.07, 0.07, 0.07, 1.0)
    button.dropDown.texture:SetAllPoints()
    button.dropDown.lineHeight = 13
    button.dropDown.numLines = 0
    button.dropDown:Hide()
  end

  do -- Create Extras (up/down arrow, dragger)
    do -- Up Arrow
      button.upArrow = CreateFrame("Button", nil, button)
      button.upArrow:SetSize(16, 16)
      button.upArrow:SetPoint("TOPLEFT", 10, 0)
      button.upArrow:SetNormalTexture("Interface/BUTTONS/Arrow-Up-Up.png")
      button.upArrow:SetPushedTexture("Interface/BUTTONS/Arrow-Up-Down.png")
      button.upArrow:SetAlpha(0)

      button.upArrow:SetScript("OnClick", function(upArrow)
        self:arrowClick("up")
      end)

      button.upArrow:SetScript("OnEnter", function(upArrow)
        button.dragger:SetAlpha(1)
        button.upArrow:SetAlpha(1)
        button.downArrow:SetAlpha(1)
        button:LockHighlight()
        lastMouseoverButton = button
      end)

      button:SetScript("OnLeave", function(upArrow)
        button.dragger:SetAlpha(0)
        button.upArrow:SetAlpha(0)
        button.downArrow:SetAlpha(0)
        button:UnlockHighlight()
        lastMouseoverButton = button
      end)
    end

    do -- Down Arrow
      button.downArrow = CreateFrame("Button", nil, button)
      button.downArrow:SetSize(16, 16)
      button.downArrow:SetPoint("BOTTOMLEFT", 10, 0)
      button.downArrow:SetNormalTexture("Interface/BUTTONS/Arrow-Down-Up.png")
      button.downArrow:SetPushedTexture("Interface/BUTTONS/Arrow-Down-Down.png")
      button.downArrow:SetAlpha(0)

      button.downArrow:SetScript("OnClick", function(downArrow)
        self:arrowClick("down")
      end)

      button.downArrow:SetScript("OnEnter", function(downArrow)
        button.dragger:SetAlpha(1)
        button.upArrow:SetAlpha(1)
        button.downArrow:SetAlpha(1)
        button:LockHighlight()
        lastMouseoverButton = button
      end)

      button.downArrow:SetScript("OnLeave", function(downArrow)
        button.dragger:SetAlpha(0)
        button.upArrow:SetAlpha(0)
        button.downArrow:SetAlpha(0)
        button:UnlockHighlight()
        lastMouseoverButton = button
      end)
    end

    do -- Dragger Button
      button.dragger = CreateFrame("Button", nil, button)
      button.dragger:SetSize(20, 20)
      button.dragger:SetPoint("BOTTOMRIGHT", -3, 2)
      button.dragger:SetNormalTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Up.png")
      button.dragger:SetPushedTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Down.png")
      button.dragger:SetHighlightTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Highlight.png")
      button.dragger:SetAlpha(0)
      -- button.dragger:SetVertexColor(0.1, 0.1, 0.1, 0.9)

      button.dragger:SetScript("OnMouseDown", function(dragger)
        self:dragMainButton()
      end)

      button.dragger:SetScript("OnEnter", function(dragger)
        button.dragger:SetAlpha(1)
        button.upArrow:SetAlpha(1)
        button.downArrow:SetAlpha(1)
        button:LockHighlight()
        lastMouseoverButton = button
      end)

      button.dragger:SetScript("OnLeave", function(dragger)
        button.dragger:SetAlpha(0)
        button.upArrow:SetAlpha(0)
        button.downArrow:SetAlpha(0)
        button:UnlockHighlight()
        lastMouseoverButton = button
      end)
    end
  end

  do -- Main Text
    self.title = button:CreateFontString("title", "ARTWORK")
    self.title:SetPoint("LEFT", button.icon, "RIGHT", 10, 0)
    self.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
    self.title:SetTextColor(1, 1, 0, 1)
    self.title:SetText(self.name)

    self.value = button:CreateFontString("value", "ARTWORK")
    self.value:SetPoint("RIGHT", button, -25, 0)
    self.value:SetFont("Fonts\\FRIZQT__.TTF", 23)
    self.value:SetTextColor(1, 1, 0, 1)
    self.value:SetText(random(70, 100) .. "%")
  end

  do -- Button Scripts
    button:SetScript("OnClick", function(button)
         PlaySound("igMainMenuOptionCheckBoxOn")
         self:expanderToggle()
    end)
    button:SetScript("OnEnter", function(button)
         button.dragger:SetAlpha(1)
         button.upArrow:SetAlpha(1)
         button.downArrow:SetAlpha(1)
         lastMouseoverButton = button
    end)
    button:SetScript("OnLeave", function(button)
         button.dragger:SetAlpha(0)
         button.upArrow:SetAlpha(0)
         button.downArrow:SetAlpha(0)
         button:UnlockHighlight()
         lastMouseoverButton = button
    end)
  end

  tinsert(CT.update, self)

  if self.graph then
    if self.uptimeGraph then
      CT.registerGraphs[self.uptimeGraph] = self
    end
  end

  if not CT.topAnchor1 then CT.topAnchor1 = {self.button:GetPoint(1)} end
  if not CT.topAnchor2 then CT.topAnchor2 = {self.button:GetPoint(2)} end

  return self
end

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

function CT.scrollFrameUpdate()
  local button
  local height = 0

  for i = 1, #CT.mainButtons do
    button = CT.mainButtons[i]
    if button.expander.expanded and button:IsShown() then
      height = height + button.expander.expandedHeight
    elseif not button.expander.expanded and button:IsShown() then
      height = height + button.expander.defaultHeight
    end
  end

  local totalHeight = CT.scrollFrame:GetHeight()
  if height <= totalHeight then
    CT.scrollBar:SetMinMaxValues(1, 1)
    return
  elseif button.expander.expanded then
    CT.scrollBar:SetMinMaxValues(1, (height - totalHeight) + (button.expander.expandedHeight - button.expander.defaultHeight) - 5)
    return
  elseif not button.expander.expanded then
    CT.scrollBar:SetMinMaxValues(1, (height - totalHeight) + button.expander.defaultHeight)
    return
  end
end

function CT.updateButtonList()
  wipe(temp)
  for i = 1, #CT.mainButtons do
    CT.mainButtons[i].coords = select(2, CT.mainButtons[i]:GetCenter())
    temp[i] = CT.mainButtons[i].coords
    temp[CT.mainButtons[i]] = CT.mainButtons[i].coords
  end

  sort(temp, function(a,b) return a>b end)

  for k,v in pairs(temp) do
    if type(k) == "table" then
      for i = 1, #CT.mainButtons do
        if CT.mainButtons[i].coords == temp[k] then
          CT.mainButtons[i] = k
          CT.mainButtons[i].num = i
          temp[k] = nil
        end
      end
    end
  end
end

function CT.updateButtonOrderByNum()
  sort(CT.mainButtons, function(a,b) return a.num<b.num end)
end

function CT.slideButtonAnimation(button, direction)
  if button and direction then
    if not button.AGSlide then
      button.AGSlide = button:CreateAnimationGroup("SlideButtons")
      button.AGSlide[1] = button.AGSlide:CreateAnimation("Translation")
      button.AGSlide[1]:SetDuration(0.0001)
      button.AGSlide[1]:SetOrder(1)
      button.AGSlide[2] = button.AGSlide:CreateAnimation("Translation")
      button.AGSlide[2]:SetDuration(0.25)
      button.AGSlide[2]:SetSmoothing("OUT")
      button.AGSlide[2]:SetOrder(2)
    end
    if direction == "up" then
      button.AGSlide[1]:SetOffset(0, -button:GetHeight())
      button.AGSlide[2]:SetOffset(0, button:GetHeight())
    elseif direction == "down" then
      button.AGSlide[1]:SetOffset(0, button:GetHeight())
      button.AGSlide[2]:SetOffset(0, -button:GetHeight())
    end
    button.AGSlide:Play()
  end
end

function CT.setButtonAnchors()
  -- CT:Print("SETTING ANCHORS")
  for i = 1, #CT.mainButtons do
    local button = CT.mainButtons[i]
    if i == 1 then
      button:ClearAllPoints()
      button:SetPoint("TOPLEFT")
      button:SetPoint("TOPRIGHT")
    else
      local prevButtonExpander = CT.mainButtons[i - 1].expander
      button:ClearAllPoints()
      button:SetPoint("TOPRIGHT", prevButtonExpander, "BOTTOMRIGHT", 0, -CT.settings.buttonSpacing)
      button:SetPoint("TOPLEFT", prevButtonExpander, "BOTTOMLEFT", 0, -CT.settings.buttonSpacing)
    end
    local _, coords = button.expander:GetCenter()
    button.coords = coords
  end
end

function CT:setButtonAnchorsDragging()
  -- NOTE: This stops all the buttons from anchoring to eachother, cause it was screwing up the drag animation
  local height = 0
  local frameLeft = CT.contentFrame:GetLeft()
  local frameTop = CT.contentFrame:GetTop() + CT.settings.buttonSpacing
  local a1point1, a1point2, a1point3, a1point4, a1point5 = unpack(CT.topAnchor1)
  local a2point1, a2point2, a2point3, a2point4, a2point5 = unpack(CT.topAnchor2)

  for i = 1, #CT.mainButtons do
    local button = CT.mainButtons[i]
    button:SetSize(button:GetSize())
    if i == 1 and not button.dragging then
      frameTop = frameTop - (button:GetHeight() + CT.settings.buttonSpacing)
      button:ClearAllPoints()
      button:SetPoint("BOTTOMLEFT", UIParent, frameLeft, frameTop)
    elseif button.dragging then
      if CT.mainButtons[i - 1] and CT.mainButtons[i - 1].expander.expanded then
        frameTop = frameTop - (CT.mainButtons[i - 1].expander.expandedHeight + CT.settings.buttonSpacing)
      else
        frameTop = frameTop - (button:GetHeight() + CT.settings.buttonSpacing)
      end
    elseif i > 1 and not button.dragging then
      if CT.mainButtons[i - 1].expander.expanded then
        frameTop = frameTop - (CT.mainButtons[i - 1].expander.expandedHeight + CT.settings.buttonSpacing)
      else
        frameTop = frameTop - (CT.mainButtons[i - 1]:GetHeight() + CT.settings.buttonSpacing)
      end
      button:ClearAllPoints()
      button:SetPoint("BOTTOMLEFT", UIParent, frameLeft, frameTop)
    end
    local _, coords = button:GetCenter()
    button.coords = coords
  end
end

function CT.cycleMainButtons() -- NOTE: If order is changed, this gets all messed up. Also it revers to the old order.
  local numBeforeUpdate = CT.totalNumButtons
  -- loadMainButtons("specUpdate")
  for i = 1, #CT.mainButtons do
    local button = CT.mainButtons[i]
    if not button.AGFadeIn then
      button.AGFadeIn = button:CreateAnimationGroup("Fade In")
      local animation = button.AGFadeIn:CreateAnimation("Alpha")
      animation:SetDuration(0.5)
      animation:SetChange(1)
      animation:SetSmoothing("IN")
      button.AGFadeIn:SetScript("OnFinished", function(self, requested)
        button:SetAlpha(1)
      end)
    end
    if not button.AGFadeOut then
      button.AGFadeOut = button:CreateAnimationGroup("Fade Out")
      local animation = button.AGFadeOut:CreateAnimation("Alpha")
      animation:SetDuration(0.5)
      animation:SetChange(-1)
      animation:SetStartDelay(i * 0.1)
      animation:SetSmoothing("OUT")
      button.AGFadeOut:SetScript("OnFinished", function(self, requested)
        button:SetAlpha(0)
        -- CT.updateText(button) -- removed this function, shouldn't be worth it overall. If needed, call SetText() here manually.
        CT.updateSpellIcons(button)
        button.AGFadeIn:Play()
        if button.num > CT.totalNumButtons then
          button:Hide()
        end
      end)
    end
    if button.num > numBeforeUpdate then
      button:SetAlpha(0)
    end
    button.AGFadeOut:Play()
  end
end

function CT:dragMainButton()
  local button = self.button
  local topDistance, bottomDistance = 0, 0
  local frameLeft = CT.contentFrame:GetLeft()
  local buttonHeight = button:GetHeight() / 2
  local buttonLevel = button:GetFrameLevel()
  button:SetSize(button:GetSize())
  button:SetFrameLevel(buttonLevel + 3)
  button.dragging = true
  local UIScale = UIParent:GetEffectiveScale()
  
  if CT.mainButtons[button.num + 1] then
    CT.mainButtons[button.num + 1]:ClearAllPoints()
  end
  
  if CT.onUpdate then
    CT.onUpdate.button = button
    CT.onUpdate:Show()
  else
    CT.onUpdate = CreateFrame("Frame")
    CT.onUpdate.button = button
    CT.onUpdate:SetScript("OnUpdate", function(self, elapsed)
      if IsMouseButtonDown() then
        local mouseX, mouseY = GetCursorPosition()
        local mouseY = (mouseY / UIScale) - 10
        self.button:ClearAllPoints()
        self.button:SetPoint("BOTTOMLEFT", UIParent, CT.contentFrame:GetLeft(), mouseY)
        local _, dragCenter = self.button.expander:GetCenter()
        self.buttonUp = nil
        self.buttonDown = nil

        if CT.mainButtons[self.button.num - 1] then
          self.buttonUp = CT.mainButtons[self.button.num - 1]
          topDistance = CT.mainButtons[self.button.num - 1].coords - dragCenter
        end
        if CT.mainButtons[self.button.num + 1] then
          self.buttonDown = CT.mainButtons[self.button.num + 1]
          bottomDistance = dragCenter - CT.mainButtons[self.button.num + 1].coords
        end

        if topDistance <= buttonHeight and self.buttonUp then
          local tempNum = self.button.num
          self.button.num = self.buttonUp.num
          self.buttonUp.num = tempNum
          CT.updateButtonOrderByNum()
          CT:setButtonAnchorsDragging()
          CT.slideButtonAnimation(self.buttonUp, "down")
        end
        if bottomDistance < buttonHeight and self.buttonDown then
          local tempNum = self.button.num
          self.button.num = self.buttonDown.num
          self.buttonDown.num = tempNum
          CT.updateButtonOrderByNum()
          CT:setButtonAnchorsDragging()
          CT.slideButtonAnimation(self.buttonDown, "up")
        end
      else
        self:Hide()
        self.button:SetFrameLevel(buttonLevel)
        self.button.dragging = false
        self.button = nil
        CT:setButtonAnchors()
        for i = 1, #CT.mainButtons do
          CT.mainButtons[i]:Enable()
        end
      end
    end)
  end
end
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
    -- lineSide.background:SetTexture("Interface\\addons\\CombatTracker\\ButtonTest4.tga")

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

  if self.graph then
    self.graphFrame = self:buildResourceGraph(100, 100)
    dropDown.dropHeight = (dropDown.dropHeight or 0) + 100 + 6
    self.graphText = {}
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

  if self.uptimeGraph then
    self:buildUptimeGraph()
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

  if self.uptimeGraph then
    self:buildUptimeGraph()
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
    --  self:buildPieChart(200)
    -- dropDown.dropHeight = (dropDown.dropHeight or 0) + 200 + 6
  end
end
--------------------------------------------------------------------------------
-- DropDown Menu Functions
--------------------------------------------------------------------------------
function CT:expanderToggle()
  local button = self.button
  local dropDown = self.button.dropDown
  local expander = self.button.expander

  if self.expanded == false and (dropDown.dropHeight or 1) > 0 then -- Expand drop down

		if not self.dropDownCreated then
			self:dropDownFunc(self.lineTable)
			self.dropDownCreated = true
		end

		if dropDown.numLines ~= 0 then
			expander.expanded = true
			self.expanded = true

			dropDown:Show()
			
			self:update(GetTime())

			-- if self.graph and #self.graphData > 10 then
			-- 	self.graph:Hide()
			-- 	self.graph = false
			-- 	CT:Print("Sorry, graph is too big to display! Loading graphs with this many points can cause a lot of lag.\nI'm working on a better solution, but in the mean time, this is the best I have.")
			-- end

			if self.graph then
				if self.graph.graphType ~= "pie" then
					self.graph:RefreshGraph()
				end

				if self.graph.graphType == "uptime" then
					self:hideUptimeLines()
				end
			end
			
			self:dropAnimationDown()
		end
  elseif self.expanded == true then -- Collapse drop down
    expander.expanded = false
    self.expanded = false
		
    self:dropAnimationUp()
  end

  expander.defaultHeight = self.button:GetHeight()
  expander.expandedHeight = expander.defaultHeight + dropDown.dropHeight
  CT.updateButtonList()
  CT.scrollFrameUpdate()
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
      self.graphFrame:Show()
    end
  end)

  for k,v in pairs(dropDown.line) do
    v:Hide()
  end

  if self.graph then
    self.graphFrame:Hide()
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
    self.graphFrame:Hide()
  end

  dropDown.animationUp:Play()
end
--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------
function CT:arrowClick(direction)
  local button = self.button
  if direction == "up" and CT.mainButtons[button.num - 1] then
    local upperButton = CT.mainButtons[button.num - 1]
    upperButton.num = button.num
    button.num = button.num - 1
    self.num = button.num
    CT.updateButtonOrderByNum()
    CT.setButtonAnchors()
    CT.slideButtonAnimation(upperButton, "down")
    CT.slideButtonAnimation(button, "up")
  elseif direction == "down" and CT.mainButtons[button.num + 1] then
    local lowerButton = CT.mainButtons[button.num + 1]
    lowerButton.num = button.num
    button.num = button.num + 1
    self.num = button.num
    CT.updateButtonOrderByNum()
    CT.setButtonAnchors()
    CT.slideButtonAnimation(lowerButton, "up")
    CT.slideButtonAnimation(button, "down")
  end
end

function CT:OnDatabaseShutdown()
  CT:saveFunction()
end

function CT:saveFunction(key, value)
  -- self.db.char[key] = value
  -- C_Timer.After(0.001, function()
  --   CT.updateButtonList()
  --   if not self.db.char[CT.player.spec] then
  --     CT:Print("Spec DB NOT found")
  --     self.db.char[CT.player.spec] = {}
  --     self.db.char[CT.player.spec].mainButtons = CT.mainButtons
  --   else
  --     CT:Print("Spec DB found")
  --     self.db.char[CT.player.spec].mainButtons = CT.mainButtons
  --   end
  -- end)
end

function CT.formatTimer(currentTimer)
  if currentTimer then
    local mins = floor(currentTimer / 60)
    local secs = currentTimer - (mins * 60)
    currentTimer = format("%d:%02d", mins, secs)
    return currentTimer
  end
end

local infinity = math.huge
function CT.round(num, decimals)
  if (num == infinity) or (num == -infinity) then num = 0 end
  return (("%%.%df"):format(decimals)):format(num) + 0
end

function CT.hasteCD(spellID, unit)
  if not unit then unit = "player" end
  return (GetSpellBaseCooldown(spellID) / 1000) / (1 + (UnitSpellHaste(unit) / 100))
end

local colors = {}
do
  colors.white = {1.0, 1.0, 1.0, 1.0}
  colors.red = {0.95, 0.04, 0.10, 1.0}
  colors.orange = {0.82, 0.35, 0.09, 1.0}
  colors.blue = {0.08, 0.38, 0.91, 1.0}
  colors.lightblue = {0.53, 0.67, 0.92, 1.0}
  colors.yellow = {0.93, 0.86, 0.01, 1.0}
  colors.darkgreen = {0.13, 0.27, 0.07, 1}
  colors.green = {0.31, 0.42, 0.20, 1}
  colors.lightgreen = {0.26, 0.46, 0.19, 1}
  colors.darkgrey = {0.20, 0.23, 0.23, 1.0}
  colors.lightgrey = {0.49, 0.49, 0.49, 1}
end


function CT.colorText(fontString, text, colorString)
	if fontString then
		if (not colorString and text and colors[text]) then
			colorString = text
			text = fontString:GetText()
		elseif not colorString then
			if type(text) == "number" then
			  colorString = colors.yellow
			else
				colorString = colors.white
			end
		end

    if not text then
      text = fontString:GetText()
    end

    if colorString == "percent" then
			if text > 97 and text <= 100 then
				fontString:SetTextColor(0.93, 0.86, 0.01, 1.0) -- Yellow
			elseif text > 90 and text <= 97 then
				fontString:SetTextColor(0.26, 0.46, 0.19, 1) -- Light Green
			elseif text > 80 and text <= 90 then
				fontString:SetTextColor(0.31, 0.42, 0.20, 1) -- Green
			elseif text > 70 and text <= 80 then
				fontString:SetTextColor(0.13, 0.27, 0.07, 1) -- Dark Green
			elseif text > 60 and text <= 70 then
				fontString:SetTextColor(0.82, 0.35, 0.09, 1.0) -- Orange
			elseif text > 50 and text <= 60 then
				fontString:SetTextColor(0.95, 0.04, 0.10, 1.0) -- Red
			elseif text >= 0 and text <= 50 then
				fontString:SetTextColor(0.95, 0.04, 0.10, 1.0) -- Red
			else
				fontString:SetTextColor(0.93, 0.86, 0.01, 1.0) -- Yellow
			end

			return
    else
			fontString:SetTextColor(unpack(colors[colorString]))
			return
    end
	end
end

function CT.getPlayerDetails()
  local class, CLASS, classID = UnitClass("player")
  local tierLevels = CLASS_TALENT_LEVELS[class] or CLASS_TALENT_LEVELS.DEFAULT
  CT.player.class = class
	CT.player.CLASS = CLASS

  local specNum = GetSpecialization()
  local activeSpec = GetActiveSpecGroup()
  local specID, specName, description, specIcon, background, role, primaryStat = GetSpecializationInfo(specNum)
  CT.player.spec = specName
  CT.player.specIcon = specIcon
  CT.player.role = role
  CT.player.primaryStat = primaryStat

  for i = 1, #tierLevels do
    for v = 1, 3 do
      local talentID, name, texture, selected, available = GetTalentInfo(i, v, activeSpec)
      if selected then
        CT.player.talents[i] = name
      end
    end
  end

  if CT.specData then wipe(CT.specData) end
  local func = CT.updateFunctions
  do
    if CLASS == "DEATHKNIGHT" then
      if specName == "Blood" then

      elseif specName == "Unholy" then

      elseif specName == "Frost" then

      end
    elseif CLASS == "DRUID" then
      if specName == "Feral" then

      elseif specName == "Balance" then

      elseif specName == "Restoration" then

      elseif specName == "Guardian" then

      end
    elseif CLASS == "HUNTER" then
      if specName == "Survival" then

      elseif specName == "Marksmanship" then

      elseif specName == "Beast Master" then

      end
    elseif CLASS == "MAGE" then
      if specName == "Frost" then

      elseif specName == "Arcane" then

      elseif specName == "Fire" then

      end
    elseif CLASS == "MONK" then
      if specName == "Windwalker" then

      elseif specName == "Mistweaver" then

      elseif specName == "Brewmaster" then

      end
    elseif CLASS == "PALADIN" then
      if specName == "Retribution" then
        CT.specData = {
          ["Activity"] = CT.TrackActivity,
          [CT.player.talents[6]] = CT.TimeLongCD,
          ["Crusader Strike"] = CT.TimeShortCD,
          ["Holy Power"] = CT.TrackResources,
          ["Divine Protection"] = CT.TimeLongCD,
          ["Exorcism"] = CT.TimeShortCD,
          ["Judgment"] = CT.TimeShortCD,
        }
        return
      elseif specName == "Holy" then
        CT.specData = {
          { ["name"] = "Activity",
            ["func"] = func.activity,
                              ["dropDownFunc"] = CT.type2,
            ["lines"] = {
              "Fight Length:",
              "Active Time:",
              "Inactive Time:",
            },
            ["icon"] = "Interface/ICONS/Ability_DualWield.png",
            -- ["graph"] = false,
            -- ["graphColor"] = colors.white,
          },

          { ["name"] = "Holy Power",
            ["func"] = func.resource2,
            ["dropDownFunc"] = CT.type1,
            ["lines"] = {
              "Total Gain:",
              "Total Loss:",
            },
            ["icon"] = "Interface/ICONS/Spell_Holy_DivineProvidence.png",
            ["graph"] = true,
            ["graphColor"] = colors.yellow,
          },

					{ ["name"] = "Mana",
            ["func"] = func.mana,
						["dropDownFunc"] = CT.type1,
            ["lines"] = {
              "Total Gain:",
              "Total Loss:",
            },
            ["graph"] = true,
            ["graphColor"] = colors.blue,
          },

          { ["name"] = "All Casts",
            ["spellID"] = 20473,
            ["func"] = func.allCasts,
            ["dropDownFunc"] = CT.type4,
            ["lines"] = {
              "Total Casts",
            },
          },

          { ["name"] = "Holy Shock",
            ["spellID"] = 20473,
            ["func"] = func.shortCD,
            ["dropDownFunc"] = CT.type2,
            ["lines"] = {
              "Fight Length",
              "Time off CD",
              "Average Delay",
              "Reset Casts",
            },
            ["graph"] = true,
            ["uptimeGraph"] = 20473,
            ["graphColor"] = colors.yellow,
          },

          { ["name"] = CT.player.talents[6],
            ["spellID"] = 114165,
            ["func"] = func.longCD,
            ["dropDownFunc"] = CT.type3,
            ["lines"] = {
							"Total Delay:",
							"Average Delay:",
							"%d. Cast Delay:",
            },
            ["graph"] = true,
            ["uptimeGraph"] = 114165,
            ["graphColor"] = colors.yellow,
          },

          { ["name"] = CT.player.talents[7],
            ["func"] = func.activity,
            ["dropDownFunc"] = CT.type2,
            ["lines"] = {
              "Activity line: 1",
              "Activity line: 2",
            },
          },

          { ["name"] = "Divine Protection",
            ["spellID"] = 498,
            ["func"] = func.longCD,
            ["dropDownFunc"] = CT.type3,
            ["lines"] = {
							"Total Delay:",
							"Average Delay:",
							"%d. Cast Delay:",
            },
            ["graph"] = true,
            ["uptimeGraph"] = 498,
          },

          { ["name"] = "Illuminated Healing",
            ["func"] = func.activity,
            ["dropDownFunc"] = CT.type2,
            ["lines"] = {
              "Activity line: 1",
              "Activity line: 2",
            },
          },

          { ["name"] = CT.player.talents[2],
            ["func"] = func.activity,
            ["dropDownFunc"] = CT.type2,
            ["lines"] = {
              "Activity line: 1",
              "Activity line: 2",
            },
          },

          { ["name"] = "Hand of Freedom",
            ["func"] = func.longCD,
            ["dropDownFunc"] = CT.type2,
            ["lines"] = {
              "Activity line: 1",
              "Activity line: 2",
            },
          },

          { ["name"] = "Lay on Hands",
            ["func"] = func.activity,
            ["dropDownFunc"] = CT.type2,
            ["lines"] = {
              "Activity line: 1",
              "Activity line: 2",
            },
          },

          { ["name"] = "Divine Shield",
            ["func"] = func.longCD,
            ["dropDownFunc"] = CT.type2,
            ["lines"] = {
              "Activity line: 1",
              "Activity line: 2",
            },
          },

          { ["name"] = "Cleanse",
            ["func"] = func.dispel,
            ["dropDownFunc"] = CT.type2,
            ["lines"] = {
              "Activity line: 1",
              "Activity line: 2",
            },
          },

        }
        
        -- { ["name"] = "Spell Costs",
        --   ["func"] = func.activity,
        --   ["dropDownFunc"] = CT.type2,
        --   ["lines"] = {
        --     "Activity line: 1",
        --     "Activity line: 2",
        --   },
        -- },
        
        return
      elseif specName == "Protection" then

      end
    elseif CLASS == "PRIEST" then
      if specName == "Discipline" then

      elseif specName == "Holy" then

      elseif specName == "Shadow" then

      end
    elseif CLASS == "ROGUE" then
      if specName == "Subtlety" then

      elseif specName == "Assassination" then

      elseif specName == "Combat" then

      end
    elseif CLASS == "SHAMAN" then
      if specName == "Enhancement" then

      elseif specName == "Elemental" then

      elseif specName == "Restoration" then

      end
    elseif CLASS == "WARLOCK" then
      if specName == "Demonology" then

      elseif specName == "Affliction" then

      elseif specName == "Destruction" then

      end
    elseif CLASS == "WARRIOR" then
      if specName == "Arms" then

      elseif specName == "Fury" then

      elseif specName == "Protection" then

      end
    end
  end
end

function CT.showLastFight()
  if not CT.base.lastFight then
    CT.base.lastFight = CreateFrame("Frame", nil, CT.base)
    local f = CT.base.lastFight
    f:SetSize(180, 64)
    f:SetPoint("BOTTOMRIGHT", CT.base.top, -12, -5)
    f.bossTexture = f:CreateTexture("BossTexture", "ARTWORK")
    f.bossTexture:SetPoint("LEFT", 0, 0)
    f.bossTexture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-Gruul.blp")

    CT.comparisonButton = CreateFrame("Button", nil, f)
    local b = CT.comparisonButton
    b:SetSize(80, 30)
    b:SetPoint("BOTTOMRIGHT", 0, 4)

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

    b.disabled = b:CreateTexture(nil, "BACKGROUND")
    b.disabled:SetTexture("Interface\\PetBattles\\PetJournal")
    b.disabled:SetTexCoord(0.49804688, 0.90625000, 0.12792969, 0.17285156)
    b.disabled:SetAllPoints(b)
    b:SetDisabledTexture(b.disabled)

    b.pushed = b:CreateTexture(nil, "BACKGROUND")
    b.pushed:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
    b.pushed:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
    b.pushed:SetAllPoints(b)
    b:SetPushedTexture(b.pushed)

    b.title = b:CreateFontString(nil, "ARTWORK")
    b.title:SetPoint("CENTER", 0, 0)
    b.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
    b.title:SetTextColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], 1)
    b.title:SetText("Compare")
  else
    CT.lastFight:Show()
  end
end

function CT.comparisonPopout(numRows)
  if not CT.popout then CT.popout = {} end
  if not CT.popout.baseStartWidth then CT.popout.baseStartWidth = CombatTrackerBase:GetWidth() end

  if CT.mainButtons[1] then
    local width = CT.mainButtons[1]:GetWidth()
    local height = CT.mainButtons[1]:GetHeight()
    if CT.popout.shown == true then
      for line = 1, CT.popout.numLines do
        for i = 1, #CT.popout[line] do
          CT.popout[line][i]:Hide()
        end
      end
      CombatTrackerBase:SetWidth(CT.popout.baseStartWidth)
      CT.popout.shown = false
    else
      for line = 1, numRows do
        CT.popout.numLines = line
        if not CT.popout[line] then CT.popout[line] = {} end
        for i = 1, #CT.mainButtons do
          CT.popout[line][i] = CreateFrame("Button", line .. "Popout" .. i, CT.mainButtons[i], "CTcomparisonPopoutTemplate")
          local button = CT.popout[line][i]
          button:SetSize(width, height)
          button.value:SetText(random(70, 100) .. "%")
          button:SetFrameLevel(2)
          if line == 1 then
            button:SetPoint("TOPLEFT", CT.mainButtons[i], "TOPRIGHT", -width * 0.75, 0)
            button:SetPoint("BOTTOMLEFT", CT.mainButtons[i], "BOTTOMRIGHT", -width * 0.75, 0)
          else
            button:SetPoint("TOPLEFT", CT.popout[line - 1][i], "TOPRIGHT", -width * 0.75, 0)
            button:SetPoint("BOTTOMLEFT", CT.popout[line - 1][i], "BOTTOMRIGHT", -width * 0.75, 0)
          end
        end
        CombatTrackerBase:SetWidth(CombatTrackerBase:GetWidth() + width * 0.25)
        CT.popout.shown = true
      end
    end
  end
end




-- function CT:updateSpellIcons()
--   if self.name and self.button.icon then
--     local name = self.name
--     local icon = self.button.icon
--     local spellTexture = GetSpellTexture(name)
--     if spellTexture ~= nil then
--       icon:SetTexture(spellTexture)
--     elseif name == "Activity" then
--       icon:SetTexture("Interface/ICONS/Ability_DualWield.png")
--     elseif name == "Healing Potion" then
--       icon:SetTexture("Interface/ICONS/INV_Potion_131.png")
--     elseif name == "DPS Potion" then
--       icon:SetTexture("Interface/ICONS/INV_Potion_132.png")
--     elseif name == "Healing Potion" then
--       icon:SetTexture("BlizzArt/Interface/ICONS/INV_Potion_131.png")
--     elseif name == "Holy Power" then
--       icon:SetTexture("Interface/ICONS/Spell_Holy_DivineProvidence.png")
--     elseif name == "Wasted Holy Power" then
--       icon:SetTexture("Interface/ICONS/Spell_Holy_DivineProvidence.png")
--     else
--       icon:SetTexture(CT.player.icon)
--     end
--     self.iconTexture = icon:GetTexture()
--     SetPortraitToTexture(icon, icon:GetTexture())
--     icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
--     icon:SetAlpha(0.9)
--   else
--     print("Icon failed!")
--   end
-- end

-- CombatTrackerBase_Popout:SetWidth(((CT.Fights[#CT.Fights]:GetWidth() + 5) * CT.Values.NumSavedFights) + 15) -- Calculates width for popout page
-- CombatTrackerBase_Popout_Page1_Scroll:SetWidth(CombatTrackerBase_Popout:GetWidth())

--[[     Handy list of all events that should be handled here. Try to keep it updated

--"RANGE_DAMAGE", -- normal
--"RANGE_MISSED", -- normal
--"SPELL_DAMAGE", -- normal
--"SPELL_DAMAGE_CRIT", -- normal BUT NOT ACTUALLY AN EVENT
--"SPELL_DAMAGE_NONCRIT", -- normal BUT NOT ACTUALLY AN EVENT
--"SPELL_MISSED", -- normal
--"SPELL_REFLECT", -- normal BUT NOT ACTUALLY AN EVENT
--"SPELL_EXTRA_ATTACKS", -- normal
--"SPELL_HEAL", -- normal
--"SPELL_ENERGIZE", -- normal
--"SPELL_DRAIN", -- normal
--"SPELL_LEECH", -- normal
--"SPELL_AURA_APPLIED", -- normal
--"SPELL_AURA_REFRESH", -- normal
--"SPELL_AURA_REMOVED", -- normal

-- "RANGE_DAMAGE_MULTISTRIKE", -- normal BUT NOT ACTUALLY AN EVENT
-- "SWING_DAMAGE_MULTISTRIKE", -- normal BUT NOT ACTUALLY AN EVENT
-- "SPELL_DAMAGE_MULTISTRIKE", -- normal BUT NOT ACTUALLY AN EVENT
-- "SPELL_PERIODIC_DAMAGE_MULTISTRIKE", -- normal BUT NOT ACTUALLY AN EVENT
-- "SPELL_HEAL_MULTISTRIKE", -- normal BUT NOT ACTUALLY AN EVENT
-- "SPELL_PERIODIC_HEAL_MULTISTRIKE", -- normal BUT NOT ACTUALLY AN EVENT

--"SPELL_PERIODIC_DAMAGE", -- normal
--"SPELL_PERIODIC_DRAIN", -- normal
--"SPELL_PERIODIC_ENERGIZE", -- normal
--"SPELL_PERIODIC_LEECH", -- normal
--"SPELL_PERIODIC_HEAL", -- normal
--"SPELL_PERIODIC_MISSED", -- normal
--"DAMAGE_SHIELD", -- normal
--"DAMAGE_SHIELD_MISSED", -- normal
--"DAMAGE_SPLIT", -- normal
--"SPELL_INSTAKILL", -- normal
--"SPELL_SUMMON" -- normal
--"SPELL_RESURRECT" -- normal
--"SPELL_CREATE" -- normal
--"SPELL_DURABILITY_DAMAGE" -- normal
--"SPELL_DURABILITY_DAMAGE_ALL" -- normal
--"SPELL_AURA_BROKEN" -- normal
--"SPELL_AURA_APPLIED_DOSE"                         --SEMI-NORMAL, CONSIDER SPECIAL IMPLEMENTATION
--"SPELL_AURA_REMOVED_DOSE"                         --SEMI-NORMAL, CONSIDER SPECIAL IMPLEMENTATION
--"SPELL_CAST_FAILED" -- normal
--"SPELL_CAST_START" -- normal
--"SPELL_CAST_SUCCESS" -- normal
]]

-- local PowerPatterns = {
--   [0]  = "^" .. gsub(MANA_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [1]  = "^" .. gsub(RAGE_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [2]  = "^" .. gsub(FOCUS_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [3]  = "^" .. gsub(ENERGY_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [4]  = "^" .. gsub(COMBO_POINTS, "%%d", "([.,%%d]+)", 1) .. "$",
--   [6]  = "^" .. gsub(RUNIC_POWER_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [7]  = "^" .. gsub(SOUL_SHARDS_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [9]  = "^" .. gsub(HOLY_POWER_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [12] = "^" .. gsub(CHI_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [13] = "^" .. gsub(SHADOW_ORBS_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [14] = "^" .. gsub(BURNING_EMBERS_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   [15] = "^" .. gsub(DEMONIC_FURY_COST, "%%d", "([.,%%d]+)", 1) .. "$",
--   -- [5] = "^" .. gsub(RUNE_COST_BLOOD, "%%d", "([.,%%d]+)", 1) .. "$",
--   -- [5] = "^" .. gsub(RUNE_COST_FROST, "%%d", "([.,%%d]+)", 1) .. "$",
--   -- [5] = "^" .. gsub(RUNE_COST_UNHOLY, "%%d", "([.,%%d]+)", 1) .. "$",
--   -- [5] = "^" .. gsub(RUNE_COST_CHROMATIC, "%%d", "([.,%%d]+)", 1) .. "$", -- death
-- }

-- TMW's upvalue list
-- local GetSpellCooldown, GetSpellInfo, GetSpellTexture, IsUsableSpell =
--        GetSpellCooldown, GetSpellInfo, GetSpellTexture, IsUsableSpell
-- local InCombatLockdown, GetTalentInfo, GetActiveSpecGroup =
--        InCombatLockdown, GetTalentInfo, GetActiveSpecGroup
-- local UnitPower, UnitClass, UnitName, UnitAura =
--        UnitPower, UnitClass, UnitName, UnitAura
-- local IsInGuild, IsInGroup, IsInInstance =
--        IsInGuild, IsInGroup, IsInInstance
-- local GetAddOnInfo, IsAddOnLoaded, LoadAddOn, EnableAddOn, GetBuildInfo =
--        GetAddOnInfo, IsAddOnLoaded, LoadAddOn, EnableAddOn, GetBuildInfo
-- local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, rawset, assert, pcall, error, getmetatable, setmetatable, loadstring, unpack, debugstack =
--        tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, rawset, assert, pcall, error, getmetatable, setmetatable, loadstring, unpack, debugstack
-- local strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, strjoin, max, ceil, floor, random =
--        strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, strjoin, max, ceil, floor, random
-- local _G, coroutine, table, GetTime, CopyTable =
--        _G, coroutine, table, GetTime, CopyTable
-- local tostringall = tostringall

-- function CT:sortDropText(sortBy, bool)
--   local dropDown = self.button.dropDown
--
--   if bool == true then
--     wipe(temp)
--     for k,v in pairs(self.text[sortBy]) do
--       temp[#temp + 1] = v
--       k.sorted = false
--     end
--
--     sort(temp, function(a,b) return a>b end)
--
--     for i = 1, #temp do
--       for k,v in pairs(self.text[sortBy]) do
--         if temp[i] == v and not k.sorted then
--           k.num = i
--           k.sorted = true
--           break
--         end
--       end
--     end
--
--     sort(dropDown.line, function(a, b) return a.num < b.num end)
--   else
--     sort(dropDown.line, function(a,b) return a.startNum < b.startNum end)
--   end
--
--   self:setDropTextAnchors()
-- end
