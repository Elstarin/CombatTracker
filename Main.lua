--------------------------------------------------------------------------------
-- Notes and Changes
--------------------------------------------------------------------------------

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
local addonName, addon = ...

local version = GetAddOnMetadata(addonName, "Version")
local locale = GetLocale()

addon.profile = false

if addon.profile then -- profile code in here
  local infinity = math.huge
  local function round(num, decimals)
    if (num == infinity) or (num == -infinity) then num = 0 end

    if decimals == 0 then
      return ("%.0f"):format(num) + 0
    elseif decimals == 1 then
      return ("%.1f"):format(num) + 0
    elseif decimals == 2 then
      return ("%.2f"):format(num) + 0
    elseif decimals == 3 then
      return ("%.3f"):format(num) + 0
    elseif decimals == 4 then
      return ("%.4f"):format(num) + 0
    elseif decimals == 5 then
      return ("%.5f"):format(num) + 0
    elseif decimals == 6 then
      return ("%.6f"):format(num) + 0
    elseif decimals == 7 then
      return ("%.7f"):format(num) + 0
    elseif decimals == 8 then
      return ("%.8f"):format(num) + 0
    elseif decimals == 9 then
      return ("%.9f"):format(num) + 0
    elseif decimals == 10 then
      return ("%.10f"):format(num) + 0
    else -- No decimals
      return ("%.0f"):format(num) + 0
    end
  end

  local function profileCode()
    local f = CreateFrame("Frame")
    local func = nil
    local time = GetTime()

    -- local texture = f:CreateTexture(nil, "ARTWORK")

    -- local loop = 10
    -- local loop = 50
    -- local loop = 100
    -- local loop = 1000
    -- local loop = 10000 -- 10 thousand
    -- local loop = 100000 -- 100 thousand
    -- local loop = 500000 -- 500 thousand
    -- local loop = 1000000 -- 1 million
    -- local loop = 10000000 -- 10 million
    -- local loop = 100000000 -- 100 million

    local t = {}
    local start = debugprofilestop() / 1000

    local loop = loop or 1
    
    local var1, var2, var3, var4, var5 = 1, 2, 3, 4, 5
    local var6, var7, var8, var9, var10 = 1, 2, 3, 4, 5
    
    collectgarbage("collect")
    collectgarbage("setpause", 10000)
    local start = debugprofilestop()
    
    for i = 1, loop do
      
    end

    local MS = debugprofilestop() - start

    local MSper = (MS / loop)

    C_Timer.After(2 + (MS / 1000), function()
      print("Time: \nMS:", MS, "\nIn 1 MS:", round(1 / MSper, 1), "\n")
      local preGC = collectgarbage("count")
      collectgarbage("collect")
      collectgarbage("setpause", 100)
      local KB = (preGC-collectgarbage("count"))

      local MB = KB / 1000
      local KBper = KB / loop

      print("Garbage: \nMB:", round(MB, 3), "\nNeeded for 1 KB:", round(1 / KBper, 5))
    end)
  end

  C_Timer.NewTicker(0.01, function(ticker)
    if IsLoggedIn() then
      C_Timer.After(0.5, profileCode)
      ticker:Cancel()
    end
  end)

  do
    --[[ At 1m
      local t = {var1, var2, var3, var4, var5}
      TOOK: 2.7 seconds, 369 per 1 MS, 178.6 MB, 5.6 per KB
        
      local function func()
        return var1, var2, var3, var4, var5
      end
      TOOK: .959 seconds, 1042 per 1 MS, 84.6 MB, 11.8 per KB
    ]]
    
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

  return
else
  CombatTracker = LibStub("AceAddon-3.0"):NewAddon("CombatTracker", "AceConsole-3.0")
end

local CT = CombatTracker
local baseFrame = CreateFrame("Frame", "CombatTracker_Base", UIParent) -- Have to do this early so that the position will be saved
baseFrame:SetMovable(true)
baseFrame:SetFrameStrata("HIGH")
CT.__index = CT
CT.settings = {}
CT.settings.buttonSpacing = 2
CT.settings.spellCooldownThrottle = 0.0085
CT.settings.graphSmoothing = 0
CT.settings.backgroundAlpha = 0.8
CT.settings.defaultColor = {0.15, 0.15, 0.15, 1.0}
CT.combatevents = {}
CT.player = {}
CT.altPower = {}
CT.player.talents = {}
CT.mainButtons = {}
CT.shown = true
CT.activeAuras = {}
CT.buttons = {}
CT.plates = {}
CT.setButtons = {}

CT.loadSpellData = false
local temp = {}
local combatevents = CT.combatevents
local lastMouseoverButton
local buttonClickNum = 7
local testMode = false
local trackingOnLogIn = false
local loadBaseOnLogin = false
local expandBaseOnLogin = false

do
  print("Test")
end

local debugMode = false
do -- Debugging stuff
  local matched
  local start = debugprofilestop() / 1000
  local printFormat = "|cFF9E5A01(|r|cFF00CCFF%.3f|r|cFF9E5A01)|r |cFF00FF00CT|r: %s"
  local t = {}

  if GetUnitName("player") == "Elstari" and GetRealmName() == "Drak'thul" then
    debugMode = true
    -- testMode = true
    -- trackingOnLogIn = true
    -- loadBaseOnLogin = true
    -- expandBaseOnLogin = true
    matched = true
  end

  local blocked = nil
  if debugMode then
    blocked = {}
  end

  function CT.debug(...)
    if debugMode then
      wipe(t)

      for i = 1, select("#", ...) do
        local var = select(i, ...)
        local obj = type(var)
        local spellName, _, _, _, _, _, spellID = GetSpellInfo(tonumber(var) or var)
        
        if _G[var] then
          t[i] = format("|cFFFF9B00%s|r", var)
        elseif spellName and spellName:match(var) then
          t[i] = "|cFFFF00FF" .. spellName .. "|r"
        elseif var == true then
          t[i] = "|cFF4B6CD7true|r"
        elseif var == false then
          t[i] = "|cFFFF9B00false|r"
        elseif obj == "table" then
          t[i] = tostring(var):gsub("(.-)%s(.+)", "|cFF888888%1&%2|r") -- Replacing the space with an & to make sure the ID doesn't get colored later
        elseif obj == "function" then
          t[i] = tostring(var):gsub("(.-)%s(.+)", "|cFFDA70D6%1&%2|r")
        elseif obj == "userdata" then
          t[i] = tostring(var):gsub("(.-)%s(.+)", "|cFF888888%1&%2|r")
        elseif obj == "nil" then
          t[i] = "|cFFFA6022nil|r"
        elseif obj == "number" or type(tonumber(obj)) == "number" then
          t[i] = var
        elseif obj == "string" then
          t[i] = var
        end
      end

      local string = table.concat(t, ",~") .. ".~" -- The ~ lets me keep track of the different chunks while I apply colors and such, it gets removed last

      if string then
        string = string:gsub("|c(%x%x%x%x%x%x%x%x)(.-)|r", "#c%1@%2#r") -- Make color sequences visible
        
        -- string = string:gsub(":%s(.-)([%.%,%!%?%#])", ": #cFFFFCC00@%1#r%2") -- Make any letters after a: gold until next punctuation mark
        -- string = string:gsub("(%w:)(%s.-)[%.%,%!%?]", "%1#cFFFFCC00@%2#r") -- Make any letters after a: gold until next punctuation mark
        string = string:gsub("(%()(.*)(%))", "#cFF9E5A01@%1#r#cFF00CCFF@%2#r#cFF9E5A01@%3#r") -- Make ( and ) orange and anything inside them blue
        string = string:gsub("([@~%s])(%d+[%d%.%%]*)([#~%s]-)", "%1#cFF00CCFF@%2#r%3") -- Make all numbers blue, including decimals and percentage signs
        
        string = string:gsub("#c", "|c") -- Reset the colors
        string = string:gsub("#r", "|r") -- Reset the colors
        string = string:gsub("@", "")
        string = string:gsub(":&", ": ")
        string = string:gsub("~", " ")
        string = string:gsub("(%p)[%.%,]?", "%1") -- Remove the added comma or period if there already is punctuation
        
        print(printFormat:format((debugprofilestop() / 1000) - start, string))
      end
    end
  end

  if not matched then
    CT.debug("If you aren't developing this addon and you see this message,",
      "that means I, being the genius that I am, released it with debug mode enabled.",
      "\n\nYou can easily fix it by opening the Main.lua document with any text editor,",
      "and finding the line |cFF00CCFFlocal debugMode = true|r and changing the |cFF00CCFFtrue|r to |cFF00CCFFfalse|r. Sorry!")
  end
end
local debug = CT.debug

-- debug("This is a string test!", "Value is: 87% which (is a) percent", addon, addonName, version, locale, 187.9, 18, 93, "Holy Shock", "end string", strmatch)

CT.eventFrame = CreateFrame("Frame")
--------------------------------------------------------------------------------
-- Upvalues
--------------------------------------------------------------------------------
local GetSpellCooldown, GetSpellInfo, GetSpellTexture, IsUsableSpell
      = GetSpellCooldown, GetSpellInfo, GetSpellTexture, IsUsableSpell
local InCombatLockdown, GetTalentInfo, GetActiveSpecGroup
      = InCombatLockdown, GetTalentInfo, GetActiveSpecGroup
local UnitPower, UnitClass, UnitName, UnitAura
      = UnitPower, UnitClass, UnitName, UnitAura
local IsInGuild, IsInGroup, IsInInstance
      = IsInGuild, IsInGroup, IsInInstance
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, rawset, assert, pcall, error, getmetatable, setmetatable, loadstring, unpack, debugstack
      = tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, rawset, assert, pcall, error, getmetatable, setmetatable, loadstring, unpack, debugstack
local strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, strjoin, max, ceil, floor, random
      = strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, strjoin, max, ceil, floor, random
local _G, coroutine, table, GetTime, CopyTable
      = _G, coroutine, table, GetTime, CopyTable
local after, newTicker, getNumWorldFrameChildren
      = C_Timer.After, C_Timer.NewTicker, WorldFrame.GetNumChildren -- Used for finding first nameplate, it's a tiny efficiency gain

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
local plateIndex, nextPlate
local index = 2
local success = true
CT.update = {}
CT.settings.updateDelay = 0.1
CT.settings.auraUpdateDelay = 0.05
CT.settings.graphUpdateDelay = 0.2
CT.settings.uptimeGraphUpdateDelay = 0.05

CT.mainUpdate = CreateFrame("Frame")
CT.mainUpdate:SetScript("OnUpdate", function(self, elsapsed)
  if not success then
    self:SetScript("OnUpdate", nil)
    return debug("Success is false, stopping main on update engine.")
  end

  success = nil

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

      if CT.base then
        CT.base.timerText:update(CT.formatTimer(timer))
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

      self.lastAuraUpdate = time + CT.settings.auraUpdateDelay
    end

    do -- Normal graph updates
      local graphs = CT.current.graphs

      if (graphs.lastUpdate or 0) < time or CT.forceUpdate then -- Take line graph points every graphs.lastUpdate seconds
        for i = 1, #CT.graphList do
          local graph = graphs[CT.graphList[i]]

          graph:update(timer)
        end

        graphs.lastUpdate = time + CT.settings.graphUpdateDelay -- Default 0.2 seconds
      end
    end

    do -- Uptime graph updates
      if CT.forceUpdate or time >= (self.lastUptimeGraphUpdate or 0) then -- Update uptime graphs
        self.uptimeGraphsUpdate(time, timer)

        self.lastUptimeGraphUpdate = time + CT.settings.uptimeGraphUpdateDelay -- Default 0.05 seconds
      end
    end
  end

  do -- Nameplate stuff
    if plateIndex then
      while _G[nextPlate] do -- Seems to be about 23 - 24 times more efficient than doing the .. every time
        local plate = _G[nextPlate]
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
        nextPlate = "NamePlate" .. plateIndex
      end
    else
      local numChildren = getNumWorldFrameChildren(WorldFrame) -- Tiny efficiency gain to have it local, might as well since it isn't throttled

      if numChildren >= index then
        for i = index, numChildren do
          local child = select(i, WorldFrame:GetChildren())
          if child.ArtContainer and child.ArtContainer.HealthBar then -- If it has these, that should guarantee it's a nameplate
            plateIndex = child:GetName():match("^NamePlate(%d+)$") + 0
            nextPlate = "NamePlate" .. plateIndex
            break
          else -- This one isn't a nameplate, so skip it next time for a tiny bit of efficiency
            index = i + 1
          end
        end
      end
    end
  end

  if CT.forceUpdate then CT.forceUpdate = false end
  success = true -- Reached the end, in theory this means there were no errors
end)
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

CT.eventFrame:SetScript("OnEvent", function(self, event, ...)
  local timer = 0
  if CT.currentDB then
    timer = (CT.currentDB.stop or GetTime()) - CT.currentDB.start
  end

  if not CT.tracking then -- Anything that happens out of combat or related to early combat detection
    if event == "UNIT_SPELLCAST_SENT" then -- Let this pass even if not tracking to allow for early combat detection
      return combatevents[event] and combatevents[event](timer, ...)
    end
  else -- Everything that's specific to combat
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
      local _, event = ...

      if combatevents[event] then
        return combatevents[event](timer, ...)
      end
    elseif combatevents[event] then
      return combatevents[event](timer, ...)
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
      
      if expandBaseOnLogin then
        C_Timer.After(2.5, function()
          CT:toggleBaseExpansion()
        end)
      end
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
    local name, description, encounterID, rootSectionID, link = EJ_GetEncounterInfo(encounterID)
    -- local instanceName, instanceDesc, backgroundTexture, buttonTexture, titleBackground, iconTexture, mapID, instanceLink = EJ_GetInstanceInfo(instanceID)

    if not CT.current then
      debug("No current set for encounter start.")
    else
      CT.currentDB.encounterID = encounterID
      CT.currentDB.encounterName = name or encounterName
      CT.currentDB.difficultyID = difficultyID
      CT.currentDB.raidSize = raidSize
      CT.currentDB.description = description
      CT.currentDB.rootSectionID = rootSectionID
      -- CT.currentDB.link = link
    end

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
      -- CT.getPlayerDetails()
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
    if CT.current and GetTime() > (self.lastStanceUpdate or 0) then
      CT.current.stance.num = GetShapeshiftForm()
      local uptimeGraphs = CT.current.uptimeGraphs

      if CT.current.stance.num > 0 then
        local icon, name, active, castable = GetShapeshiftFormInfo(CT.current.stance.num)
        local stanceName, _, _, _, _, _, stanceID = GetSpellInfo(name)
        CT.current.stance.name = stanceName
        CT.current.stanceID = stanceID
        CT.current.stanceSwitchTime = GetTime()

        local timer = 0
        if CT.currentDB then
          timer = (CT.currentDB.stop or GetTime()) - CT.currentDB.start
        end

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

      self.lastStanceUpdate = GetTime() + 0.1
    end
  elseif event == "PET_ATTACK_START" then
    if uptimeGraphs.misc["Pet"] then
      local timer = 0
      if CT.currentDB then
        timer = (CT.currentDB.stop or GetTime()) - CT.currentDB.start
      end

      local self = uptimeGraphs.misc["Pet"]
      local num = #self.data + 1
      self.data[num] = GetTime() - CT.combatStart
      -- self.spellName[num] = stanceName -- TODO: Pet name here?

      self:refresh()
    end

    CT.current.pet.active = true
  elseif event == "PET_ATTACK_STOP" then
    if uptimeGraphs.misc["Pet"] then
      local timer = 0
      if CT.currentDB then
        timer = (CT.currentDB.stop or GetTime()) - CT.currentDB.start
      end

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
end)
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

  -- if not CombatTrackerDB then debug("Passed 1") CombatTrackerDB = {} end
  -- if not CombatTrackerCharDB then debug("Passed 2") CombatTrackerCharDB = {} end
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
    -- CT.createBaseFrame()
    -- CT.getPlayerDetails()
    -- CT.createSpecDataButtons()
    
    CT.createBaseFrame()
    
    local specData = CT.getPlayerDetails()
    
    for i = 1, #specData do
      setmetatable(specData[i], CT)
      specData[i].__index = CT
      
      specData[i]:buildNewButton(i)
    end
    
    CT.totalNumButtons = #specData
    CT.contentFrame:displayMainButtons(CT.buttons)
  end
end

function CT:OnDisable()
  -- CT.current = nil
  -- debug("CT Disable")
  -- debug("CT Disable")
end

function CT:OnDatabaseShutdown()
  if CT.tracking then
    CT.stopTracking()
  end
end
--------------------------------------------------------------------------------
-- Main Button Functions
--------------------------------------------------------------------------------
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

local function findInfoText(self, s)
  local name = self.spellName or self.name or s -- One without coloring
  local sName = self.spellName or self.name or s
  local pName = self.powerIndex and CT.powerTypesFormatted[self.powerIndex]

  local pNameColored
  if pName then
    pNameColored = CT.getPowerColor(pName) .. pName .. "|r"
  else
    for i = 0, #CT.powerTypesFormatted do -- Check if the passed name is a power type
      if CT.powerTypesFormatted[i] == s then
        pName = s
        pNameColored = CT.getPowerColor(s) .. s .. "|r"
      end
    end

    if not pName then -- Still nothing
      pName = "Unknown Power"
      pNameColored = "|cFF9E5A01Unknown Power|r"
    end
  end

  if sName then
    sName = "|cFFFFFF00" .. (self.spellName or self.name or s) .. "|r"
  else
    sName = "|cFF9E5A01Unknown Name|r"
  end

  do -- Power
    if s == pName.." Gained:" then
      return "The total amount of "..pNameColored.." generated by this spell."
    elseif s == pName.." Wasted:" then
      return "An estimate of the total "..pNameColored.." wasted. This is just from checking your default regen and the total time at max." ..
              "\n\n|cFF00FF00BETA NOTE:|r |cFF4B6CD7When your regen rate varies, this will give screwed up numbers. Making this far more accurate is on my to do list," ..
              " but there are a ton of things to do, so it may be a while.|r"
    elseif s == pName.." Spent:" then
      return "The total amount of "..pNameColored.." spent by this spell."
    elseif s == "Effective Gain:" then
      return "Total "..pNameColored.." gained minus the wasted amount."
    elseif s == "Times Capped:" then
      return "The number of different times you hit maximum "..pNameColored..".\n\nTry to avoid this, because anything you generate while at the cap goes to waste."
    elseif s == "Seconds Capped:" then
      return "The total number of seconds you spent at maximum "..pNameColored..".\n\nKeep this as low as possible, because anything generated while at max is wasted."
    end
  end

  do -- Spell
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
    elseif s == "Total Procs:" then
      return "The total number of times it procced."
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
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Crusader Strike" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Explosive Shot" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Black Arrow" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Chimaera Shot" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Judgment" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Exorcism" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "All Casts" then
    return "Includes details about every spell cast you did. Mouseover each spell for more details."
  elseif s == "Cleanse" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Light's Hammer" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Execution Sentence" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Holy Prism" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Seraphim" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Empowered Seals" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Stance" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Illuminated Healing" then
    return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
  elseif s == "Stance" then
    -- return "Includes details about every "..sName.." you cast. Mouseover each spell for more details."
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

    f.name = self.name
    f.spellName = self.spellName
    f.spellID = self.spellID
    f.powerIndex = self.powerIndex

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

      f.info = findInfoText(f, lineText)

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

      b:SetScript("OnClick", function(self, click)
        local cTime = GetTime()

        if cTime >= (popup.shownTime or 0) then -- Don't let it be clicked too soon after popping up, default 0.3 seconds
          if cTime >= (self.lastClick or 0) then -- Don't let clicks be spammed too close together, default 0.2 seconds
            b.func(self, click, cTime)

            self.lastClick = cTime + 0.2
          end
        end
      end)
    end
  end

  return popup
end

function CT:arrowClick(direction)
  local button = self
  if direction == "up" and CT.mainButtons[button.num - 1] then
    local upperButton = CT.mainButtons[button.num - 1]
    upperButton.num = button.num
    button.num = button.num - 1
    self.num = button.num
    CT.updateButtonOrderByNum()
    CT.contentFrame:setButtonAnchors()
    CT.slideButtonAnimation(upperButton, "down")
    CT.slideButtonAnimation(button, "up")
  elseif direction == "down" and CT.mainButtons[button.num + 1] then
    local lowerButton = CT.mainButtons[button.num + 1]
    lowerButton.num = button.num
    button.num = button.num + 1
    self.num = button.num
    CT.updateButtonOrderByNum()
    CT.contentFrame:setButtonAnchors()
    CT.slideButtonAnimation(lowerButton, "up")
    CT.slideButtonAnimation(button, "down")
  end
end

function CT.slideButtonAnimation(button, direction)
  if not button then return debug("No button passed for slide animation") end

  local slide = button.slide
  if not slide then
    slide = button:CreateAnimationGroup("SlideButtons")

    slide[1] = slide:CreateAnimation("Translation")
    slide[1]:SetDuration(0.0001)
    slide[1]:SetOrder(1)

    slide[2] = slide:CreateAnimation("Translation")
    slide[2]:SetDuration(0.25)
    slide[2]:SetSmoothing("OUT")
    slide[2]:SetOrder(2)

    button.slide = slide
  end

  local height = button:GetHeight()

  if direction == "up" then
    slide[1]:SetOffset(0, -height)
    slide[2]:SetOffset(0, height)
  elseif direction == "down" then
    slide[1]:SetOffset(0, height)
    slide[2]:SetOffset(0, -height)
  end

  CT.buttonSlideInProgress = true
  C_Timer.After(0.25, function()
    CT.buttonSlideInProgress = false
  end)

  slide:Play()
end

local function clickArrowUp(self, click)
  local buttons = CT.contentFrame.sourceTable

  for i = 1, #CT.contentFrame do
    local b = buttons[i]

    if b.upArrow and b.upArrow == self then
      local prevButton = buttons[i - 1]

      if prevButton then
        buttons[i - 1] = b
        buttons[i] = prevButton
        CT.contentFrame[i - 1] = b
        CT.contentFrame[i] = prevButton

        CT.contentFrame:setButtonAnchors()
        CT.slideButtonAnimation(prevButton, "down")
        CT.slideButtonAnimation(b, "up")
      end

      break
    end
  end
end

local function clickArrowDown(self, click)
  local buttons = CT.contentFrame.sourceTable

  for i = 1, #CT.contentFrame do
    local b = CT.contentFrame[i]

    if b.downArrow and b.downArrow == self then
      local nextButton = buttons[i + 1]

      if nextButton then
        buttons[i + 1] = b
        buttons[i] = nextButton
        CT.contentFrame[i + 1] = b
        CT.contentFrame[i] = nextButton

        CT.contentFrame:setButtonAnchors()
        CT.slideButtonAnimation(nextButton, "up")
        CT.slideButtonAnimation(b, "down")
      end

      break
    end
  end
end

local function dragMainButton(self, click)
  local buttons = CT.contentFrame.sourceTable
  local button = self:GetParent()

  local frameLeft = CT.contentFrame:GetLeft()
  local UIScale = UIParent:GetEffectiveScale()
  local halfButtonHeight = button:GetHeight() / 2
  local buttonLevel = button:GetFrameLevel()

  local topDistance = 0
  local bottomDistance = 0
  button.dragging = true

  button:SetSize(button:GetSize())
  local mouseDown, getCursor = IsMouseButtonDown, GetCursorPosition
  button:SetFrameLevel(buttonLevel + 3)

  button:ClearAllPoints()
  C_Timer.NewTicker(0.001, function(ticker) -- Creating a new ticker every time might be a bit wasteful, but it's convenient and shouldn't matter much overall
    if mouseDown() then
      local mouseX, mouseY = getCursor()
      local mouseY = (mouseY / UIScale) - 10

      local index, prevButton, nextButton
      CT.contentFrame:setButtonAnchors()
      for i = 1, #buttons do
        if buttons[i] == button then
          prevButton = buttons[i - 1]
          nextButton = buttons[i + 1]
          index = i

          if prevButton then prevButton:ClearAllPoints() end
          if nextButton then nextButton:ClearAllPoints() end

          break
        end
      end

      button:ClearAllPoints()
      button:SetPoint("BOTTOMLEFT", UIParent, frameLeft, mouseY)
      local _, dragCenter = button:GetCenter()

      if prevButton then
        local _, prevCenter = prevButton:GetCenter()

        if prevCenter then
          local gap = prevCenter - dragCenter

          if gap < halfButtonHeight then -- It's over half way across the button above, slide up
            buttons[index - 1] = button
            buttons[index] = prevButton
            CT.contentFrame[index - 1] = button
            CT.contentFrame[index] = prevButton

            CT.contentFrame:setButtonAnchors()
            CT.slideButtonAnimation(prevButton, "down")
          end
        end
      end

      if nextButton then
        local _, nextCenter = nextButton:GetCenter()

        if nextCenter then
          local gap = nextCenter - dragCenter

          if gap > -halfButtonHeight then -- It's over half way across the button below, slide down
            buttons[index + 1] = button
            buttons[index] = nextButton
            CT.contentFrame[index + 1] = button
            CT.contentFrame[index] = nextButton

            CT.contentFrame:setButtonAnchors()
            CT.slideButtonAnimation(nextButton, "up")
          end
        end
      end
    else
      ticker:Cancel()
      button:SetFrameLevel(buttonLevel)
      button.dragging = false
      CT.contentFrame:setButtonAnchors()
    end
  end)
end

local function createMainButton(button)
  -- button:SetPoint("TOPLEFT", 0, 0)
  -- button:SetPoint("TOPRIGHT", 0, 0)
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

  local icon = button.icon
  if not icon then -- Create Icon
    icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", 30, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetAlpha(0.9)

    button.icon = icon
  end

  local expander = button.expander
  if not expander then
    expander = button:CreateTexture(nil, "BACKGROUND")
    expander:SetSize(button:GetWidth(), button:GetHeight())
    expander:SetPoint("TOPLEFT")
    expander:SetPoint("TOPRIGHT")
    expander.defaultHeight = button:GetHeight()
    expander.height = expander:GetHeight()
    expander.expanded = false

    button.expander = expander
  end

  local dropDown = button.dropDown
  if not dropDown then
    dropDown = CreateFrame("Frame", nil, button)
    dropDown.texture = dropDown:CreateTexture(nil, "BACKGROUND")
    dropDown:SetSize(button:GetWidth(), 70)
    dropDown:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 5, 2)
    dropDown:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", -5, 2)
    dropDown.texture:SetTexture(0.07, 0.07, 0.07, 1.0)
    dropDown.texture:SetAllPoints()
    dropDown.lineHeight = 13
    dropDown.numLines = 0
    dropDown:Hide()

    button.dropDown = dropDown
  end

  do -- Main Text
    button.value = button:CreateFontString(nil, "ARTWORK")
    -- button.value:SetPoint("RIGHT", button, -13, 0)
    button.value:SetPoint("TOPRIGHT", button, -11, 0)
    button.value:SetPoint("BOTTOMRIGHT", button, -11, 0)
    button.value:SetPoint("LEFT", button, "RIGHT", -80, 0)
    button.value:SetFont("Fonts\\FRIZQT__.TTF", 22)
    button.value:SetTextColor(1, 1, 0, 1)
    button.value:SetJustifyH("RIGHT")

    button.title = button:CreateFontString(nil, "ARTWORK")
    button.title:SetPoint("LEFT", button.icon, "RIGHT", 5, 0)
    button.title:SetPoint("TOP", button, 5, 0)
    button.title:SetPoint("BOTTOM", button, 5, 0)
    button.title:SetPoint("RIGHT", button.value, "LEFT", -3, 0)
    button.title:SetFont("Fonts\\FRIZQT__.TTF", 15)
    button.title:SetTextColor(1, 1, 0, 1)
    button.title:SetJustifyH("LEFT")
  end

  do -- Generic Scripts
    button:SetScript("OnEnter", function(button)
      local up = button.upArrow
      if not up then -- Create up arrow if necessary
        up = CreateFrame("Button", nil, button)
        up:SetSize(16, 16)
        up:SetPoint("TOPLEFT", 10, 0)
        up:SetNormalTexture("Interface/BUTTONS/Arrow-Up-Up.png")
        up:SetPushedTexture("Interface/BUTTONS/Arrow-Up-Down.png")
        up:SetAlpha(0)

        up:SetScript("OnClick", clickArrowUp)

        up:SetScript("OnEnter", function(self)
          button.dragger:SetAlpha(1)
          button.upArrow:SetAlpha(1)
          button.downArrow:SetAlpha(1)
          button:LockHighlight()
          lastMouseoverButton = button
        end)

        up:SetScript("OnLeave", function(self)
          button.dragger:SetAlpha(0)
          button.upArrow:SetAlpha(0)
          button.downArrow:SetAlpha(0)
          button:UnlockHighlight()
          lastMouseoverButton = button
        end)

        button.upArrow = up
      end

      local down = button.downArrow
      if not down then -- Create down arrow if necessary
        down = CreateFrame("Button", nil, button)
        down:SetSize(16, 16)
        down:SetPoint("BOTTOMLEFT", 10, 0)
        down:SetNormalTexture("Interface/BUTTONS/Arrow-Down-Up.png")
        down:SetPushedTexture("Interface/BUTTONS/Arrow-Down-Down.png")
        down:SetAlpha(0)

        down:SetScript("OnClick", clickArrowDown)

        down:SetScript("OnEnter", function(self)
          button.dragger:SetAlpha(1)
          button.upArrow:SetAlpha(1)
          button.downArrow:SetAlpha(1)
          button:LockHighlight()
          lastMouseoverButton = button
        end)

        down:SetScript("OnLeave", function(self)
          button.dragger:SetAlpha(0)
          button.upArrow:SetAlpha(0)
          button.downArrow:SetAlpha(0)
          button:UnlockHighlight()
          lastMouseoverButton = button
        end)

        button.downArrow = down
      end

      local dragger = button.dragger
      if not dragger then -- create dragger button if necessary
        dragger = CreateFrame("Button", nil, button)
        dragger:SetSize(20, 20)
        dragger:SetPoint("BOTTOMRIGHT", -3, 2)
        dragger:SetNormalTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Up.png")
        dragger:SetPushedTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Down.png")
        dragger:SetHighlightTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Highlight.png")
        dragger:SetAlpha(0)

        dragger:SetScript("OnMouseDown", dragMainButton)

        dragger:SetScript("OnEnter", function(dragger)
          button.dragger:SetAlpha(1)
          button.upArrow:SetAlpha(1)
          button.downArrow:SetAlpha(1)
          button:LockHighlight()
          lastMouseoverButton = button
        end)

        dragger:SetScript("OnLeave", function(dragger)
          button.dragger:SetAlpha(0)
          button.upArrow:SetAlpha(0)
          button.downArrow:SetAlpha(0)
          button:UnlockHighlight()
          lastMouseoverButton = button
        end)

        button.dragger = dragger
      end

      up:SetAlpha(1)
      down:SetAlpha(1)
      dragger:SetAlpha(1)
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

function CT.createSpecDataButtons() -- Create the default main buttons
  for i = 1, #CT.specData do
    local b = CT.buttons[i]

    if not b then
      CT.buttons[i] = CreateFrame("CheckButton", "CT_Main_Button_" .. i, CT.contentFrame)
      b = CT.buttons[i]

      b.text = {}

      createMainButton(b)
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
                  CT.contentFrame:updateMinMaxValues()
                end
              elseif self.expandedDown == true then -- Collapse drop down
                self:UnlockHighlight()
                expander.expanded = false
                self.expandedDown = false

                self:dropAnimationUp()

                expander.defaultHeight = self:GetHeight()
                expander.expandedHeight = expander.defaultHeight + dropDown.dropHeight
                CT.updateButtonList()
                CT.contentFrame:updateMinMaxValues()
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

    local data = CT.specData[i]

    b.name = data.name
    b.num = i
    b.powerIndex = data.powerIndex
    b.update = data.func
    b.expanderUpdate = data.expanderFunc
    b.dropDownFunc = data.dropDownFunc
    b.lineTable = data.lines
    b.costsPower = data.costsPower
    b.givesPower = data.givesPower
    b.spellID = data.spellID or select(7, GetSpellInfo(b.name))
    b.spellName = data.spellName or GetSpellInfo(b.spellID)
    b.iconTexture = data.icon or GetSpellTexture(b.spellID) or GetSpellTexture(b.name) or CT.player.specIcon

    b.title:SetText(b.name)

    do -- Update icon texture
      if b.iconTexture then
        b.icon:SetTexture(b.iconTexture)
      else
        b.icon:SetTexture(CT.player.specIcon)
      end

      SetPortraitToTexture(b.icon, b.icon:GetTexture())
    end
  end

  if CT.buttons[1] then
    if not CT.topAnchor1 then CT.topAnchor1 = {CT.buttons[1]:GetPoint(1)} end
    if not CT.topAnchor2 then CT.topAnchor2 = {CT.buttons[1]:GetPoint(2)} end
  end

  CT.totalNumButtons = #CT.specData

  CT.contentFrame:displayMainButtons(CT.buttons)
end

function CT.createSavedSetButtons(sets)
  for i = 1, #sets do
    local set = sets[i]
    local b = CT.setButtons[i]

    if not b then
      CT.setButtons[i] = CreateFrame("CheckButton", "CT_Saved_Set_Button_" .. i, CT.contentFrame)
      b = CT.setButtons[i]

      b.name = table.setName
      b.num = i
      b.text = {}
      b.expanded = false
      b.expandedDown = false

      createMainButton(b)

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
              local set, db = CT.loadSavedSet(sets[i])
            else
              CT.loadActiveSet() -- Change displayed set to current
            end

            CT.base.bottomExpander.popup[1]:Click() -- Toggles it back to normal buttons
            CT.forceUpdate = true
          elseif click == "RightButton" then
            -- if self:GetChecked() then self:SetChecked(false) end -- Don't let right click set it to checked

            local accept, decline = CT.confirmDialogue(self) -- Shows the dialogue frame

            accept.LeftButton = function()
              local t = tremove(sets, i) -- Remove saved variable set
              t = nil

              if not InCombatLockdown() then
                collectgarbage("collect")
              end

              CT.createSavedSetButtons(sets) -- Refresh list
            end

            decline.LeftButton = function()

            end

            for i = 1, #sets do
              if CT.displayedDB and CT.displayedDB == sets[i] then
                CT.setButtons[i]:SetChecked(true)
              else
                CT.setButtons[i]:SetChecked(false)
              end
            end
          end
        end)
      end
    end

    do -- Update icon texture
      if set.icon then
        b.icon:SetTexture(set.icon)
      else
        b.icon:SetTexture(CT.player.specIcon)
      end

      SetPortraitToTexture(b.icon, b.icon:GetTexture())
    end

    b.title:SetFormattedText("|cFFFFFF00%s|r", set.setName or "|cFF9E5A01No name found|r")
    b.value:SetFormattedText("|cFF00CCFF%s|r", CT.formatTimer(tonumber(set.fightLength)) or "|cFF9E5A010:00|r")

    if CT.displayedDB and CT.displayedDB == sets[i] then
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
  end

  if CT.buttons[1] then
    if not CT.topAnchor1 then CT.topAnchor1 = {CT.buttons[1].button:GetPoint(1)} end
    if not CT.topAnchor2 then CT.topAnchor2 = {CT.buttons[1].button:GetPoint(2)} end
  end

  CT.contentFrame:displayMainButtons(CT.setButtons)
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
--------------------------------------------------------------------------------
-- Main frames and their functions
--------------------------------------------------------------------------------
function CT:expanderFrame_OLD(command)
  if not CT.base then CT:OnEnable("load") end

  local f = CT.base.expander
  if not f then
    f = CreateFrame("Frame", nil, CT.base)
    f.anchor = CreateFrame("ScrollFrame", nil, CT.base)
    f.anchor:SetScrollChild(f)
    f:SetAllPoints(f.anchor)

    f.anchor:SetPoint("LEFT", CT.base, "RIGHT")
    f.anchor:SetSize(500, 556)

    local backdrop = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tileSize = 32,
    edgeSize = 16,}

    f.anchor:SetBackdrop(backdrop)
    f.anchor:SetBackdropColor(0.15, 0.15, 0.15, 1)
    f.anchor:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)

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
        CT.base.expander.titleData.rightText1:SetText(CT.displayedDB.setName or "None loaded.")

        if self.graphFrame and not self.graphFrame.displayed[1] then -- No regular graph is loaded
          debug("No regular graph, loading default.")

          CT.loadDefaultGraphs()
          CT.finalizeGraphLength("line")
        end

        if self.uptimeGraph and not self.uptimeGraph.displayed then -- No uptime graph is loaded
          debug("No uptime graph, loading default.")

          CT.loadDefaultUptimeGraph()
          CT.finalizeGraphLength("uptime")
        end
      end
    end)

    f:SetScript("OnHide", function(self)
      -- debug("Expander hiding")
    end)

    f:Hide()
    CT.base.expander = f
  end

  local slider = f.slider
  if not slider then
    slider = CreateFrame("Slider", nil, f)
    slider:SetSize(100, 20)
    slider:SetPoint("TOPLEFT", f, 5, -3)
    slider:SetPoint("TOPRIGHT", f, -5, -3)

    slider:SetBackdrop({
      bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
      edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 8,})
    slider:SetBackdropColor(0.15, 0.15, 0.15, 0)
    slider:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.5)

    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
    slider:SetOrientation("VERTICAL")
    slider:SetMinMaxValues(0, 400)
    slider:SetValue(0)

    slider:SetScript("OnValueChanged", function(self, value)
      f:SetSize(f.anchor:GetSize())
      f.anchor:SetVerticalScroll(value)
    end)

    f.scrollMultiplier = 10 -- Percent of total distance per scroll

    if not slider.mouseWheelFunc then
      function slider.mouseWheelFunc(self, value)
        local current = slider:GetValue()
        local minimum, maximum = slider:GetMinMaxValues()

        local onePercent = (maximum - minimum) / 100
        local percent = (current - minimum) / (maximum - minimum) * 100

        if value < 0 and current < maximum then
          current = min(maximum, current + (onePercent * f.scrollMultiplier))
        elseif value > 0 and current > minimum then
          current = max(minimum, current - (onePercent * f.scrollMultiplier))
        end

        slider:SetValue(current)
      end
    end

    slider:SetScript("OnMouseWheel", slider.mouseWheelFunc)
    f.anchor:SetScript("OnMouseWheel", slider.mouseWheelFunc)

    slider:Hide()
    f.slider = slider
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

        f.titleBG.info = findInfoText(f.titleBG, displayed)

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

  if not f.resetAnchors then
    function f.resetAnchors()
      local uptimeGraphs, normalGraphs = f.uptimeGraphs, f.normalGraphs

      do -- Uptime graph anchors
        for i = 1, #uptimeGraphs do
          local uptimeGraph = uptimeGraphs[i]

          uptimeGraph:ClearAllPoints()
          uptimeGraph.defaultHeight = uptimeGraph:GetHeight()

          if i == 1 then
            uptimeGraph:SetPoint("LEFT", f.dataFrames[3], 0, 0)
            uptimeGraph:SetPoint("RIGHT", f.dataFrames[4], 0, 0)
            uptimeGraph:SetPoint("TOP", f.dataFrames[4], "BOTTOM", 0, -10)
          else
            local anchor = uptimeGraphs[i - 1]
            uptimeGraph:SetPoint("LEFT", anchor, 0, 0)
            uptimeGraph:SetPoint("RIGHT", anchor, 0, 0)
            uptimeGraph:SetPoint("TOP", anchor, "BOTTOM", 0, 0)
          end
        end
      end

      do -- Normal graph anchors
        for i = 1, #normalGraphs do
          local normalGraph = normalGraphs[i]

          normalGraph:ClearAllPoints()

          if i == 1 then
            local anchor = uptimeGraphs[#uptimeGraphs] -- Lowest uptime graph
            normalGraph:SetPoint("LEFT", anchor, 0, 0)
            normalGraph:SetPoint("RIGHT", anchor, 0, 0)
            normalGraph:SetPoint("TOP", anchor, "BOTTOM", 0, -10)
          else
            local anchor = normalGraphs[i - 1]
            normalGraph:SetPoint("LEFT", anchor, 0, 0)
            normalGraph:SetPoint("RIGHT", anchor, 0, 0)
            normalGraph:SetPoint("TOP", anchor, "BOTTOM", 0, -10)
          end
        end
      end
    end
  end

  local uptimeGraphs = f.uptimeGraphs
  if not uptimeGraphs then
    uptimeGraphs = {}

    function f.addUptimeGraph()
      local num = #uptimeGraphs + 1
      uptimeGraphs[num] = CT.buildUptimeGraph(f)
      uptimeGraphs[num]:SetHeight(25)
      uptimeGraphs[num]:SetParent(f)

      return uptimeGraphs[num]
    end

    f.addUptimeGraph()

    f.uptimeGraphs = uptimeGraphs
  end

  local normalGraphs = f.normalGraphs
  if not normalGraphs then
    normalGraphs = {}

    function f.addNormalGraph()
      local num = #normalGraphs + 1
      normalGraphs[num] = CT.buildGraph(f)
      normalGraphs[num]:SetParent(f)
      normalGraphs[num]:SetHeight(150)

      return normalGraphs[num]
    end

    function f.removeNormalGraph() -- TODO: Set this up, and for uptime as well
      local num = #normalGraphs + 1
      normalGraphs[num] = CT.buildGraph(f)
      normalGraphs[num]:SetParent(f)
      normalGraphs[num]:SetHeight(150)

      debug("REMOVING normal graph.")

      return normalGraphs[num]
    end

    f.addNormalGraph()

    f.normalGraphs = normalGraphs
  end

  f.resetAnchors()

  if f.shown and (command and command == "hide") or (not command and f:IsShown()) then
    f:Hide()
    f.anchor:Hide()
    f.shown = false
  elseif not f.shown and (command and command == "show") or (not command and not f:IsShown()) then
    f:Show()
    f.anchor:Show()
    f.shown = true
  end

  if f.shown and self ~= CombatTracker then
    if self and self.name then
      f.currentButton = self

      f.icon:SetTexture(self.iconTexture or CT.player.specIcon)
      SetPortraitToTexture(f.icon, f.icon:GetTexture())

      f.titleText:SetText(self.name)

      addExpanderText(self, self.lineTable)

      local buttonName = self.name

      if CT.displayed then
        do -- Try to find default graphs related to this particular button
          local spellName = self.spellName or GetSpellInfo(self.spellID) or GetSpellInfo(self.name) or self.name

          if spellName then
            local matchedGraph

            for i = 1, #CT.graphList do
              if spellName:match(CT.graphList[i]) then
                matchedGraph = CT.graphList[i]
                break
              end
            end

            if matchedGraph then
              CT.graphFrame:hideAllGraphs()
              CT.displayed.graphs[matchedGraph]:toggle("show")
            end
          end
        end

        do -- Try to match an uptime graph with this button
          local spellName = self.spellName or GetSpellInfo(self.spellID) or GetSpellInfo(self.name) or self.name
          local spellID = self.spellID or select(7, GetSpellInfo(self.name))

          local uptimeGraphs = CT.displayed.uptimeGraphs
          local matchedGraph, activityGraph

          for index = 1, #CT.uptimeCategories do -- Run through each type of uptime graph (ex: "buffs")
            for graphIndex, setGraph in ipairs(uptimeGraphs[CT.uptimeCategories[index]]) do -- Run every graph in that type (ex: "Illuminated Healing")

              if spellID and spellID == setGraph.spellID then
                matchedGraph = setGraph
              elseif spellName == setGraph.name then
                matchedGraph = setGraph
              elseif self.name == setGraph.name then
                matchedGraph = setGraph
              elseif self.name == setGraph.spellID then
                matchedGraph = setGraph
              end

              if setGraph.name == "Activity" then
                activityGraph = setGraph
              end
            end
          end

          if matchedGraph then
            matchedGraph:toggle("show")
          elseif CT.settings.hideUptimeGraph then
            if CT.uptimeGraphFrame and CT.uptimeGraphFrame.displayed then
              CT.uptimeGraphFrame.displayed:toggle("clear")
            end
          elseif activityGraph then
            activityGraph:toggle("show")
          end
        end

        do -- Handles power and spell frames
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
    end

    CT.forceUpdate = true
  end
end

function CT.createBaseFrame()
  local f = CT.base
  if not f then -- NOTE: Base frame is created at the top so that its position gets saved properly.
    CT.base = baseFrame
    f = CT.base
    f:SetPoint("CENTER")
    f:SetSize(300, 500)
    
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetTexture(0, 0, 0, CT.settings.backgroundAlpha or 0.7)
    f.bg:SetAllPoints()
    
    f:SetScript("OnMouseDown", function(self, click)
      if click == "LeftButton" and not self.isMoving then
        if CT.graphFrame and CT.graphFrame.displayed and CT.graphFrame.displayed[1] then -- Hide any graphs before dragging, they can cause insane lag
          for index = 1, #CT.graphFrame.displayed do
            local graph = CT.graphFrame.displayed[index]
            local lines, bars, triangles = graph.lines, graph.bars, graph.triangles

            for i = 1, #graph.data do -- Show all the lines
              if lines[i] then
                lines[i]:Hide()
              end

              if bars and bars[i] then
                bars[i]:Hide()
              end

              if triangles and triangles[i] then
                triangles[i]:Hide()
              end
            end
          end
        end

        self:StartMoving()
        self.isMoving = true
      end
    end)

    f:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        CT:updateButtonList()

        if CT.graphFrame and CT.graphFrame.displayed and CT.graphFrame.displayed[1] then -- Put them all back
          for index = 1, #CT.graphFrame.displayed do
            local graph = CT.graphFrame.displayed[index]
            local lines, bars, triangles = graph.lines, graph.bars, graph.triangles

            for i = 1, #graph.data do -- Show all the lines
              if lines[i] then
                lines[i]:Show()
              end

              if bars and bars[i] then
                bars[i]:Show()
              end

              if triangles and triangles[i] then
                triangles[i]:Show()
              end
            end
          end
        end
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

    f:SetScript("OnShow", function(self)
      self.shown = true
      
      if not CT.current and not CT.displayed then
        debug("CT.base (OnShow): No current set, so trying to load the last saved set.")
        CT.loadSavedSet() -- Load the most recent set as default
      end
    end)
    
    f:SetScript("OnHide", function(self)
      self.shown = false
    end)
  end
  
  local scroll = f.scroll
  if not scroll then
    scroll = CreateFrame("Frame", "CombatTracker_Base_Scroll_Frame", f)
    scroll.anchor = CreateFrame("ScrollFrame", "CombatTracker_Base_Scroll_Frame_Anchor", f)
    scroll.anchor:SetScrollChild(scroll)
    scroll:SetAllPoints(scroll.anchor)
    
    local width, height = f:GetSize()

    scroll.anchor:SetPoint("TOPLEFT", f, 10, -50)
    scroll.anchor:SetPoint("TOPRIGHT", f, -15, -50)
    scroll.anchor:SetPoint("BOTTOMLEFT", f, 10, 30)
    scroll.anchor:SetPoint("BOTTOMRIGHT", f, -15, 30)
    scroll.anchor:SetSize(width, height)
    
    f.scroll = scroll
    CT.contentFrame = scroll -- Easier access, cause I'm too lazy to change it at the moment
    
    scroll.stepSize = 20
    scroll.up = 0
    scroll.down = height
    
    scroll.anchor:SetScript("OnMouseWheel", function(self, direction)
      local newValue = (scroll.scrollValue or 0) + (-scroll.stepSize * direction)
      
      if (scroll.up > newValue) then
        newValue = scroll.up
      elseif (newValue > scroll.down) then
        newValue = scroll.down
      end
      
      scroll.scrollValue = newValue
      
      if direction > 0 then -- Up
        scroll:SetSize(self:GetSize())
        self:SetVerticalScroll(scroll.scrollValue)
      else -- Down
        scroll:SetSize(self:GetSize())
        self:SetVerticalScroll(scroll.scrollValue)
      end
    end)
    
    local function finishCycleHide(self, requested)
      local b = self:GetParent()
      b:Hide()
    end

    local function finishCycleShow(self, requested)
      local b = self:GetParent()
      b:Show()
      b:SetAlpha(1)

      if b.done then
        CT.contentFrame.animating = false
      end
    end

    function CT.contentFrame:displayMainButtons(buttons)
      if not buttons then debug("Called display buttons, but didn't pass a button table.") return end

      local num = #buttons
      self.animating = true
      self.sourceTable = buttons

      for i = 1, #self do -- Animate button out and hide
        local b = self[i]

        local fadeOut = b.fadeOut
        if not fadeOut then
          fadeOut = b:CreateAnimationGroup()
          local a = fadeOut:CreateAnimation("Alpha")
          a:SetDuration(0.2)
          a:SetSmoothing("OUT")
          a:SetFromAlpha(1)
          a:SetToAlpha(-1)
          fadeOut:SetScript("OnFinished", finishCycleHide)

          fadeOut.a = a
          b.a = fadeOut
        end

        fadeOut.a:SetStartDelay(i * 0.05)
        fadeOut:Play()

        self[i] = nil
      end

      for i = 1, num do -- Load in new button
        local b = buttons[i]
        b:Show()
        b:SetAlpha(0)

        local fadeIn = b.fadeIn
        if not fadeIn then
          fadeIn = b:CreateAnimationGroup()
          local a = fadeIn:CreateAnimation("Alpha")
          a:SetDuration(0.2)
          a:SetSmoothing("IN")
          a:SetFromAlpha(-1)
          a:SetToAlpha(1)

          fadeIn:SetScript("OnFinished", finishCycleShow)

          fadeIn.a = a
          b.a = fadeIn
        end

        if i == num then -- Last one
          b.done = true
        else
          b.done = false
        end

        fadeIn.a:SetStartDelay(i * 0.05)
        fadeIn:Play()

        self[i] = buttons[i]
      end

      CT.contentFrame:setButtonAnchors(buttons)
    end

    -- function CT.contentFrame:setButtonAnchors()
    --   local y = -CT.settings.buttonSpacing
    --
    --   for i = 1, #self do
    --     local button = self[i]
    --     local prevButton = self[i - 1]
    --
    --     if i == 1 then
    --       button:ClearAllPoints()
    --       button:SetPoint("TOPLEFT", 0, 0)
    --       button:SetPoint("TOPRIGHT")
    --     else
    --       if i > 2 and prevButton and prevButton.dragging then
    --         local prevButtonExpander = self[i - 2].expander
    --         local height = prevButton:GetHeight()
    --         button:ClearAllPoints()
    --         button:SetPoint("TOPRIGHT", prevButtonExpander, "BOTTOMRIGHT", 0, (y * 2) - height)
    --         button:SetPoint("TOPLEFT", prevButtonExpander, "BOTTOMLEFT", 0, (y * 2) - height)
    --       else
    --         local prevButtonExpander = self[i - 1].expander
    --         button:ClearAllPoints()
    --         button:SetPoint("TOPRIGHT", prevButtonExpander, "BOTTOMRIGHT", 0, y)
    --         button:SetPoint("TOPLEFT", prevButtonExpander, "BOTTOMLEFT", 0, y)
    --       end
    --     end
    --   end
    --
    --   CT.contentFrame:updateMinMaxValues(self)
    -- end
    
    function CT.contentFrame:updateMinMaxValues(table)
      local height = 0
    
      local spacing = CT.settings.buttonSpacing
    
      for i, button in ipairs(table) do
        height = height + button:GetHeight() + spacing
      end
      
      height = height - self.anchor:GetHeight()
      if 0 > height then height = 0 end
      
      self.down = height
    end
  end
  
  local logo = f.logo
  if not logo then
    logo = f:CreateTexture("CombatTracker_Base_Logo", "BORDER")
    logo:SetTexture("Interface/ICONS/Ability_DualWield.png")
    -- logo:SetTexture("Interface/ICONS/Ability_Racial_TimeIsMoney.png")
    logo:SetPoint("TOPLEFT", f, 5, -5)
    logo:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    -- logo:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    -- logo:SetMask("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
    logo:SetAlpha(0.9)
    
    local edges = {}
    for i = 1, 4 do
      local edge = f:CreateTexture(nil, "OVERLAY")
      edge:SetTexture(0, 0, 0, 0.9)
      
      if i == 1 then
        -- edge:SetGradientAlpha("VERTICAL", 0, 0, 0, 1, 0, 0, 0, 0)
        edge:SetSize(16, 1)
        edge:SetPoint("TOP", logo, 0, -1)
      elseif i == 2 then
        edge:SetSize(1, 16)
        edge:SetPoint("RIGHT", logo, -1, 0)
      elseif i == 3 then
        edge:SetSize(1, 16)
        edge:SetPoint("LEFT", logo, 1, 0)
      elseif i == 4 then
        edge:SetSize(7, 1)
        edge:SetPoint("BOTTOM", logo, 0, 1)
      end
      
      edges[i] = edge
    end
    
    logo:SetSize(40, 40)
    
    do -- Title
      title = {}
    
      for i = 1, 2 do
        title[i] = f:CreateFontString(nil, "ARTWORK")
        title[i]:SetTextColor(0.2, 0.72, 1.0, 1)
        title[i]:SetShadowOffset(1, -3)
    
        if i == 1 then
          title[i]:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE")
          title[i]:SetPoint("CENTER", logo, -5, 3)
          title[i]:SetText("C")
        else
          title[i]:SetFont("Fonts\\FRIZQT__.TTF", 25, "OUTLINE")
          title[i]:SetPoint("CENTER", logo, 7, -5)
          title[i]:SetText("T")
        end
      end
    end
    
    f.logo = logo
  end
  
  local header = f.header
  if not header then
    header = CreateFrame("Frame", "CombatTracker_Base_Header", f)
    header:SetPoint("LEFT", logo, "RIGHT", 5, 0)
    header:SetPoint("RIGHT", f, -20, 0)
    -- header:SetPoint("TOPRIGHT", f, -15, -5)
    header:SetHeight(40)
    header.texture = header:CreateTexture(nil, "BACKGROUND")
    header.texture:SetTexture(0.1, 0.1, 0.1, (CT.settings.backgroundAlpha or 0.7))
    header.texture:SetAllPoints(header)
    
    f.header = header
  end
  
  local headerObjectSize = header:GetHeight() - 3
  
  local save = f.saveButton
  if not save then
    save = CreateFrame("Button", "CombatTracker_Base_Saves", f)
    save:SetSize(headerObjectSize - 3, headerObjectSize - 3)
    -- save:SetPoint("LEFT", settings, "RIGHT", 20, 3)
    save:SetPoint("LEFT", header, 10, 0)
    
    save.bg = save:CreateTexture("CombatTracker_Base_Settings", "ARTWORK")
    save.bg:SetTexture("Interface\\addons\\CombatTracker\\Media\\save.tga")
    save.bg:SetAllPoints()
    -- save.bg:SetAlpha(0.9)
    -- save.bg:SetDesaturated(true)
    save.bg:SetVertexColor(0.5, 0.5, 0.5, 1)
    -- save:SetVertexColor(0.0, 0.0, 0.0, 0.1)
    
    save.title = save:CreateFontString(nil, "OVERLAY")
    save.title:SetTextColor(0.2, 0.72, 1.0, 1)
    save.title:SetShadowOffset(1, -1)

    save.title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    save.title:SetPoint("CENTER", save, 0, 0)
    save.title:SetText("Saves")
    
    f.saveButton = save
  end
  
  local reset = f.resetButton
  if not reset then
    reset = CreateFrame("Button", "CombatTracker_Base_Reset_Button", f)
    reset:SetSize(headerObjectSize, headerObjectSize)
    -- reset:SetPoint("RIGHT", header, -(headerObjectSize + 10), 0)
    reset:SetPoint("LEFT", save, "RIGHT", 20, 0)
    
    reset.bg = reset:CreateTexture("CombatTracker_Base_Settings", "ARTWORK")
    reset.bg:SetTexture("Interface/ICONS/INV_Misc_Note_05.png")
    reset.bg:SetAllPoints()
    reset.bg:SetAlpha(0.9)
    -- reset.bg:SetDesaturated(true)
    -- reset.bg:SetVertexColor(0.5, 0.5, 0.5, 1)
    -- reset:SetVertexColor(0.0, 0.0, 0.0, 0.1)
    
    reset.bg:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    
    local edges = {}
    for i = 1, 4 do
      local edge = reset:CreateTexture(nil, "OVERLAY")
      edge:SetTexture(0, 0, 0, 0.9)
      
      if i == 1 then
        -- edge:SetGradientAlpha("VERTICAL", 0, 0, 0, 1, 0, 0, 0, 0)
        edge:SetSize(14, 1)
        edge:SetPoint("TOP", reset, 0, -1)
      elseif i == 2 then
        edge:SetSize(1, 16)
        edge:SetPoint("RIGHT", reset, -1, 0)
      elseif i == 3 then
        edge:SetSize(1, 14)
        edge:SetPoint("LEFT", reset, 1, 0)
      elseif i == 4 then
        edge:SetSize(7, 1)
        edge:SetPoint("BOTTOM", reset, 0, 0)
      end
      
      edges[i] = edge
    end
    
    reset.title = reset:CreateFontString(nil, "OVERLAY")
    reset.title:SetTextColor(0.2, 0.72, 1.0, 1)
    reset.title:SetShadowOffset(1, -1)

    reset.title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    reset.title:SetPoint("CENTER", reset, 0, 0)
    reset.title:SetText("Reset")
    
    f.resetButton = reset
  end
  
  local settings = f.settingsButton
  if not settings then
    settings = CreateFrame("Button", "CombatTracker_Base_Settings", f)
    settings:SetSize(headerObjectSize + 15, headerObjectSize + 15)
    -- settings:SetPoint("LEFT", header, 10, 0)
    settings:SetPoint("LEFT", reset, "RIGHT", 20, 0)
    
    settings.bg = settings:CreateTexture("CombatTracker_Base_Settings", "ARTWORK")
    settings.bg:SetTexture("Interface/HELPFRAME/HelpIcon-CharacterStuck.png")
    settings.bg:SetAllPoints()
    -- settings.bg:SetAlpha(0.9)
    -- settings.bg:SetDesaturated(true)
    settings.bg:SetVertexColor(0.5, 0.5, 0.5, 1)
    -- settings:SetVertexColor(0.0, 0.0, 0.0, 0.1)
    
    settings.title = settings:CreateFontString(nil, "OVERLAY")
    settings.title:SetTextColor(0.2, 0.72, 1.0, 1)
    settings.title:SetShadowOffset(1, -1)

    settings.title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    settings.title:SetPoint("CENTER", settings, 0, 0)
    settings.title:SetText("Settings")
    
    f.settingsButton = settings
  end
  
  local close = f.closeButton
  if not close then -- Close button
    close = CreateFrame("Button", "CombatTracker_Base_Close_Button", f)
    close:SetSize(40, 40)
    close:SetPoint("RIGHT", header, 0, 0)
    -- close:SetNormalTexture("Interface/FriendsFrame/BlockCommunicationsIcon.png")
    -- close:SetHighlightTexture("Interface\\RaidFrame\\ReadyCheck-NotReady.png")
    close:SetNormalTexture("Interface\\RaidFrame\\ReadyCheck-NotReady.png")
    close:SetHighlightTexture("Interface\\RaidFrame\\ReadyCheck-NotReady.png")
  
    close.bg = close:CreateTexture(nil, "BORDER")
    close.bg:SetAllPoints()
    close.bg:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
    close.bg:SetVertexColor(0, 0, 0, 0.2)
    
    close.title = close:CreateFontString(nil, "OVERLAY")
    close.title:SetTextColor(0.2, 0.72, 1.0, 1)
    close.title:SetShadowOffset(1, -1)

    close.title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    close.title:SetPoint("CENTER", close, 0, 0)
    close.title:SetText("Close")
  
    close:SetScript("OnClick", function(self)
      CT.base:Hide()
    end)
  
    close:SetScript("OnEnter", function(self)
      self.info = "Closes Combat Tracker, but it will still be recording CT.current.\n\nType /ct in chat to open it again. Type /ct help to see a full list of chat commands."
  
      CT.createInfoTooltip(self, "Close", nil, nil, nil, nil)
    end)
  
    close:SetScript("OnLeave", function()
      CT.createInfoTooltip()
    end)
  
    f.closeButton = close
  end
  
  local expB = f.expandButton
  if not expB then
    expB = CreateFrame("Button", "CombatTracker_Base_Expander_Button", f)
    expB:SetPoint("RIGHT", f, -1, 0)
    expB:SetSize(10, 200)
    
    expB.bg = expB:CreateTexture(nil, "BACKGROUND")
    expB.bg:SetTexture("Interface\\addons\\CombatTracker\\Media\\ScrollBG.tga")
    expB.bg:SetAllPoints()
    
    expB.arrows = {}
    local y = 20
    for i = 1, 3 do
      local a = expB:CreateTexture(nil, "ARTWORK")
      a:SetTexture("Interface/MONEYFRAME/Arrow-Right-Up.png")
      a:SetSize(15, 15)
      a:SetPoint("CENTER", expB, 2, y)
      a:SetVertexColor(0.5, 0.5, 0.5, 0.9)
      
      y = y - 20
      
      expB.arrows[i] = a
    end
    
    expB:SetScript("OnMouseDown", function(self, click)
      for i = 1, #expB.arrows do
        expB.arrows[i]:SetTexture("Interface/MONEYFRAME/Arrow-Right-Down.png") -- Pushed version
      end
    end)
    
    expB:SetScript("OnMouseUp", function(self, click)
      for i = 1, #expB.arrows do
        expB.arrows[i]:SetTexture("Interface/MONEYFRAME/Arrow-Right-Up.png") -- Restore texture
      end
      
      if MouseIsOver(self) then
        CT:expanderFrame()
      end
    end)
    
    f.expandButton = expB
  end
  
  tinsert(UISpecialFrames, f:GetName())
end

local mouseExitButton, mouseEnterButton, mousePushButton, mouseReleaseButton
do -- Register general button functions
  do -- On enter and on leave
    local highlightButton, ticker = nil, nil
    
    function mouseExitButton(self) -- Sometimes the OnLeave event gets missed. All of this extra stuff is here to make sure it's caught
      if self.Cancel then self = highlightButton end -- A ticker was passed as first arg, use local instead
      
      if not MouseIsOver(self) then
        CT.setTooltip()
        
        self.background:SetTexture(0.1, 0.1, 0.1, 1.0)
        highlightButton = nil
        
        if ticker then
          ticker:Cancel()
          ticker = nil
        end
      end
    end

    function mouseEnterButton(self)
      -- local textString = ("The current button name is: %s"):format(self.name or "NO NAME!")
      CT.setTooltip(self, self.titleString, self.textString)
      
      self.background:SetTexture(0.13, 0.13, 0.13, 1.0)
      highlightButton = self
      
      if ticker then
        ticker:Cancel()
        ticker = nil
      end
      
      ticker = newTicker(0.1, mouseExitButton)
    end
  end
  
  do -- On mouse down and on mouse up
    local pushedButton, clickType, ticker = nil, nil, nil
    local icon1, icon2, icon3, icon4, icon5 = nil, nil, nil, nil, nil
    local value1, value2, value3, value4, value5 = nil, nil, nil, nil, nil
    -- local title1, title2, title3, title4, title5 = nil, nil, nil, nil, nil
    
    function mouseReleaseButton(self, click)
      if click == "LeftButton" then
        -- if self.Cancel then self = pushedButton end -- A ticker was passed as first arg, use local instead
        
        self.background[1]:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
        self.background[2]:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
        
        if self.icon then
          self.icon:SetPoint(icon1, icon2, icon3, icon4, icon5)
        end
        
        if self.value then
          self.value:SetPoint(value1, value2, value3, value4, value5)
        end
        
        if self.title then
          self.title:SetPoint(title1, title2, title3, title4, title5)
        end
        
        if self.mouseUpFunc then
          self.mouseUpFunc()
        end
        
        -- if MouseIsOver(self) then
        --   pushedButton = nil
        --
        --   if ticker then
        --     ticker:Cancel()
        --     ticker = nil
        --   end
        -- else
        --
        -- end
      end
    end
    
    local iconOffset = 2
    local textOffset = 1
    function mousePushButton(self, click)
      if click == "LeftButton" then
        self.background[2]:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
        self.background[1]:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
        
        if self.icon then
          icon1, icon2, icon3, icon4, icon5 = self.icon:GetPoint()
          self.icon:SetPoint(icon1, icon2, icon3, (icon4 + iconOffset), (icon5 - iconOffset))
        end
        
        if self.value then
          value1, value2, value3, value4, value5 = self.value:GetPoint()
          self.value:SetPoint(value1, value2, value3, (value4 + iconOffset), (value5 - iconOffset))
        end
        
        if self.title then
          title1, title2, title3, title4, title5 = self.title:GetPoint()
          self.title:SetPoint(title1, title2, title3, (title4 + textOffset), (title5 - textOffset))
        end
        
        -- pushedButton = self
        -- clickType = click
        
        -- ticker = newTicker(0.1, mouseReleaseButton)
      end
    end
  end
end

function CT:expanderFrame(command)
  local f = CT.base.expander
  if not f then
    f = CreateFrame("Frame", "CombatTracker_Expander_Scroll_Frame", CT.base)
    f.anchor = CreateFrame("ScrollFrame", "CombatTracker_Expander_Scroll_Frame_Anchor", CT.base)
    f.anchor:SetScrollChild(f)
    f:SetAllPoints(f.anchor)

    f.anchor:SetPoint("TOPLEFT", CT.base.scroll.anchor, "TOPRIGHT", 10, 0)
    f.anchor:SetPoint("BOTTOMRIGHT", CT.base, -10, 10)
    
    local width, height = CT.base:GetSize()
    f.anchor:SetSize(width, height)

    f.stepSize = 20
    f.up = 0
    f.down = height
    
    f.anchor:SetScript("OnMouseWheel", function(self, direction)
      local newValue = (f.scrollValue or 0) + (-f.stepSize * direction)
      
      if (f.up > newValue) then
        newValue = f.up
      elseif (newValue > f.down) then
        newValue = f.down
      end
      
      f.scrollValue = newValue
      
      if direction > 0 then -- Up
        f:SetSize(self:GetSize())
        self:SetVerticalScroll(f.scrollValue)
      else -- Down
        f:SetSize(self:GetSize())
        self:SetVerticalScroll(f.scrollValue)
      end
    end)

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
        -- CT.base.expander.titleData.rightText1:SetText(CT.displayedDB.setName or "None loaded.")

        if self.graphFrame and not self.graphFrame.displayed[1] then -- No regular graph is loaded
          debug("No regular graph, loading default.")

          CT.loadDefaultGraphs()
          CT.finalizeGraphLength("line")
        end

        if self.uptimeGraph and not self.uptimeGraph.displayed then -- No uptime graph is loaded
          debug("No uptime graph, loading default.")

          CT.loadDefaultUptimeGraph()
          CT.finalizeGraphLength("uptime")
        end
      end
    end)

    f:SetScript("OnHide", function(self)
      -- debug("Expander hiding")
    end)

    function f:updateMinMaxValues(table)
      local height = 0
    
      local spacing = CT.settings.buttonSpacing
    
      for i, button in ipairs(table) do
        height = height + button:GetHeight() + spacing
      end
      
      height = height - self.anchor:GetHeight()
      if 0 > height then height = 0 end
      
      self.down = height
    end
    
    CT.base.expander = f
  end
  
  if not f.resetAnchors then -- The function for resetting graph anchors
    function f.resetAnchors()
      local uptimeGraphs, normalGraphs = f.uptimeGraphs, f.normalGraphs
  
      do -- Uptime graph anchors
        for i = 1, #uptimeGraphs do
          local uptimeGraph = uptimeGraphs[i]
  
          uptimeGraph:ClearAllPoints()
          uptimeGraph.defaultHeight = uptimeGraph:GetHeight()
  
          if i == 1 then
            -- uptimeGraph:SetPoint("LEFT", f.dataFrames[3], 0, 0)
            -- uptimeGraph:SetPoint("RIGHT", f.dataFrames[4], 0, 0)
            -- uptimeGraph:SetPoint("TOP", f.dataFrames[4], "BOTTOM", 0, -10)
            uptimeGraph:SetPoint("LEFT", f, 10, 0)
            uptimeGraph:SetPoint("RIGHT", f, -10, 0)
            uptimeGraph:SetPoint("BOTTOM", f, 0, 180)
          else
            local anchor = uptimeGraphs[i - 1]
            uptimeGraph:SetPoint("LEFT", anchor, 0, 0)
            uptimeGraph:SetPoint("RIGHT", anchor, 0, 0)
            uptimeGraph:SetPoint("TOP", anchor, "BOTTOM", 0, 0)
          end
        end
      end
  
      do -- Normal graph anchors
        for i = 1, #normalGraphs do
          local normalGraph = normalGraphs[i]
  
          normalGraph:ClearAllPoints()
  
          if i == 1 then
            local anchor = uptimeGraphs[#uptimeGraphs] -- Lowest uptime graph
            normalGraph:SetPoint("LEFT", anchor, 0, 0)
            normalGraph:SetPoint("RIGHT", anchor, 0, 0)
            normalGraph:SetPoint("TOP", anchor, "BOTTOM", 0, -10)
          else
            local anchor = normalGraphs[i - 1]
            normalGraph:SetPoint("LEFT", anchor, 0, 0)
            normalGraph:SetPoint("RIGHT", anchor, 0, 0)
            normalGraph:SetPoint("TOP", anchor, "BOTTOM", 0, -10)
          end
        end
      end
    end
  end
  
  local uptimeGraphs = f.uptimeGraphs
  if not uptimeGraphs then -- The function for creating a new uptime graph
    uptimeGraphs = {}
  
    function f.addUptimeGraph()
      local num = #uptimeGraphs + 1
      uptimeGraphs[num] = CT.buildUptimeGraph(f)
      uptimeGraphs[num]:SetHeight(25)
      uptimeGraphs[num]:SetParent(f)
  
      return uptimeGraphs[num]
    end
    
    f.addUptimeGraph()
  
    f.uptimeGraphs = uptimeGraphs
  end
  
  local normalGraphs = f.normalGraphs
  if not normalGraphs then -- The function for creating a new normal graph
    normalGraphs = {}
  
    function f.addNormalGraph()
      local num = #normalGraphs + 1
      normalGraphs[num] = CT.buildGraph(f)
      normalGraphs[num]:SetParent(f)
      normalGraphs[num]:SetHeight(150)
  
      return normalGraphs[num]
    end
  
    function f.removeNormalGraph() -- TODO: Set this up, and for uptime as well
      local num = #normalGraphs + 1
      normalGraphs[num] = CT.buildGraph(f)
      normalGraphs[num]:SetParent(f)
      normalGraphs[num]:SetHeight(150)
  
      debug("REMOVING normal graph.")
  
      return normalGraphs[num]
    end
    
    f.addNormalGraph()
  
    f.normalGraphs = normalGraphs
  end
  
  f.resetAnchors()
  
  if f.shown and (command and command == "hide") or (not command and f:IsShown()) then
    f:Hide()
    f.anchor:Hide()
    f.shown = false
  elseif not f.shown and (command and command == "show") or (not command and not f:IsShown()) then
    f:Show()
    f.anchor:Show()
    f.shown = true
  end

  if f.shown and self ~= CombatTracker then
    if self and self.name then
      f.currentButton = self

      f.icon:SetTexture(self.iconTexture or CT.player.specIcon)
      SetPortraitToTexture(f.icon, f.icon:GetTexture())

      f.titleText:SetText(self.name)

      addExpanderText(self, self.lineTable)

      local buttonName = self.name

      if CT.displayed then
        do -- Try to find default graphs related to this particular button
          local spellName = self.spellName or GetSpellInfo(self.spellID) or GetSpellInfo(self.name) or self.name

          if spellName then
            local matchedGraph

            for i = 1, #CT.graphList do
              if spellName:match(CT.graphList[i]) then
                matchedGraph = CT.graphList[i]
                break
              end
            end

            if matchedGraph then
              CT.graphFrame:hideAllGraphs()
              CT.displayed.graphs[matchedGraph]:toggle("show")
            end
          end
        end

        do -- Try to match an uptime graph with this button
          local spellName = self.spellName or GetSpellInfo(self.spellID) or GetSpellInfo(self.name) or self.name
          local spellID = self.spellID or select(7, GetSpellInfo(self.name))

          local uptimeGraphs = CT.displayed.uptimeGraphs
          local matchedGraph, activityGraph

          for index = 1, #CT.uptimeCategories do -- Run through each type of uptime graph (ex: "buffs")
            for graphIndex, setGraph in ipairs(uptimeGraphs[CT.uptimeCategories[index]]) do -- Run every graph in that type (ex: "Illuminated Healing")

              if spellID and spellID == setGraph.spellID then
                matchedGraph = setGraph
              elseif spellName == setGraph.name then
                matchedGraph = setGraph
              elseif self.name == setGraph.name then
                matchedGraph = setGraph
              elseif self.name == setGraph.spellID then
                matchedGraph = setGraph
              end

              if setGraph.name == "Activity" then
                activityGraph = setGraph
              end
            end
          end

          if matchedGraph then
            matchedGraph:toggle("show")
          elseif CT.settings.hideUptimeGraph then
            if CT.uptimeGraphFrame and CT.uptimeGraphFrame.displayed then
              CT.uptimeGraphFrame.displayed:toggle("clear")
            end
          elseif activityGraph then
            activityGraph:toggle("show")
          end
        end

        do -- Handles power and spell frames
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
    end

    CT.forceUpdate = true
  end
end

local function animateExpand(self, elapsed)
  local remaining = self.animation - GetTime()
  
  local baseWidth = self.stopBaseWidth - ((remaining / self.animationTotal) * (self.stopBaseWidth - self.startBaseWidth))
  local anchorWidth = self.stopAnchorWidth - ((remaining / self.animationTotal) * (self.stopAnchorWidth - self.startAnchorWidth))
  local buttonWidth = self.stopButtonWidth - ((remaining / self.animationTotal) * (self.stopButtonWidth - self.startButtonWidth))
  
  local y = -2
  for i = 1, #self.scroll do
    local b = self.scroll[i]
    local mod = ((i + 1) % 2) + 1
    
    local p1, p2, p3, p4, p5 = unpack(b.points[1])
    local Y = y + (remaining / self.animationTotal) * (p5 - y)
    
    b:ClearAllPoints()
    b:SetPoint(p1, p2, p3, p4, Y)
    b:SetPoint(unpack(b.points[2]))
    b:SetWidth(buttonWidth)
    
    y = (y - 68)
  end
  
  self:SetWidth(baseWidth)
  self.scroll.anchor:SetWidth(anchorWidth)
  self.scroll:SetAllPoints(self.scroll.anchor)
  
  if 0 >= remaining then -- Done
    self:SetScript("OnUpdate", nil)
    self.animation = nil
    
    local y = -2
    for i = 1, #self.scroll do
      local b = self.scroll[i]
      
      b:ClearAllPoints()
      b:SetPoint("TOP", self.scroll, "TOP", 0, y)
      b:SetWidth(self.stopButtonWidth)
      
      y = (y - 68)
    end
  end
end

local function animateCollapse(self, elapsed)
  local remaining = self.animation - GetTime()
  
  local baseWidth = self.stopBaseWidth - ((remaining / self.animationTotal) * (self.stopBaseWidth - self.startBaseWidth))
  local anchorWidth = self.stopAnchorWidth - ((remaining / self.animationTotal) * (self.stopAnchorWidth - self.startAnchorWidth))
  local buttonWidth = self.stopButtonWidth - ((remaining / self.animationTotal) * (self.stopButtonWidth - self.startButtonWidth))
  
  local y = -2
  for i = 1, #self.scroll do
    local b = self.scroll[i]
    local mod = ((i + 1) % 2) + 1
    
    local p1, p2, p3, p4, p5 = unpack(b.points[1])
    local Y = p5 + ((remaining / self.animationTotal) * y)
    
    b:ClearAllPoints()
    b:SetPoint(p1, p2, p3, p4, Y)
    b:SetPoint(unpack(b.points[2]))
    b:SetWidth(buttonWidth)
    
    y = (y - 68)
  end
  
  self:SetWidth(baseWidth)
  self.scroll.anchor:SetWidth(anchorWidth)
  self.scroll:SetAllPoints(self.scroll.anchor)
  
  if 0 >= remaining then -- Done
    self:SetScript("OnUpdate", nil)
    self.animation = nil
    
    self.scroll.anchor:ClearAllPoints()
    self.scroll.anchor:SetPoint("TOPLEFT", self, 10, -50)
    self.scroll.anchor:SetPoint("TOPRIGHT", self, -10, -50)
    self.scroll.anchor:SetPoint("BOTTOMLEFT", self, 10, 30)
    self.scroll.anchor:SetPoint("BOTTOMRIGHT", self, -10, 30)
    self.scroll.anchor:SetSize(self.defaultWidth, self.defaultHeight)
    self.scroll:SetAllPoints(self.scroll.anchor)
    
    for i = 1, #self.scroll do
      local b = self.scroll[i]
      
      b.icon:ClearAllPoints()
      b.value:ClearAllPoints()
      
      b.icon:SetPoint("LEFT", b, 7.5, 0)
      b.value:SetPoint("LEFT", b.icon, "RIGHT")
      b.value:SetPoint("RIGHT", b, 0, 0)
    end
    
    self.scroll:setButtonAnchors()
    
    CT:expanderFrame()
  end
end

function CT:toggleBaseExpansion(command) -- NOTE: Maybe make the sizing changes a percentage?
  local f = self.base
  local scroll = self.base.scroll
  local width, height = f.defaultWidth, f.defaultHeight
  local scrollOffsetX = 10
  f.expandedWidth = width + width
  
  if not f.expander then
    CT:expanderFrame(command)
  end
  
  f.animationTotal = 0.3
  f.animation = (GetTime() + f.animationTotal)
  
  if (command and command == "hide" and f.expanded) or (not command and f.expanded) then -- Collapse it
    for i = 1, #scroll do
      local b = scroll[i]
    
      b:ClearAllPoints()
    end
    
    f.startBaseWidth = f:GetWidth()
    f.stopBaseWidth = f.defaultWidth
    
    f.startAnchorWidth = 100
    f.stopAnchorWidth = scroll.anchor.defaultWidth
    
    f.startButtonWidth = 90
    f.stopButtonWidth = scroll[1].defaultWidth
    
    f.startBaseWidth = f:GetWidth()
    f.stopBaseWidth = f.defaultWidth
    
    f.startAnchorWidth = 100
    f.stopAnchorWidth = scroll.anchor.defaultWidth
    
    f.startButtonWidth = 90
    f.stopButtonWidth = scroll[1].defaultWidth
    
    self.base:SetScript("OnUpdate", animateCollapse)
    
    f.expanded = false
  elseif (command and command == "show" and not f.expanded) or (not command and not f.expanded) then -- Expand it
    for i = 1, #scroll do
      local b = scroll[i]
      
      b.icon:ClearAllPoints()
      b.value:ClearAllPoints()
      
      b.icon:SetPoint("CENTER", b, 0, 0)
      b.value:SetPoint("CENTER", b.icon)
      
      b:ClearAllPoints()
    end
    
    -- f.defaultWidth, f.defaultHeight = f:GetSize()
    scroll.anchor.defaultWidth, scroll.anchor.defaultHeight = scroll.anchor:GetSize()
    
    scroll.anchor:ClearAllPoints()
    scroll.anchor:SetPoint("LEFT", f, 10, 0)
    scroll.anchor:SetPoint("TOP", f, 0, -50)
    scroll.anchor:SetPoint("BOTTOM", f, 0, 30)
    scroll:SetAllPoints(scroll.anchor)
    
    f.startBaseWidth = f.defaultWidth
    f.stopBaseWidth = f.expandedWidth
    
    f.startAnchorWidth = scroll.anchor:GetWidth()
    f.stopAnchorWidth = 100
    
    f.startButtonWidth = scroll[1]:GetWidth()
    f.stopButtonWidth = 90
    
    CT:expanderFrame(command)
    
    f:SetScript("OnUpdate", animateExpand)
    
    f.expanded = true
  end
end

function CT:updatePoints(multiplier)
  local X = multiplier * (self.stopPoints.width - self.startPoints.width)
  self:SetWidth(self.startPoints.width + X)
  
  for i = 1, #self.startPoints do
    local p = self.startPoints[1]
    self:SetPoint(p[1], p[2], p[3], p[4], p[5])
  end
end

local function runAnimation(self, elapsed)
  local remaining = self.animation - GetTime()
  
  if 0 >= remaining then -- Done
    self:SetScript("OnUpdate", nil)
    
    CT.setToStopPoints(self)
    CT.setToStopPoints(self.expander.anchor)
    CT.setToStopPoints(self.scroll.anchor)
    
    for i = 1, #self.scroll do
      local b = self.scroll[i]
      
      CT.setToStopPoints(b)
      CT.setToStopPoints(b.icon)
      CT.setToStopPoints(b.value)
    end
    
    return
  end
  
  local multiplier = 1 - (remaining / self.animationTotal)
  
  local f = self
  do -- Handle the base frame
    local width = multiplier * (f.stopPoints.width - f.startPoints.width)
    local height = multiplier * (f.stopPoints.height - f.startPoints.height)
    f:SetSize(f.startPoints.width + width, f.startPoints.height + height)
  end
  
  local f = self.scroll.anchor
  do -- Handle the scroll frame buttons are on
    local width = multiplier * (f.stopPoints.width - f.startPoints.width)
    local height = multiplier * (f.stopPoints.height - f.startPoints.height)
    f:SetSize(f.startPoints.width + width, f.startPoints.height + height)
  end
  
  local f = self.expander.anchor
  do -- Expander sizing
    local width = multiplier * (f.stopPoints.width - f.startPoints.width)
    local height = multiplier * (f.stopPoints.height - f.startPoints.height)
    f:SetSize(f.startPoints.width + width, f.startPoints.height + height)
  end
  
  for i = 1, #self.scroll do
    local b = self.scroll[i]
  
    local width = multiplier * (b.stopPoints.width - b.startPoints.width)
    local height = multiplier * (b.stopPoints.height - b.startPoints.height)
    b:SetSize(b.startPoints.width + width, b.startPoints.height + height)
    
    local X = multiplier * (b.stopPoints.centerX - b.startPoints.centerX)
    local Y = multiplier * (b.stopPoints.centerY - b.startPoints.centerY)
    
    b:ClearAllPoints()
    
    local p1 = b.startPoints[1]
    local p2 = b.stopPoints[1]
    b:SetPoint(p1[1], p1[2], p1[3], p1[4], p1[5] + Y)
    
    local p1 = b.startPoints[2]
    local p2 = b.stopPoints[2]
    b:SetPoint(p1[1], p1[2], p1[3], p1[4], p1[5])
  end
end

function CT:toggleBaseExpansion(command)
  if (command and command == "hide" and self.base.expanded) or (not command and self.base.expanded) then -- Collapse it
    -- CT:expanderFrame("hide")
    
    do -- Store START points
      CT.storeStartPoints(self.base, true)
      CT.storeStartPoints(self.base.expander.anchor)
      CT.storeStartPoints(self.base.scroll.anchor)
      
      for i = 1, #self.base.scroll do
        local b = self.base.scroll[i]
        
        CT.storeStartPoints(b)
        CT.storeStartPoints(b.icon)
        CT.storeStartPoints(b.value)
      end
    end
    
    do -- Set to ORIGINAL points
      CT.setToOriginalPoints(self.base, true)
      CT.setToOriginalPoints(self.base.expander.anchor)
      CT.setToOriginalPoints(self.base.scroll.anchor)
    
      for i = 1, #self.base.scroll do
        local b = self.base.scroll[i]
    
        CT.setToOriginalPoints(b)
        CT.setToOriginalPoints(b.icon)
        CT.setToOriginalPoints(b.value)
      end
    end
    
    debug("Returning to default size")
    self.base.expanded = false
  elseif (command and command == "show" and not self.base.expanded) or (not command and not self.base.expanded) then -- Expand it
    CT:expanderFrame("show")
    
    do -- Store START points
      CT.storeStartPoints(self.base, true)
      CT.storeStartPoints(self.base.expander.anchor)
      CT.storeStartPoints(self.base.scroll.anchor)
      
      for i = 1, #self.base.scroll do
        local b = self.base.scroll[i]
        
        CT.storeStartPoints(b)
        CT.storeStartPoints(b.icon)
        CT.storeStartPoints(b.value)
      end
    end
    
    self.base:SetWidth(600)
    
    self.base.expander.anchor:SetPoint("TOPLEFT", self.base.scroll.anchor, "TOPRIGHT", 10, 0)
    self.base.expander.anchor:SetPoint("BOTTOMRIGHT", self.base, -10, 10)
    
    self.base.scroll.anchor:SetWidth(100)
    self.base.scroll.anchor:SetPoint("LEFT", self.base, 10, 0)
    self.base.scroll.anchor:SetPoint("TOP", self.base, 0, -50)
    self.base.scroll.anchor:SetPoint("BOTTOM", self.base, 0, 30)
    self.base.scroll:SetAllPoints(self.base.scroll.anchor)
    
    local y = -2
    for i = 1, #self.base.scroll do
      local b = self.base.scroll[i]
      
      b:SetPoint("TOPLEFT", self.base.scroll, 2, y)
      b:SetPoint("TOPRIGHT", self.base.scroll, -2, y)
      b.icon:SetPoint("CENTER", b, 0, 0)
      b.value:SetPoint("CENTER", b.icon)
      
      y = (y - 68)
    end
    
    debug("Setting to expanded size.")
    self.base.expanded = true
  end
  
  do -- Store STOP points
    CT.storeStopPoints(self.base, true)
    CT.storeStopPoints(self.base.expander.anchor, true)
    CT.storeStopPoints(self.base.scroll.anchor)
    
    for i = 1, #self.base.scroll do
      local b = self.base.scroll[i]
      
      CT.storeStopPoints(b)
      CT.storeStopPoints(b.icon)
      CT.storeStopPoints(b.value)
    end
  end
  
  self.base.animationTotal = 2.3
  self.base.animation = (GetTime() + self.base.animationTotal)
  self.base:SetScript("OnUpdate", runAnimation)
end

function CT.createBaseFrame()
  local r, g, b, a = unpack(CT.settings.defaultColor)
  local scrollOffsetX = 10
  
  local f = CT.base
  if not f then -- NOTE: Base frame is created at the top so that its position gets saved properly.
    CT.base = baseFrame
    f = CT.base
    f:SetPoint("CENTER")
    f:SetSize(300, 500)
    
    f.defaultWidth, f.defaultHeight = f:GetSize()
    
    local bg = f.background
    if not bg then -- Background texture and gradient
      bg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
      bg:SetTexture(r, g, b, a)
      
      local cornerSize = 20
      bg.corners = {}
      for i = 1, 4 do
        local c = f:CreateTexture("CT_Base_Button_Corner_" .. i, "BACKGROUND", nil, -8)
        c:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
        c:SetVertexColor(r, g, b, a)
      
        if i == 1 then
          c:SetSize(cornerSize, cornerSize)
          c:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
          bg:SetPoint("TOPLEFT", c, (cornerSize / 2), 0)
        elseif i == 2 then
          c:SetSize(cornerSize, cornerSize)
          c:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
          bg:SetPoint("TOPRIGHT", c, -(cornerSize / 2), 0)
        elseif i == 3 then
          c:SetSize(cornerSize, cornerSize)
          c:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
          bg:SetPoint("BOTTOMLEFT", c, (cornerSize / 2), 0)
        elseif i == 4 then
          c:SetSize(cornerSize, cornerSize)
          c:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
          bg:SetPoint("BOTTOMRIGHT", c, -(cornerSize / 2), 0)
        end
      
        bg.corners[i] = c
      end
      
      f.fill1 = f:CreateTexture("CT_Base_Button_Circle_Fill_1", "BACKGROUND", nil, 0)
      f.fill1:SetTexture(r, g, b, a)
      f.fill1:SetPoint("TOPLEFT", bg.corners[2], 0, -(cornerSize / 2))
      f.fill1:SetPoint("BOTTOMRIGHT", bg.corners[4], 0, (cornerSize / 2))
      
      f.fill2 = f:CreateTexture("CT_Base_Button_Circle_Fill_2", "BACKGROUND", nil, 0)
      f.fill2:SetTexture(r, g, b, a)
      f.fill2:SetPoint("TOPRIGHT", bg.corners[1], 0, -(cornerSize / 2))
      f.fill2:SetPoint("BOTTOMLEFT", bg.corners[3], 0, (cornerSize / 2))
      
      -- local g = f:CreateTexture("CT_Base_Button_Background_Gradient_Top", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
      -- g:SetTexture(1, 1, 1, 1)
      -- g:SetSize(width, height / 2)
      -- g:SetPoint("CENTER", bg, 0, 0)
      -- g:SetPoint("RIGHT", bg, 0, 0)
      -- g:SetPoint("LEFT", bg, 0, 0)
      -- g:SetPoint("TOP", bg, 0, 0)
      -- bg[1] = g
      --
      -- local g = f:CreateTexture("CT_Base_Button_Background_Gradient_Bottom", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
      -- g:SetTexture(1, 1, 1, 1)
      -- g:SetSize(width, height / 2)
      -- g:SetPoint("CENTER", bg, 0, 0)
      -- g:SetPoint("RIGHT", bg, 0, 0)
      -- g:SetPoint("LEFT", bg, 0, 0)
      -- g:SetPoint("BOTTOM", bg, 0, 0)
      -- bg[2] = g
      
      f.background = bg
    end
    
    f:SetScript("OnMouseDown", function(self, click)
      if click == "LeftButton" and not self.isMoving then
        if CT.graphFrame and CT.graphFrame.displayed and CT.graphFrame.displayed[1] then -- Hide any graphs before dragging, they can cause insane lag
          for index = 1, #CT.graphFrame.displayed do
            local graph = CT.graphFrame.displayed[index]
            local lines, bars, triangles = graph.lines, graph.bars, graph.triangles

            for i = 1, #graph.data do -- Show all the lines
              if lines[i] then
                lines[i]:Hide()
              end

              if bars and bars[i] then
                bars[i]:Hide()
              end

              if triangles and triangles[i] then
                triangles[i]:Hide()
              end
            end
          end
        end

        self:StartMoving()
        self.isMoving = true
      end
    end)

    f:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        CT:updateButtonList()

        if CT.graphFrame and CT.graphFrame.displayed and CT.graphFrame.displayed[1] then -- Put them all back
          for index = 1, #CT.graphFrame.displayed do
            local graph = CT.graphFrame.displayed[index]
            local lines, bars, triangles = graph.lines, graph.bars, graph.triangles

            for i = 1, #graph.data do -- Show all the lines
              if lines[i] then
                lines[i]:Show()
              end

              if bars and bars[i] then
                bars[i]:Show()
              end

              if triangles and triangles[i] then
                triangles[i]:Show()
              end
            end
          end
        end
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

    f:SetScript("OnShow", function(self)
      self.shown = true
      
      if not CT.current and not CT.displayed then
        debug("CT.base (OnShow): No current set, so trying to load the last saved set.")
        CT.loadSavedSet() -- Load the most recent set as default
      end
    end)
    
    f:SetScript("OnHide", function(self)
      self.shown = false
    end)
  end
  
  local scroll = f.scroll
  if not scroll then
    scroll = CreateFrame("Frame", "CombatTracker_Base_Scroll_Frame", f)
    scroll.anchor = CreateFrame("ScrollFrame", "CombatTracker_Base_Scroll_Frame_Anchor", f)
    scroll.anchor:SetScrollChild(scroll)
    scroll:SetAllPoints(scroll.anchor)
    
    local width, height = f:GetSize()

    scroll.anchor:SetPoint("TOPLEFT", f, scrollOffsetX, -50)
    scroll.anchor:SetPoint("TOPRIGHT", f, -scrollOffsetX, -50)
    scroll.anchor:SetPoint("BOTTOMLEFT", f, scrollOffsetX, 30)
    scroll.anchor:SetPoint("BOTTOMRIGHT", f, -scrollOffsetX, 30)
    scroll.anchor:SetSize(width, height)
    
    f.scroll = scroll
    CT.contentFrame = scroll -- Easier access, cause I'm too lazy to change it at the moment
    
    scroll.stepSize = 20
    scroll.up = 0
    scroll.down = height
    
    scroll.anchor:SetScript("OnMouseWheel", function(self, direction)
      local newValue = (scroll.scrollValue or 0) + (-scroll.stepSize * direction)
      
      if (scroll.up > newValue) then
        newValue = scroll.up
      elseif (newValue > scroll.down) then
        newValue = scroll.down
      end
      
      scroll.scrollValue = newValue
      
      if direction > 0 then -- Up
        scroll:SetSize(self:GetSize())
        self:SetVerticalScroll(scroll.scrollValue)
      else -- Down
        scroll:SetSize(self:GetSize())
        self:SetVerticalScroll(scroll.scrollValue)
      end
    end)
    
    local function finishCycleHide(self, requested)
      local b = self:GetParent()
      b:Hide()
    end

    local function finishCycleShow(self, requested)
      local b = self:GetParent()
      b:Show()
      b:SetAlpha(1)

      if b.done then
        CT.contentFrame.animating = false
      end
    end

    function CT.contentFrame:displayMainButtons(buttons)
      if not buttons then debug("Called display buttons, but didn't pass a button table.") return end

      local num = #buttons
      self.animating = true
      self.sourceTable = buttons

      for i = 1, #self do -- Animate button out and hide
        local b = self[i]

        local fadeOut = b.fadeOut
        if not fadeOut then
          fadeOut = b:CreateAnimationGroup()
          local a = fadeOut:CreateAnimation("Alpha")
          a:SetDuration(0.2)
          a:SetSmoothing("OUT")
          a:SetFromAlpha(1)
          a:SetToAlpha(-1)
          fadeOut:SetScript("OnFinished", finishCycleHide)

          fadeOut.a = a
          b.a = fadeOut
        end

        fadeOut.a:SetStartDelay(i * 0.05)
        fadeOut:Play()

        self[i] = nil
      end

      for i = 1, num do -- Load in new button
        local b = buttons[i]
        b:Show()
        b:SetAlpha(0)

        local fadeIn = b.fadeIn
        if not fadeIn then
          fadeIn = b:CreateAnimationGroup()
          local a = fadeIn:CreateAnimation("Alpha")
          a:SetDuration(0.2)
          a:SetSmoothing("IN")
          a:SetFromAlpha(-1)
          a:SetToAlpha(1)

          fadeIn:SetScript("OnFinished", finishCycleShow)

          fadeIn.a = a
          b.a = fadeIn
        end

        if i == num then -- Last one
          b.done = true
        else
          b.done = false
        end

        fadeIn.a:SetStartDelay(i * 0.05)
        fadeIn:Play()

        self[i] = buttons[i]
      end

      CT.contentFrame:setButtonAnchors(buttons)
    end
    
    function CT.contentFrame:setButtonAnchors(buttons)
      if not buttons then buttons = self end
      local y = -2
      local width, height = self:GetSize()
      
      for i = 1, #buttons do
        local b = buttons[i]
        
        local mod = ((i + 1) % 2) + 1
        local opposite = (i % 2) + 1
        
        local anchor = "LEFT"
        if mod == 2 then
          anchor = "RIGHT"
        end
        
        b:SetWidth((width / 2) - 5)
        
        b:ClearAllPoints()
        b:SetPoint("TOP", self, "TOP", 0, y)
        b:SetPoint(anchor, self, anchor, 0)
        
        if (mod == 2) then
          y = (y - 60) - 8
        end
      end
      
      CT.contentFrame:updateMinMaxValues(self)
    end
    
    function CT.contentFrame:updateMinMaxValues(table)
      local height = 0
    
      local spacing = CT.settings.buttonSpacing
    
      for i, button in ipairs(table) do
        height = height + button:GetHeight() + spacing
      end
      
      height = height - self.anchor:GetHeight()
      if 0 > height then height = 0 end
      
      self.down = height
    end
  end
  
  -- local logo = f.logo
  -- if not logo then
  --   logo = f:CreateTexture("CombatTracker_Base_Logo", "BORDER")
  --   logo:SetTexture("Interface/ICONS/Ability_DualWield.png")
  --   -- logo:SetTexture("Interface/ICONS/Ability_Racial_TimeIsMoney.png")
  --   logo:SetPoint("TOPLEFT", f, 5, -5)
  --   logo:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
  --   -- logo:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  --   -- logo:SetMask("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
  --   logo:SetAlpha(0.9)
  --
  --   local edges = {}
  --   for i = 1, 4 do
  --     local edge = f:CreateTexture(nil, "OVERLAY")
  --     edge:SetTexture(0, 0, 0, 0.9)
  --
  --     if i == 1 then
  --       -- edge:SetGradientAlpha("VERTICAL", 0, 0, 0, 1, 0, 0, 0, 0)
  --       edge:SetSize(16, 1)
  --       edge:SetPoint("TOP", logo, 0, -1)
  --     elseif i == 2 then
  --       edge:SetSize(1, 16)
  --       edge:SetPoint("RIGHT", logo, -1, 0)
  --     elseif i == 3 then
  --       edge:SetSize(1, 16)
  --       edge:SetPoint("LEFT", logo, 1, 0)
  --     elseif i == 4 then
  --       edge:SetSize(7, 1)
  --       edge:SetPoint("BOTTOM", logo, 0, 1)
  --     end
  --
  --     edges[i] = edge
  --   end
  --
  --   logo:SetSize(40, 40)
  --
  --   do -- Title
  --     title = {}
  --
  --     for i = 1, 2 do
  --       title[i] = f:CreateFontString(nil, "ARTWORK")
  --       title[i]:SetTextColor(0.2, 0.72, 1.0, 1)
  --       title[i]:SetShadowOffset(1, -3)
  --
  --       if i == 1 then
  --         title[i]:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE")
  --         title[i]:SetPoint("CENTER", logo, -5, 3)
  --         title[i]:SetText("C")
  --       else
  --         title[i]:SetFont("Fonts\\FRIZQT__.TTF", 25, "OUTLINE")
  --         title[i]:SetPoint("CENTER", logo, 7, -5)
  --         title[i]:SetText("T")
  --       end
  --     end
  --   end
  --
  --   f.logo = logo
  -- end
  
  local header = f.header
  if not header then -- Background texture and gradient
    local r, g, b, a = 0.1, 0.1, 0.1, 1.0
    
    header = CreateFrame("Frame", "CombatTracker_Base_Header_Frame", f)
    header:SetHeight(40)
    header:SetPoint("LEFT", f, scrollOffsetX, 0)
    header:SetPoint("RIGHT", f, -scrollOffsetX, 0)
    header:SetPoint("TOP", f, 0, -5)
    -- header:SetPoint("BOTTOM", scroll, "TOP", 0, 5)
    
    header.bg = header:CreateTexture(nil, "BACKGROUND", nil, 3)
    header.bg:SetTexture(r, g, b, a)
    header.bg:SetAllPoints()
    
    local cornerSize = 20
    header.corners = {}
    for i = 1, 4 do
      local c = header:CreateTexture("CT_Base_Header_Corner_" .. i, "BACKGROUND", nil, -8)
      c:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
      c:SetVertexColor(r, g, b, a)
    
      if i == 1 then
        c:SetSize(cornerSize, cornerSize)
        c:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
        header.bg:SetPoint("TOPLEFT", c, (cornerSize / 2), 0)
      elseif i == 2 then
        c:SetSize(cornerSize, cornerSize)
        c:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 0)
        header.bg:SetPoint("TOPRIGHT", c, -(cornerSize / 2), 0)
      elseif i == 3 then
        c:SetSize(cornerSize, cornerSize)
        c:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
        header.bg:SetPoint("BOTTOMLEFT", c, (cornerSize / 2), 0)
      elseif i == 4 then
        c:SetSize(cornerSize, cornerSize)
        c:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
        header.bg:SetPoint("BOTTOMRIGHT", c, -(cornerSize / 2), 0)
      end
    
      header.corners[i] = c
    end
    
    header.fill1 = header:CreateTexture("CT_Base_Button_Circle_Fill_1", "BACKGROUND", nil, 0)
    header.fill1:SetTexture(r, g, b, a)
    header.fill1:SetPoint("TOPLEFT", header.corners[2], 0, -(cornerSize / 2))
    header.fill1:SetPoint("BOTTOMRIGHT", header.corners[4], 0, (cornerSize / 2))
    
    header.fill2 = header:CreateTexture("CT_Base_Button_Circle_Fill_2", "BACKGROUND", nil, 0)
    header.fill2:SetTexture(r, g, b, a)
    header.fill2:SetPoint("TOPRIGHT", header.corners[1], 0, -(cornerSize / 2))
    header.fill2:SetPoint("BOTTOMLEFT", header.corners[3], 0, (cornerSize / 2))
    
    f.header = header
  end
  
  local nameText = f.nameText
  if not nameText then
    nameText = {}
    
    nameText[1] = header:CreateFontString(nil, "ARTWORK")
    nameText[1]:SetPoint("TOPLEFT", header, 5, -5)
    nameText[1]:SetFont("Fonts\\FRIZQT__.TTF", 12)
    nameText[1]:SetTextColor(1.0, 1.0, 1.0, 1.0)
    nameText[1]:SetShadowOffset(1, -1)
    nameText[1]:SetJustifyH("LEFT")
    nameText[1]:SetText("Fight:")

    nameText[2] = header:CreateFontString(nil, "ARTWORK")
    nameText[2]:SetPoint("LEFT", nameText[1], "RIGHT", 3, 0)
    nameText[2]:SetFont("Fonts\\FRIZQT__.TTF", 12)
    nameText[2]:SetTextColor(1.0, 1.0, 0.0, 1.0)
    nameText[2]:SetShadowOffset(1, -1)
    nameText[2]:SetJustifyH("RIGHT")
    nameText[2]:SetText("None")
    
    function nameText:update(name)
      if name then
        self[1]:SetText("Fight:")
        self[2]:SetText(name)
      else
        self[1]:SetText()
        self[2]:SetText()
      end
    end
    
    f.nameText = nameText
  end
  
  local timerText = f.timerText
  if not timerText then
    timerText = {}
    
    timerText[1] = header:CreateFontString(nil, "ARTWORK")
    timerText[1]:SetPoint("BOTTOMLEFT", header, 5, 5)
    timerText[1]:SetFont("Fonts\\FRIZQT__.TTF", 12)
    timerText[1]:SetTextColor(1.0, 1.0, 1.0, 1.0)
    timerText[1]:SetShadowOffset(1, -1)
    timerText[1]:SetJustifyH("LEFT")
    timerText[1]:SetText("Timer:")

    timerText[2] = header:CreateFontString(nil, "ARTWORK")
    timerText[2]:SetPoint("LEFT", timerText[1], "RIGHT", 3, 0)
    timerText[2]:SetFont("Fonts\\FRIZQT__.TTF", 12)
    timerText[2]:SetTextColor(1.0, 1.0, 0.0, 1.0)
    timerText[2]:SetShadowOffset(1, -1)
    timerText[2]:SetJustifyH("RIGHT")
    timerText[2]:SetText("0:03")
    
    function timerText:update(timer)
      if timer then
        self[1]:SetText("Timer:")
        self[2]:SetText(timer)
      else
        self[1]:SetText()
        self[2]:SetText()
      end
    end
    
    f.timerText = timerText
  end
  
  if not f.titleBG and false then -- Title Background, icon, and text
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

        f.titleBG.info = findInfoText(f.titleBG, displayed)

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
      f.titleData:SetPoint("TOPRIGHT", f, -rightOffset, -15)
      -- f.titleData:SetPoint("TOPRIGHT", f, -15, -15)
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
  
  local headerObjectSize = header:GetHeight() - 10
  local headerObjectSpacing = 5
  
  local close = f.closeButton
  if not close then
    local width, height = 160, 60
    
    local f = header
    local b = CreateFrame("Button", nil, f)
    b:SetSize(width, height)
    b:SetPoint("LEFT", f, 5, 0)
    
    local bg = b.background
    if not bg then -- Background texture and gradient
      bg = b:CreateTexture(nil, "BACKGROUND", nil, -8)
      bg:SetTexture(0.1, 0.1, 0.1, 1.0)
      bg:SetAllPoints()
      b:SetNormalTexture(bg)
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Top", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.1, 0, 0, 0, 0) -- Top
      g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("TOP", bg, 0, 0)
      bg[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Bottom", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.1) -- Bottom
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("BOTTOM", bg, 0, 0)
      bg[2] = g
      
      b.background = bg
    end
    
    local shadow = b.shadow
    if not shadow then
      shadow = b:CreateTexture("CT_Base_Button_Shadow", "BACKGROUND")
      shadow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
      shadow:SetPoint("TOPLEFT", -1, 1)
      shadow:SetPoint("BOTTOMRIGHT", 0, -0)
      shadow:SetVertexColor(0, 0, 0, 1)
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Bottom_Edge", "BACKGROUND")
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 1)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, 5)
      g:SetPoint("TOP", shadow, "BOTTOM", 0, 0)
      g:SetPoint("RIGHT", shadow, 2, 0)
      g:SetPoint("LEFT", shadow, 0, 0)
      shadow[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Right_Edge", "BACKGROUND")
      g:SetGradientAlpha("HORIZONTAL", 0.01, 0.01, 0.01, 1, 0, 0, 0, 0)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(3, height)
      g:SetPoint("LEFT", shadow, "RIGHT", 0, 0)
      g:SetPoint("TOP", shadow, 0, 0)
      g:SetPoint("BOTTOM", shadow, 0, -2)
      shadow[2] = g
    
      b.shadow = shadow
    end
    
    local icon = b.icon
    if not icon then -- Icon
      icon = b:CreateTexture(nil, "ARTWORK", nil, 6)
      -- icon:SetTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Up.png")
      icon:SetTexture("Interface/RAIDFRAME/ReadyCheck-NotReady.png")
      -- SetPortraitToTexture(icon, icon:GetTexture())
      icon:SetPoint("CENTER", b, 0, 0)
      -- icon:SetAllPoints()
      icon:SetSize(height - 25, height - 25)
      icon:SetTexCoord(0.07, 0.95, 0.08, 0.97)
      icon:SetAlpha(0.9)
      icon:SetDesaturated(true)
    
      b.icon = icon
    end
    
    -- local value = b.value
    -- if not value then
    --   value = b:CreateFontString(nil, "ARTWORK")
    --   value:SetAllPoints(b)
    --   value:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
    --   value:SetTextColor(0.95, 0.95, 1.0, 1)
    --   -- value:SetJustifyH("LEFT")
    --   -- value:SetShadowOffset(-1, 1)
    --   value:SetText("X")
    --
    --   b.value = value
    -- end
    
    b:SetScript("OnEnter", mouseEnterButton)
    b:SetScript("OnLeave", mouseExitButton)
    b:SetScript("OnMouseDown", mousePushButton)
    b:SetScript("OnMouseUp", mouseReleaseButton)
    
    b.titleString = "Close"
    b.textString = "Click to close CombatTracker. It will still be gathering data."
    
    close = b
    close:SetSize(headerObjectSize, headerObjectSize)
    close:ClearAllPoints()
    close:SetPoint("RIGHT", header, -headerObjectSpacing - 5, 0)
    
    function close.mouseUpFunc()
      CT.base:Hide()
    end
  
    f.closeButton = close
  end
  
  local save = f.saveButton
  if not save then
    local width, height = 160, 60
    
    local f = header
    local b = CreateFrame("Button", nil, f)
    b:SetSize(width, height)
    b:SetPoint("LEFT", f, 5, 0)
    
    local bg = b.background
    if not bg then -- Background texture and gradient
      bg = b:CreateTexture(nil, "BACKGROUND", nil, -8)
      bg:SetTexture(0.1, 0.1, 0.1, 1.0)
      bg:SetAllPoints()
      b:SetNormalTexture(bg)
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Top", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.1, 0, 0, 0, 0) -- Top
      g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("TOP", bg, 0, 0)
      bg[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Bottom", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.1) -- Bottom
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("BOTTOM", bg, 0, 0)
      bg[2] = g
      
      b.background = bg
    end
    
    local shadow = b.shadow
    if not shadow then
      shadow = b:CreateTexture("CT_Base_Button_Shadow", "BACKGROUND")
      shadow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
      shadow:SetPoint("TOPLEFT", -1, 1)
      shadow:SetPoint("BOTTOMRIGHT", 0, -0)
      shadow:SetVertexColor(0, 0, 0, 1)
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Bottom_Edge", "BACKGROUND")
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 1)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, 5)
      g:SetPoint("TOP", shadow, "BOTTOM", 0, 0)
      g:SetPoint("RIGHT", shadow, 2, 0)
      g:SetPoint("LEFT", shadow, 0, 0)
      shadow[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Right_Edge", "BACKGROUND")
      g:SetGradientAlpha("HORIZONTAL", 0.01, 0.01, 0.01, 1, 0, 0, 0, 0)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(3, height)
      g:SetPoint("LEFT", shadow, "RIGHT", 0, 0)
      g:SetPoint("TOP", shadow, 0, 0)
      g:SetPoint("BOTTOM", shadow, 0, -2)
      shadow[2] = g
    
      b.shadow = shadow
    end
    
    local icon = b.icon
    if not icon then -- Icon
      icon = b:CreateTexture(nil, "ARTWORK", nil, 6)
      icon:SetTexture("Interface\\addons\\CombatTracker\\Media\\save.tga") -- "Interface/ICONS/Ability_DualWield.png"
      -- SetPortraitToTexture(icon, icon:GetTexture())
      icon:SetPoint("CENTER", b, 0, 3)
      icon:SetSize(height - 30, height - 30)
      -- icon:SetAllPoints()
      icon:SetTexCoord(0.07, 0.95, 0.08, 0.97)
      icon:SetAlpha(0.9)
      icon:SetDesaturated(true)
    
      b.icon = icon
    end
    
    -- local value = b.value
    -- if not value then
    --   value = b:CreateFontString(nil, "ARTWORK")
    --   value:SetAllPoints()
    --   value:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
    --   value:SetTextColor(0.95, 0.95, 1.0, 1)
    --   -- value:SetJustifyV("BOTTOM")
    --   -- value:SetShadowOffset(1, -1)
    --   value:SetText("*")
    --
    --   b.value = value
    -- end
    
    b:SetScript("OnEnter", mouseEnterButton)
    b:SetScript("OnLeave", mouseExitButton)
    b:SetScript("OnMouseDown", mousePushButton)
    b:SetScript("OnMouseUp", mouseReleaseButton)
    
    b.titleString = "Saves"
    b.textString = "Load saved fights."
    
    save = b
    save:SetSize(headerObjectSize, headerObjectSize)
    save:ClearAllPoints()
    save:SetPoint("RIGHT", close, "LEFT", -headerObjectSpacing, 0)
  
    f.saveButton = save
  end

  local reset = f.resetButton
  if not reset then
    local width, height = 160, 60
    
    local f = header
    local b = CreateFrame("Button", nil, f)
    b:SetSize(width, height)
    b:SetPoint("LEFT", f, 5, 0)
    
    local bg = b.background
    if not bg then -- Background texture and gradient
      bg = b:CreateTexture(nil, "BACKGROUND", nil, -8)
      bg:SetTexture(0.1, 0.1, 0.1, 1.0)
      bg:SetAllPoints()
      b:SetNormalTexture(bg)
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Top", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.1, 0, 0, 0, 0) -- Top
      g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("TOP", bg, 0, 0)
      bg[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Bottom", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.1) -- Bottom
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("BOTTOM", bg, 0, 0)
      bg[2] = g
      
      b.background = bg
    end
    
    local shadow = b.shadow
    if not shadow then
      shadow = b:CreateTexture("CT_Base_Button_Shadow", "BACKGROUND")
      shadow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
      shadow:SetPoint("TOPLEFT", -1, 1)
      shadow:SetPoint("BOTTOMRIGHT", 0, -0)
      shadow:SetVertexColor(0, 0, 0, 1)
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Bottom_Edge", "BACKGROUND")
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 1)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, 5)
      g:SetPoint("TOP", shadow, "BOTTOM", 0, 0)
      g:SetPoint("RIGHT", shadow, 2, 0)
      g:SetPoint("LEFT", shadow, 0, 0)
      shadow[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Right_Edge", "BACKGROUND")
      g:SetGradientAlpha("HORIZONTAL", 0.01, 0.01, 0.01, 1, 0, 0, 0, 0)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(3, height)
      g:SetPoint("LEFT", shadow, "RIGHT", 0, 0)
      g:SetPoint("TOP", shadow, 0, 0)
      g:SetPoint("BOTTOM", shadow, 0, -2)
      shadow[2] = g
    
      b.shadow = shadow
    end
    
    local icon = b.icon
    if not icon then -- Icon
      icon = b:CreateTexture(nil, "ARTWORK", nil, 6)
      -- icon:SetTexture("Interface/ICONS/INV_Misc_Note_05.png")
      icon:SetTexture("Interface/HELPFRAME/HelpIcon-ReportLag.png")
      -- SetPortraitToTexture(icon, icon:GetTexture())
      -- icon:SetAllPoints()
      icon:SetPoint("CENTER", b, 0, 0)
      icon:SetSize(height - 20, height - 20)
      icon:SetTexCoord(0.07, 0.95, 0.08, 0.97)
      icon:SetAlpha(0.9)
      icon:SetDesaturated(true)
    
      b.icon = icon
    end
    
    -- local value = b.value
    -- if not value then
    --   value = b:CreateFontString(nil, "ARTWORK")
    --   value:SetAllPoints()
    --   value:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
    --   value:SetTextColor(0.95, 0.95, 1.0, 1)
    --   -- value:SetJustifyH("LEFT")
    --   -- value:SetShadowOffset(1, -1)
    --   value:SetText("%")
    --
    --   b.value = value
    -- end
    
    b:SetScript("OnEnter", mouseEnterButton)
    b:SetScript("OnLeave", mouseExitButton)
    b:SetScript("OnMouseDown", mousePushButton)
    b:SetScript("OnMouseUp", mouseReleaseButton)
    
    b.titleString = "Reset"
    b.textString = "Reset current fight."
    
    reset = b
    reset:SetSize(headerObjectSize, headerObjectSize)
    reset:ClearAllPoints()
    reset:SetPoint("RIGHT", save, "LEFT", -headerObjectSpacing, 0)
  
    f.resetButton = reset
  end

  local settings = f.settingsButton
  if not settings then
    local width, height = 160, 60
    
    local f = header
    local b = CreateFrame("Button", nil, f)
    b:SetSize(width, height)
    b:SetPoint("LEFT", f, 5, 0)
    
    local bg = b.background
    if not bg then -- Background texture and gradient
      bg = b:CreateTexture(nil, "BACKGROUND", nil, -8)
      bg:SetTexture(0.1, 0.1, 0.1, 1.0)
      bg:SetAllPoints()
      b:SetNormalTexture(bg)
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Top", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.1, 0, 0, 0, 0) -- Top
      g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("TOP", bg, 0, 0)
      bg[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Bottom", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.1) -- Bottom
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("BOTTOM", bg, 0, 0)
      bg[2] = g
      
      b.background = bg
    end
    
    local shadow = b.shadow
    if not shadow then
      shadow = b:CreateTexture("CT_Base_Button_Shadow", "BACKGROUND")
      shadow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
      shadow:SetPoint("TOPLEFT", -1, 1)
      shadow:SetPoint("BOTTOMRIGHT", 0, -0)
      shadow:SetVertexColor(0, 0, 0, 1)
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Bottom_Edge", "BACKGROUND")
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 1)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, 5)
      g:SetPoint("TOP", shadow, "BOTTOM", 0, 0)
      g:SetPoint("RIGHT", shadow, 2, 0)
      g:SetPoint("LEFT", shadow, 0, 0)
      shadow[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Right_Edge", "BACKGROUND")
      g:SetGradientAlpha("HORIZONTAL", 0.01, 0.01, 0.01, 1, 0, 0, 0, 0)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(3, height)
      g:SetPoint("LEFT", shadow, "RIGHT", 0, 0)
      g:SetPoint("TOP", shadow, 0, 0)
      g:SetPoint("BOTTOM", shadow, 0, -2)
      shadow[2] = g
    
      b.shadow = shadow
    end
    
    local icon = b.icon
    if not icon then -- Icon
      icon = b:CreateTexture(nil, "ARTWORK", nil, 6)
      icon:SetTexture("Interface/HELPFRAME/HelpIcon-CharacterStuck.png")
      -- SetPortraitToTexture(icon, icon:GetTexture())
      icon:SetPoint("CENTER", b, 0, 0)
      -- icon:SetAllPoints()
      icon:SetSize(height - 15, height - 15)
      icon:SetTexCoord(0.07, 0.95, 0.08, 0.97)
      icon:SetAlpha(0.9)
      icon:SetDesaturated(true)
    
      b.icon = icon
    end
    
    -- local value = b.value
    -- if not value then
    --   value = b:CreateFontString(nil, "ARTWORK")
    --   value:SetAllPoints()
    --   value:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
    --   value:SetTextColor(0.95, 0.95, 1.0, 1)
    --   value:SetText("#")
    --
    --   b.value = value
    -- end
    
    b:SetScript("OnEnter", mouseEnterButton)
    b:SetScript("OnLeave", mouseExitButton)
    b:SetScript("OnMouseDown", mousePushButton)
    b:SetScript("OnMouseUp", mouseReleaseButton)
    
    b.titleString = "Settings"
    b.textString = "Load CombatTracker's settings."
    
    settings = b
    settings:SetSize(headerObjectSize, headerObjectSize)
    -- settings:SetPoint("LEFT", reset, "RIGHT", 20, 0)
    settings:ClearAllPoints()
    settings:SetPoint("RIGHT", reset, "LEFT", -headerObjectSpacing, 0)
  
    f.settingsButton = settings
  end
  
  local expand = f.expandButton
  if not expand then
    local width, height = 160, 60
    
    local f = header
    local b = CreateFrame("Button", nil, f)
    b:SetSize(width, height)
    b:SetPoint("LEFT", f, 5, 0)
    
    local bg = b.background
    if not bg then -- Background texture and gradient
      bg = b:CreateTexture(nil, "BACKGROUND", nil, -8)
      bg:SetTexture(0.1, 0.1, 0.1, 1.0)
      bg:SetAllPoints()
      b:SetNormalTexture(bg)
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Top", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.1, 0, 0, 0, 0) -- Top
      g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("TOP", bg, 0, 0)
      bg[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Bottom", "ARTWORK", nil, 1)
      -- g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.1) -- Bottom
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, height / 2)
      g:SetPoint("CENTER", bg, 0, 0)
      g:SetPoint("RIGHT", bg, 0, 0)
      g:SetPoint("LEFT", bg, 0, 0)
      g:SetPoint("BOTTOM", bg, 0, 0)
      bg[2] = g
      
      b.background = bg
    end
    
    local shadow = b.shadow
    if not shadow then
      shadow = b:CreateTexture("CT_Base_Button_Shadow", "BACKGROUND")
      shadow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
      shadow:SetPoint("TOPLEFT", -1, 1)
      shadow:SetPoint("BOTTOMRIGHT", 0, -0)
      shadow:SetVertexColor(0, 0, 0, 1)
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Bottom_Edge", "BACKGROUND")
      g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 1)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(width, 5)
      g:SetPoint("TOP", shadow, "BOTTOM", 0, 0)
      g:SetPoint("RIGHT", shadow, 2, 0)
      g:SetPoint("LEFT", shadow, 0, 0)
      shadow[1] = g
      
      local g = b:CreateTexture("CT_Base_Button_Shadow_Right_Edge", "BACKGROUND")
      g:SetGradientAlpha("HORIZONTAL", 0.01, 0.01, 0.01, 1, 0, 0, 0, 0)
      g:SetTexture(1, 1, 1, 1)
      g:SetSize(3, height)
      g:SetPoint("LEFT", shadow, "RIGHT", 0, 0)
      g:SetPoint("TOP", shadow, 0, 0)
      g:SetPoint("BOTTOM", shadow, 0, -2)
      shadow[2] = g
    
      b.shadow = shadow
    end
    
    local icon = b.icon
    if not icon then -- Icon
      icon = b:CreateTexture(nil, "ARTWORK", nil, 6)
      icon:SetTexture("Interface/HELPFRAME/ReportLagIcon-AuctionHouse.png")
      -- SetPortraitToTexture(icon, icon:GetTexture())
      icon:SetPoint("CENTER", b, 0, 0)
      -- icon:SetAllPoints()
      icon:SetSize(height - 15, height - 15)
      icon:SetTexCoord(0.07, 0.95, 0.08, 0.97)
      icon:SetAlpha(0.9)
      icon:SetDesaturated(true)
    
      b.icon = icon
    end
    
    -- local value = b.value
    -- if not value then
    --   value = b:CreateFontString(nil, "ARTWORK")
    --   value:SetAllPoints()
    --   value:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
    --   value:SetTextColor(0.95, 0.95, 1.0, 1)
    --   value:SetText("#")
    --
    --   b.value = value
    -- end
    
    b:SetScript("OnEnter", mouseEnterButton)
    b:SetScript("OnLeave", mouseExitButton)
    b:SetScript("OnMouseDown", mousePushButton)
    b:SetScript("OnMouseUp", mouseReleaseButton)
    
    b.titleString = "Expand"
    b.textString = "Expand the frame to view more details."
    
    expand = b
    expand:SetSize(headerObjectSize, headerObjectSize)
    -- settings:SetPoint("LEFT", reset, "RIGHT", 20, 0)
    expand:ClearAllPoints()
    expand:SetPoint("RIGHT", settings, "LEFT", -headerObjectSpacing, 0)
    
    function expand.mouseUpFunc()
      CT:toggleBaseExpansion()
    end
  
    f.expandButton = expand
  end
  
  tinsert(UISpecialFrames, f:GetName())
end

local highlightButton, ticker = nil, nil
local function mouseExitButton(self) -- Sometimes the OnLeave event gets missed. All of this extra stuff is here to make sure it's caught
  if self.Cancel then self = highlightButton end -- A ticker was passed as first arg, use local instead
  
  if not MouseIsOver(self) then
    CT.setTooltip()
    
    self.background:SetTexture(0.1, 0.1, 0.1, 1.0)
    highlightButton = nil
    
    if ticker then
      ticker:Cancel()
      ticker = nil
    end
  end
end

local function mouseEnterButton(self)
  -- local textString = ("The current button name is: %s"):format(self.name or "NO NAME!")
  CT.setTooltip(self, self.titleString, self.textString)
  
  self.background:SetTexture(0.13, 0.13, 0.13, 1.0)
  highlightButton = self
  
  if ticker then
    ticker:Cancel()
    ticker = nil
  end
  
  ticker = newTicker(0.1, mouseExitButton)
end

local pushedButton, clickType, ticker = nil, nil, nil
local icon1, icon2, icon3, icon4, icon5 = nil, nil, nil, nil, nil
local value1, value2, value3, value4, value5 = nil, nil, nil, nil, nil
local title1, title2, title3, title4, title5 = nil, nil, nil, nil, nil
local function mouseReleaseButton(self, click)
  if click == "LeftButton" then
    -- if self.Cancel then self = pushedButton end -- A ticker was passed as first arg, use local instead
    
    self.background[1]:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
    self.background[2]:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
    
    if self.icon then
      self.icon:SetPoint(icon1, icon2, icon3, icon4, icon5)
    end
    
    if self.value then
      self.value:SetPoint(value1, value2, value3, value4, value5)
    end
    
    if self.title then
      self.title:SetPoint(title1, title2, title3, title4, title5)
    end

    if MouseIsOver(self) then
      CT:toggleBaseExpansion("show")
      
      if not self.checked then
        self.checked = self:CreateTexture(nil, "BACKGROUND")
        self.checked:SetTexture("Interface\\PetBattles\\PetJournal")
        self.checked:SetTexCoord(0.49804688, 0.90625000, 0.17480469, 0.21972656) -- Blue highlight border
        self.checked:SetBlendMode("ADD")
        self.checked:SetPoint("TOPLEFT", 0, 0)
        self.checked:SetPoint("BOTTOMRIGHT", 0, 0)
        self:SetCheckedTexture(self.checked)

        self.checked:SetVertexColor(0.3, 0.5, 0.8, 0.8) -- Blue: Dark and more subtle blue
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
      
      for i = 1, #CT.buttons do
        if CT.buttons[i] ~= self and CT.buttons[i]:GetChecked() then
          CT.buttons[i]:SetChecked(false)
          CT.buttons[i].expanded = false
        end
      end
      
      PlaySound("igMainMenuOptionCheckBoxOn")
    end
  end
end

local iconOffset = 1
local textOffset = 1
local function mousePushButton(self, click)
  if click == "LeftButton" then
    self.background[2]:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
    self.background[1]:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
    
    if self.icon then
      icon1, icon2, icon3, icon4, icon5 = self.icon:GetPoint()
      self.icon:SetPoint(icon1, icon2, icon3, (icon4 + iconOffset), (icon5 - iconOffset))
    end
    
    if self.value then
      value1, value2, value3, value4, value5 = self.value:GetPoint()
      self.value:SetPoint(value1, value2, value3, (value4 + iconOffset), (value5 - iconOffset))
    end
    
    if self.title then
      title1, title2, title3, title4, title5 = self.title:GetPoint()
      self.title:SetPoint(title1, title2, title3, (title4 + textOffset), (title5 - textOffset))
    end
    
    -- pushedButton = self
    -- clickType = click
    
    -- ticker = newTicker(0.1, mouseReleaseButton)
  end
end

function CT:buildNewButton(index, parent)
  local width, height = 160, 60
  
  local f = parent or CT.base.scroll
  local b = CreateFrame("CheckButton", "CombatTracker_Main_Button_" .. index, f)
  b:SetSize(width, height)
  b:SetPoint("LEFT", f, 5, 0)
  
  do -- Set up button data from the specData table (self)
    b.name = self.name
    b.num = index
    b.powerIndex = self.powerIndex
    b.update = self.func
    b.expanderUpdate = self.expanderFunc
    b.dropDownFunc = self.dropDownFunc
    b.lineTable = self.lines
    b.costsPower = self.costsPower
    b.givesPower = self.givesPower
    b.spellID = self.spellID or select(7, GetSpellInfo(self.name))
    b.spellName = self.spellName or GetSpellInfo(self.spellID)
    b.iconTexture = self.icon or GetSpellTexture(self.spellID) or GetSpellTexture(self.name) or CT.player.specIcon
    
    tinsert(CT.update, b)
  end
  
  local bg = b.background
  if not bg then -- Background texture and gradient
    bg = b:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetTexture(0.1, 0.1, 0.1, 1.0)
    bg:SetAllPoints()
    b:SetNormalTexture(bg)
    
    local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Top", "ARTWORK", nil, 1)
    -- g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.1, 0, 0, 0, 0) -- Top
    g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
    g:SetTexture(1, 1, 1, 1)
    g:SetSize(width, height / 2)
    g:SetPoint("CENTER", bg, 0, 0)
    g:SetPoint("RIGHT", bg, 0, 0)
    g:SetPoint("LEFT", bg, 0, 0)
    g:SetPoint("TOP", bg, 0, 0)
    bg[1] = g
    
    local g = b:CreateTexture("CT_Base_Button_Background_Gradient_Bottom", "ARTWORK", nil, 1)
    -- g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.1) -- Bottom
    g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
    g:SetTexture(1, 1, 1, 1)
    g:SetSize(width, height / 2)
    g:SetPoint("CENTER", bg, 0, 0)
    g:SetPoint("RIGHT", bg, 0, 0)
    g:SetPoint("LEFT", bg, 0, 0)
    g:SetPoint("BOTTOM", bg, 0, 0)
    bg[2] = g
    
    b.background = bg
  end
  
  local shadow = b.shadow
  if not shadow then
    shadow = b:CreateTexture("CT_Base_Button_Shadow", "BACKGROUND")
    shadow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    shadow:SetPoint("TOPLEFT", -1, 1)
    shadow:SetPoint("BOTTOMRIGHT", 0, -0)
    shadow:SetVertexColor(0, 0, 0, 1)
    
    local g = b:CreateTexture("CT_Base_Button_Shadow_Bottom_Edge", "BACKGROUND")
    g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 1)
    g:SetTexture(1, 1, 1, 1)
    g:SetSize(width, 5)
    g:SetPoint("TOP", shadow, "BOTTOM", 0, 0)
    g:SetPoint("RIGHT", shadow, 2, 0)
    g:SetPoint("LEFT", shadow, 0, 0)
    shadow[1] = g
    
    local g = b:CreateTexture("CT_Base_Button_Shadow_Right_Edge", "BACKGROUND")
    g:SetGradientAlpha("HORIZONTAL", 0.01, 0.01, 0.01, 1, 0, 0, 0, 0)
    g:SetTexture(1, 1, 1, 1)
    g:SetSize(3, height)
    g:SetPoint("LEFT", shadow, "RIGHT", 0, 0)
    g:SetPoint("TOP", shadow, 0, 0)
    g:SetPoint("BOTTOM", shadow, 0, -2)
    shadow[2] = g
  
    b.shadow = shadow
  end
  
  local icon = b.icon
  if not icon then -- Icon
    icon = b:CreateTexture(nil, "ARTWORK", nil, 6)
    icon:SetTexture(self.icon or GetSpellTexture(self.name) or CT.player.specIcon)
    SetPortraitToTexture(icon, icon:GetTexture())
    icon:SetPoint("LEFT", b, 7.5, 0)
    icon:SetSize(height - 15, height - 15)
    icon:SetTexCoord(0.07, 0.95, 0.08, 0.97)
    icon:SetAlpha(0.9)
    
    b.icon = icon
  end
  
  local value = b.value
  if not value then
    value = b:CreateFontString(nil, "ARTWORK")
    value:SetPoint("LEFT", icon, "RIGHT")
    value:SetPoint("RIGHT", b, 0, 0)
    -- value:SetPoint("BOTTOMRIGHT", b)
    -- value:SetPoint("TOP", b, 0, 0)
    -- value:SetPoint("BOTTOM", b, 0, 0)
    -- value:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    value:SetFont("Fonts\\FRIZQT__.TTF", 26, "OUTLINE")
    value:SetTextColor(0.95, 0.95, 1.0, 1)
    value:SetJustifyH("LEFT")
    value:SetShadowOffset(1, -1)
    value:SetFormattedText("%s%%", random(1, 100))
    
    b.value = value
  end
  
  b:SetScript("OnEnter", mouseEnterButton)
  b:SetScript("OnLeave", mouseExitButton)
  b:SetScript("OnMouseDown", mousePushButton)
  b:SetScript("OnMouseUp", mouseReleaseButton)
  
  b.titleString = self.name
  b.textString = findInfoText(b, self.name or "")
  
  if self.name and self.name ~= "CombatTracker" then
    self.button = b
  end
  
  b.defaultWidth, b.defaultHeight = b:GetSize()
  
  CT.buttons[#CT.buttons + 1] = b
  
  return b
end

function CT:expanderFrame_OLD(command)
  if true then return error("Called CT:expanderFrame") end
  
  if not CT.base then CT:OnEnable("load") end

  local f = CT.base.expander
  if not f then
    f = CreateFrame("Frame", "CombatTracker_Expander_Scroll_Frame", CT.base)
    f.anchor = CreateFrame("ScrollFrame", "CombatTracker_Expander_Scroll_Frame_Anchor", CT.base)
    f.anchor:SetScrollChild(f)
    f:SetAllPoints(f.anchor)

    -- f.anchor:SetPoint("LEFT", CT.base, "RIGHT")
    f.anchor:SetPoint("TOPLEFT", CT.base, "TOPRIGHT")
    f.anchor:SetPoint("BOTTOMLEFT", CT.base, "BOTTOMRIGHT")

    local width, height = CT.base:GetSize()
    f.anchor:SetSize(width + 100, height)

    f.anchor.bg = f.anchor:CreateTexture(nil, "BACKGROUND")
    f.anchor.bg:SetTexture(0, 0, 0, CT.settings.backgroundAlpha or 0.7)
    f.anchor.bg:SetAllPoints()

    -- f:EnableMouse(true)

    f.stepSize = 20
    f.up = 0
    f.down = height

    f.anchor:SetScript("OnMouseWheel", function(self, direction)
      local newValue = (f.scrollValue or 0) + (-f.stepSize * direction)

      if (f.up > newValue) then
        newValue = f.up
      elseif (newValue > f.down) then
        newValue = f.down
      end

      f.scrollValue = newValue

      if direction > 0 then -- Up
        f:SetSize(self:GetSize())
        self:SetVerticalScroll(f.scrollValue)
        debug("Up", f.scrollValue)
      else -- Down
        f:SetSize(self:GetSize())
        self:SetVerticalScroll(f.scrollValue)
        debug("Down", f.scrollValue)
      end
    end)

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
        CT.base.expander.titleData.rightText1:SetText(CT.displayedDB.setName or "None loaded.")

        if self.graphFrame and not self.graphFrame.displayed[1] then -- No regular graph is loaded
          debug("No regular graph, loading default.")

          CT.loadDefaultGraphs()
          CT.finalizeGraphLength("line")
        end

        if self.uptimeGraph and not self.uptimeGraph.displayed then -- No uptime graph is loaded
          debug("No uptime graph, loading default.")

          CT.loadDefaultUptimeGraph()
          CT.finalizeGraphLength("uptime")
        end
      end
    end)

    f:SetScript("OnHide", function(self)
      -- debug("Expander hiding")
    end)

    f:Hide()
    CT.base.expander = f

    function CT.base.expander:updateMinMaxValues(table)
      local height = 0

      local spacing = CT.settings.buttonSpacing

      for i, button in ipairs(table) do
        height = height + button:GetHeight() + spacing
      end

      height = height - self.anchor:GetHeight()
      if 0 > height then height = 0 end

      self.down = height
    end
  end

  local slider = f.slider
  if not slider then
    slider = CreateFrame("Slider", nil, f)
    slider:SetSize(100, 20)
    slider:SetPoint("TOPLEFT", f, 5, -3)
    slider:SetPoint("TOPRIGHT", f, -5, -3)

    slider:SetBackdrop({
      bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
      edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 8,})
    slider:SetBackdropColor(0.15, 0.15, 0.15, 0)
    slider:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.5)

    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
    slider:SetOrientation("VERTICAL")
    slider:SetMinMaxValues(0, 400)
    slider:SetValue(0)

    slider:SetScript("OnValueChanged", function(self, value)
      f:SetSize(f.anchor:GetSize())
      f.anchor:SetVerticalScroll(value)
    end)

    f.scrollMultiplier = 10 -- Percent of total distance per scroll

    if not slider.mouseWheelFunc then
      function slider.mouseWheelFunc(self, value)
        local current = slider:GetValue()
        local minimum, maximum = slider:GetMinMaxValues()

        local onePercent = (maximum - minimum) / 100
        local percent = (current - minimum) / (maximum - minimum) * 100

        if value < 0 and current < maximum then
          current = min(maximum, current + (onePercent * f.scrollMultiplier))
        elseif value > 0 and current > minimum then
          current = max(minimum, current - (onePercent * f.scrollMultiplier))
        end

        slider:SetValue(current)
      end
    end

    slider:SetScript("OnMouseWheel", slider.mouseWheelFunc)
    f.anchor:SetScript("OnMouseWheel", slider.mouseWheelFunc)

    slider:Hide()
    f.slider = slider
  end

  local colB = f.collapseButton
  if not colB then
    colB = CreateFrame("Button", "CombatTracker_Base_Expander_Button", f)
    colB:SetPoint("RIGHT", f, -1, 0)
    colB:SetSize(10, 200)

    colB.bg = colB:CreateTexture(nil, "BACKGROUND")
    colB.bg:SetTexture("Interface\\addons\\CombatTracker\\Media\\ScrollBG.tga")
    colB.bg:SetAllPoints()

    colB.arrows = {}
    local y = 20
    for i = 1, 3 do
      local a = colB:CreateTexture(nil, "ARTWORK")
      a:SetTexture("Interface/MONEYFRAME/Arrow-Left-Up.png")
      a:SetSize(15, 15)
      a:SetPoint("CENTER", colB, -3, y)
      a:SetVertexColor(0.5, 0.5, 0.5, 0.9)

      y = y - 20

      colB.arrows[i] = a
    end

    colB:SetScript("OnMouseDown", function(self, click)
      for i = 1, #colB.arrows do
        colB.arrows[i]:SetTexture("Interface/MONEYFRAME/Arrow-Left-Down.png") -- Pushed version
      end
    end)

    colB:SetScript("OnMouseUp", function(self, click)
      for i = 1, #colB.arrows do
        colB.arrows[i]:SetTexture("Interface/MONEYFRAME/Arrow-Left-Up.png") -- Restore texture
      end

      if MouseIsOver(self) then
        CT:expanderFrame()
      end
    end)

    f.collapseButton = colB
  end

  local rightOffset = 20
  local leftOffSet = 15

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

        f.titleBG.info = findInfoText(f.titleBG, displayed)

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
      f.titleData:SetPoint("TOPRIGHT", f, -rightOffset, -15)
      -- f.titleData:SetPoint("TOPRIGHT", f, -15, -15)
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

  if not f.resetAnchors then
    function f.resetAnchors()
      local uptimeGraphs, normalGraphs = f.uptimeGraphs, f.normalGraphs

      do -- Uptime graph anchors
        for i = 1, #uptimeGraphs do
          local uptimeGraph = uptimeGraphs[i]

          uptimeGraph:ClearAllPoints()
          uptimeGraph.defaultHeight = uptimeGraph:GetHeight()

          if i == 1 then
            uptimeGraph:SetPoint("LEFT", f.dataFrames[3], 0, 0)
            uptimeGraph:SetPoint("RIGHT", f.dataFrames[4], 0, 0)
            uptimeGraph:SetPoint("TOP", f.dataFrames[4], "BOTTOM", 0, -10)
          else
            local anchor = uptimeGraphs[i - 1]
            uptimeGraph:SetPoint("LEFT", anchor, 0, 0)
            uptimeGraph:SetPoint("RIGHT", anchor, 0, 0)
            uptimeGraph:SetPoint("TOP", anchor, "BOTTOM", 0, 0)
          end
        end
      end

      do -- Normal graph anchors
        for i = 1, #normalGraphs do
          local normalGraph = normalGraphs[i]

          normalGraph:ClearAllPoints()

          if i == 1 then
            local anchor = uptimeGraphs[#uptimeGraphs] -- Lowest uptime graph
            normalGraph:SetPoint("LEFT", anchor, 0, 0)
            normalGraph:SetPoint("RIGHT", anchor, 0, 0)
            normalGraph:SetPoint("TOP", anchor, "BOTTOM", 0, -10)
          else
            local anchor = normalGraphs[i - 1]
            normalGraph:SetPoint("LEFT", anchor, 0, 0)
            normalGraph:SetPoint("RIGHT", anchor, 0, 0)
            normalGraph:SetPoint("TOP", anchor, "BOTTOM", 0, -10)
          end
        end
      end
    end
  end

  local uptimeGraphs = f.uptimeGraphs
  if not uptimeGraphs then
    uptimeGraphs = {}

    function f.addUptimeGraph()
      local num = #uptimeGraphs + 1
      uptimeGraphs[num] = CT.buildUptimeGraph(f)
      uptimeGraphs[num]:SetHeight(25)
      uptimeGraphs[num]:SetParent(f)

      return uptimeGraphs[num]
    end

    f.addUptimeGraph()

    f.uptimeGraphs = uptimeGraphs
  end

  local normalGraphs = f.normalGraphs
  if not normalGraphs then
    normalGraphs = {}

    function f.addNormalGraph()
      local num = #normalGraphs + 1
      normalGraphs[num] = CT.buildGraph(f)
      normalGraphs[num]:SetParent(f)
      normalGraphs[num]:SetHeight(150)

      return normalGraphs[num]
    end

    function f.removeNormalGraph() -- TODO: Set this up, and for uptime as well
      local num = #normalGraphs + 1
      normalGraphs[num] = CT.buildGraph(f)
      normalGraphs[num]:SetParent(f)
      normalGraphs[num]:SetHeight(150)

      debug("REMOVING normal graph.")

      return normalGraphs[num]
    end

    f.addNormalGraph()

    f.normalGraphs = normalGraphs
  end

  f.resetAnchors()

  if f.shown and (command and command == "hide") or (not command and f:IsShown()) then
    f:Hide()
    f.anchor:Hide()
    f.collapseButton:Hide()
    CT.base.expandButton:Show()
    f.shown = false
  elseif not f.shown and (command and command == "show") or (not command and not f:IsShown()) then
    f:Show()
    f.anchor:Show()
    f.collapseButton:Show()
    CT.base.expandButton:Hide()
    f.shown = true
  end

  if f.shown and self ~= CombatTracker then
    if self and self.name then
      f.currentButton = self

      f.icon:SetTexture(self.iconTexture or CT.player.specIcon)
      SetPortraitToTexture(f.icon, f.icon:GetTexture())

      f.titleText:SetText(self.name)

      addExpanderText(self, self.lineTable)

      local buttonName = self.name

      if CT.displayed then
        do -- Try to find default graphs related to this particular button
          local spellName = self.spellName or GetSpellInfo(self.spellID) or GetSpellInfo(self.name) or self.name

          if spellName then
            local matchedGraph

            for i = 1, #CT.graphList do
              if spellName:match(CT.graphList[i]) then
                matchedGraph = CT.graphList[i]
                break
              end
            end

            if matchedGraph then
              CT.graphFrame:hideAllGraphs()
              CT.displayed.graphs[matchedGraph]:toggle("show")
            end
          end
        end

        do -- Try to match an uptime graph with this button
          local spellName = self.spellName or GetSpellInfo(self.spellID) or GetSpellInfo(self.name) or self.name
          local spellID = self.spellID or select(7, GetSpellInfo(self.name))

          local uptimeGraphs = CT.displayed.uptimeGraphs
          local matchedGraph, activityGraph

          for index = 1, #CT.uptimeCategories do -- Run through each type of uptime graph (ex: "buffs")
            for graphIndex, setGraph in ipairs(uptimeGraphs[CT.uptimeCategories[index]]) do -- Run every graph in that type (ex: "Illuminated Healing")

              if spellID and spellID == setGraph.spellID then
                matchedGraph = setGraph
              elseif spellName == setGraph.name then
                matchedGraph = setGraph
              elseif self.name == setGraph.name then
                matchedGraph = setGraph
              elseif self.name == setGraph.spellID then
                matchedGraph = setGraph
              end

              if setGraph.name == "Activity" then
                activityGraph = setGraph
              end
            end
          end

          if matchedGraph then
            matchedGraph:toggle("show")
          elseif CT.settings.hideUptimeGraph then
            if CT.uptimeGraphFrame and CT.uptimeGraphFrame.displayed then
              CT.uptimeGraphFrame.displayed:toggle("clear")
            end
          elseif activityGraph then
            activityGraph:toggle("show")
          end
        end

        do -- Handles power and spell frames
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
    end

    CT.forceUpdate = true
  end
end

-- function CT.createBaseFrame_OLD() -- Create Base Frame
--   local f = CT.base
--   if not f then -- NOTE: Base frame is created at the top so that its position gets saved properly.
--     CT.base = baseFrame
--     f = CT.base
--     f:SetPoint("CENTER")
--     f:SetSize(350, 556)
--
--     local backdrop = {
--     bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
--     edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
--     tileSize = 32,
--     edgeSize = 16,}
--
--     f:SetBackdrop(backdrop)
--     f:SetBackdropColor(0.15, 0.15, 0.15, 1)
--     f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)
--
--     f:EnableMouse(true)
--     f:EnableKeyboard(true)
--     f:SetResizable(true)
--     f:SetUserPlaced(true)
--
--     f:SetScript("OnMouseDown", function(self, click)
--       if click == "LeftButton" and not self.isMoving then
--         if CT.graphFrame and CT.graphFrame.displayed and CT.graphFrame.displayed[1] then -- Hide any graphs before dragging, they can cause insane lag
--           for index = 1, #CT.graphFrame.displayed do
--             local graph = CT.graphFrame.displayed[index]
--             local lines, bars, triangles = graph.lines, graph.bars, graph.triangles
--
--             for i = 1, #graph.data do -- Show all the lines
--               if lines[i] then
--                 lines[i]:Hide()
--               end
--
--               if bars and bars[i] then
--                 bars[i]:Hide()
--               end
--
--               if triangles and triangles[i] then
--                 triangles[i]:Hide()
--               end
--             end
--           end
--         end
--
--         self:StartMoving()
--         self.isMoving = true
--       end
--     end)
--
--     f:SetScript("OnMouseUp", function(self, button)
--       if button == "LeftButton" and self.isMoving then
--         self:StopMovingOrSizing()
--         self.isMoving = false
--         CT:updateButtonList()
--
--         if CT.graphFrame and CT.graphFrame.displayed and CT.graphFrame.displayed[1] then -- Put them all back
--           for index = 1, #CT.graphFrame.displayed do
--             local graph = CT.graphFrame.displayed[index]
--             local lines, bars, triangles = graph.lines, graph.bars, graph.triangles
--
--             for i = 1, #graph.data do -- Show all the lines
--               if lines[i] then
--                 lines[i]:Show()
--               end
--
--               if bars and bars[i] then
--                 bars[i]:Show()
--               end
--
--               if triangles and triangles[i] then
--                 triangles[i]:Show()
--               end
--             end
--           end
--         end
--       end
--     end)
--
--     f:SetScript("OnEnter", function(self)
--       if lastMouseoverButton then
--         lastMouseoverButton.dragger:SetAlpha(0)
--         lastMouseoverButton.upArrow:SetAlpha(0)
--         lastMouseoverButton.downArrow:SetAlpha(0)
--         lastMouseoverButton:UnlockHighlight()
--       end
--     end)
--
--     f:SetScript("OnShow", function(self)
--       self.shown = true
--
--       if not CT.current and not CT.displayed then
--         debug("CT.base (OnShow): No current set, so trying to load the last saved set.")
--         CT.loadSavedSet() -- Load the most recent set as default
--       end
--     end)
--
--     f:SetScript("OnHide", function(self)
--       self.shown = false
--     end)
--
--     function CT.base:cycleMainButtons() -- NOTE: If order is changed, this gets all messed up. Also it revers to the old order.
--       if true then return end
--       local numBeforeUpdate = CT.totalNumButtons
--
--       for i = 1, #CT.mainButtons do
--         local button = CT.mainButtons[i]
--         if not button.AGFadeIn then
--           button.AGFadeIn = button:CreateAnimationGroup("Fade In")
--           local animation = button.AGFadeIn:CreateAnimation("Alpha")
--           animation:SetDuration(0.5)
--           animation:SetChange(1)
--           animation:SetSmoothing("IN")
--           button.AGFadeIn:SetScript("OnFinished", function(self, requested)
--             button:SetAlpha(1)
--           end)
--         end
--         if not button.AGFadeOut then
--           button.AGFadeOut = button:CreateAnimationGroup("Fade Out")
--           local animation = button.AGFadeOut:CreateAnimation("Alpha")
--           animation:SetDuration(0.5)
--           animation:SetChange(-1)
--           animation:SetStartDelay(i * 0.1)
--           animation:SetSmoothing("OUT")
--           button.AGFadeOut:SetScript("OnFinished", function(self, requested)
--             button:SetAlpha(0)
--             -- CT.updateText(button) -- removed this function, shouldn't be worth it overall. If needed, call SetText() here manually.
--             CT.updateSpellIcons(button)
--             button.AGFadeIn:Play()
--             if button.num > CT.totalNumButtons then
--               button:Hide()
--             end
--           end)
--         end
--         if button.num > numBeforeUpdate then
--           button:SetAlpha(0)
--         end
--         button.AGFadeOut:Play()
--       end
--     end
--   end
--
--   local dragger = f.dragger
--   if not dragger then -- Main size dragger
--     f:SetMaxResize(350, 700)
--     f:SetMinResize(350, 556)
--
--     f.dragger = CreateFrame("Button", nil, f)
--     dragger = f.dragger
--
--     f.dragger:SetSize(20, 20)
--     f.dragger:SetPoint("BOTTOMRIGHT", -1, 2)
--     f.dragger:SetNormalTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Up.png")
--     f.dragger:SetPushedTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Down.png")
--     f.dragger:SetHighlightTexture("Interface/CHATFRAME/UI-ChatIM-SizeGrabber-Highlight.png")
--
--     -- NOTE: Need to get resolution properly
--     f.dragger:SetScript("OnMouseDown", function(self)
--       CT.base:StartSizing()
--
--       -- local UIScale = UIParent:GetEffectiveScale()
--       -- local startX, startY = GetCursorPosition()
--       -- local startX = startX / UIScale
--       -- local startY = startY / UIScale
--       --
--       -- local resolutionX = 1920
--       -- local resolutionY = 1080
--       --
--       -- local startLeft, startBottom, startWidth, startHeight = CT.base:GetRect()
--       -- local startScale = CT.base:GetScale()
--       -- -- GetEffectiveScale()
--       --
--       -- self.ticker = C_Timer.NewTicker(0.001, function(ticker)
--       -- local mouseX, mouseY = GetCursorPosition()
--       -- local mouseX = (mouseX / UIScale)
--       -- local mouseY = (mouseY / UIScale)
--       --
--         -- if (mouseX > startX) or (mouseY < startY) then -- Increasing Scale
--         --   local valX = (mouseX - startX) / resolutionX
--         --   local valY = (startY - mouseY) / resolutionY
--         --
--         --   local maxVal = max(valX, valY)
--         --   local newScale = startScale + maxVal
--         --
--         --   CT.base:SetScale(newScale)
--         -- else -- Decreasing Scale
--         --   local valX = (mouseX - startX) / resolutionX
--         --   local valY = (startY - mouseY) / resolutionY
--         --
--         --   local minVal = min(valX, valY)
--         --   local newScale = startScale + minVal
--         --
--         --   CT.base:SetScale(newScale)
--         -- end
--       -- end)
--     end)
--
--     f.dragger:SetScript("OnMouseUp", function(self)
--       CT.base:StopMovingOrSizing()
--
--       -- self.ticker:Cancel()
--     end)
--   end
--
--   local scrollFrame = CT.scrollFrame
--   if not scrollFrame then -- Scroll Frame, Main Content Frame, and Scroll Bar
--     CT.scrollFrame = CreateFrame("ScrollFrame", "CT_ScrollFrame", CT.base)
--     scrollFrame = CT.scrollFrame
--
--     CT.scrollFrame:SetPoint("TOPLEFT", 25, -88)
--     CT.scrollFrame:SetPoint("BOTTOMRIGHT", -25, 53)
--
--     CT.scrollBar = CreateFrame("Slider", "CT_ScrollBar", CT.scrollFrame, "UIPanelScrollBarTemplate")
--     CT.scrollBar:SetPoint("TOPRIGHT", CT.scrollFrame, 20, 0)
--     CT.scrollBar:SetPoint("BOTTOMRIGHT", CT.scrollFrame, 20, 0)
--     CT.scrollBar.background = CT.scrollBar:CreateTexture("CT_ScrollBarBackground", "BACKGROUND")
--     CT.scrollBar.background:SetTexture("Interface\\addons\\CombatTracker\\Media\\ScrollBG.tga")
--     CT.scrollBar.background:SetAllPoints()
--     CT.scrollBar.thumbTexture = CT.scrollBar:CreateTexture("CT_ScrollBarThumbTexture")
--     CT.scrollBar.thumbTexture:SetTexture("Interface\\addons\\CombatTracker\\Media\\ThumbSlider.tga")
--     CT.scrollBar.thumbTexture:SetSize(10, 32)
--     CT.scrollBar:SetThumbTexture(CT.scrollBar.thumbTexture)
--
--     CT.scrollBar.AG = CT.scrollBar:CreateAnimationGroup("ScrollHider")
--     CT.scrollBar.AG.A = CT.scrollBar.AG:CreateAnimation("Alpha")
--     CT.scrollBar.AG.A:SetChange(-1)
--     CT.scrollBar.AG.A:SetDuration(1)
--     CT.scrollBar.AG.A:SetStartDelay(1)
--     CT.scrollBar.AG.A:SetSmoothing("OUT")
--     local c1, c2 = CT.scrollBar:GetChildren()
--       c1:Hide()
--       c2:Hide()
--     CT.scrollBar:SetAlpha(0)
--     CT.scrollBar:SetValueStep(46)
--     CT.scrollBar.scrollStep = 1
--     CT.scrollBar:SetWidth(16)
--     CT.scrollBar:SetScript("OnValueChanged", function(self, value)
--       CT.scrollFrame:SetVerticalScroll(value)
--     end)
--
--     CT.scrollBar.AG:SetScript("OnFinished", function(self, requested)
--       CT.scrollBar:SetAlpha(0)
--     end)
--
--     CT.contentFrame = CreateFrame("Frame", "CT_MainContent", CT.base)
--     CT.contentFrame:SetSize(CT.scrollFrame:GetWidth(), CT.scrollFrame:GetHeight())
--     CT.scrollFrame:SetScrollChild(CT.contentFrame)
--     CT.contentFrame:SetPoint("TOPLEFT", CT.base, 25, -88)
--     CT.contentFrame:SetPoint("BOTTOMRIGHT", CT.base, -25, 100)
--
--     CT.scrollBar:SetScript("OnEnter", function(self, value)
--       CT.scrollBar:SetAlpha(1)
--     end)
--
--     CT.scrollBar:SetScript("OnLeave", function(self, value)
--       CT.scrollBar.AG:Stop()
--       CT.scrollBar.AG:Play()
--     end)
--
--     CT.scrollBar:SetScript("OnMouseWheel", function(self, value)
--       local current = CT.scrollBar:GetValue()
--       local minimum, maximum = CT.scrollBar:GetMinMaxValues()
--
--       if value < 0 and current < maximum then
--         current = min(maximum, current + 46)
--         CT.scrollBar:SetValue(current)
--       elseif value > 0 and current > minimum then
--         current = max(minimum, current - 46)
--         CT.scrollBar:SetValue(current)
--       end
--     end)
--
--     CT.scrollFrame:SetScript("OnMouseWheel", function(self, value)
--       CT.scrollBar:SetAlpha(1)
--
--       local current = CT.scrollBar:GetValue()
--       local minimum, maximum = CT.scrollBar:GetMinMaxValues()
--
--       if value < 0 and current < maximum then
--         current = min(maximum, current + 46)
--         CT.scrollBar:SetValue(current)
--       elseif value > 0 and current > minimum then
--         current = max(minimum, current - 46)
--         CT.scrollBar:SetValue(current)
--       end
--
--       CT.scrollBar.AG:Stop()
--       CT.scrollBar.AG:Play()
--     end)
--
--     local function finishCycleHide(self, requested)
--       local b = self:GetParent()
--       b:Hide()
--     end
--
--     local function finishCycleShow(self, requested)
--       local b = self:GetParent()
--       b:Show()
--       b:SetAlpha(1)
--
--       if b.done then
--         CT.contentFrame.animating = false
--       end
--     end
--
--     function CT.contentFrame:displayMainButtons(buttons)
--       if not buttons then debug("Called display buttons, but didn't pass a button table.") return end
--
--       local num = #buttons
--       self.animating = true
--       self.sourceTable = buttons
--
--       for i = 1, #self do -- Animate button out and hide
--         local b = self[i]
--
--         local fadeOut = b.fadeOut
--         if not fadeOut then
--           fadeOut = b:CreateAnimationGroup()
--           local a = fadeOut:CreateAnimation("Alpha")
--           a:SetDuration(0.2)
--           a:SetSmoothing("OUT")
--           a:SetFromAlpha(1)
--           a:SetToAlpha(-1)
--           fadeOut:SetScript("OnFinished", finishCycleHide)
--
--           fadeOut.a = a
--           b.a = fadeOut
--         end
--
--         fadeOut.a:SetStartDelay(i * 0.05)
--         fadeOut:Play()
--
--         self[i] = nil
--       end
--
--       for i = 1, num do -- Load in new button
--         local b = buttons[i]
--         b:Show()
--         b:SetAlpha(0)
--
--         local fadeIn = b.fadeIn
--         if not fadeIn then
--           fadeIn = b:CreateAnimationGroup()
--           local a = fadeIn:CreateAnimation("Alpha")
--           a:SetDuration(0.2)
--           a:SetSmoothing("IN")
--           a:SetFromAlpha(-1)
--           a:SetToAlpha(1)
--
--           fadeIn:SetScript("OnFinished", finishCycleShow)
--
--           fadeIn.a = a
--           b.a = fadeIn
--         end
--
--         if i == num then -- Last one
--           b.done = true
--         else
--           b.done = false
--         end
--
--         fadeIn.a:SetStartDelay(i * 0.05)
--         fadeIn:Play()
--
--         self[i] = buttons[i]
--       end
--
--       CT.contentFrame:setButtonAnchors(buttons)
--     end
--
--     -- function CT.contentFrame:setButtonAnchors()
--     --   local y = -CT.settings.buttonSpacing
--     --
--     --   for i = 1, #self do
--     --     local button = self[i]
--     --     local prevButton = self[i - 1]
--     --
--     --     if i == 1 then
--     --       button:ClearAllPoints()
--     --       button:SetPoint("TOPLEFT", 0, 0)
--     --       button:SetPoint("TOPRIGHT")
--     --     else
--     --       if i > 2 and prevButton and prevButton.dragging then
--     --         local prevButtonExpander = self[i - 2].expander
--     --         local height = prevButton:GetHeight()
--     --         button:ClearAllPoints()
--     --         button:SetPoint("TOPRIGHT", prevButtonExpander, "BOTTOMRIGHT", 0, (y * 2) - height)
--     --         button:SetPoint("TOPLEFT", prevButtonExpander, "BOTTOMLEFT", 0, (y * 2) - height)
--     --       else
--     --         local prevButtonExpander = self[i - 1].expander
--     --         button:ClearAllPoints()
--     --         button:SetPoint("TOPRIGHT", prevButtonExpander, "BOTTOMRIGHT", 0, y)
--     --         button:SetPoint("TOPLEFT", prevButtonExpander, "BOTTOMLEFT", 0, y)
--     --       end
--     --     end
--     --
--     --     -- local _, coords = button.expander:GetCenter()
--     --     -- button.coords = coords
--     --   end
--     --
--     --   CT.contentFrame:updateMinMaxValues(self)
--     -- end
--   end
--
--   local header, title = f.header, f.title
--   if not header and not title then -- Header and title text and close button
--     header = CreateFrame("Frame", "CT_Base_Header", f)
--     header:SetPoint("TOPLEFT", f, 15, -15)
--     header:SetPoint("TOPRIGHT", f, -15, -15)
--     header:SetHeight(40)
--     header.texture = header:CreateTexture(nil, "BACKGROUND")
--     header.texture:SetTexture(0.1, 0.1, 0.1, 1)
--     header.texture:SetAllPoints(header)
--
--     title = header:CreateFontString(nil, "ARTWORK")
--     title:SetPoint("LEFT", header.texture, 10, 0)
--     title:SetFont("Fonts\\FRIZQT__.TTF", 30)
--     title:SetTextColor(0.8, 0.8, 0, 1)
--     title:SetShadowOffset(3, -3)
--     title:SetText("Combat Tracker")
--     -- title:SetText("Combat \n  Tracker")
--
--     header:SetScript("OnEnter", function(self)
--       self.info = "Combat Tracker tries to detailed information about your performance in combat.\n\nIt is in its beta stages, so please help me out and report bugs! Thanks."
--
--       CT.createInfoTooltip(self, "Title")
--     end)
--
--     header:SetScript("OnLeave", function(self)
--       CT.createInfoTooltip()
--     end)
--
--     f.header = header
--     f.title = title
--   end
--
--   local close = f.closeButton
--   if not close then -- Close button
--     close = CreateFrame("Button", nil, header)
--     close:SetSize(40, 40)
--     close:SetPoint("RIGHT", 0, 0)
--     close:SetNormalTexture("Interface\\RaidFrame\\ReadyCheck-NotReady.png")
--     close:SetHighlightTexture("Interface\\RaidFrame\\ReadyCheck-NotReady.png")
--
--     close.BG = close:CreateTexture(nil, "BORDER")
--     close.BG:SetAllPoints()
--     close.BG:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
--     close.BG:SetVertexColor(0, 0, 0, 0.3)
--
--     close:SetScript("OnClick", function(self)
--       CT.base:Hide()
--     end)
--
--     close:SetScript("OnEnter", function(self)
--       self.info = "Closes Combat Tracker, but it will still be recording CT.current.\n\nType /ct in chat to open it again. Type /ct help to see a full list of chat commands."
--
--       CT.createInfoTooltip(self, "Close", nil, nil, nil, nil)
--     end)
--
--     close:SetScript("OnLeave", function()
--       CT.createInfoTooltip()
--     end)
--
--     f.closeButton = close
--   end
--
--   local expander = f.bottomExpander
--   if not expander then -- Popup expander
--     local width = f:GetWidth()
--
--     expander = CreateFrame("Button", "CT_Base_Expander_Button", f)
--
--     do -- Basic textures and stuff
--       local button = expander
--
--       button.background = button:CreateTexture(nil, "BACKGROUND")
--       button.background:SetPoint("TOPLEFT", button, 4.5, -4)
--       button.background:SetPoint("BOTTOMRIGHT", button, -4, 3)
--       button.background:SetTexture(0.07, 0.07, 0.07, 1.0)
--
--       button.upArrow = button:CreateTexture(nil, "ARTWORK")
--       button.upArrow:SetTexture("Interface/BUTTONS/Arrow-Up-Up.png") -- "Interface/BUTTONS/Arrow-Up-Down.png"
--       button.upArrow:SetSize(16, 16)
--       button.upArrow:SetPoint("CENTER", 0, 0)
--
--       button.normal = button:CreateTexture(nil, "BACKGROUND")
--       button.normal:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
--       button.normal:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
--       button.normal:SetAllPoints(button)
--       button:SetNormalTexture(button.normal)
--
--       button.highlight = button:CreateTexture(nil, "BACKGROUND")
--       button.highlight:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
--       button.highlight:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
--       button.highlight:SetVertexColor(0.7, 0.7, 0.7, 1.0)
--       button.highlight:SetAllPoints(button)
--       button:SetHighlightTexture(button.highlight)
--
--       button.pushed = button:CreateTexture(nil, "BACKGROUND")
--       button.pushed:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
--       button.pushed:SetTexCoord(0.00195313, 0.58789063, 0.92968750, 0.98437500)
--       button.pushed:SetAllPoints(button)
--       button:SetPushedTexture(button.pushed)
--     end
--
--     expander:SetSize(width - 40, 15)
--     expander:SetPoint("BOTTOM", f, 0, 7)
--
--     -- expander:SetScript("OnEnter", function(self)
--     --   after(0.3, function() -- Require the mouse to hover for X seconds before showing
--     --     if not (self.popup and self.popup:IsShown()) and MouseIsOver(self) then -- If hidden and mouse is still over
--     --       self:Click()
--     --     end
--     --   end)
--     -- end)
--
--     expander:SetScript("OnClick", function(self, button)
--       local cTime = GetTime()
--
--       if cTime >= (self.lastClick or 0) then -- Block rapid clicks
--         if not self.popup then
--           self.popup = CreateFrame("Frame", nil, self)
--           self.popup:SetFrameStrata("TOOLTIP")
--           self.popup:SetSize(width - 10, 120)
--           self.popup:SetPoint("BOTTOM", self, 0, 0)
--           self.popup.bg = self.popup:CreateTexture(nil, "BACKGROUND")
--           self.popup.bg:SetAllPoints()
--           self.popup.bg:SetTexture(0.05, 0.05, 0.05, 1.0)
--           self.popup:Hide()
--
--           self.popup:SetScript("OnMouseUp", function(popup)
--             popup:Hide()
--           end)
--
--           self.popup:SetScript("OnShow", function(popup)
--             self.popup.exitTime = GetTime() + 0.5
--
--             if not self.popup.ticker then
--               self.popup.ticker = C_Timer.NewTicker(0.1, function(ticker)
--                 if not MouseIsOver(self.popup) and not MouseIsOver(self) then
--                   if GetTime() > self.popup.exitTime then
--                     self.popup:Hide()
--                     self.popup.ticker:Cancel()
--                     self.popup.ticker = nil
--                   end
--                 else
--                   self.popup.exitTime = GetTime() + 0.5
--                 end
--               end)
--             end
--           end)
--         end
--
--         local animation = self.animation
--         if not animation then
--           self.animation = self:CreateAnimationGroup()
--
--           local a = self.animation:CreateAnimation("Scale")
--           a:SetDuration(0.05)
--           -- self.a.scale:SetSmoothing("OUT")
--           a:SetOrigin("BOTTOM", 0, 0)
--           -- self.a.scale:SetScale(0.3, 0.3)
--           a:SetFromScale(1, 0)
--           a:SetToScale(1, 1)
--           -- self.popup.animation.scale:SetScale(xFactor, yFactor)
--
--           local b = self.animation:CreateAnimation("Alpha")
--           b:SetDuration(0.05)
--           b:SetFromAlpha(0)
--           b:SetToAlpha(1)
--         end
--
--         self.animation:Play()
--
--         if self.popup:IsShown() then
--           self.popup:Hide()
--         else
--           local popup = createMenuButtons(self.popup)
--           popup.shownTime = GetTime() + 0.3
--
--           if not popup[1].func then -- Load saved fights on click handler
--             popup[1].title:SetText("Load Saved Fights")
--
--             local count = 0
--             popup[1].func = function(self, click, cTime)
--               if not CT.contentFrame.animating then
--                 count = count + 1
--
--                 if count == 1 then
--                   local _, specName = GetSpecializationInfo(GetSpecialization())
--
--                   CT.createSavedSetButtons(CombatTrackerCharDB[specName].sets)
--                   popup[1].title:SetText("Return")
--                 else
--                   CT.createSpecDataButtons(CT.specData)
--                   popup[1].title:SetText("Load Saved Fights")
--
--                   count = 0
--                 end
--               end
--             end
--           end
--
--           if not popup[2].func then -- Expand frame on click handler
--             popup[2].title:SetText("Expand Frame")
--
--             popup[2].func = function(self, click, cTime)
--               CT:expanderFrame()
--             end
--           end
--
--           if not popup[3].func then -- Reset data on click handler
--             popup[3].title:SetText("Reset Data")
--
--             popup[3].func = function(self, click, cTime)
--               -- CT.resetData(click)
--               self.title:SetText("This is currently broken and will mess things up.")
--
--               after(3, function()
--                 self.title:SetText("Reset Data")
--               end)
--             end
--           end
--
--           if not popup[4].func then -- Options button on click handler TODO: Make this do something
--             popup[4].title:SetText("Options\n(but not really)")
--
--             popup[4].func = function(self, click, cTime)
--               self.title:SetText("Umm, you don't need options, everything is perfect the way it is.")
--
--               after(3, function()
--                 self.title:SetText("(But seriously, they're on my to-do list. I promise.)")
--
--                 after(3, function()
--                   self.title:SetText("Options\n(but not really)")
--                 end)
--               end)
--             end
--           end
--
--           self.popup:Show()
--         end
--
--         self.lastClick = cTime + 0.2
--       end
--     end)
--
--     f.bottomExpander = expander
--   end
--
--   tinsert(UISpecialFrames, f:GetName())
-- end
--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------
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

-- function CT.comparisonPopout(numRows)
--   if not CT.popout then CT.popout = {} end
--   if not CT.popout.baseStartWidth then CT.popout.baseStartWidth = CombatTrackerBase:GetWidth() end
--
--   if CT.mainButtons[1] then
--     local width = CT.mainButtons[1]:GetWidth()
--     local height = CT.mainButtons[1]:GetHeight()
--     if CT.popout.shown == true then
--       for line = 1, CT.popout.numLines do
--         for i = 1, #CT.popout[line] do
--           CT.popout[line][i]:Hide()
--         end
--       end
--       CombatTrackerBase:SetWidth(CT.popout.baseStartWidth)
--       CT.popout.shown = false
--     else
--       for line = 1, numRows do
--         CT.popout.numLines = line
--         if not CT.popout[line] then CT.popout[line] = {} end
--         for i = 1, #CT.mainButtons do
--           CT.popout[line][i] = CreateFrame("Button", line .. "Popout" .. i, CT.mainButtons[i], "CTcomparisonPopoutTemplate")
--           local button = CT.popout[line][i]
--           button:SetSize(width, height)
--           button.value:SetText(random(70, 100) .. "%")
--           button:SetFrameLevel(2)
--           if line == 1 then
--             button:SetPoint("TOPLEFT", CT.mainButtons[i], "TOPRIGHT", -width * 0.75, 0)
--             button:SetPoint("BOTTOMLEFT", CT.mainButtons[i], "BOTTOMRIGHT", -width * 0.75, 0)
--           else
--             button:SetPoint("TOPLEFT", CT.popout[line - 1][i], "TOPRIGHT", -width * 0.75, 0)
--             button:SetPoint("BOTTOMLEFT", CT.popout[line - 1][i], "BOTTOMRIGHT", -width * 0.75, 0)
--           end
--         end
--         CombatTrackerBase:SetWidth(CombatTrackerBase:GetWidth() + width * 0.25)
--         CT.popout.shown = true
--       end
--     end
--   end
-- end

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
  elseif command == "save" then
    debug("Trying to save set")
    CT.stopTracking()
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
