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

-- do -- Line graphs
--   graphs = {}
--   graphs.updateDelay = 0.2
--   graphs.lastUpdate = 0
--   graphs.splitAmount = 500
-- end
--
-- do -- Uptime graphs
--   uptimeGraphs = {}
--   uptimeGraphs.cooldowns = {}
--   uptimeGraphs.buffs = {}
--   uptimeGraphs.debuffs = {}
--   uptimeGraphs.misc = {}
--   uptimeGraphs.categories = {
--     uptimeGraphs.cooldowns,
--     uptimeGraphs.buffs,
--     uptimeGraphs.debuffs,
--     uptimeGraphs.misc,
--   }
-- end

CT.loadSpellData = false
local temp = {}
local combatevents = CT.combatevents
local lastMouseoverButton
local buttonClickNum = 7
local testMode = true
-- local start = debugprofilestop() / 1000
-- print((debugprofilestop() / 1000) - start)

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
  colors.blue = {0.08, 0.38, 0.91, 1.0}
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
local function updateHandler(self, elapsed) -- Dedicated function to avoid creating the throwaway function every update
  local time = GetTime()
  CT.currentTime = time

  local timer = 0
  if CT.combatStart then
    timer = (CT.combatStop or time) - CT.combatStart
  end

  if CT.current then CT.current.fightLength = timer end

  CT.combatTimer = timer
  CT.lastTick = elapsed

  if CT.shown and CT.displayed then -- All updates to displayed data go in here
    if CT.forceUpdate or time >= (self.lastNormalUpdate or 0) then
      for i = 1, #CT.update do -- Update drop down menus or expanders
        local self = CT.update[i]

        if self.expanded and CT.base.expander.shown and self.expanderUpdate then
          self:expanderUpdate(time, timer)
        else
          self:update(time, timer)
        end
      end

      if CT.base.expander then --  and (CT.base.expander.shown or CT.forceUpdate)
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
      local graphs = CT.current.temp.graphs
      -- local uptimeGraphs = CT.current.uptimeGraphs

      if (time >= graphs.lastUpdate or 0) or CT.forceUpdate then -- Take line graph points every graphs.lastUpdate seconds
        for i = 1, #CT.graphList do graphs[CT.graphList[i]].update(timer) end

        graphs.lastUpdate = time + graphs.updateDelay
      end

      -- local uptimeGraphs = CT.current.uptimeGraphs
      -- local graphs = CT.current.graphs
    --
      -- if (time >= graphs.lastUpdate) or CT.forceUpdate then -- Take line graph points every graphs.lastUpdate seconds
      --   self.graphUpdate(time, timer)
      --
      --   graphs.lastUpdate = time + graphs.updateDelay
      -- end
    --
    --   if CT.forceUpdate or time >= (self.lastUptimeGraphUpdate or 0) then -- Update uptime graphs
    --     self.uptimeGraphsUpdate(time, timer)
    --
    --     self.lastUptimeGraphUpdate = time + 0.05
    --   end
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
-- On Initialize
--------------------------------------------------------------------------------
function CT:OnInitialize()
  -- self.db = LibStub("AceDB-3.0"):New("CombatTrackerDB")
  -- self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")
  -- self.db = LibStub("AceDB-3.0"):New("CombatTrackerCharDB")
  -- self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")

  -- local _, _, _, _, _, id = strsplit("-", destGUID) -- NOTE: Might be handy

  CT.eventFrame = CreateFrame("Frame")
  local eventFrame = CT.eventFrame

  do -- Register events
    local events = {
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
    if event == "UNIT_SPELLCAST_SENT" then -- Let this pass even if not tracking to allow for early combat detection
      combatevents[event](...)
    elseif CT.tracking and combatevents[event] then
      if not CT.current then return end
      combatevents[event](...)
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
      if not CT.current then return end
      if not CT.tracking then
        local _, event, _, srcGUID, srcName = ...

        if srcName == CT.current.name and event == "SPELL_AURA_APPLIED" then
          -- print(event, GetTime())

          C_Timer.After(0, function()
            -- print(event, GetTime())
          end)
          -- print("Ignoring:", event)
        end
      else
        local _, event = ...
        if combatevents[event] then
          combatevents[event](...)
        end
      end
    elseif event == "PLAYER_LOGIN" then
      eventFrame:UnregisterEvent("PLAYER_LOGIN")
      CT.player.loggedIn = true

      -- local preGC = collectgarbage("count")
      -- collectgarbage("collect")
      -- local num = (preGC - collectgarbage("count")) / 1000
      -- print("Collected " .. CT.round(num, 3) .. " MB of garbage")

      if testMode then
        -- CT.startTracking()

        C_Timer.After(1.0, function()
          if CT.mainButtons[buttonClickNum] then
            CT.mainButtons[buttonClickNum]:Click("LeftButton")
          elseif CT.mainButtons[1] then
            CT.mainButtons[#CT.mainButtons]:Click("LeftButton")
          end
        end)
      else
        C_Timer.After(1.0, function()
          if CT.mainButtons[buttonClickNum] then
            CT.mainButtons[buttonClickNum]:Click("LeftButton")
          elseif CT.mainButtons[1] then
            CT.mainButtons[#CT.mainButtons]:Click("LeftButton")
          end
        end)

        CT.base:Hide()
      end

      CT.startTracking()
    elseif event == "PLAYER_LOGOUT" then
      -- CT.cleanSetsTable()
      CombatTrackerCharDB[CT.player.specName].sets.current = nil
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
        -- CT:Print(event)
        -- CT.cycleMainButtons()
      end
    elseif event == "PLAYER_REGEN_DISABLED" then -- Start Combat
      CT.startTracking()
    elseif event == "PLAYER_REGEN_ENABLED" then -- Stop Combat
      CT.stopTracking()
    elseif event == "PLAYER_TALENT_UPDATE" then
      if IsLoggedIn() then
        CT.getPlayerDetails()
      end
    elseif event == "PLAYER_ALIVE" then
      CT.player.alive = true
    elseif event == "PLAYER_DEAD" then
      CT.player.alive = false
    elseif event == "UPDATE_SHAPESHIFT_FORMS" then
      -- print(event)
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
      -- print(event, ...)
    elseif event == "UNIT_PET" then
      local petName = GetUnitName("pet", false)
      if petName then
        if CT.current.pet then wipe(CT.current.pet) else CT.current.pet = {} end
        if CT.current.pet.damage then wipe(CT.current.pet.damage) else CT.current.pet.damage = {} end
        CT.current.pet.name = petName

        if petName then
          CT.addLineGraph("Total Damage", {"DPS", 100}, colors.orange, -200, 10000) -- Total damage (player + pet)

          CT.addLineGraph("Pet Damage", {"DPS", 100}, colors.lightgrey, -200, 10000) -- Pet Damage
        end
      else
        if graphs["Total Damage"] then
          graphs["Total Damage"].hideButton = true
        end

        if graphs["Pet Damage"] then
          graphs["Pet Damage"].hideButton = true
        end
      end
    elseif event == "UNIT_FLAGS" then
      if ... == "player" then
        local inCombat = InCombatLockdown()
        -- print(GetTime(), inCombat)
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

  eventFrame:SetScript("OnEvent", eventHandler)
end

function CT:OnEnable()
  local _, specName = GetSpecializationInfo(GetSpecialization())

  if not CombatTrackerDB then CombatTrackerDB = {} end
  if not CombatTrackerCharDB then CombatTrackerCharDB = {} end
  -- wipe(CombatTrackerCharDB)
  if not CombatTrackerCharDB[specName] then CombatTrackerCharDB[specName] = {} end
  if not CombatTrackerCharDB[specName].sets then CombatTrackerCharDB[specName].sets = {} end
  -- if not CombatTrackerCharDB[specName].sets.current then CombatTrackerCharDB[specName].sets.current = {} end

  CT.setDB = CombatTrackerCharDB[specName].sets
  -- CT.current = CombatTrackerCharDB[specName].sets.current

  -- CT.setBasicData()

  CT.getPlayerDetails()
  CT.createMainButtons()
  CT.setButtonAnchors()
  CT.scrollFrameUpdate()

  -- CT.showLastFight()
end

function CT:OnDisable()
  -- CT.current = nil
  -- CT:Print("CT Disable")
end
--------------------------------------------------------------------------------
-- Main Button Functions
--------------------------------------------------------------------------------
local profile = false
local function profileCode()
  local start = debugprofilestop()

  local t = {}
  local func = CT.mainUpdate.graphUpdate
  local time = GetTime()
  -- local timer = time - CT.combatStart
  local data = CT.current
  local infinity = math.huge
  local self = graphs[1]

  local function callback()

  end

  -- local loop = 100 -- 100
  -- local loop = 10000 -- 10 thousand
  -- local loop = 100000 -- 100 thousand
  local loop = 500000 -- 500 thousand
  -- local loop = 1000000 -- 1 million
  -- local loop = 10000000 -- 10 million
  -- local loop = 100000000 -- 100 million
  for i = 1, loop do
    -- C_Timer.NewTicker(0.1, callback, 1)

    -- C_Timer.After(0, testFunc)

    -- C_Timer.After(0, function()
    --
    -- end)
  end

  local MS = debugprofilestop() - start

  local MSper = (MS / loop)

  CT:Print("Time: \nMS:", MS, "\nIn 1 MS:", CT.round(1 / MSper, 1), "\n")

  C_Timer.After(1.0, function()
    local preGC = collectgarbage("count")
    collectgarbage("collect")
    local KB = (preGC-collectgarbage("count"))

    local MB = KB / 1000
    local KBper = KB / loop

    CT:Print("Garbage: \nMB:", CT.round(MB, 3), "\nNeeded for 1 KB:", CT.round(1 / KBper, 5))
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

local function addUptimeGraphDropDownButtons(parent)
  local texture, text
  local uptimeGraphs = CT.current.uptimeGraphs

  if not parent then parent = CT.base.expander.uptimeGraphButton.popup end

  for i, v in ipairs(uptimeGraphs.categories) do
    if not parent[v] and #v > 0 then
      parent[v] = parent:CreateTexture(nil, "ARTWORK")
      texture = parent[v]
      texture:SetTexture(0.1, 0.1, 0.1, 1.0)

      if not parent.prevTexture then
        texture:SetPoint("TOP", parent, 0, 0)
      else
        texture:SetPoint("TOP", parent.prevTexture, "BOTTOM", 0, 0)
      end

      if v == uptimeGraphs.cooldowns then
        text = "Cooldown:"
      elseif v == uptimeGraphs.buffs then
        text = "Buffs:"
      elseif v == uptimeGraphs.debuffs then
        text = "Debuffs:"
      elseif v == uptimeGraphs.misc then
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
    else
      texture = parent[v]
    end

    for i = 1, #v do
      local self = v[i]

      if not texture[i] then
        texture[i] = CreateFrame("CheckButton", nil, parent)
        local b = texture[i]
        b:SetSize(parent:GetWidth() - 5, 20)
        b:SetPoint("TOP", texture, 0, i * -20)
        parent.height = (parent.height or 0) + b:GetHeight()
        texture[i].height = (texture[i].height or 0) + 20

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
          CT.toggleUptimeGraph(self)
        end)
      end

      if self.shown then
        texture[i]:SetChecked(true)
      else
        texture[i]:SetChecked(false)
      end

      if self.color then
        texture[i].title:SetTextColor(self.color[1], self.color[2], self.color[3], self.color[4])
      end
    end

    if texture then
      texture:SetSize(parent:GetWidth(), (#v * 20) + 25)
    end
  end

  parent:SetHeight(parent.height)
end

local function addGraphDropDownButtons(parent)
  for i, name in ipairs(CT.graphList) do
    local self = CT.displayed.temp.graphs[name]

    if not parent[i] then
      parent[i] = CreateFrame("CheckButton", nil, parent)
      local b = parent[i]
      b:SetSize(parent:GetWidth() - 20, 20)
      b:SetPoint("TOP", 0, i * -20)

      parent.height = (parent.height or 0) + 20

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
        if self.color then
          b.title:SetTextColor(self.color[1], self.color[2], self.color[3], self.color[4])
        else
          b.title:SetTextColor(0.93, 0.86, 0.01, 1.0)
        end
        b.title:SetText(self.name)
      end

      b:SetScript("OnClick", function()
        local text = CT.base.expander.graph.titleText

        if b:GetChecked() then -- Show graph
          self:toggle()
          self:refresh()
          -- CT.showLineGraph(self)
        else -- Hide graph
          -- CT.hideLineGraphs(self)
          self:toggle()
        end
      end)
    end

    if self.shown then
      parent[i]:SetChecked(true)
    else
      parent[i]:SetChecked(false)
    end

    if self.hideButton and parent[i]:IsShown() then
      parent[i]:Hide()
      parent.height = parent.height - 20
    elseif not parent[i]:IsShown() then
      parent[i]:Show()
      parent.height = (parent.height or 0) + 20
    end
  end

  parent:SetHeight(25 + parent.height)
end

local function findInfoText(s, name, spellID, powerIndex)
  if not CT.current then return end
  local spell = CT.current.spells[spellID]
  local power = CT.current.power[powerIndex]

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
    if spell then
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

  if s == "Holy Shock" then
    return ""
  elseif s == "Crusader Strike" then
    return ""
  elseif s == "Explosive Shot" then
    return ""
  elseif s == "Black Arrow" then
    return ""
  elseif s == "Chimaera Shot" then
    return ""
  elseif s == "Judgment" then
    return ""
  elseif s == "Exorcism" then
    return ""
  elseif s == "All Casts" then
    return "Includes details about every spell cast you did. Mouseover each spell for more details."
  elseif s == "Cleanse" then
    return ""
  elseif s == "Light's Hammer" then
    return ""
  elseif s == "Execution Sentence" then
    return ""
  elseif s == "Holy Prism" then
    return ""
  elseif s == "Seraphim" then
    return ""
  elseif s == "Empowered Seals" then
    return ""
  elseif s == "Stance" then
    return ""
  elseif s == "Illuminated Healing" then
    return ""
  elseif s == "Stance" then
    return ""
  elseif s == "Stance" then
    return ""
  elseif s == "Stance" then
    return ""
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

local function addExpanderText(self)
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

  for i = 1, #self.lineTable do
    local lineText = self.lineTable[i]
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
    f.info = findInfoText(lineText, self.name, self.spellID, self.powerIndex)

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

    f:SetScript("OnEnter", function()
      CT.createInfoTooltip(f, lineText, self.iconTexture, nil, nil, nil)
    end)

    f:SetScript("OnLeave", function()
      CT.createInfoTooltip()
    end)

    if lineText == "" then
      f:Hide()
    end
  end
end

do -- Create Base Frame
  CT.base = CreateFrame("Frame", "CT_Base", UIParent)
  local f = CT.base
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

  do -- Close button
    f.closeButton = CreateFrame("Button", nil, f)
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

    f.closeButton:SetScript("OnEnter", function()
      f.closeButton.info = "Closes Combat Tracker, but it will still be recording CT.current.\n\nType /ct in chat to open it again. Type /ct help to see a full list of chat commands."

      CT.createInfoTooltip(f.closeButton, "Close", nil, nil, nil, nil)
    end)

    f.closeButton:SetScript("OnLeave", function()
      CT.createInfoTooltip()
    end)
  end

  do -- Main size dragger
    f:SetMaxResize(350, 700)
    f:SetMinResize(350, 556)

    f.dragger = CreateFrame("Button", nil, f)
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

  do -- Scroll Frame, Main Content Frame, and Scroll Bar
    CT.scrollFrame = CreateFrame("ScrollFrame", "CT_ScrollFrame", CT.base)
    CT.scrollFrame:SetPoint("TOPLEFT", 25, -88)
    CT.scrollFrame:SetPoint("BOTTOMRIGHT", -25, 100)

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
      local buttonFrame = f.bottom.buttonFrame
      buttonFrame:SetPoint("TOPLEFT", width, -20)
      buttonFrame:SetPoint("TOPRIGHT", -width, -20)
      buttonFrame:SetPoint("BOTTOMLEFT", width, 5)
      buttonFrame:SetPoint("BOTTOMRIGHT", -width, 5)
      buttonFrame.buttons = {}
      -- f.bottom.buttonFrame.texture = f.bottom.buttonFrame:CreateTexture(nil, "ARTWORK")
      -- f.bottom.buttonFrame.texture:SetAllPoints()
      -- f.bottom.buttonFrame.texture:SetTexture(0.05, 0.05, 0.05, 0)

      local function toggleButtons(ticker)
        local self = buttonFrame

        if self.buttons[1]:IsShown() then -- not MouseIsOver(self)
          if not MouseIsOver(self) then
            self.buttons[1]:Hide()
            self.buttons[2]:Hide()

            if self.ticker then
              self.ticker:Cancel()
              self.ticker = nil
            end
          end
        else
          self.buttons[1]:Show()
          self.buttons[2]:Show()

          if not self.ticker then
            self.ticker = C_Timer.NewTicker(0.1, toggleButtons)
          end
        end
      end

      buttonFrame:SetScript("OnEnter", toggleButtons)
      buttonFrame:SetScript("OnLeave", toggleButtons)

      do -- Button 1
        buttonFrame.buttons[1] = CreateFrame("Button", nil, f.bottom.buttonFrame)
        local b1 = buttonFrame.buttons[1]
        b1:SetSize(150, buttonFrame:GetHeight() - 10)
        b1:SetPoint("LEFT", 10, 0)
        b1:SetPoint("CENTER", 0, 0)
        -- b1:SetPoint("RIGHT", -(buttonFrame:GetWidth() / 2 + 5), 0)
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
          CT.resetData(button)
        end)

        b1:Hide()
      end

      do -- Button 2
        buttonFrame.buttons[2] = CreateFrame("Button", nil, f.bottom.buttonFrame)
        local b2 = buttonFrame.buttons[2]
        b2:SetSize(150, buttonFrame:GetHeight() - 10)
        -- b2:SetPoint("LEFT", (buttonFrame:GetWidth() / 2 + 5), 0)
        b2:SetPoint("RIGHT", -10, 0)
        b2:SetPoint("CENTER", 0, 0)
        b2.normal = b2:CreateTexture(nil, "BACKGROUND")
        -- b2.normal:SetTexture("Interface\\addons\\CombatTracker\\Media\\TestButton.png")
        -- b2.normal:SetTexture("Interface\\addons\\CombatTracker\\Media\\OptionsButtonBlueTest.tga")
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
        b2.title:SetText("Expand Frame")

        b2:SetScript("OnClick", function(self, button)
          if not profile then
            CT:expanderFrame()
          else
            profileCode()
          end
        end)

        b2:Hide()
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

  do -- Previous Fights button
    f.prevFights = CreateFrame("Button", nil, f)
    local b = CT.createSmallButton(f.prevFights)
    b:SetFrameStrata("TOOLTIP")
    b.title:SetText("Load Fight")
    b:SetPoint("LEFT", f.top.title, "TOPRIGHT", 0, -10)

    b:SetScript("OnEnter", function()
      b.info = "Load a previous fight."

      CT.createInfoTooltip(b, "Uptime Graphs", nil, nil, nil, nil)
    end)

    b:SetScript("OnLeave", function()
      CT.createInfoTooltip()
    end)

    b:SetScript("OnClick", function(self, click)
      local m = self.dropDownMenu

      if not m then
        self.dropDownMenu = CreateFrame("Frame", nil, self)
        m = self.dropDownMenu
        m:SetSize(150, 20)
        m:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0)
        m.bg = m:CreateTexture(nil, "BACKGROUND")
        m.bg:SetAllPoints()
        m.bg:SetTexture(0.05, 0.05, 0.05, 1.0)
        m:Hide()

        m:SetScript("OnShow", function()
          m.exitTime = GetTime() + 1

          if not m.ticker then
            m.ticker = C_Timer.NewTicker(0.1, function(ticker)
              if not MouseIsOver(m) and not MouseIsOver(self) then
                if GetTime() > m.exitTime then
                  m:Hide()
                  m.ticker:Cancel()
                  m.ticker = nil
                end
              else
                m.exitTime = GetTime() + 1
              end
            end)
          end
        end)
      end

      if m:IsShown() then
        m:Hide()
      else
        CT.createSetButtons(m, CT.setDB, leftClickFunc, rightClickFunc)
        m:Show()
      end
    end)
  end
end

function CT:expanderFrame()
  if CT.base.expander and CT.base.expander:IsShown() then
    CT.base.expander:Hide()
    CT.base.expander.shown = false
  elseif CT.base.expander then
    CT.base.expander:Show()
    CT.base.expander.shown = true
    if CT.tracking then
      CT.base.expander.titleData.rightText2:SetText(CT.formatTimer((CT.combatStop or GetTime()) - CT.combatStart or GetTime()))
    end

    CT.finalizeGraphLength() -- This also does a full graph refresh, and I need them to instantly refresh when it shows
  elseif not CT.base.expander then
    local f
    do -- Main Frame
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
    end

    do -- Title Background, icon, and text
      do -- Title Background
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

      f.icon = f.titleBG:CreateTexture(nil, "OVERLAY")
      f.icon:SetSize(30, 30)
      f.icon:SetPoint("LEFT", f.titleBG, 10, 0)
      f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      f.icon:SetAlpha(0.9)

      f.titleText = f.titleBG:CreateFontString(nil, "ARTWORK")
      f.titleText:SetPoint("LEFT", f.icon, "RIGHT", 5, 0)
      f.titleText:SetFont("Fonts\\FRIZQT__.TTF", 24)
      f.titleText:SetTextColor(0.8, 0.8, 0, 1)

      do -- Title Data
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

      do -- Top Row Data Text
        f.titleData.leftText1 = f.titleData:CreateFontString(nil, "ARTWORK")
        f.titleData.leftText1:SetPoint("TOPLEFT", f.titleData, 5, -5)
        f.titleData.leftText1:SetFont("Fonts\\FRIZQT__.TTF", 12)
        f.titleData.leftText1:SetTextColor(1.0, 1.0, 1.0, 1.0)
        f.titleData.leftText1:SetShadowOffset(1, -1)
        f.titleData.leftText1:SetJustifyH("LEFT")
        f.titleData.leftText1:SetText("Fight:")

        f.titleData.rightText1 = f.titleData:CreateFontString(nil, "ARTWORK")
        f.titleData.rightText1:SetPoint("LEFT", f.titleData.leftText1, "RIGHT", 0, 0)
        f.titleData.rightText1:SetPoint("RIGHT", f.titleData, -3, 0)
        f.titleData.rightText1:SetFont("Fonts\\FRIZQT__.TTF", 12)
        f.titleData.rightText1:SetTextColor(1.0, 1.0, 0.0, 1.0)
        f.titleData.rightText1:SetShadowOffset(1, -1)
        f.titleData.rightText1:SetJustifyH("RIGHT")
        f.titleData.rightText1:SetText(CT.fightName or "None")
      end

      do -- Bottom Row Data Text
        f.titleData.leftText2 = f.titleData:CreateFontString(nil, "ARTWORK")
        f.titleData.leftText2:SetPoint("BOTTOMLEFT", f.titleData, 5, 5)
        f.titleData.leftText2:SetFont("Fonts\\FRIZQT__.TTF", 12)
        f.titleData.leftText2:SetTextColor(1.0, 1.0, 1.0, 1.0)
        f.titleData.leftText2:SetShadowOffset(1, -1)
        f.titleData.leftText2:SetJustifyH("LEFT")
        f.titleData.leftText2:SetText("Length:")

        f.titleData.rightText2 = f.titleData:CreateFontString(nil, "ARTWORK")
        f.titleData.rightText2:SetPoint("LEFT", f.titleData.leftText2, "RIGHT", 0, 0)
        f.titleData.rightText2:SetPoint("RIGHT", f.titleData, -3, 0)
        f.titleData.rightText2:SetFont("Fonts\\FRIZQT__.TTF", 12)
        f.titleData.rightText2:SetTextColor(1.0, 1.0, 0.0, 1.0)
        f.titleData.rightText2:SetShadowOffset(1, -1)
        f.titleData.rightText2:SetJustifyH("RIGHT")
      end
    end

    do -- Data Frames
      f.dataFrames = {}
      f.spellFrames = {}
      f.textData = {}
      f.textData.title = {}
      f.textData.value = {}

      do -- Data 1
        f.dataFrames[1] = f:CreateTexture(nil, "BORDER")
        f.dataFrames[1]:SetPoint("LEFT", f.titleBG, 0, 0)
        f.dataFrames[1]:SetPoint("RIGHT", f, -(f:GetWidth() / 2) - 5, 0)
        f.dataFrames[1]:SetPoint("TOP", f.titleBG, "BOTTOM", 0, -10)
        f.dataFrames[1]:SetTexture(0.1, 0.1, 0.1, 1)
        f.dataFrames[1]:SetHeight(100)
      end

      do -- Data 2
        f.dataFrames[2] = f:CreateTexture(nil, "BORDER")
        f.dataFrames[2]:SetPoint("LEFT", f, (f:GetWidth() / 2) + 5, 0)
        f.dataFrames[2]:SetPoint("RIGHT", f.titleData, 0, 0)
        f.dataFrames[2]:SetPoint("TOP", f.titleData, "BOTTOM", 0, -10)
        f.dataFrames[2]:SetTexture(0.1, 0.1, 0.1, 1)
        f.dataFrames[2]:SetHeight(100)
      end

      do -- Data 3
        f.dataFrames[3] = f:CreateTexture(nil, "BORDER")
        f.dataFrames[3]:SetPoint("LEFT", f.dataFrames[1], 0, 0)
        f.dataFrames[3]:SetPoint("RIGHT", f.dataFrames[1], 0, 0)
        f.dataFrames[3]:SetPoint("TOP", f.dataFrames[1], "BOTTOM", 0, -10)
        f.dataFrames[3]:SetTexture(0.1, 0.1, 0.1, 1)
        f.dataFrames[3]:SetHeight(100)
      end

      do -- Data 4
        f.dataFrames[4] = f:CreateTexture(nil, "BORDER")
        f.dataFrames[4]:SetPoint("LEFT", f.dataFrames[2], 0, 0)
        f.dataFrames[4]:SetPoint("RIGHT", f.dataFrames[2], 0, 0)
        f.dataFrames[4]:SetPoint("TOP", f.dataFrames[2], "BOTTOM", 0, -10)
        f.dataFrames[4]:SetTexture(0.1, 0.1, 0.1, 1)
        f.dataFrames[4]:SetHeight(100)
      end
    end

    do -- Uptime Graph
      f.uptimeGraphBG = f:CreateTexture(nil, "BORDER")
      f.uptimeGraphBG:SetPoint("LEFT", f.dataFrames[3], 0, 0)
      f.uptimeGraphBG:SetPoint("RIGHT", f.dataFrames[4], 0, 0)
      f.uptimeGraphBG:SetPoint("TOP", f.dataFrames[4], "BOTTOM", 0, -10)
      f.uptimeGraphBG:SetTexture(0.1, 0.1, 0.1, 1)
      f.uptimeGraphBG:SetHeight(20)
      f.uptimeGraphBG.height = 20

      local uptimeGraph = CT.buildUptimeGraph(f, f.uptimeGraphBG)

      uptimeGraph.titleText = uptimeGraph:CreateFontString(nil, "ARTWORK")
      uptimeGraph.titleText:SetPoint("BOTTOMLEFT", uptimeGraph, "TOPLEFT", 2, 4)
      uptimeGraph.titleText:SetFont("Fonts\\FRIZQT__.TTF", 12)
      uptimeGraph.titleText:SetTextColor(1, 1, 1, 1)
      uptimeGraph.titleText:SetJustifyH("LEFT")
      uptimeGraph.titleText:SetText("Current Graph: ")
      uptimeGraph.titleText.default = "Current Graph: "

      local b
      do
        f.uptimeGraphButton = CreateFrame("Button", nil, uptimeGraph)
        b = f.uptimeGraphButton
        b:SetSize(90, 20)
        b:SetPoint("TOPRIGHT", f.uptimeGraphBG, -1, 1)

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
        b.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
        b.title:SetTextColor(0.93, 0.86, 0.01, 1.0)
        b.title:SetText("Select Graph")
      end

      b:SetScript("OnEnter", function()
        b.info = "Select an uptime graph from the list."

        CT.createInfoTooltip(b, "Uptime Graphs", nil, nil, nil, nil)
      end)

      b:SetScript("OnLeave", function()
        CT.createInfoTooltip()
      end)

      b:SetScript("OnClick", function(button, click)
        if not b.popup then
          b.popup = CreateFrame("Frame", nil, b)
          b.popup:SetSize(150, 20)
          b.popup:SetPoint("TOPLEFT", b, "TOPRIGHT", 0, 0)
          b.popup.bg = b.popup:CreateTexture(nil, "BACKGROUND")
          b.popup.bg:SetAllPoints()
          b.popup.bg:SetTexture(0.05, 0.05, 0.05, 1.0)
          b.popup:Hide()

          b.popup:SetScript("OnShow", function()
            b.popup.exitTime = GetTime() + 1

            if not b.popup.ticker then
              b.popup.ticker = C_Timer.NewTicker(0.1, function(ticker)
                if not MouseIsOver(b.popup) and not MouseIsOver(b) then
                  if GetTime() > b.popup.exitTime then
                    b.popup:Hide()
                    b.popup.ticker:Cancel()
                    b.popup.ticker = nil
                  end
                else
                  b.popup.exitTime = GetTime() + 1
                end
              end)
            end
          end)
        end

        if b.popup:IsShown() then
          b.popup:Hide()
        else
          addUptimeGraphDropDownButtons(b.popup)
          b.popup:Show()
        end
      end)
    end

    do -- Main Graph
      f.mainUptimeGraph = f:CreateTexture(nil, "ARTWORK")
      f.mainUptimeGraph:SetPoint("LEFT", f.uptimeGraphBG, 0, 0)
      f.mainUptimeGraph:SetPoint("RIGHT", f.uptimeGraphBG, 0, 0)
      f.mainUptimeGraph:SetPoint("TOP", f.uptimeGraphBG, "BOTTOM", 0, -10)
      f.mainUptimeGraph:SetPoint("BOTTOM", f, 0, 10)
      f.mainUptimeGraph:SetTexture(0.1, 0.1, 0.1, 1)

      CT.buildGraph(f)

      local graph = f.graph
      graph:ClearAllPoints()
      graph:SetParent(f)
      graph:SetPoint("LEFT", f.mainUptimeGraph, 0, 0)
      graph:SetPoint("RIGHT", f.mainUptimeGraph, 0, 0)
      graph:SetPoint("TOP", f.mainUptimeGraph, 0, -20)
      graph:SetPoint("BOTTOM", f.mainUptimeGraph, 0, 0)

      graph.titleText = graph:CreateFontString(nil, "ARTWORK")
      graph.titleText:SetPoint("BOTTOMLEFT", graph, "TOPLEFT", 2, 4)
      graph.titleText:SetFont("Fonts\\FRIZQT__.TTF", 12)
      graph.titleText:SetTextColor(1, 1, 1, 1)
      graph.titleText:SetJustifyH("LEFT")
      graph.titleText:SetText("Currently Displayed: ")
      graph.titleText.default = "Currently Displayed: "

      local b
      do
        f.mainGraphButton = CreateFrame("Button", nil, graph)
        b = f.mainGraphButton
        b:SetSize(90, 20)
        b:SetPoint("BOTTOMRIGHT", graph, "TOPRIGHT", -1, 1)

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
        b.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
        b.title:SetTextColor(0.93, 0.86, 0.01, 1.0)
        b.title:SetText("Select Graph")

        b.popup = CreateFrame("Frame", "DropDownFrameMiddleBar", b)
        b.popup:SetSize(150, 20)
        b.popup:SetPoint("TOPLEFT", b, "TOPRIGHT", 0, 0)
        b.popup.bg = b.popup:CreateTexture(nil, "BACKGROUND")
        b.popup.bg:SetAllPoints()
        b.popup.bg:SetTexture(0.1, 0.1, 0.1, 1.0)

        b.popup.title = b.popup:CreateFontString(nil, "ARTWORK")
        b.popup.title:SetPoint("TOP", b.popup, 0, -1)
        b.popup.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
        b.popup.title:SetTextColor(1, 1, 1, 1)
        b.popup.title:SetText("Graphs:")
        b.popup:Hide()
      end

      b:SetScript("OnEnter", function()
        b.info = "Select a normal graph from the list."

        CT.createInfoTooltip(b, "Normal Graphs", nil, nil, nil, nil)
      end)

      b:SetScript("OnLeave", function()
        CT.createInfoTooltip()
      end)

      b.popup:SetScript("OnShow", function()
        b.popup.exitTime = GetTime() + 1

        if not b.popup.ticker then
          b.popup.ticker = C_Timer.NewTicker(0.1, function(ticker)
            if not MouseIsOver(b.popup) and not MouseIsOver(b) then
              if GetTime() > b.popup.exitTime then
                b.popup:Hide()
                b.popup.ticker:Cancel()
                b.popup.ticker = nil
              end
            else
              b.popup.exitTime = GetTime() + 1
            end
          end)
        end
      end)
      b:SetScript("OnClick", function(button, click)
        if b.popup:IsShown() then
          b.popup:Hide()
        else
          addGraphDropDownButtons(b.popup)
          b.popup:Show()
        end
      end)
    end

    CT.base.expander.shown = true
  end
end

local function createButtonFrame(self, button)
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
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.icon:SetAlpha(0.9)
  end

  do -- Update icon texture
    if self.iconTexture then
      self.button.icon:SetTexture(self.iconTexture)
    else
      self.button.icon:SetTexture(CT.player.specIcon)
    end

    SetPortraitToTexture(self.button.icon, self.button.icon:GetTexture())
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
    self.title = button:CreateFontString(nil, "ARTWORK")
    self.title:SetPoint("LEFT", button.icon, "RIGHT", 10, 0)
    self.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
    self.title:SetTextColor(1, 1, 0, 1)
    self.title:SetText(self.name)

    self.value = button:CreateFontString(nil, "ARTWORK")
    self.value:SetPoint("RIGHT", button, -13, 0)
    self.value:SetFont("Fonts\\FRIZQT__.TTF", 22)
    self.value:SetTextColor(1, 1, 0, 1)
  end

  do -- Button Scripts
    local lastClickTime = GetTime()
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(button, click)
      if GetTime() > lastClickTime then
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:expanderToggle(click)

        local time = GetTime()
        local timer
        if CT.combatStart then
          timer = (CT.combatStop or time) - CT.combatStart
        else
          timer = 0
        end

        if CT.current then
          if self.expanded and self.expanderUpdate then
            self:expanderUpdate(time, timer)
          elseif self.shown and self.update then
            self:update(time, timer)
          end
        end

        lastClickTime = GetTime() + 0.1
      end
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
end

function CT.createMainButtons()
  for i = 1, #CT.specData do
    local self = CT.buttons[i]

    if not self then
      self = {}
      setmetatable(self, CT)
      CT.buttons[i] = self
      local specData = CT.specData[i]

      self.button = CreateFrame("Button", "MainButton" .. i, CT.contentFrame)
      self.name = specData.name
      self.num = i
      self.powerIndex = specData.powerIndex
      self.update = specData.func
      self.expanderUpdate = specData.expanderFunc
      self.dropDownFunc = specData.dropDownFunc
      self.lineTable = specData.lines
      self.costsPower = specData.costsPower
      self.givesPower = specData.givesPower
      self.spellID = specData.spellID or select(7, GetSpellInfo(self.name))
      self.iconTexture = specData.icon or GetSpellTexture(self.spellID) or GetSpellTexture(self.name) or CT.player.specIcon
      self.graphUpdateDelay = 0
      self.text = {}
      self.expanded = false
      self.expandedDown = false

      CT.mainButtons[i] = self.button
      CT.mainButtons[i].self = self
      self.button.name = name
      self.button.num = i

      createButtonFrame(self, self.button)
      tinsert(CT.update, self)
    end
  end

  if CT.buttons[1] then
    if not CT.topAnchor1 then CT.topAnchor1 = {CT.buttons[1].button:GetPoint(1)} end
    if not CT.topAnchor2 then CT.topAnchor2 = {CT.buttons[1].button:GetPoint(2)} end
  end

  CT.totalNumButtons = #CT.specData
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

function CT:expandedMenu()
  local f = CT.base.expander
  f.icon:SetTexture(self.iconTexture or CT.player.specIcon)
  SetPortraitToTexture(f.icon, f.icon:GetTexture())

  f.titleText:SetText(self.name)

  addExpanderText(self)

  local buttonName = self.name

  if CT.current then
    CT.hideLineGraphs()
    CT.showLineGraph(nil, self.name)

    local uptimeGraphs = CT.current.uptimeGraphs
    -- local graphs = CT.current.graphs

    -- local foundGraph
    -- for index, v in ipairs(uptimeGraphs.categories) do
    --   for i = 1, #v do
    --     if v[i].name == buttonName then
    --       foundGraph = true
    --       CT.toggleUptimeGraph(v[i], true)
    --     end
    --   end
    -- end
    --
    -- if not foundGraph then
    --   for index, v in ipairs(uptimeGraphs.categories) do
    --     for i = 1, #v do
    --       if v[i].name == "Activity" then
    --         CT.toggleUptimeGraph(v[i], true)
    --       end
    --     end
    --   end
    -- end

    for i = 1, #CT.current.power do
      local power = CT.current.power[i]

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
  -- CT.forceUpdate = true
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
