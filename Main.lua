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
  RE.TooltipBackdrop = {
      ["bgFile"] = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark";
      ["tileSize"] = 0;
      ["edgeFile"] = "Interface\\DialogFrame\\UI-DialogBox-Border";
      ["edgeSize"] = 16;
      ["insets"] = {
          ["top"] = 3.4999997615814;
          ["right"] = 3.4999997615814;
          ["left"] = 3.4999997615814;
          ["bottom"] = 3.4999997615814;
      };
  };
]]--
--------------------------------------------------------------------------------
-- Notes and Changes
--------------------------------------------------------------------------------

-- Should restore saved settings OnInitialize instead of OnEnable
-- For sorting, store the old order in a table, and bring it back on a second press.

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

--------------------------------------------------------------------------------
-- Locals, Frames, and Tables
--------------------------------------------------------------------------------
CombatTracker = LibStub("AceAddon-3.0"):NewAddon("CombatTracker", "AceConsole-3.0")
local CT = CombatTracker
local baseFrame = CreateFrame("Frame", "CT_Base", UIParent) -- Have to do this early so that the position will be saved
baseFrame:SetMovable(true)
CT.__index = CT
CT.settings = {}
CT.settings.buttonSpacing = 2
CT.settings.spellCooldownThrottle = 0.0085
CT.combatevents = {}
CT.player = {}
CT.altPower = {}
CT.player.talents = {}
CT.mainButtons = {}
CT.shown = true
CT.activeAuras = {}
CT.registerReset = {}
CT.buttons = {}
CT.plates = {}
CT.graphLines = {}
CT.uptimeGraphLines = {}
CT.uptimeGraphLines.Cooldown = {}
CT.uptimeGraphLines.Buff = {}
CT.uptimeGraphLines.Debuff = {}
CT.uptimeGraphLines.Misc = {}

CT.setButtons = {}

CT.loadSpellData = false
local temp = {}
local combatevents = CT.combatevents
local lastMouseoverButton
local buttonClickNum = 7
local testMode = false
local trackingOnLogIn = false
local loadBaseOnLogin = false

do -- Debugging stuff
  local match
  local start = debugprofilestop() / 1000
  local printFormat = "|cFF9E5A01(|r|cFF00CCFF%.3f|r|cFF9E5A01)|r |cFF00FF00%s|r: %s"
  local debugMode = false
  if GetUnitName("player") == "Elstari" or GetUnitName("player") == "Elendi" and GetRealmName() == "Drak'thul" then
    debugMode = true
    testMode = true
    trackingOnLogIn = true
    loadBaseOnLogin = true
    match = true
  end

  function CT.debug(...)
    if debugMode then
      local t = {...}
      print(printFormat:format((debugprofilestop() / 1000) - start, CombatTracker:GetName(), table.concat(t, " ")))
    end
  end

  if not match then
    CT.debug("If you aren't developing this addon and you see this message,",
      "that means I, being the genius that I am, released it with debug mode enabled.",
      "\n\nYou can easily fix it by opening the Main.lua document with any text editor,",
      "and finding the line |cFF00CCFFlocal debugMode = true|r and changing the |cFF00CCFFtrue|r to |cFF00CCFFfalse|r. Sorry!")
  end
end
local debug = CT.debug

CT.eventFrame = CreateFrame("Frame")
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

local anchorTable = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
local cornerAnchors = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}

CT.colors = {}
local colors = CT.colors
do
  colors.white = {1.0, 1.0, 1.0, 1.0}
  colors.red = {0.95, 0.04, 0.10, 1.0}
  colors.orange = {0.82, 0.35, 0.09, 1.0}
  colors.blue = {0, 0.0, 1.0, 1.0}
  colors.blueOLD = {0.08, 0.38, 0.91, 1.0}
  colors.lightblue = {0.53, 0.67, 0.92, 1.0}
  colors.yellow = {0.93, 0.86, 0.01, 1.0}
  colors.darkgreen = {0.13, 0.27, 0.07, 1}
  colors.green = {0.31, 0.42, 0.20, 1}
  colors.lightgreen = {0.26, 0.46, 0.19, 1}
  colors.darkgrey = {0.20, 0.23, 0.23, 1.0}
  colors.lightgrey = {0.49, 0.49, 0.49, 1}

  colors.deathKnight = {0.77, 0.12, 0.23, 1}
  colors.druid = {1.00, 0.49, 0.04, 1}
  colors.hunter = {0.67, 0.83, 0.45, 1}
  colors.mage = {0.41, 0.80, 0.94, 1}
  colors.monk = {0.33, 0.54, 0.52, 1}
  colors.paladin = {0.96, 0.55, 0.73, 1}
  colors.priest = {1.00, 1.00, 1.00, 1}
  colors.rogue = {1.00, 0.96, 0.41, 1}
  colors.shaman = {0.0, 0.44, 0.87, 1}
  colors.warlock = {0.58, 0.51, 0.79, 1}
  colors.warrior = {0.78, 0.61, 0.43, 1}

  colors.mana = {0.00, 0.00, 1.00, 1.00}
  colors.rage = {1.00, 0.00, 0.00, 1.00}
  colors.focus = {1.00, 0.50, 0.25, 1.00}
  colors.energy = {1.00, 1.00, 0.00, 1.00}
  colors.chi = {0.71, 1.00, 0.92, 1.00}
  colors.runes = {0.50, 0.50, 0.50, 1.00}
  colors.runicPower =	{0.00, 0.82, 1.00, 1.00}
  colors.soulShards = {0.50, 0.32, 0.55, 1.00}
  colors.eclipseNegative = {0.30, 0.52, 0.90, 1.00}
  colors.eclipsePositive = {0.80, 0.82, 0.60, 1.00}
  colors.holyPower = {0.95, 0.90, 0.60, 1.00}
  colors.demonicFury = {0.5, 0.32, 0.55, 1.00}
  colors.ammoSlot =	{0.80, 0.60, 0.00, 1.00}
  colors.fuel = {0.00, 0.55, 0.50, 1.00}
  colors.staggerLight = {0.52, 1.00, 0.52, 1.00}
  colors.staggerMedium = {1.00, 0.98, 0.72, 1.00}
  colors.staggerHeavy = {1.00, 0.42, 0.42, 1.00}

  -- Custom colors, couldn't find an official one
  colors.comboPoints = {0.5, 0.70, 0.70, 1.00}
  colors.shadowOrbs = {0.22, 0.16, 0.31, 1.00}
  colors.burningEmbers = {0.75, 0.42, 0.01, 1.00}
end
--------------------------------------------------------------------------------
-- Main Update Engine
--------------------------------------------------------------------------------
local plateIndex
local index = 2
local function updateHandler(self, elapsed) -- Dedicated handler to avoid creating the throwaway function every update
  local time = GetTime()

  local timer = 0
  if CT.currentDB then
    timer = (CT.currentDB.stop or time) - CT.currentDB.start
    CT.currentDB.fightLength = timer
  end

  CT.combatTimer = timer
  CT.lastTick = elapsed

  if CT.shown and CT.displayed then -- All updates to displayed data go in here
    local timer = (CT.displayedDB.stop or time) - CT.displayedDB.start

    if CT.forceUpdate or time >= (self.lastNormalUpdate or 0) then
      for i = 1, #CT.update do -- Update drop down menus or expanders
        local self = CT.update[i]

        if self.expanded and CT.base.expander.shown and self.expanderUpdate then
          self:expanderUpdate(time, timer)
        else
          self:update(time, timer)
        end
      end

      if CT.base and CT.base.expander then --  and (CT.base.expander.shown or CT.forceUpdate)
        CT.base.expander.titleData.rightText2:SetText(CT.formatTimer(timer))
      end

      do -- Handle refreshing of displayed graphs
        local uptimeGraphs = CT.displayed.uptimeGraphs

        for index, self in ipairs(CT.displayed.graphs) do
          if self.graphFrame and CT.base.expander.shown and not self.graphFrame.zoomed then
            self:refresh(self.needsRefresh)
          end
        end
      end

      self.lastNormalUpdate = time + CT.settings.updateDelay
    end
  end

  if CT.current then -- All data gathering updates go in here, except for nameplate registering
    if CT.current.casting then
      CT.current.currentCastDuration = (time - CT.current.currentCastStopTime) + CT.current.currentCastLength
    end

    if CT.current.GCD then
      CT.current.currentGCDDuration = (time - CT.current.GCDStopTime) + CT.current.GCD
    end

    if (time >= (self.lastAuraUpdate or 0) and CT.activeAuras[1]) or CT.forceUpdate then -- Running active auras
      for i = 1, #CT.activeAuras do
        local aura = CT.activeAuras[i]
        if not aura then break end

        if aura.start and aura.duration then
          aura.timer = timer - aura.start
          aura.remaining = aura.duration - (timer - aura.start)
        elseif not aura.start then
          tremove(CT.activeAuras, i)
        end
      end

      self.lastAuraUpdate = time + 0.05
    end

    do -- Handle graph updates
      local graphs = CT.current.graphs

      if (graphs.lastUpdate or 0) < time or CT.forceUpdate then -- Take line graph points every graphs.lastUpdate seconds
        for i = 1, #CT.graphList do
          local graph = graphs[CT.graphList[i]]

          if not graph.updating then graph:update(timer) end
        end

        graphs.lastUpdate = time + graphs.updateDelay
      end

      if CT.forceUpdate or time >= (self.lastUptimeGraphUpdate or 0) then -- Update uptime graphs
        self.uptimeGraphsUpdate(time, timer)

        self.lastUptimeGraphUpdate = time + 0.05
      end


      -- local uptimeGraphs = CT.current.uptimeGraphs
      -- local graphs = CT.current.graphs

      -- if (time >= graphs.lastUpdate) or CT.forceUpdate then -- Take line graph points every graphs.lastUpdate seconds
      --   self.graphUpdate(time, timer)
      --
      --   graphs.lastUpdate = time + graphs.updateDelay
      -- end

      -- if CT.forceUpdate or time >= (self.lastUptimeGraphUpdate or 0) then -- Update uptime graphs
      --   self.uptimeGraphsUpdate(time, timer)
      --
      --   self.lastUptimeGraphUpdate = time + 0.05
      -- end
    end
  end

  do -- Nameplate stuff
    if plateIndex then
      while _G["NamePlate" .. plateIndex] do
        local plate = _G["NamePlate" .. plateIndex]
        local container = plate.ArtContainer

        CT.plates[container] = {}

        plate:HookScript("OnShow", CT.plateShow)
        plate:HookScript("OnHide", CT.plateHide)

        CT.plates[container.HealthBar] = CT.plates[container]
        container.HealthBar:HookScript("OnValueChanged", CT.plateHealthUpdate)
        -- container.HealthBar:HookScript("OnMinMaxChanged", CT.plateHealthUpdate)

        -- CT.plates[container.CastBar] = CT.plates[container]
        -- container.CastBar:HookScript("OnShow", CT.plateCastBarStart)
        -- container.CastBar:HookScript("OnHide", CT.plateCastBarStop)
        -- container.CastBar:HookScript("OnValueChanged", CT.plateCastBar)

        CT.plateShow(plate)

        plateIndex = plateIndex + 1
      end
    else
      local numChildren = WorldFrame:GetNumChildren()

      if numChildren >= index then
        for i = index, numChildren do
          local child = select(i, WorldFrame:GetChildren())
          if child and child.ArtContainer and child.ArtContainer.HealthBar then -- If it has these, that should guarantee it's a nameplate
            plateIndex = child:GetName():match("^NamePlate(%d+)") + 0
            break
          else -- This one isn't a nameplate, so skip it next time for a tiny bit of efficiency
            index = i + 1
          end
        end
      end
    end
  end

  if CT.forceUpdate then CT.forceUpdate = false end
end

CT.update = {}
CT.settings.updateDelay = 0.1
CT.mainUpdate = CreateFrame("Frame")
CT.mainUpdate:SetScript("OnUpdate", updateHandler)
--------------------------------------------------------------------------------
-- Main Event Handler
--------------------------------------------------------------------------------
do -- Register events
  local eventFrame = CT.eventFrame

  local events = {
    "ADDON_LOADED",
    "COMBAT_LOG_EVENT_UNFILTERED",
    -- "COMBAT_RATING_UPDATE",
    "PLAYER_LOGIN",
    "PLAYER_LOGOUT",
    -- "PLAYER_CONTROL_GAINED",
    -- "PLAYER_CONTROL_LOST",
    "PLAYER_ALIVE",
    "PLAYER_DEAD",
    "PLAYER_TALENT_UPDATE",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "ENCOUNTER_START",
    "ENCOUNTER_END",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_FOCUS_CHANGED",
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
    -- "SPELL_UPDATE_COOLDOWN",
    -- "SPELL_UPDATE_USABLE",
    -- "SPELL_UPDATE_CHARGES",
    "PLAYER_SPECIALIZATION_CHANGED",
    -- "CURRENT_SPELL_CAST_CHANGED",
    "UNIT_HEALTH_FREQUENT",
    -- "UNIT_POWER_FREQUENT",
    "UNIT_ATTACK_POWER",
    "SPELL_POWER_CHANGED",
    "UNIT_RANGED_ATTACK_POWER",
    "UNIT_DISPLAYPOWER",
    "WEIGHTED_SPELL_UPDATED",
    "UNIT_DEFENSE",
    -- "UNIT_ABSORB_AMOUNT_CHANGED",
    "UPDATE_SHAPESHIFT_FORMS",
    "UPDATE_SHAPESHIFT_FORM",
    "UPDATE_MOUSEOVER_UNIT",
    "GROUP_ROSTER_UPDATE",
    "PLAYER_ENTERING_WORLD",
    "UNIT_AURA",
    "MODIFIER_STATE_CHANGED",
  }

  local unitEvents = {
    "UNIT_HEALTH_FREQUENT",
    "UNIT_MAXHEALTH",
    "UNIT_MAXPOWER",
    "UNIT_POWER_FREQUENT",
    "UNIT_POWER",
    "UNIT_MAXPOWER",
    "UNIT_ATTACK_POWER",
    "SPELL_POWER_CHANGED",
    "UNIT_RANGED_ATTACK_POWER",
    -- "UNIT_DISPLAYPOWER",
    -- "WEIGHTED_SPELL_UPDATED",
    "UNIT_PET",
    "UNIT_DEFENSE",
    "UNIT_ABSORB_AMOUNT_CHANGED",
    "UNIT_STATS",
    "UNIT_SPELL_HASTE",
    "UNIT_SPELL_CRITICAL",
    "PET_DISMISS_START",
    "UNIT_FLAGS",
    -- "UNIT_COMBAT",
  }

  for i = 1, #unitEvents do
    eventFrame:RegisterUnitEvent(unitEvents[i], "player")
  end

  for i = 1, #events do
    eventFrame:RegisterEvent(events[i])
  end
end

local lastEventTime = GetTime()
local function eventHandler(self, event, ...) -- Dedicated handler to avoid creating a throw away function every event
  if not CT.tracking then -- Anything that happens out of combat or related to early combat detection
    if event == "UNIT_SPELLCAST_SENT" then -- Let this pass even if not tracking to allow for early combat detection
      return combatevents[event] and combatevents[event](...)
    end
  else -- Everything that's specific to combat
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
      local _, event = ...
      return combatevents[event] and combatevents[event](...)
    elseif combatevents[event] then
      return combatevents[event](...)
    end
  end

  if event == "ADDON_LOADED" then
    local name = ...

    if name == "CombatTracker" then

    end
  elseif event == "PLAYER_LOGIN" then
    CT.eventFrame:UnregisterEvent(event)
    CT.player.loggedIn = true

    -- local preGC = collectgarbage("count")
    -- collectgarbage("collect")
    -- local num = (preGC - collectgarbage("count")) / 1000
    -- debug("Collected " .. CT.round(num, 3) .. " MB of garbage")

    if testMode then
      C_Timer.After(1.0, function()
        if CT.base then
          if CT.buttons[buttonClickNum] then
            CT.buttons[buttonClickNum]:Click("LeftButton")
          elseif CT.buttons[1] then
            CT.buttons[#CT.buttons]:Click("LeftButton")
          end

          CT.base:Show()
        end

        if trackingOnLogIn then
          CT.startTracking("Starting tracking from logging in. (Test Mode)")
        end
      end)
    end
  elseif event == "PLAYER_LOGOUT" then
    local _, specName = GetSpecializationInfo(GetSpecialization())

    if specName and CombatTrackerCharDB[specName] then
      if CombatTrackerCharDB[specName].sets then
        if CombatTrackerCharDB[specName].sets.currentDB then
          CombatTrackerCharDB[specName].sets.currentDB = nil -- Don't let it save the currentDB
          -- CombatTrackerCharDB[specName].sets.current = nil -- Uhh, how did this get created in the first place? Keep an eye out for it popping up again
        end
      end
    end
  elseif event == "ENCOUNTER_START" then
    local encounterID, encounterName, difficultyID, raidSize = ...

    CT.fightName = encounterName
  elseif event == "ENCOUNTER_END" then
    -- function CT:ENCOUNTER_END(eventName, ...)
    --   local encounterID, encounterName, difficultyID, raidSize, endStatus = ...
    --   CT.fightName = encounterName
    --   -- NOTE: encounterID
    --   --[[
    --     DIFFICULTY IDs:
    --     0 - None; not in an Instance.
    --     1 - 5-player Instance.
    --     2 - 5-player Heroic Instance.
    --     3 - 10-player Raid Instance.
    --     4 - 25-player Raid Instance.
    --     5 - 10-player Heroic Raid Instance.
    --     6 - 25-player Heroic Raid Instance.
    --     7 - Raid Finder Instance.
    --     8 - Challenge Mode Instance.
    --     9 - 40-player Raid Instance.
    --     10 - Not used.
    --     11 - Heroic Scenario Instance.
    --     12 - Scenario Instance.
    --     13 - Not used.
    --     14 - Flexible Raid.
    --     15 - Heroic Flexible Raid.
    --     END STATUS:
    --     0 - Wipe.
    --     1 - Success.
    --   ]]--
    -- end
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    if IsLoggedIn() then
      -- debug(event)
      -- CT.cycleMainButtons()
    end
  elseif event == "PLAYER_REGEN_DISABLED" then -- Start Combat
    return CT.startTracking("Starting tracking from entering combat.")
  elseif event == "PLAYER_REGEN_ENABLED" then -- Stop Combat
    return CT.stopTracking()
  elseif event == "PLAYER_TALENT_UPDATE" then
    if IsLoggedIn() then
      CT.getPlayerDetails()
    end
  elseif event == "PLAYER_ALIVE" then
    CT.player.alive = true
  elseif event == "PLAYER_DEAD" then
    CT.player.alive = false
  elseif event == "UPDATE_SHAPESHIFT_FORMS" then
    -- debug(event)
    -- local maxNum = GetNumShapeshiftForms()
    -- local stanceNum = GetShapeshiftForm()
    -- local startTime, duration, isActive = GetShapeshiftFormCooldown(stanceNum)
    -- local index = GetShapeshiftFormID()
    -- local icon, name, active, castable = GetShapeshiftFormInfo(stanceNum)
  elseif event == "UPDATE_SHAPESHIFT_FORM" then
    if CT.current and GetTime() > lastEventTime then
      CT.current.stance.num = GetShapeshiftForm()
      local uptimeGraphs = CT.current.uptimeGraphs

      if CT.current.stance.num > 0 then
        local icon, name, active, castable = GetShapeshiftFormInfo(CT.current.stance.num)
        local stanceName, _, _, _, _, _, stanceID = GetSpellInfo(name)
        CT.current.stance.name = stanceName
        CT.current.stanceID = stanceID
        CT.current.stanceSwitchTime = GetTime()

        if uptimeGraphs.misc["Stance"] and CT.combatStart then -- TODO: Fix stance
          local self = uptimeGraphs.misc["Stance"]
          local num = #self.data + 1
          self.data[num] = CT.current.stanceSwitchTime - CT.combatStart

          self.data[num + 1] = CT.current.stanceSwitchTime - CT.combatStart
          self.spellName[num + 1] = stanceName

          if self.colorPrimary and self.color == self.colorPrimary then
            self.color = self.colorSecondary
            self.colorChange[num + 1] = self.colorSecondary
          else
            self.color = self.colorPrimary
            self.colorChange[num + 1] = self.colorPrimary
          end

          self:refresh()
        end
      end

      lastEventTime = GetTime() + 0.1
    end
  elseif event == "PET_ATTACK_START" then
    if uptimeGraphs.misc["Pet"] then
      local self = uptimeGraphs.misc["Pet"]
      local num = #self.data + 1
      self.data[num] = GetTime() - CT.combatStart
      -- self.spellName[num] = stanceName -- TODO: Pet name here?

      self:refresh()
    end

    CT.current.pet.active = true
  elseif event == "PET_ATTACK_STOP" then
    if uptimeGraphs.misc["Pet"] then
      local self = uptimeGraphs.misc["Pet"]
      local num = #self.data + 1
      self.data[num] = GetTime() - CT.combatStart

      self:refresh()
    end

    CT.current.pet.active = false
  elseif event == "PET_DISMISS_START" then
  elseif event == "UNIT_COMBAT" then
    -- debug(event, ...)
  elseif event == "UNIT_PET" then
    local petName = GetUnitName("pet", false)

    if petName and CT.current then
      if CT.current.pet then wipe(CT.current.pet) else CT.current.pet = {} end
      if CT.current.pet.damage then wipe(CT.current.pet.damage) else CT.current.pet.damage = {} end
      CT.current.pet.name = petName

      if petName then
        CT.addLineGraph("Total Damage", {"DPS", 100}, colors.orange, -200, 10000) -- Total damage (player + pet)

        CT.addLineGraph("Pet Damage", {"DPS", 100}, colors.lightgrey, -200, 10000) -- Pet Damage
      end
    else
      -- if graphs["Total Damage"] then
      --   graphs["Total Damage"].hideButton = true
      -- end
      --
      -- if graphs["Pet Damage"] then
      --   graphs["Pet Damage"].hideButton = true
      -- end
    end
  elseif event == "UNIT_FLAGS" then
    if ... == "player" then
      local inCombat = InCombatLockdown()
      -- debug(GetTime(), inCombat)
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    if not CT.current then return end
    local data = CT.current

    local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()

    do -- Gather party/raid GUIDs
      if not CT.current.group then
        CT.current.group = {}
        CT.current.groupPets = {}
      else
        wipe(CT.current.group)
        wipe(CT.current.groupPets)
      end

      local num = GetNumGroupMembers()
      local group = "party"

      if num > 4 then
        group = "raid"
      end

      for i = 1, num do
        local unitID = group .. i

        CT.current.group[UnitGUID(unitID)] = unitID

        local petGUID = UnitGUID(unitID .. "pet")

        if petGUID then
          CT.current.groupPets[petGUID] = unitID .. "pet"
        end
      end
    end

    if instanceType == "arena" then
      if not CT.current.arena then
        CT.current.arena = {}
        CT.current.arenaPets = {}
      else
        wipe(CT.current.arena)
        wipe(CT.current.arenaPets)
      end

      for i = 1, 5 do
        local unitID = instanceType .. i

        CT.current.arena[UnitGUID(unitID)] = unitID

        local petGUID = UnitGUID(unitID .. "pet")

        if petGUID then
          CT.current.groupPets[petGUID] = unitID .. "pet"
        end
      end
    end
  elseif event == "GROUP_ROSTER_UPDATE" then
    local data = CT.current

    if not CT.current.group then
      CT.current.group = {}
      CT.current.groupPets = {}
    else
      wipe(CT.current.group)
      wipe(CT.current.groupPets)
    end

    local num = GetNumGroupMembers()
    local group = "party"

    if num > 4 then
      group = "raid"
    end

    for i = 1, num do
      local unitID = group .. i

      CT.current.group[UnitGUID(unitID)] = unitID

      local petGUID = UnitGUID(unitID .. "pet")

      if petGUID then
        CT.current.groupPets[petGUID] = unitID .. "pet"
      end
    end
  end
end

CT.eventFrame:SetScript("OnEvent", eventHandler)
--------------------------------------------------------------------------------
-- On Initialize
--------------------------------------------------------------------------------
function CT:OnInitialize()
  -- self.db = LibStub("AceDB-3.0"):New("CombatTrackerDB")
  -- self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")
  -- self.db = LibStub("AceDB-3.0"):New("CombatTrackerCharDB")
  -- self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")

  -- local _, _, _, _, _, id = strsplit("-", destGUID) -- NOTE: Might be handy
end

function CT:OnEnable(load)
  local _, specName = GetSpecializationInfo(GetSpecialization())

  -- if not CombatTrackerDB then print("Passed 1") CombatTrackerDB = {} end
  -- if not CombatTrackerCharDB then print("Passed 2") CombatTrackerCharDB = {} end
  -- debug(CombatTrackerCharDB)
  -- wipe(CombatTrackerCharDB)
  -- if not CombatTrackerCharDB[specName] then CombatTrackerCharDB[specName] = {} end
  -- if not CombatTrackerCharDB[specName].sets then CombatTrackerCharDB[specName].sets = {} end

  local _, specName = GetSpecializationInfo(GetSpecialization())
  debug("Loaded for", specName .. ".")

  local db = CombatTrackerCharDB[specName]
  if not db then
    debug("Creating DB for", specName .. ".")
    CombatTrackerCharDB[specName] = {}
    CombatTrackerCharDB[specName].sets = {}
  end

  local maxSets = 19

  for spec, db in pairs(CombatTrackerCharDB) do
    if db and db.sets and #db.sets >= maxSets then
      debug("DB for", spec, "has", maxSets, "or more sets.")

      for i = maxSets, #db.sets do
        tremove(db.sets, i)
      end
    end
  end

  if loadBaseOnLogin or load then
    CT.createBaseFrame()
    CT.getPlayerDetails()
    CT.createSpecDataButtons()
  end
end

function CT:OnDisable()
  -- CT.current = nil
  -- debug("CT Disable")
  -- debug("CT Disable")
end
--------------------------------------------------------------------------------
-- Main Button Functions
--------------------------------------------------------------------------------
local profile = false
local function profileCode()
  collectgarbage("collect")

  local start = debugprofilestop()

  local t = {}
  local func = CT.mainUpdate.graphUpdate
  local time = GetTime()
  -- local timer = time - CT.combatStart
  local data = CT.current
  local infinity = math.huge

  local function callback()

  end

  local f = CreateFrame("Frame")

  -- local loop = 100 -- 100
  -- local loop = 10000 -- 10 thousand
  local loop = 100000 -- 100 thousand
  -- local loop = 500000 -- 500 thousand
  -- local loop = 1000000 -- 1 million
  -- local loop = 10000000 -- 10 million
  -- local loop = 100000000 -- 100 million
  for i = 1, loop do
    local texture = f:CreateTexture(nil, "ARTWORK")
    texture:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  end

  local MS = debugprofilestop() - start

  local MSper = (MS / loop)

  debug("Time: \nMS:", MS, "\nIn 1 MS:", CT.round(1 / MSper, 1), "\n")

  C_Timer.After(1.0, function()
    local preGC = collectgarbage("count")
    collectgarbage("collect")
    local KB = (preGC-collectgarbage("count"))

    local MB = KB / 1000
    local KBper = KB / loop

    debug("Garbage: \nMB:", CT.round(MB, 3), "\nNeeded for 1 KB:", CT.round(1 / KBper, 5))
  end)

  do
    --[[Local Time Indexes
      100m
        GetTime = 3.2
        debugprofilestop = 3.7
        IsSpellOverlayed = 5.8
        GetFramerate = 6.56, 6.57
        self.value = 1.844
        t.value = i = 1.0 something, no garbage
        t[i] = "value" = 34.5, no garbage
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
        Setting 56 Upvalue Functions = 2.24
        GetUnitName = 2.714, 0.00027
        UnitGUID = 1.61, 0.000161
      1m
        GetSpellTexture = 5.5
        GetSpellInfo = 4.0
        IsUsableSpell = 17.3
        IsCurrentSpell = 0.36
        SetPoint = 0.288
        GetText = 0.146
        Setting 56 Upvalue Functions = 0.22
        C_After.Timer = 0.985 with 54.69 MB garbage, 0.055 KB per
          -- 18.2k of them = 1 MB
          -- 1,015 = 1 milisecond
        C_After.NewTicker = 32.6 with 477 MB total, 0.477 KB per
        CT.round = 1.59 total, 0.0016 per
        CT.formatTimer = 0.884 total, 0.000884 per
        UnitAura("player", "Sign of Battle") = 3.16, 0.00000316 per
        UnitAura("player", count) = 2.321, 0.00232 -- Exact same as using i
        t = {} = 0.627 total, 0.000627 per, 1.31 MB, 0.0001 KB per
        t[i] = {} = 1.336 total, 0.00133 per, 94.9 MB total, 0.095 KB per
        t[i] = {"val" x4} = 3.28 total, 0.00328 per, 212 MB total, 0.212 KB per
        t[i] = {true, x4} = 3.22 total, 0.00322 per, 212 MB total, 0.212 KB per
        t[i][1] = "val", x4 = 6.147 total, 0.00614 per, 282.3 MB total, 0.282 KB per
        local tab = t[i], tab[1] = "val", x4 = 6.02 total, 0.00602 per, 282.5 MB total, 0.283 KB per -- Setting the local doesn't speed it up for 5
        t[i] = {[1] = "val", x4} = 9.7 total, 0.0097 per, 532.6 MB total, 0.533 KB per
        t[i] = {["val"] = "val", x4} = 10.3 total, 0.0103 per, 532.6 MB total, 0.533 KB per
        t[i] = {["val"] = true, x4} = 9.74 total, 0.0097 per, 532.6 MB total, 0.533 KB per
      1k
        C_After.NewTicker = 32.6 with 477 MB total, 0.477 KB per
    ]]
  end
end

function CT.createSmallButton(b, indexed, checked)
  b:SetSize(90, 20)
  b:SetPoint("CENTER", 0, 0)

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

  if b:GetObjectType() == "CheckButton" then
    b.checked = b:CreateTexture(nil, "BACKGROUND")
    b.checked:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
    b.checked:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
    b.checked:SetAllPoints(b)
    b:SetCheckedTexture(b.checked)
  end

  if indexed then
    b.index = b:CreateFontString(nil, "ARTWORK")
    b.index:SetPoint("LEFT", 5, 0)
    b.index:SetFont("Fonts\\FRIZQT__.TTF", 12)
    b.index:SetTextColor(1, 1, 1, 1)
    b.index:SetJustifyH("LEFT")
  end

  b.title = b:CreateFontString(nil, "ARTWORK")
  b.title:SetPoint("CENTER", 0, 0)
  b.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
  b.title:SetTextColor(0.93, 0.86, 0.01, 1.0)

  return b
end

local function findInfoText(s, name, spellID, powerIndex)
  local spell = CT.current and CT.current.spells[spellID]
  local power = CT.current and CT.current.power[powerIndex]

  local pName
  if power then
    pName = power.tColor .. power.name .. "|r"

    if s == power.name.." Gained:" then
      return "The total amount of "..pName.." generated by this spell."
    elseif s == power.name.." Wasted:" then
      return "An estimate of the total "..pName.." wasted. This is just from checking your default regen and the total time at max." ..
              "\n\n|cFF00FF00BETA NOTE:|r |cFF4B6CD7When your regen rate varies, this will give screwed up numbers. Making this far more accurate is on my to do list," ..
              " but there are a ton of things to do, so it may be a while.|r"
    elseif s == power.name.." Spent:" then
      return "The total amount of "..pName.." spent by this spell."
    elseif s == "Effective Gain:" then
      return "Total "..pName.." gained minus the wasted amount."
    elseif s == "Times Capped:" then
      return "The number of different times you hit maximum "..pName..".\n\nTry to avoid this, because anything you generate while at the cap goes to waste."
    elseif s == "Seconds Capped:" then
      return "The total number of seconds you spent at maximum "..pName..".\n\nKeep this as low as possible, because anything generated while at max is wasted."
    end
  end

  local sName
  if spell or name then
    if spell and spell.name then
      sName = "|cFFFFFF00" .. spell.name .. "|r"
    else
      sName = "|cFFFFFF00" .. name .. "|r"
    end

    if s == "Holy Power Gained:" then
      return "The total amount of Holy Power generated by "..sName.."."
    elseif s == "Holy Power Spent:" then
      return "The total amount of Holy Power spent by "..sName.."."
    elseif s == "Total Absorbs:" then
      return "The total amount of absorbs created by "..sName.."."
    elseif s == "Wasted Absorbs:" then
      return "The total amount of absorbs wasted from "..sName.."."
    elseif s == "Average Absorb:" then
      return "The average absorb created by "..sName.."."
    elseif s == "Biggest Absorb:" then
      return "The biggest absorb created by "..sName.."."
    elseif s == "Percent of Healing:" then
      return "The percent of your total healing caused by "..sName.."."
    elseif s == "Procs Used:" then
      return "The number of times "..sName.." had an activation border when you cast it."
    -- elseif s == "Total Procs:" then
    --   return ""
    elseif s == "Percent on CD:" then
      return "The percent of the total fight that "..sName.." was on CD. Generally you want this to be as high as possible."
    elseif s == "Seconds Wasted:" then
      return "The percent of the total fight that "..sName.." was not on CD. Generally you want this to be as low as possible."
    elseif s == "Average Delay:" then
      return "The average delay between casts of "..sName..". Generally you want this to be as low as possible."
    elseif s == "Number of Casts:" then
      return "The total number of times you cast "..sName.."."
    elseif s == "Reset Casts:" then
      return "The total number of times "..sName.."'s CD got reset early."
    elseif s == "Longest Delay:" then
      return "The longest gap you had between casts of "..sName.."."
    elseif s == "Biggest Heal:" then
      return "The biggest heal from "..sName.."."
    elseif s == "Average Heal:" then
      return "The average heal done by "..sName.."."
    elseif s == "Average Targets Hit:" then
      return "The average number of targets hit per "..sName.." cast."
    end
  end

  do -- Resources
    if s == "Mana" then
      return "Includes lots of details about your Mana usage. Mouseover each spell for more details."
    elseif s == "Rage" then
      return "Includes lots of details about your Rage usage. Mouseover each spell for more details."
    elseif s == "Focus" then
      return "Includes lots of details about your Focus usage. Mouseover each spell for more details."
    elseif s == "Energy" then
      return "Includes lots of details about your Energy usage. Mouseover each spell for more details."
    elseif s == "Combo Points" then
      return "Includes lots of details about your Combo Point usage. Mouseover each spell for more details."
    elseif s == "Runes" then
      return "Includes lots of details about your Rune usage. Mouseover each spell for more details."
    elseif s == "Runic Power" then
      return "Includes lots of details about your Runic Power usage. Mouseover each spell for more details."
    elseif s == "Soul Shards" then
      return "Includes lots of details about your Soul Shards usage. Mouseover each spell for more details."
    elseif s == "Eclipse" then
      return "Includes lots of details about your Eclipse usage. Mouseover each spell for more details."
    elseif s == "Holy Power" then
      return "Includes lots of details about your Holy Power usage. Mouseover each spell for more details."
    elseif s == "Alternate Power" then
      return "Includes lots of details about your Alternate Power usage. Mouseover each spell for more details."
    elseif s == "Dark Force" then
      return "Includes lots of details about your Dark Force usage. Mouseover each spell for more details."
    elseif s == "Chi" then
      return "Includes lots of details about your Chi usage. Mouseover each spell for more details."
    elseif s == "Shadow Orbs" then
      return "Includes lots of details about your Shadow Orbs usage. Mouseover each spell for more details."
    elseif s == "Burning Embers" then
      return "Includes lots of details about your Burning Embers usage. Mouseover each spell for more details."
    elseif s == "Demonic Fury" then
      return "Includes lots of details about your Demonic Fury usage. Mouseover each spell for more details."
    end
  end

  if s == "Holy Shock" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Crusader Strike" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Explosive Shot" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Black Arrow" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Chimaera Shot" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Judgment" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Exorcism" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "All Casts" then
    return "Includes details about every spell cast you did. Mouseover each spell for more details."
  elseif s == "Cleanse" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Light's Hammer" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Execution Sentence" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Holy Prism" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Seraphim" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Empowered Seals" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Stance" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Illuminated Healing" then
    return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Stance" then
    -- return "Includes details about every " .. s .. " you cast. Mouseover each spell for more details."
  elseif s == "Stance" then
    -- return ""
  elseif s == "Stance" then
    -- return ""
  elseif s == "Damage" then
    return "Includes details about your total damage and every spell that did damage. Mouseover each frame for more details."
  end

  if name and name == "Activity" then
    if s == "Active Time:" then
      return "Total activity, counting all casts and GCDs."
    elseif s == "Percent:" then
      return "The percent of the fight that you were active."
    elseif s == "Seconds Active:" then
      return "The total seconds that you were active."
    elseif s == "Total Active Seconds:" then
      return "The total number of seconds you were on a GCD or doing a hard cast."
    elseif s == "Seconds Casting:" then
      return "Total number of seconds doing hard casts."
    elseif s == "Seconds on GCD:" then
      return "Total number of seconds on a GCD. This ignores GCD caused by cast times."
    elseif s == "Total Casts:" then
      return "The total number of casts done, combining hard casts and instant."
    elseif s == "Total Instant Casts:" then
      return "The total number of instant casts done."
    elseif s == "Total Hard Casts:" then
      return "The total number of hard casts done."
    end
  end

  if s == "Total Gain:" then
    return "Total power gained."
  elseif s == "Total Loss:" then
    return "Total power lost."
  elseif s == "Uptime:" then
    return "Overall uptime of the aura."
  elseif s == "Downtime:" then
    return "Overall downtime of the aura."
  -- elseif s == "Average Downtime:" then
  --   return ""
  -- elseif s == "Longest Downtime:" then
  --   return ""
  -- elseif s == "Total Applications:" then
  --   return ""
  -- elseif s == "Times Refreshed:" then
  --   return ""
  -- elseif s == "Wasted Time:" then
  --   return ""
  elseif s == ":" then
    return ""
  elseif s == ":" then
    return ""
  elseif s == "Total Damage:" then
    return "The total amount of damage you did during the fight."
  elseif s == "Average DPS:" then
    return "The average damage per second you did during the fight."
  end

  if s == "" then
    s = "NO STRING!"
  end

  return "|cFFFF0000Failed to find any info text for this tooltip!\n\nSearched for string was:|r |cFFFA6022" .. s ..
          "|r\n\n|cFF00FF00BETA NOTE:|r |cFF4B6CD7If you see this, please let me know and tell me what you were mousing over " ..
          "at the time and what the searched for string was so I can add it. Thanks. :)|r"
end

local function addExpanderText(self, lines)
  if not lines then return debug("Called expand text without a line table", self and self.name) end

  local frameNum = 1
  local dataFrame = CT.base.expander.dataFrames[frameNum]
  if not CT.base.expander.textFrames then CT.base.expander.textFrames = {} end
  local exp = CT.base.expander

  local columns = 2
  local width, height = dataFrame:GetSize()
  local width = width / columns
  local listNum = min(#self.lineTable, columns)
  local fHeight = height / columns
  local newFrame

  for i, v in ipairs(CT.base.expander.textFrames) do
    v:Hide()
  end

  for i = 1, #lines do
    local lineText = lines[i]
    local f = exp.textFrames[i]

    if not f then
      local num = #exp.textFrames + 1

      exp.textFrames[num] = CreateFrame("Button", "CT_TextFrame_" .. i, exp)
      f = exp.textFrames[num]
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

      do -- Text
        exp.textData.title[i] = f:CreateFontString(nil, "ARTWORK")
        exp.textData.title[i]:SetPoint("TOPLEFT", 0, -2)
        exp.textData.title[i]:SetPoint("TOPRIGHT", 0, -2)
        exp.textData.title[i]:SetFont("Fonts\\FRIZQT__.TTF", 12)
        exp.textData.title[i]:SetTextColor(1, 1, 1, 1)
        exp.textData.title[i]:SetJustifyH("CENTER")

        exp.textData.value[i] = f:CreateFontString(nil, "ARTWORK")
        exp.textData.value[i]:SetPoint("TOP", exp.textData.title[i], "BOTTOM", 0, 0)
        exp.textData.value[i]:SetPoint("BOTTOM", 0, 0)
        exp.textData.value[i]:SetFont("Fonts\\FRIZQT__.TTF", 18)
        exp.textData.value[i]:SetTextColor(1, 1, 0, 1)
        exp.textData.value[i]:SetJustifyH("CENTER")
      end
    end

    f:Show()

    do -- Calculate each frame's size and position
      local mod = i % 4
      if mod == 0 then
        mod = 4
        newFrame = true
      end

      exp.textData.title[i]:SetText(lineText)
      exp.textData.value[i]:SetText()

      f:ClearAllPoints()
      f:SetPoint(cornerAnchors[mod], dataFrame, 0, 0)

      if newFrame then
        frameNum = frameNum + 1
        dataFrame = exp.dataFrames[frameNum]
        if dataFrame then
          width, height = dataFrame:GetSize()
          width = width / columns
        end
        newFrame = false
      end
    end

    f:SetScript("OnEnter", function(self)
      CT.mouseFrameBorder(self, 2)

      f.info = findInfoText(lineText, self.name, self.spellID, self.powerIndex)

      CT.createInfoTooltip(f, lineText, self.iconTexture, nil, nil, nil)
    end)

    f:SetScript("OnLeave", function()
      CT.mouseFrameBorder()
      CT.createInfoTooltip()
    end)

    if lineText == "" then
      f:Hide()
    end
  end
end

local function createMenuButtons(popup)
  for i = 1, 4 do
    local b = popup[i]

    if not b then
      popup[i] = CreateFrame("Button", "CT_Menu_Button_" .. i, popup)
      local b = popup[i]

      b:SetSize(170, (popup:GetHeight() / 2) - 2)
      b:SetPoint(cornerAnchors[i], 0, 0)
      -- b:SetPoint("CENTER", 0, 0)
      -- b1:SetPoint("RIGHT", -(buttonFrame:GetWidth() / 2 + 5), 0)

      b.normal = b:CreateTexture(nil, "BACKGROUND")
      b.normal:SetTexture("Interface\\EncounterJournal\\UI-EncounterJournalTextures")
      b.normal:SetTexCoord(0.00195313, 0.34179688, 0.42871094, 0.52246094)
      b.normal:SetAllPoints()
      b:SetNormalTexture(b.normal)

      b.highlight = b:CreateTexture(nil, "BACKGROUND")
      b.highlight:SetTexture("Interface\\EncounterJournal\\UI-EncounterJournalTextures")
      -- b1.highlight:SetTexCoord(0.34570313, 0.68554688, 0.33300781, 0.42675781)
      b.highlight:SetTexCoord(0.00195313, 0.34179688, 0.42871094, 0.52246094)
      b.highlight:SetVertexColor(0.5, 0.5, 0.5, 1)
      b.highlight:SetAllPoints()
      b:SetHighlightTexture(b.highlight)

      b.pushed = b:CreateTexture(nil, "BACKGROUND")
      b.pushed:SetTexture("Interface\\EncounterJournal\\UI-EncounterJournalTextures")
      b.pushed:SetTexCoord(0.00195313, 0.34179688, 0.33300781, 0.42675781)
      b.pushed:SetAllPoints()
      b:SetPushedTexture(b.pushed)

      b.title = b:CreateFontString(nil, "ARTWORK")
      b.title:SetPoint("TOPLEFT", 0, 0)
      b.title:SetPoint("BOTTOMRIGHT", 0, 0)
      b.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
      b.title:SetTextColor(0.8, 0.8, 0, 1)
      b.title:SetShadowOffset(3, -3)

      b:SetScript("OnClick", function(self, button)
        b.func()
      end)
    end
  end

  return popup
end

function CT:expanderFrame(command)
  if not CT.base then CT:OnEnable("load") end

  local f = CT.base.expander

  if not f then
    CT.base.expander = CreateFrame("Frame", nil, CT.base)
    f = CT.base.expander
    f:SetPoint("LEFT", CT.base, "RIGHT")
    f:SetSize(500, 556)

    local backdrop = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tileSize = 32,
    edgeSize = 16,}

    f:SetBackdrop(backdrop)
    f:SetBackdropColor(0.15, 0.15, 0.15, 1)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)

    f:EnableMouse(true)

    f:SetScript("OnMouseDown", function(self, button)
      if button == "LeftButton" and not CT.base.isMoving then
        CT.base:StartMoving()
        CT.base.isMoving = true -- TODO: Make graphs vanish when moving is started
      end
    end)

    f:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" and CT.base.isMoving then
        CT.base:StopMovingOrSizing()
        CT.base.isMoving = false
        CT:updateButtonList()
      end
    end)

    f:SetScript("OnShow", function(self)
      if CT.displayed then
        if not self.graphFrame.displayed[1] then -- No regular graph is loaded
          -- debug("No regular graph, loading default.")

          CT.loadDefaultGraphs()
          CT.finalizeGraphLength("line")
        end

        if not self.uptimeGraph.displayed then -- No uptime graph is loaded
          -- debug("No uptime graph, loading default.")

          CT.loadDefaultUptimeGraph()
          CT.finalizeGraphLength("uptime")
        end
      end
    end)

    f:SetScript("OnHide", function(self)
      -- debug("Expander hiding")
    end)

    f:Hide()
  end

  if not f.titleBG then -- Title Background, icon, and text
    if not f.titleBG then -- Title Background
      f.titleBG = CreateFrame("Button", "CT_Main_Title_Background", f)
      f.titleBG:SetPoint("TOPLEFT", f, 15, -15)
      f.titleBG:SetPoint("TOPRIGHT", f, -(f:GetWidth() / 3) - 10, -15)
      f.titleBG:SetHeight(40)
      f.titleBG.texture = f.titleBG:CreateTexture(nil, "BACKGROUND")
      f.titleBG.texture:SetTexture(0.1, 0.1, 0.1, 1)
      f.titleBG.texture:SetAllPoints()

      f.titleBG:SetScript("OnEnter", function()
        local displayed = f.titleText:GetText()

        f.titleBG.info = findInfoText(displayed)

        CT.createInfoTooltip(f.titleBG, "Title")
      end)

      f.titleBG:SetScript("OnLeave", function()
        CT.createInfoTooltip()
      end)
    end

    if not f.icon then
      f.icon = f.titleBG:CreateTexture(nil, "OVERLAY")
      f.icon:SetSize(30, 30)
      f.icon:SetPoint("LEFT", f.titleBG, 10, 0)
      f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      f.icon:SetAlpha(0.9)
    end

    if not f.titleText then
      f.titleText = f.titleBG:CreateFontString(nil, "ARTWORK")
      f.titleText:SetPoint("LEFT", f.icon, "RIGHT", 5, 0)
      f.titleText:SetFont("Fonts\\FRIZQT__.TTF", 24)
      f.titleText:SetTextColor(0.8, 0.8, 0, 1)
    end

    if not f.titleData then -- Title Data
      f.titleData = CreateFrame("Button", "CT_Title_Data", f)
      f.titleData:SetPoint("TOPLEFT", f, ((f:GetWidth() / 3) * 2) + 0, -15)
      f.titleData:SetPoint("TOPRIGHT", f, -15, -15)
      f.titleData:SetHeight(40)
      f.titleData.texture = f.titleData:CreateTexture(nil, "BACKGROUND")
      f.titleData.texture:SetTexture(0.1, 0.1, 0.1, 1)
      f.titleData.texture:SetAllPoints()

      f.titleData:SetScript("OnEnter", function()
        f.titleData.info = "The currently displayed fight and the amount of time in combat."

        CT.createInfoTooltip(f.titleData, "Title Data", nil, nil, nil, nil)
      end)

      f.titleData:SetScript("OnLeave", function()
        CT.createInfoTooltip()
      end)
    end

    if not f.titleData.leftText1 then -- Top Row Data Text
      f.titleData.leftText1 = f.titleData:CreateFontString(nil, "ARTWORK")
      f.titleData.leftText1:SetPoint("TOPLEFT", f.titleData, 5, -5)
      f.titleData.leftText1:SetFont("Fonts\\FRIZQT__.TTF", 12)
      f.titleData.leftText1:SetTextColor(1.0, 1.0, 1.0, 1.0)
      f.titleData.leftText1:SetShadowOffset(1, -1)
      f.titleData.leftText1:SetJustifyH("LEFT")
      f.titleData.leftText1:SetText("Fight:")
    end

    if not f.titleData.rightText1 then
      f.titleData.rightText1 = f.titleData:CreateFontString(nil, "ARTWORK")
      f.titleData.rightText1:SetPoint("LEFT", f.titleData.leftText1, "RIGHT", 0, 0)
      f.titleData.rightText1:SetPoint("RIGHT", f.titleData, -3, 0)
      f.titleData.rightText1:SetFont("Fonts\\FRIZQT__.TTF", 12)
      f.titleData.rightText1:SetTextColor(1.0, 1.0, 0.0, 1.0)
      f.titleData.rightText1:SetShadowOffset(1, -1)
      f.titleData.rightText1:SetJustifyH("RIGHT")
    end

    if not f.titleData.leftText2 then -- Bottom Row Data Text
      f.titleData.leftText2 = f.titleData:CreateFontString(nil, "ARTWORK")
      f.titleData.leftText2:SetPoint("BOTTOMLEFT", f.titleData, 5, 5)
      f.titleData.leftText2:SetFont("Fonts\\FRIZQT__.TTF", 12)
      f.titleData.leftText2:SetTextColor(1.0, 1.0, 1.0, 1.0)
      f.titleData.leftText2:SetShadowOffset(1, -1)
      f.titleData.leftText2:SetJustifyH("LEFT")
      f.titleData.leftText2:SetText("Length:")
    end

    if not f.titleData.rightText2 then
      f.titleData.rightText2 = f.titleData:CreateFontString(nil, "ARTWORK")
      f.titleData.rightText2:SetPoint("LEFT", f.titleData.leftText2, "RIGHT", 0, 0)
      f.titleData.rightText2:SetPoint("RIGHT", f.titleData, -3, 0)
      f.titleData.rightText2:SetFont("Fonts\\FRIZQT__.TTF", 12)
      f.titleData.rightText2:SetTextColor(1.0, 1.0, 0.0, 1.0)
      f.titleData.rightText2:SetShadowOffset(1, -1)
      f.titleData.rightText2:SetJustifyH("RIGHT")
    end
  end

  if not f.dataFrames then -- Data Frames
    f.dataFrames = {}
    f.spellFrames = {}
    f.textData = {}
    f.textData.title = {}
    f.textData.value = {}

    if not f.dataFrames[1] then -- Data 1
      f.dataFrames[1] = f:CreateTexture(nil, "BORDER")
      f.dataFrames[1]:SetPoint("LEFT", f.titleBG, 0, 0)
      f.dataFrames[1]:SetPoint("RIGHT", f, -(f:GetWidth() / 2) - 5, 0)
      f.dataFrames[1]:SetPoint("TOP", f.titleBG, "BOTTOM", 0, -10)
      f.dataFrames[1]:SetTexture(0.1, 0.1, 0.1, 1)
      f.dataFrames[1]:SetHeight(100)
    end

    if not f.dataFrames[2] then -- Data 2
      f.dataFrames[2] = f:CreateTexture(nil, "BORDER")
      f.dataFrames[2]:SetPoint("LEFT", f, (f:GetWidth() / 2) + 5, 0)
      f.dataFrames[2]:SetPoint("RIGHT", f.titleData, 0, 0)
      f.dataFrames[2]:SetPoint("TOP", f.titleData, "BOTTOM", 0, -10)
      f.dataFrames[2]:SetTexture(0.1, 0.1, 0.1, 1)
      f.dataFrames[2]:SetHeight(100)
    end

    if not f.dataFrames[3] then -- Data 3
      f.dataFrames[3] = f:CreateTexture(nil, "BORDER")
      f.dataFrames[3]:SetPoint("LEFT", f.dataFrames[1], 0, 0)
      f.dataFrames[3]:SetPoint("RIGHT", f.dataFrames[1], 0, 0)
      f.dataFrames[3]:SetPoint("TOP", f.dataFrames[1], "BOTTOM", 0, -10)
      f.dataFrames[3]:SetTexture(0.1, 0.1, 0.1, 1)
      f.dataFrames[3]:SetHeight(100)
    end

    if not f.dataFrames[4] then  -- Data 4
      f.dataFrames[4] = f:CreateTexture(nil, "BORDER")
      f.dataFrames[4]:SetPoint("LEFT", f.dataFrames[2], 0, 0)
      f.dataFrames[4]:SetPoint("RIGHT", f.dataFrames[2], 0, 0)
      f.dataFrames[4]:SetPoint("TOP", f.dataFrames[2], "BOTTOM", 0, -10)
      f.dataFrames[4]:SetTexture(0.1, 0.1, 0.1, 1)
      f.dataFrames[4]:SetHeight(100)
    end
  end

  local uptimeGraph = f.uptimeGraph
  if not uptimeGraph then
    f.uptimeGraph = CT.buildUptimeGraph(f)
    uptimeGraph = f.uptimeGraph

    uptimeGraph:ClearAllPoints()
    uptimeGraph:SetParent(f)
    uptimeGraph:SetPoint("LEFT", f.dataFrames[3], 0, 0)
    uptimeGraph:SetPoint("RIGHT", f.dataFrames[4], 0, 0)
    uptimeGraph:SetPoint("TOP", f.dataFrames[4], "BOTTOM", 0, -10)
    uptimeGraph:SetHeight(25)
    uptimeGraph.defaultHeight = uptimeGraph:GetHeight()
  end

  local graphFrame = f.graphFrame
  if not graphFrame then
    f.graphFrame = CT.buildGraph(f)
    graphFrame = f.graphFrame

    graphFrame:ClearAllPoints()
    graphFrame:SetParent(f)
    graphFrame:SetPoint("LEFT", uptimeGraph, 0, 0)
    graphFrame:SetPoint("RIGHT", uptimeGraph, 0, 0)
    graphFrame:SetPoint("TOP", uptimeGraph, "BOTTOM", 0, -10)
    graphFrame:SetPoint("BOTTOM", f, 0, 10)
  end

  if f.shown and (command and command == "hide") or (not command and f:IsShown()) then
    f:Hide()
    f.shown = false
  elseif not f.shown and (command and command == "show") or (not command and not f:IsShown()) then
    f:Show()
    f.shown = true
  end

  if f.shown then
    if self and self.name then
      f.currentButton = self

      f.icon:SetTexture(self.iconTexture or CT.player.specIcon)
      SetPortraitToTexture(f.icon, f.icon:GetTexture())

      f.titleText:SetText(self.name)

      addExpanderText(self, self.lineTable)

      local buttonName = self.name

      if not CT.current and not CT.displayed then
        debug("No current set, so loading last saved set.")
        CT.loadSavedSet() -- Load the most recent set as default
      end

      if CT.displayed then
        local uptimeGraphs = CT.displayed.uptimeGraphs
        local graphs = CT.displayed.graphs

        for i = 1, #CT.displayed.power do
          local power = CT.displayed.power[i]

          if power.costFrames then
            if self.powerNum and self.powerNum == i then
              for i = 1, #power.costFrames do
                power.costFrames[i]:Show()
              end
            else
              for i = 1, #power.costFrames do
                power.costFrames[i]:Hide()
              end
            end
          end
        end

        for k, v in pairs(CT.base.expander.spellFrames) do
          v:Hide()
        end
      end
    end

    if CT.displayed then
      local timer = ((CT.displayedDB.stop or GetTime()) - CT.displayedDB.start) or 0

      f.titleData.rightText1:SetText(CT.displayedDB.setName or "None loaded")
      CT.base.expander.titleData.rightText2:SetText(CT.formatTimer(timer))
    else
      f.titleData.rightText1:SetText("None loaded")
    end

    CT.forceUpdate = true
  end
end

local function createButtonFrame(button)
  button:SetPoint("TOPLEFT", 0, 0)
  button:SetPoint("TOPRIGHT", 0, 0)
  button:SetSize(150, 44)

  do -- Basic textures and stuff
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
  end

  do -- Create Icon
    button.icon = button:CreateTexture(nil, "OVERLAY")
    button.icon:SetSize(32, 32)
    button.icon:SetPoint("LEFT", 30, 0)
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
    button.title = button:CreateFontString(nil, "ARTWORK")
    button.title:SetPoint("LEFT", button.icon, "RIGHT", 10, 0)
    button.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
    button.title:SetTextColor(1, 1, 0, 1)

    button.value = button:CreateFontString(nil, "ARTWORK")
    button.value:SetPoint("RIGHT", button, -13, 0)
    button.value:SetFont("Fonts\\FRIZQT__.TTF", 22)
    button.value:SetTextColor(1, 1, 0, 1)
  end

  do -- Generic Scripts
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
end

local function loadButtonsToFrame(table)
  if not table then return end

  for i = 1, max(#table, #CT.contentFrame) do

  end
end

function CT.createSpecDataButtons() -- Create the default main buttons
  for i = 1, #CT.setButtons do
    CT.setButtons[i]:Hide()
  end

  for i = 1, #CT.specData do
    local b = CT.buttons[i]

    if not b then
      CT.buttons[i] = CreateFrame("CheckButton", "CT_Main_Button_" .. i, CT.contentFrame)
      b = CT.buttons[i]

      b.text = {}

      createButtonFrame(b)
      tinsert(CT.update, b)

      do -- Button Scripts
        local lastClickTime = GetTime()
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        b:SetScript("OnClick", function(self, click)
          if GetTime() > lastClickTime then

            if not self.checked then
              self.checked = self:CreateTexture(nil, "BACKGROUND")
              self.checked:SetTexture("Interface\\PetBattles\\PetJournal")
              self.checked:SetTexCoord(0.49804688, 0.90625000, 0.17480469, 0.21972656) -- Blue highlight border
              self.checked:SetBlendMode("ADD")
              self.checked:SetPoint("TOPLEFT", 2, -2)
              self.checked:SetPoint("BOTTOMRIGHT", -2, 2)
              self:SetCheckedTexture(self.checked)

              self.checked:SetVertexColor(0.3, 0.5, 0.8, 0.8) -- Blue: Dark and more subtle blue
            end

            if click == "LeftButton" then
              if not self.expand then self.expand = CT.expanderFrame end

              if self:GetChecked() then
                self:expand("show")
                self.expanded = true
              else
                self:expand("hide")
                self.expanded = false
              end

              for i = 1, #CT.buttons do
                if CT.buttons[i] ~= self and CT.buttons[i]:GetChecked() then
                  CT.buttons[i]:SetChecked(false)
                  CT.buttons[i].expanded = false
                end
              end
            elseif click == "RightButton" then
              if CT.base.expander and CT.base.expander.currentButton and CT.base.expander.currentButton ~= self then self:SetChecked(false) end
              if true then return debug("Blocking right click, it isn't set up properly and will error.") end

              if not self.expandedDown and (dropDown.dropHeight or 1) > 0 then -- Expand drop down
                self:UnlockHighlight()

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

                  expander.defaultHeight = self:GetHeight()
                  expander.expandedHeight = expander.defaultHeight + dropDown.dropHeight
                  CT.updateButtonList()
                  CT.scrollFrameUpdate()
                end
              elseif self.expandedDown == true then -- Collapse drop down
                self:UnlockHighlight()
                expander.expanded = false
                self.expandedDown = false

                self:dropAnimationUp()

                expander.defaultHeight = self:GetHeight()
                expander.expandedHeight = expander.defaultHeight + dropDown.dropHeight
                CT.updateButtonList()
                CT.scrollFrameUpdate()
              end
            end

            if CT.displayed then
              local time = GetTime()
              local timer = ((CT.displayedDB.stop or GetTime()) - CT.displayedDB.start) or 0

              if self.expanded and self.expanderUpdate then
                self:expanderUpdate(time, timer)
              elseif self.shown and self.update then
                self:update(time, timer)
              end
            end

            PlaySound("igMainMenuOptionCheckBoxOn")
            lastClickTime = GetTime() + 0.1
          end
        end)
      end
    end

    local specData = CT.specData[i]

    b.name = specData.name
    b.num = i
    b.powerIndex = specData.powerIndex
    b.update = specData.func
    b.expanderUpdate = specData.expanderFunc
    b.dropDownFunc = specData.dropDownFunc
    b.lineTable = specData.lines
    b.costsPower = specData.costsPower
    b.givesPower = specData.givesPower
    b.spellID = specData.spellID or select(7, GetSpellInfo(b.name))
    b.iconTexture = specData.icon or GetSpellTexture(b.spellID) or GetSpellTexture(b.name) or CT.player.specIcon

    b.title:SetText(b.name)

    do -- Update icon texture
      if b.iconTexture then
        b.icon:SetTexture(b.iconTexture)
      else
        b.icon:SetTexture(CT.player.specIcon)
      end

      SetPortraitToTexture(b.icon, b.icon:GetTexture())
    end

    b:Show()
  end

  if CT.buttons[1] then
    if not CT.topAnchor1 then CT.topAnchor1 = {CT.buttons[1]:GetPoint(1)} end
    if not CT.topAnchor2 then CT.topAnchor2 = {CT.buttons[1]:GetPoint(2)} end
  end

  CT.totalNumButtons = #CT.specData

  CT.setButtonAnchors(CT.buttons)
end

function CT.createSavedSetButtons(table)
  for i = 1, #CT.buttons do
    CT.buttons[i]:Hide()
  end

  for i = 1, #table do
    local b = CT.setButtons[i]

    if not b then
      CT.setButtons[i] = CreateFrame("CheckButton", "CT_Saved_Set_Button_" .. i, CT.contentFrame)
      b = CT.setButtons[i]

      b.name = table.setName
      b.num = i
      b.text = {}
      b.expanded = false
      b.expandedDown = false

      createButtonFrame(b)

      do -- Button Scripts
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b:SetScript("OnClick", function(self, click)
          PlaySound("igMainMenuOptionCheckBoxOn")

          if not self.checked then
            self.checked = self:CreateTexture(nil, "BACKGROUND")
            self.checked:SetTexture("Interface\\PetBattles\\PetJournal")
            self.checked:SetTexCoord(0.49804688, 0.90625000, 0.17480469, 0.21972656) -- Blue highlight border
            self.checked:SetBlendMode("ADD")
            self.checked:SetPoint("TOPLEFT", 2, -2)
            self.checked:SetPoint("BOTTOMRIGHT", -2, 2)
            self:SetCheckedTexture(self.checked)

            self.checked:SetVertexColor(0.3, 0.5, 0.8, 0.8) -- Blue: Dark and more subtle blue
          end

          if click == "LeftButton" then
            if self:GetChecked() then
              local set, db = CT.loadSavedSet(table[i])
            else
              CT.loadActiveSet() -- Change displayed set to current
            end

            CT.base.bottomExpander.popup[1]:Click() -- Toggles it back to normal buttons
            CT.forceUpdate = true
          elseif click == "RightButton" then
            -- if self:GetChecked() then self:SetChecked(false) end -- Don't let right click set it to checked

            local accept, decline = CT.confirmDialogue(self) -- Shows the dialogue frame

            accept.LeftButton = function()
              local t = tremove(table, i) -- Remove saved variable set
              t = nil

              if not InCombatLockdown() then
                collectgarbage("collect")
              end

              CT.createSavedSetButtons(table) -- Refresh list
            end

            decline.LeftButton = function()

            end

            for i = 1, #table do
              if CT.displayedDB and CT.displayedDB == table[i] then
                CT.setButtons[i]:SetChecked(true)
              else
                CT.setButtons[i]:SetChecked(false)
              end
            end
          end
        end)
      end
    elseif b then
      b:Hide()
    end

    local text = table[i].setName or "Unknown"
    local time = CT.formatTimer(table[i].fightLength) or "0:00"
    b.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
    b.title:SetPoint("LEFT", 20, 0)
    b.title:SetJustifyH("LEFT")
    b.title:SetFormattedText("%s. %s%s|r (%s%s|r)", i, "|cFFFFFF00", text, "|cFF00CCFF", time)

    if CT.displayedDB and CT.displayedDB == table[i] then
      if not b.checked then
        b.checked = b:CreateTexture(nil, "BACKGROUND")
        b.checked:SetTexture("Interface\\PetBattles\\PetJournal")
        b.checked:SetTexCoord(0.49804688, 0.90625000, 0.17480469, 0.21972656) -- Blue highlight border
        b.checked:SetBlendMode("ADD")
        b.checked:SetPoint("TOPLEFT", 2, -2)
        b.checked:SetPoint("BOTTOMRIGHT", -2, 2)
        b.checked:SetVertexColor(0.3, 0.5, 0.8, 0.8) -- Blue: Dark and more subtle blue
        b:SetCheckedTexture(b.checked)
      end

      b:SetChecked(true)
    elseif b.checked then
      b:SetChecked(false)
    end

    b:Show()
  end

  if CT.buttons[1] then
    if not CT.topAnchor1 then CT.topAnchor1 = {CT.buttons[1].button:GetPoint(1)} end
    if not CT.topAnchor2 then CT.topAnchor2 = {CT.buttons[1].button:GetPoint(2)} end
  end

  CT.setButtonAnchors(CT.setButtons)
end

function CT.scrollFrameUpdate(table)
  local height = 0

  local spacing = CT.settings.buttonSpacing

  for i, button in ipairs(table) do
    height = height + button:GetHeight() + spacing
  end

  CT.scrollBar:SetMinMaxValues(0, max(height - CT.scrollBar:GetHeight(), 0))
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

function CT.setButtonAnchors(table)
  local table = table or CT.buttons

  for i = 1, #table do
    local button = table[i]
    if i == 1 then
      button:ClearAllPoints()
      button:SetPoint("TOPLEFT", 0, 0)
      button:SetPoint("TOPRIGHT")
    else
      local prevButtonExpander = table[i - 1].expander
      button:ClearAllPoints()
      button:SetPoint("TOPRIGHT", prevButtonExpander, "BOTTOMRIGHT", 0, -CT.settings.buttonSpacing)
      button:SetPoint("TOPLEFT", prevButtonExpander, "BOTTOMLEFT", 0, -CT.settings.buttonSpacing)
    end
    local _, coords = button.expander:GetCenter()
    button.coords = coords
  end

  CT.scrollFrameUpdate(table)
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
  local button = self
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
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", UIParent, CT.contentFrame:GetLeft(), mouseY)
        local _, dragCenter = self.expander:GetCenter()
        self.buttonUp = nil
        self.buttonDown = nil

        if CT.mainButtons[self.num - 1] then
          self.buttonUp = CT.mainButtons[self.num - 1]
          topDistance = CT.mainButtons[self.num - 1].coords - dragCenter
        end
        if CT.mainButtons[self.num + 1] then
          self.buttonDown = CT.mainButtons[self.num + 1]
          bottomDistance = dragCenter - CT.mainButtons[self.num + 1].coords
        end

        if topDistance <= buttonHeight and self.buttonUp then
          local tempNum = self.num
          self.num = self.buttonUp.num
          self.buttonUp.num = tempNum
          CT.updateButtonOrderByNum()
          CT:setButtonAnchorsDragging()
          CT.slideButtonAnimation(self.buttonUp, "down")
        end
        if bottomDistance < buttonHeight and self.buttonDown then
          local tempNum = self.num
          self.num = self.buttonDown.num
          self.buttonDown.num = tempNum
          CT.updateButtonOrderByNum()
          CT:setButtonAnchorsDragging()
          CT.slideButtonAnimation(self.buttonDown, "up")
        end
      else
        self:Hide()
        self:SetFrameLevel(buttonLevel)
        self.dragging = false
        self = nil
        CT:setButtonAnchors()
        for i = 1, #CT.mainButtons do
          CT.mainButtons[i]:Enable()
        end
      end
    end)
  end
end

function CT:expandedMenu()
  debug("Expand called", self.name)
  local f = CT.base.expander
  f.icon:SetTexture(self.iconTexture or CT.player.specIcon)
  SetPortraitToTexture(f.icon, f.icon:GetTexture())

  f.titleText:SetText(self.name)

  addExpanderText(self, self.lineTable)

  local buttonName = self.name

  if CT.displayed then
    local uptimeGraphs = CT.displayed.uptimeGraphs
    local graphs = CT.displayed.graphs

    for i = 1, #CT.displayed.power do
      local power = CT.displayed.power[i]

      if power.costFrames then
        if self.powerNum and self.powerNum == i then
          for i = 1, #power.costFrames do
            power.costFrames[i]:Show()
          end
        else
          for i = 1, #power.costFrames do
            power.costFrames[i]:Hide()
          end
        end
      end
    end
  end

  for k, v in pairs(CT.base.expander.spellFrames) do
    v:Hide()
  end

  f.last = self
  CT.forceUpdate = true
end

function CT.createBaseFrame() -- Create Base Frame
  local f = CT.base
  if not f then
    CT.base = baseFrame
    f = CT.base
    f:SetPoint("CENTER")
    f:SetSize(350, 556)

    local backdrop = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tileSize = 32,
    edgeSize = 16,}

    f:SetBackdrop(backdrop)
    f:SetBackdropColor(0.15, 0.15, 0.15, 1)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)

    f:EnableMouse(true)
    f:EnableKeyboard(true)
    f:SetResizable(true)
    f:SetUserPlaced(true)

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
  end

  local close = f.closeButton
  if not close then -- Close button
    f.closeButton = CreateFrame("Button", nil, f)
    close = f.closeButton
    f.closeButton:SetSize(40, 40)
    f.closeButton:SetPoint("TOPRIGHT", -10, -10)
    f.closeButton:SetNormalTexture("Interface\\RaidFrame\\ReadyCheck-NotReady.png")
    f.closeButton:SetHighlightTexture("Interface\\RaidFrame\\ReadyCheck-NotReady.png")

    f.closeButton.BG = f.closeButton:CreateTexture(nil, "BORDER")
    f.closeButton.BG:SetAllPoints()
    f.closeButton.BG:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
    f.closeButton.BG:SetVertexColor(0, 0, 0, 0.3)

    f.closeButton:SetScript("OnClick", function()
      CT.base:Hide()
    end)

    f.closeButton:SetScript("OnEnter", function(self)
      self.info = "Closes Combat Tracker, but it will still be recording CT.current.\n\nType /ct in chat to open it again. Type /ct help to see a full list of chat commands."

      CT.createInfoTooltip(self, "Close", nil, nil, nil, nil)
    end)

    f.closeButton:SetScript("OnLeave", function()
      CT.createInfoTooltip()
    end)
  end

  local dragger = f.dragger
  if not dragger then -- Main size dragger
    f:SetMaxResize(350, 700)
    f:SetMinResize(350, 556)

    f.dragger = CreateFrame("Button", nil, f)
    dragger = f.dragger

    f.dragger:SetSize(20, 20)
    f.dragger:SetPoint("BOTTOMRIGHT", -1, 2)
    f.dragger:SetNormalTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Up.png")
    f.dragger:SetPushedTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Down.png")
    f.dragger:SetHighlightTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Highlight.png")

    -- NOTE: Need to get resolution properly
    f.dragger:SetScript("OnMouseDown", function(self)
      CT.base:StartSizing()

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
      -- local mouseX, mouseY = GetCursorPosition()
      -- local mouseX = (mouseX / UIScale)
      -- local mouseY = (mouseY / UIScale)
      --
        -- if (mouseX > startX) or (mouseY < startY) then -- Increasing Scale
        --   local valX = (mouseX - startX) / resolutionX
        --   local valY = (startY - mouseY) / resolutionY
        --
        --   local maxVal = max(valX, valY)
        --   local newScale = startScale + maxVal
        --
        --   CT.base:SetScale(newScale)
        -- else -- Decreasing Scale
        --   local valX = (mouseX - startX) / resolutionX
        --   local valY = (startY - mouseY) / resolutionY
        --
        --   local minVal = min(valX, valY)
        --   local newScale = startScale + minVal
        --
        --   CT.base:SetScale(newScale)
        -- end
      -- end)
    end)

    f.dragger:SetScript("OnMouseUp", function(self)
      CT.base:StopMovingOrSizing()

      -- self.ticker:Cancel()
    end)
  end

  local scrollFrame = CT.scrollFrame
  if not scrollFrame then -- Scroll Frame, Main Content Frame, and Scroll Bar
    CT.scrollFrame = CreateFrame("ScrollFrame", "CT_ScrollFrame", CT.base)
    scrollFrame = CT.scrollFrame

    CT.scrollFrame:SetPoint("TOPLEFT", 25, -88)
    CT.scrollFrame:SetPoint("BOTTOMRIGHT", -25, 53)

    CT.scrollBar = CreateFrame("Slider", "CT_ScrollBar", CT.scrollFrame, "UIPanelScrollBarTemplate")
    CT.scrollBar:SetPoint("TOPRIGHT", CT.scrollFrame, 20, 0)
    CT.scrollBar:SetPoint("BOTTOMRIGHT", CT.scrollFrame, 20, 0)
    CT.scrollBar.background = CT.scrollBar:CreateTexture("CT_ScrollBarBackground", "BACKGROUND")
    CT.scrollBar.background:SetTexture("Interface\\addons\\CombatTracker\\Media\\ScrollBG.tga")
    CT.scrollBar.background:SetAllPoints()
    CT.scrollBar.thumbTexture = CT.scrollBar:CreateTexture("CT_ScrollBarThumbTexture")
    CT.scrollBar.thumbTexture:SetTexture("Interface\\addons\\CombatTracker\\Media\\ThumbSlider.tga")
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

  do -- Popup button
    local width = f:GetWidth()

    f.bottomExpander = CreateFrame("Button", "CT_Base_Expander_Button", f)
    local expander = f.bottomExpander

    do -- Basic textures and stuff
      local button = expander

      button.background = button:CreateTexture(nil, "BACKGROUND")
      button.background:SetPoint("TOPLEFT", button, 4.5, -4)
      button.background:SetPoint("BOTTOMRIGHT", button, -4, 3)
      button.background:SetTexture(0.07, 0.07, 0.07, 1.0)

      button.upArrow = button:CreateTexture(nil, "ARTWORK")
      button.upArrow:SetTexture("Interface/BUTTONS/Arrow-Up-Up.png") -- "Interface/BUTTONS/Arrow-Up-Down.png"
      button.upArrow:SetSize(16, 16)
      button.upArrow:SetPoint("CENTER", 0, 0)

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

      button.pushed = button:CreateTexture(nil, "BACKGROUND")
      button.pushed:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
      button.pushed:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
      button.pushed:SetAllPoints(button)
      button:SetPushedTexture(button.pushed)
    end

    expander:SetSize(width - 40, 15)
    expander:SetPoint("BOTTOM", f, 0, 7)

    expander:SetScript("OnEnter", function(self)
      self:Click()
    end)

    expander:SetScript("OnClick", function(self, button)
      if not self.popup then
        self.popup = CreateFrame("Frame", nil, self)
        self.popup:SetFrameStrata("HIGH")
        self.popup:SetSize(width - 10, 120)
        self.popup:SetPoint("BOTTOM", self, 0, 0)
        self.popup.bg = self.popup:CreateTexture(nil, "BACKGROUND")
        self.popup.bg:SetAllPoints()
        self.popup.bg:SetTexture(0.05, 0.05, 0.05, 1.0)
        self.popup:Hide()

        self.popup:SetScript("OnMouseUp", function(popup)
          popup:Hide()
        end)

        self.popup:SetScript("OnShow", function(popup)
          self.popup.exitTime = GetTime() + 0.5

          if not self.popup.ticker then
            self.popup.ticker = C_Timer.NewTicker(0.1, function(ticker)
              if not MouseIsOver(self.popup) and not MouseIsOver(self) then
                if GetTime() > self.popup.exitTime then
                  self.popup:Hide()
                  self.popup.ticker:Cancel()
                  self.popup.ticker = nil
                end
              else
                self.popup.exitTime = GetTime() + 0.5
              end
            end)
          end
        end)
      end

      local animation = self.animation
      if not animation then
        self.animation = self:CreateAnimationGroup()

        local a = self.animation:CreateAnimation("Scale")
        a:SetDuration(0.05)
        -- self.a.scale:SetSmoothing("OUT")
        a:SetOrigin("BOTTOM", 0, 0)
        -- self.a.scale:SetScale(0.3, 0.3)
        a:SetFromScale(1, 0)
        a:SetToScale(1, 1)
        -- self.popup.animation.scale:SetScale(xFactor, yFactor)

        local b = self.animation:CreateAnimation("Alpha")
        b:SetDuration(0.05)
        b:SetFromAlpha(0)
        b:SetToAlpha(1)
      end

      self.animation:Play()

      if self.popup:IsShown() then
        self.popup:Hide()
      else
        local popup = createMenuButtons(self.popup)

        if not popup[1].func then
          popup[1].title:SetText("Load Saved Fight")

          local count = 0
          popup[1].func = function(self, button)
            count = count + 1

            if count == 1 then
              local _, specName = GetSpecializationInfo(GetSpecialization())

              CT.createSavedSetButtons(CombatTrackerCharDB[specName].sets)
              popup[1].title:SetText("Return")
            else
              CT.createSpecDataButtons()
              popup[1].title:SetText("Load Saved Fight")

              count = 0
            end
          end
        end

        if not popup[2].func then
          if not profile then
            popup[2].title:SetText("Expand Frame")
          else
            popup[2].title:SetText("Profile Code")
          end

          popup[2].func = function(popup, button)
            if not profile then
              CT:expanderFrame()
            else
              profileCode()
            end
          end
        end

        if not popup[3].func then
          popup[3].title:SetText("Reset Data")

          popup[3].func = function(popup, button)
            CT.resetData(button)
          end
        end

        if not popup[4].func then
          popup[4].title:SetText("Options\n(but not really)")

          popup[4].func = function(f, button)
            popup[4].title:SetText("Umm, you don't need options, everything is perfect the way it is.")

            C_Timer.After(5, function()
              popup[4].title:SetText("(But seriously, they're on my to-do list. I promise.)")

              C_Timer.After(5, function()
                popup[4].title:SetText("Options\n(but not really)")
              end)
            end)
          end
        end

        self.popup:Show()
      end
    end)
  end

  do -- Combat Tracker Title Text
    f.title = f:CreateFontString(nil, "ARTWORK")
    f.title:SetPoint("TOPLEFT", f, 15, -10)
    f.title:SetFont("Fonts\\FRIZQT__.TTF", 30)
    f.title:SetTextColor(0.8, 0.8, 0, 1)
    f.title:SetShadowOffset(3, -3)
    f.title:SetText("Combat \n  Tracker")
  end

  tinsert(UISpecialFrames, CT.base:GetName())
end
--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------
function CT:arrowClick(direction)
  local button = self
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
  if CT.tracking then
    CT.stopTracking()
  end

  CT:saveFunction()
end

function CT:saveFunction(key, value)
  -- self.db.char[key] = value
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

SLASH_CombatTracker1 = "/ct"
function SlashCmdList.CombatTracker(msg, editbox)
  local direction, offSet = msg:match("([xXyY])([+-]?%d+)")
  if direction then direction = direction:lower() end
  local command, rest = msg:match("^(%S*)%s*(.-)$"):lower()

  if command == "toggle" or command == "" then
    if CT.base then -- It's already created
      if not CT.base:IsVisible() then
        CT.base:Show()
      else
        CT.base:Hide()
      end
    else -- Create it and then make sure it's shown
      CT:OnEnable("load")
      CT.base:Show()
    end
  elseif command == "show" then
    if not CT.base then CT:OnEnable("load") end

    CT.base:Show()
  elseif command == "hide" then
    if CT.base then CT.base:Hide() end
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
