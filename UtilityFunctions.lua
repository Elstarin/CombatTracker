local addonName, CombatTracker = ...

if not CombatTracker then return end
if CombatTracker.profile then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
local infinity = math.huge
local colors = CT.colors
local debug = CT.debug

local red = "|cFFFF0000"
local darkorange = "|cFFA83000"
local orange = "|cFF9E5A01"
local lightorange = "|cFFFA6022"
local orangeishyellow = "|cFFFF9B00"
local yellow = "|cFFFFFF00"
local greenishyellow = "|cFF75DD00"
local lightgreen = "|cFF498A00"
local green = "|cFF00FF00"
local darkgreen = "|cFF305B00"
local lightblue = "|cFF4B6CD7"
local blue = "|cFF0000FF"
local lightRed = "|cFFFF6060"
local lightBlue = "|cFF00CCFF"
local torquiseBlue = "|cff00C78C"
local springGreen = "|cff00FF7F"
local greenYellow = "|cffADFF2F"
local blue = "|cff0000ff"
local purple = "|cFFDA70D6"
local green = "|cff00ff00"
local red = "|cffff0000"
local gold = "|cFFFFCC00"
local gold2 = "|cffFFC125"
local grey = "|cFF888888"
local white = "|cFFFFFFFF"
local subwhite = "|cffbbbbbb"
local magenta = "|cFFFF00FF"
local yellow = "|cffffff00"
local orangey = "|cFFFF4500"
local chocolate = "|cffCD661D"
local cyan = "|cff00ffff"
local ivory = "|cFF8B8B83"
local lightYellow = "|cFFFFFFE0"
local sGreen = "|cff71C671"
local sTeal = "|cFF388E8E"
local sPink = "|cffC67171"
local sBlue = "|cff00E5EE"
local sHotPink = "|cffFF6EB4"

local hunterColor = "|cFFAAD372"
local warlockColor = "|cFF9482C9"
local priestColor = "|cFFFFFFFF"
local paladinColor = "|cFFF48CBA"
local mageColor = "|cFF68CCEF"
local rogueColor = "|cFFFFF468"
local druidColor = "|cFFFF7C0A"
local shamanColor = "|cFF0070DD"
local warriorColor = "|cFFC69B6D"
local deathKnightColor = "|cFFC41E3A"
local monkColor = "|cFF00FF96"

local mana = "|cFF0000FF" -- Blue
local rage = "|cFFFF0000" -- Red
local focus = "|cFFFF8040" -- Light Orange
local energy = "|cFFFFFF00"	-- Yellow
local chi = "|cFFB5FFEB" -- Aero Blue
local runes = "|cFF808080" -- Grey
local runicPower = "|cFF00D1FF"	-- Cyan
local soulShards = "|cFF80528C"	-- Purple
local eclipseNegative = "|cFF4D85E6" -- Royal Blue
local eclipsePositive = "|cFFCCD199" -- Pine Glade
local holyPower = "|cFFF2E699" -- Khaki
local demonicFury = "|cFF80528C" -- Purple
local ammoSlot = "|cFFCC9900"	-- Gold
local fuel = "|cFF008C80"	-- Teal

local burningEmbers = "|cFFBF6B02" -- Orange-ish, TODO: custom, will probably need correcting
local comboPoints = "|cFFFFFFFF" -- White, TODO: custom, will probably need correcting

local staggerLight = "|cFF85FF85" -- Mint Green
local staggerMedium = "|cFFFFFAB8"	-- Pale Yellow
local staggerHeavy = "|cFFFF6B6B" -- Light Red
--------------------------------------------------------------------------------
-- Locales
--------------------------------------------------------------------------------
local function check(originalString, string)
  -- print("Checking", string)
  
  local spellName = GetSpellInfo(string)
  
  if spellName then
    debug("Found a spell name for", string)
  
    return spellName
  end
  
  local powerColor, coloredString = CT.getPowerColor(string)
  
  if powerColor then -- This word is a variable
    debug("Found a power color for:", coloredString)
    local str = string:gsub(word, "%%s") -- Replace it with %s and check for a match again
  
    if L[str] then
      local title = string:gsub(word, coloredString) -- In the original string, replace the current word with the colored version
      local text = L[str]:gsub("%%s", coloredString) -- Replace all %s with the colored string
  
      return title, text
    end
  end
end

local function checkWords(originalString, words)
  local numWords = #words
  
  local title, text
  
  for i = 1, numWords do -- Run through words table 1 word at a time
    title, text = check(originalString, words[i])
  end
  
  if (not title and not text) and numWords > 1 then -- Run through words table in sets of 2, starting from 1
    for i = 1, numWords, 2 do
      if (i + 1) > numWords then break end
            
      title, text = check(originalString, table.concat(words, " ", i, (i + 1)))
      if title or text then break end
    end
  end
  
  if (not title and not text) and numWords > 2 then -- Run through words table in sets of 2, starting from 2
    for i = 2, numWords, 2 do
      if (i + 1) > numWords then break end
      
      title, text = check(originalString, table.concat(words, " ", i, (i + 1)))
      if title or text then break end
    end
  end
  
  if (not title and not text) and numWords > 3 then -- Run through words table in sets of 3, starting from 1
    for i = 1, numWords, 3 do
      if (i + 2) > numWords then break end
      
      title, text = check(originalString, table.concat(words, " ", i, (i + 2)))
      if title or text then break end
    end
  end
  
  if (not title and not text) and numWords > 4 then -- Run through words table in sets of 3, starting from 1
    for i = 2, numWords, 3 do
      if (i + 2) > numWords then break end
      
      title, text = check(originalString, table.concat(words, " ", i, (i + 2)))
      if title or text then break end
    end
  end
  
  wipe(words)
  
  debug("Returning:", title, text)
  
  return title, text
end

local words = {}
local function findLocale(self, string) -- After CT.findLocale is called once, replace it with this function which actually returns the strings
  local L = CT.L
  
  local name = self.spellName or self.name or string -- One without coloring
  local sName = self.spellName or self.name or string
  local pName = self.powerIndex and CT.powerTypesFormatted[self.powerIndex]
  
  local title = string
  local text = L[string]
  
  if text then
    
  else
    wipe(words)
    for word in string:gmatch("%w+") do -- Search word by word first
      words[#words + 1] = word
    end
    
    checkWords(string, words)
    
    if not text then -- Still haven't found anything, so return the error string
      text = "|cFFFF0000Failed to find any info text for this tooltip!\n\nSearched for string was:|r |cFFFA6022" .. string ..
               "|r\n\n|cFF00FF00BETA NOTE:|r |cFF4B6CD7If you see this, please let me know and tell me what you were mousing over" ..
               "at the time and what the searched for string was so I can add it. Thanks. :)|r"
    end
  end
  
  return title, text
end

function CT:findLocale(string)
  local L = {}
          
  local locale = GetLocale()
  if locale == "enUS" then
    do -- Power gained/lost/wasted, etc
      L["%s Gained:"] = "The total amount of %s generated by this spell."
      L["%s Wasted:"] = [[An estimate of the total %s wasted. This is just from checking your default regen and the total time at max.
              \n\n|cFF00FF00BETA NOTE:|r |cFF4B6CD7When your regen rate varies, this will give screwed up numbers. Making this far more accurate is on my to do list,
              but there are a ton of things to do, so it may be a while.|r]]
      L["%s Spent:"] = "The total amount of %s spent by this spell."
      L["Effective Gain:"] = "Total %s gained minus the wasted amount."
      L["Times Capped:"] = "The number of different times you hit maximum %s.\n\nTry to avoid this, because anything you generate while at the cap goes to waste."
      L["Seconds Capped:"] = "The total number of seconds you spent at maximum %s.\n\nKeep this as low as possible, because anything generated while at max is wasted."
    end
    
    do -- Holy power stuff? Seems like a mix, don't remember
      L["Holy Power Gained:"] = "The total amount of Holy Power generated by %s."
      L["Holy Power Spent:"] = "The total amount of Holy Power spent by %s."
      L["Total Absorbs:"] = "The total amount of absorbs created by %s."
      L["Average Absorbs:"] = "The average absorb created by %s."
      L["Biggest Absorbs:"] = "The biggest absorb created by %s."
      L["Percent of Healing:"] = "The percent of your total healing caused by %s."
      L["Procs Used:"] = "The number of times %s had an activation border when you cast it."
      L["Total Procs:"] = "The total number of times it procced."
      L["Percent on CD:"] = "The percent of the total fight that %s was on CD. Generally you want this to be as high as possible."
      L["Seconds Wasted:"] = "The percent of the total fight that %s was not on CD. Generally you want this to be as low as possible."
      L["Average Delay:"] = "The average delay between casts of %s. Generally you want this to be as low as possible."
      L["Number of Casts:"] = "The total number of times you cast %s."
      L["Reset Casts:"] = "The total number of times %s's CD got reset early."
      L["Longest Delay:"] = "The longest gap you had between casts of %s."
      L["Biggest Heal:"] = "The biggest heal from %s."
      L["Average Heal:"] = "The average heal done by %s."
      L["Average Targets Hit:"] = "The average number of targets hit per %s cast."
    end

    do -- Resources
      L["Mana"] = "Includes lots of details about your Mana usage. Mouseover each spell for more details."
      L["Rage"] = "Includes lots of details about your Rage usage. Mouseover each spell for more details."
      L["Focus"] = "Includes lots of details about your Focus usage. Mouseover each spell for more details."
      L["Energy"] = "Includes lots of details about your Energy usage. Mouseover each spell for more details."
      L["Combo Points"] = "Includes lots of details about your Combo Point usage. Mouseover each spell for more details."
      L["Runes"] = "Includes lots of details about your Rune usage. Mouseover each spell for more details."
      L["Runic Power"] = "Includes lots of details about your Runic Power usage. Mouseover each spell for more details."
      L["Soul Shards"] = "Includes lots of details about your Soul Shards usage. Mouseover each spell for more details."
      L["Eclipse"] = "Includes lots of details about your Eclipse usage. Mouseover each spell for more details."
      L["Holy Power"] = "Includes lots of details about your Holy Power usage. Mouseover each spell for more details."
      L["Alternate Power"] = "Includes lots of details about your Alternate Power usage. Mouseover each spell for more details."
      L["Dark Force"] = "Includes lots of details about your Dark Force usage. Mouseover each spell for more details."
      L["Chi"] = "Includes lots of details about your Chi usage. Mouseover each spell for more details."
      L["Shadow Orbs"] = "Includes lots of details about your Shadow Orbs usage. Mouseover each spell for more details."
      L["Burning Embers"] = "Includes lots of details about your Burning Embers usage. Mouseover each spell for more details."
      L["Demonic Fury"] = "Includes lots of details about your Demonic Fury usage. Mouseover each spell for more details."
    end
    
    do -- Spell
      L["Holy Power Gained:"] = "The total amount of Holy Power generated by %s."
      L["Holy Power Spent:"] = "The total amount of Holy Power spent by %s."
      L["Total Absorbs:"] = "The total amount of absorbs created by %s."
      L["Wasted Absorbs:"] = "The total amount of absorbs wasted from %s."
      L["Average Absorb:"] = "The average absorb created by %s."
      L["Biggest Absorb:"] = "The biggest absorb created by %s."
      L["Percent of Healing:"] = "The percent of your total healing caused by %s."
      L["Procs Used:"] = "The number of times %s had an activation border when you cast it."
      L["Total Procs:"] = "The total number of times it procced."
      L["Percent on CD:"] = "The percent of the total fight that %s was on CD. Generally you want this to be as high as possible."
      L["Seconds Wasted:"] = "The percent of the total fight that %s was not on CD. Generally you want this to be as low as possible."
      L["Average Delay:"] = "The average delay between casts of %s. Generally you want this to be as low as possible."
      L["Number of Casts:"] = "The total number of times you cast %s."
      L["Reset Casts:"] = "The total number of times %s's CD got reset early."
      L["Longest Delay:"] = "The longest gap you had between casts of %s."
      L["Biggest Heal:"] = "The biggest heal from %s."
      L["Average Heal:"] = "The average heal done by %s."
      L["Average Targets Hit:"] = "The average number of targets hit per %s cast."
    end
    
    do -- Titles
      L["Holy Shock"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Crusader Strike"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Explosive Shot"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Black Arrow"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Chimaera Shot"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Judgment"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Exorcism"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["All Casts"] = "Includes details about every spell cast you did. Mouseover each spell for more details."
      L["Cleanse"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Light's Hammer"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Execution Sentence"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Holy Prism"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Seraphim"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Empowered Seals"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Stance"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Illuminated Healing"] = "Includes details about every %s you cast. Mouseover each spell for more details."
      L["Stance"] = "Details about your stance usage in combat."
      L["Damage"] = "Includes details about your total damage and every spell that did damage. Mouseover each frame for more details."
    end
    
    do -- Activity
      L["Active Time:"] = "Total activity, counting all casts and GCDs."
      L["Percent:"] = "The percent of the fight that you were active."
      L["Seconds Active:"] = "The total seconds that you were active."
      L["Total Active Seconds:"] = "The total number of seconds you were on a GCD or doing a hard cast."
      L["Seconds Casting:"] = "Total number of seconds doing hard casts."
      L["Seconds on GCD:"] = "Total number of seconds on a GCD. This ignores GCD caused by cast times."
      L["Total Casts:"] = "The total number of casts done, combining hard casts and instant."
      L["Total Instant Casts:"] = "The total number of instant casts done."
      L["Total Hard Casts:"] = "The total number of hard casts done."
    end

    do -- Misc
      L["Total Gain:"] = "Total power gained."
      L["Total Delay:"] = "Total amount of time delayed."
      L["Total Gained"] = "Total power gained."
      L["Total Loss:"] = "Total power lost."
      L["Uptime:"] = "Overall uptime of the aura."
      L["Downtime:"] = "Overall downtime of the aura."
      L["Average Downtime:"] = ""
      L["Longest Downtime:"] = ""
      L["Total Applications:"] = ""
      L["Times Refreshed:"] = ""
      L["Wasted Time:"] = ""
      L[":"] = ""
      L["Total Damage:"] = "The total amount of damage you did during the fight."
      L["Average DPS:"] = "The average damage per second you did during the fight."
      
      L["None"] = "No string."
    end
  end
  CT.L = L
  
  CT.findLocale = findLocale -- After it's called once, replace it with a new function to actually return the string
  return CT.findLocale(self, string) -- Call the new function
end

function CT.getPowerColor(powerName)
  local color = nil

  if powerName then
    local lowered = powerName:lower()
    
    if lowered == "mana" then color = "|cFF0000FF"
    elseif lowered == "rage" then color = "|cFFFF0000"
    elseif lowered == "focus" then color = "|cFFFF8040"
    elseif lowered == "energy" then color = "|cFFFFFF00"
    elseif lowered == "combo points" then color = "|cFFFFFFFF"
    elseif lowered == "chi" then color = "|cFFB5FFEB"
    elseif lowered == "runes" then color = "|cFF808080"
    elseif lowered == "runic power" then color = "|cFF00D1FF"
    elseif lowered == "soul shards" then color = "|cFF80528C"
    elseif lowered == "eclipse" then color = "|cFF4D85E6"
    elseif lowered == "holy power" then color = "|cFFF2E699"
    elseif lowered == "demonic fury" then color = "|cFF80528C"
    elseif lowered == "burning embers" then color = "|cFFBF6B02"
    end
  end
  
  if color then
    return color, color .. powerName .. "|r"
  else
    return nil
  end
end

local title, text = CT.findLocale(CT, "A test string about Holy Shock.")

function CT.formatTimer(timer)
  if timer then
    local mins = floor(timer / 60)
    local secs = timer - (mins * 60)
    timer = format("%d:%02d", mins, secs)
    return timer
  end
end

function CT.shortenNumbers(num)
  local letter = ""

  if num >= 1000000 then -- Millions
    num = num / 1000000
    letter = "M"
  elseif num >= 1000 then -- Thousands
    num = num / 1000
    letter = "K"
  end

  return num, letter
end

function CT.round(num, decimals)
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

function CT.hasteCD(spellID, unit)
  if not unit then unit = "player" end
  return (GetSpellBaseCooldown(spellID) / 1000) / (1 + (UnitSpellHaste(unit) / 100))
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

function CT.colorPercentText(text, limit)
  local color

  if text > 97 and text <= 100 then
    color = green
  elseif text > 90 and text <= 97 then
    color = yellow
  elseif text > 80 and text <= 90 then
    color = orangeishyellow
  elseif text > 70 and text <= 80 then
    color = lightorange
  elseif text > 60 and text <= 70 then
    color = orange
  elseif text > 50 and text <= 60 then
    color = darkorange
  elseif text >= 0 and text <= 50 then
    color = red
  else
    color = yellow
  end

  if not limit then
    return color .. text
  else
    return color .. text .. "|r"
  end
end

function CT.colorPercentText2(num)
  if num > 97 and num <= 100 then
    return green
  elseif num > 90 and num <= 97 then
    return yellow
  elseif num > 80 and num <= 90 then
    return orangeishyellow
  elseif num > 70 and num <= 80 then
    return lightorange
  elseif num > 60 and num <= 70 then
    return orange
  elseif num > 50 and num <= 60 then
    return darkorange
  elseif num >= 0 and num <= 50 then
    return red
  else
    return yellow
  end
end

function CT.convertColor(r, g, b)
  return format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

local function createTicker(duration, callback, iterations)
  local ticker = {}
  local count = 0

  local function func()
    count = count + 1

    if not ticker.cancelled then
      callback(ticker)
    end

    if count >= iterations then
      ticker.cancelled = true
    end

    if not ticker.cancelled then
      C_Timer.After(duration, func)
    end
  end

  C_Timer.After(duration, func)
  return ticker
end

local function createTickerTest(duration, callback, ticks)
  local count = 0

  local function func()
    count = count + 1
    -- debug("Calling ticker", duration)
    callback(count)

    if not (count >= ticks) then
      C_Timer.After(duration, func)
    end
  end

  C_Timer.After(duration, func)
end

function CT.mouseFrameBorder(parent, size, color)
  local border = CT.mouseoverBorder

  if not border then
    border = CreateFrame("Frame", "CombatTracker_Mouseover_Border", CT.base)
    -- border = CT.base:CreateTexture("CT_Mouseover_Border", "OVERLAY")
    border:SetFrameStrata("HIGH")
    border:SetSize(10, 10)

    border[1] = border:CreateTexture("CombatTracker_Mouseover_Border_TOP", "OVERLAY")
    border[1]:SetPoint("TOPRIGHT", border, 0, 0)
    border[1]:SetPoint("TOPLEFT", border, 0, 0)

    border[2] = border:CreateTexture("CombatTracker_Mouseover_Border_BOTTOM", "OVERLAY")
    border[2]:SetPoint("BOTTOMRIGHT", border, 0, 0)
    border[2]:SetPoint("BOTTOMLEFT", border, 0, 0)

    border[3] = border:CreateTexture("CombatTracker_Mouseover_Border_LEFT", "OVERLAY")
    border[3]:SetPoint("TOPLEFT", border, 0, 0)
    border[3]:SetPoint("BOTTOMLEFT", border, 0, 0)

    border[4] = border:CreateTexture("CombatTracker_Mouseover_Border_RIGHT", "OVERLAY")
    border[4]:SetPoint("TOPRIGHT", border, 0, 0)
    border[4]:SetPoint("BOTTOMRIGHT", border, 0, 0)

    CT.mouseoverBorder = border
  end

  do -- Size
    local size = size or 2

    border[1]:SetSize(size, size)
    border[2]:SetSize(size, size)
    border[3]:SetSize(size, size)
    border[4]:SetSize(size, size)
  end

  do -- Color
    local color = color or CT.colors.white

    local c1 = color[1]
    local c2 = color[2]
    local c3 = color[3]
    local c4 = 0.1 or color[4]

    border[1]:SetTexture(c1, c2, c3, c4)
    border[2]:SetTexture(c1, c2, c3, c4)
    border[3]:SetTexture(c1, c2, c3, c4)
    border[4]:SetTexture(c1, c2, c3, c4)
  end

  if parent then
    border:Show()
    border:SetAllPoints(parent)
  else
    border:Hide()
    border:ClearAllPoints()
  end

  return border
end

function CT.confirmDialogue(parent)
  local confirm = CT.buttons.confirm

  if not confirm then
    CT.buttons.confirm = CreateFrame("Frame", "CT_Button_Confirmation_Dialogue", CT.base)
    confirm = CT.buttons.confirm

    local width, height = parent:GetSize()
    confirm:SetFrameStrata("HIGH")
    confirm:SetSize(width, height)
    confirm:EnableMouse(true)

    confirm.shader = confirm:CreateTexture(nil, "ARTWORK")
    confirm.shader:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
    confirm.shader:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
    confirm.shader:SetVertexColor(0, 0, 0, 1)
    confirm.shader:SetAllPoints()

    confirm.bg = confirm:CreateTexture(nil, "ARTWORK")
    confirm.bg:SetTexture("Interface\\PVPFrame\\PvPMegaQueue")
    confirm.bg:SetTexCoord(0.00195313, 0.58789063, 0.87304688, 0.92773438)
    confirm.bg:SetVertexColor(0, 0, 0, 1)
    confirm.bg:SetAllPoints()

    confirm.accept = CreateFrame("Button", "CT_Button_Confirmation_Dialogue_Accept", confirm)
    confirm.accept:SetPoint("CENTER", confirm.bg, width / 6, 0)
    confirm.accept:SetSize(height - 5, height - 5)
    confirm.accept.texture = confirm.accept:CreateTexture(nil, "ARTWORK")
    confirm.accept.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    confirm.accept.texture:SetAllPoints()

    confirm.accept.pushed = confirm.accept:CreateTexture(nil, "OVERLAY")
    confirm.accept.pushed:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    confirm.accept.pushed:SetVertexColor(0.5, 0.5, 0.5, 0.7)
    confirm.accept.pushed:SetAllPoints()
    confirm.accept:SetPushedTexture(confirm.accept.pushed)

    confirm.decline = CreateFrame("Button", "CT_Button_Confirmation_Dialogue_Decline", confirm)
    confirm.decline:SetPoint("LEFT", confirm.accept, "RIGHT", 0, 0)
    confirm.decline:SetSize(height - 5, height - 5)

    confirm.decline.texture = confirm.decline:CreateTexture(nil, "ARTWORK")
    confirm.decline.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    confirm.decline.texture:SetAllPoints()

    confirm.decline.pushed = confirm.decline:CreateTexture(nil, "OVERLAY")
    confirm.decline.pushed:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    confirm.decline.pushed:SetVertexColor(0.5, 0.5, 0.5, 0.7)
    confirm.decline.pushed:SetAllPoints()
    confirm.decline:SetPushedTexture(confirm.decline.pushed)

    confirm.accept:SetScript("OnClick", function(self, click)
      if self[click] then
        self[click]()
        confirm:Hide()
      end
    end)

    confirm.decline:SetScript("OnClick", function(self, click)
      if self[click] then
        self[click]()
        confirm:Hide()
      end
    end)

    confirm.text = confirm:CreateFontString(nil, "OVERLAY")
    confirm.text:SetPoint("RIGHT", confirm.accept, "LEFT", -10, 0)
    confirm.text:SetFont("Fonts\\FRIZQT__.TTF", 18)
    confirm.text:SetTextColor(1, 1, 0, 1)
    confirm.text:SetText("Delete this set?")
  end

  confirm:Show()
  confirm:SetAllPoints(parent)

  return confirm.accept, confirm.decline
end

function CT:storeStartPoints(dontClear)
  if not self.startPoints then self.startPoints = {} end
  
  for i = 1, self:GetNumPoints() do
    if self.startPoints[i] then
      local p = self.startPoints[i]
      p[1], p[2], p[3], p[4], p[5] = self:GetPoint(i)
    else
      self.startPoints[i] = {self:GetPoint(i)} -- Create a new table if necessary
    end
  end
  
  if not dontClear then
    self:ClearAllPoints()
  end
end

function CT:storeStopPoints(dontClear)
  if not self.stopPoints then self.stopPoints = {} end
  
  for i = 1, self:GetNumPoints() do
    if self.stopPoints[i] then
      local p = self.stopPoints[i]
      p[1], p[2], p[3], p[4], p[5] = self:GetPoint(i)
    else
      self.stopPoints[i] = {self:GetPoint(i)} -- Create a new table if necessary
    end
  end
end

function CT:swapStartAndStop()
  local numPoints = self:GetNumPoints()
  
  local start = self.startPoints
  local stop = self.stopPoints
  
  start.width, stop.width = stop.width, start.width
  start.height, stop.height = stop.height, start.height
  
  -- start.left, stop.left = stop.left, start.left
  
  start.centerX, stop.centerX = stop.centerX, start.centerX
  start.centerY, stop.centerY = stop.centerY, start.centerY
  
  for i = 1, numPoints do
    local start = start[i]
    local stop = stop[i]
    
    if start and stop then
      start[1], stop[1] = stop[1], start[1]
      start[2], stop[2] = stop[2], start[2]
      start[3], stop[3] = stop[3], start[3]
      start[4], stop[4] = stop[4], start[4]
      start[5], stop[5] = stop[5], start[5]
    end
  end
end

function CT:setToStartPoints()
  if not self.startPoints then return end
  
  if self.startPoints.width and self.startPoints.height then
    self:SetSize(self.startPoints.width, self.startPoints.height)
  elseif self.startPoints.width then
    self:SetWidth(self.startPoints.width)
  elseif self.startPoints.height then
    self:SetHeight(self.startPoints.height)
  end
  
  if self.startPoints.parent then
    self:SetParent(self.startPoints.parent)
  end
  
  self:ClearAllPoints()
  for i = 1, #self.startPoints do
    local p = self.startPoints[i]
    self:SetPoint(p[1], p[2], p[3], p[4], p[5])
  end
end

function CT:setToStopPoints()
  if not self.stopPoints then return end
  
  self:SetSize(self.stopPoints.width, self.stopPoints.height)
  self:SetParent(self.stopPoints.parent)
  
  self:ClearAllPoints()
  for i = 1, #self.stopPoints do
    local p = self.stopPoints[i]
    self:SetPoint(p[1], p[2], p[3], p[4], p[5])
  end
end

function CT:setToOriginalPoints()
  if not self.originalPoints then return end
  
  self:SetSize(self.originalPoints.width, self.originalPoints.height)
  self:SetParent(self.originalPoints.parent)
  
  self:ClearAllPoints()
  for i = 1, #self.originalPoints do
    local p = self.originalPoints[i]
    self:SetPoint(p[1], p[2], p[3], p[4], p[5])
  end
end

function CT:createRoundedBackground(r, g, b, a)
  local r, g, b, a = (r or 0.1), (g or 0.1), (b or 0.1), (a or 1)
  
  local bg = self.background
  if not bg then
    bg = self:CreateTexture(nil, "BACKGROUND", nil, 0)
    bg:SetTexture(r, g, b, a)
    
    bg.corners = {}
    bg.fill = {}
    
    local cornerSize = 20
    for i = 1, 4 do
      local c = self:CreateTexture(nil, "BACKGROUND", nil, -8)
      c:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMaskSmall.png")
      c:SetVertexColor(r, g, b, a)
    
      if i == 1 then
        c:SetSize(cornerSize, cornerSize)
        c:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
        bg:SetPoint("TOPLEFT", c, (cornerSize / 2), 0)
      elseif i == 2 then
        c:SetSize(cornerSize, cornerSize)
        c:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
        bg:SetPoint("TOPRIGHT", c, -(cornerSize / 2), 0)
      elseif i == 3 then
        c:SetSize(cornerSize, cornerSize)
        c:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
        bg:SetPoint("BOTTOMLEFT", c, (cornerSize / 2), 0)
      elseif i == 4 then
        c:SetSize(cornerSize, cornerSize)
        c:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
        bg:SetPoint("BOTTOMRIGHT", c, -(cornerSize / 2), 0)
      end
    
      bg.corners[i] = c
    end
    
    bg.fill[1] = self:CreateTexture(nil, "BACKGROUND", nil, 0)
    bg.fill[1]:SetTexture(r, g, b, a)
    bg.fill[1]:SetPoint("TOPLEFT", bg.corners[2], 0, -(cornerSize / 2))
    bg.fill[1]:SetPoint("BOTTOMRIGHT", bg.corners[4], 0, (cornerSize / 2))
    
    bg.fill[2] = self:CreateTexture(nil, "BACKGROUND", nil, 0)
    bg.fill[2]:SetTexture(r, g, b, a)
    bg.fill[2]:SetPoint("TOPRIGHT", bg.corners[1], 0, -(cornerSize / 2))
    bg.fill[2]:SetPoint("BOTTOMLEFT", bg.corners[3], 0, (cornerSize / 2))
    
    self.background = bg
  end
  
  return bg
end

function CT:createDropShadow()
  local width, height = self:GetSize()
  
  local bg = self.background
  if not bg then -- Background texture and gradient
    bg = self:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetTexture(0.1, 0.1, 0.1, 1.0)
    bg:SetAllPoints()
    self:SetNormalTexture(bg)
    
    local g = self:CreateTexture(nil, "ARTWORK", nil, 1)
    g:SetGradientAlpha("VERTICAL", 0.01, 0.01, 0.01, 0.2, 0, 0, 0, 0) -- Top
    g:SetTexture(1, 1, 1, 1)
    g:SetSize(width, height / 2)
    g:SetPoint("CENTER", bg, 0, 0)
    g:SetPoint("RIGHT", bg, 0, 0)
    g:SetPoint("LEFT", bg, 0, 0)
    g:SetPoint("TOP", bg, 0, 0)
    bg[1] = g
    
    local g = self:CreateTexture("CT_Base_Button_Background_Gradient_Bottom", "ARTWORK", nil, 1)
    g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 0.2) -- Bottom
    g:SetTexture(1, 1, 1, 1)
    g:SetSize(width, height / 2)
    g:SetPoint("CENTER", bg, 0, 0)
    g:SetPoint("RIGHT", bg, 0, 0)
    g:SetPoint("LEFT", bg, 0, 0)
    g:SetPoint("BOTTOM", bg, 0, 0)
    bg[2] = g
    
    self.background = bg
  end
  
  local shadow = self.shadow
  if not shadow then
    shadow = self:CreateTexture(nil, "BACKGROUND")
    shadow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    shadow:SetPoint("TOPLEFT", -1, 1)
    shadow:SetPoint("BOTTOMRIGHT", 0, -0)
    shadow:SetVertexColor(0, 0, 0, 1)
    
    local g = self:CreateTexture(nil, "BACKGROUND")
    g:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.01, 0.01, 0.01, 1)
    g:SetTexture(1, 1, 1, 1)
    g:SetSize(width, 5)
    g:SetPoint("TOP", shadow, "BOTTOM", 0, 0)
    g:SetPoint("RIGHT", shadow, 2, 0)
    g:SetPoint("LEFT", shadow, 0, 0)
    shadow[1] = g
    
    local g = self:CreateTexture(nil, "BACKGROUND")
    g:SetGradientAlpha("HORIZONTAL", 0.01, 0.01, 0.01, 1, 0, 0, 0, 0)
    g:SetTexture(1, 1, 1, 1)
    g:SetSize(3, height)
    g:SetPoint("LEFT", shadow, "RIGHT", 0, 0)
    g:SetPoint("TOP", shadow, 0, 0)
    g:SetPoint("BOTTOM", shadow, 0, -2)
    shadow[2] = g
  
    self.shadow = shadow
  end
  
  return bg, shadow
end

local function rotateTexture(self, elapsed)
  self.timer = (self.timer or 0) + elapsed;
  
  if ( self.timer > 0.01 ) then
    self.hAngle = (self.hAngle or 0) - 0.25;
    self.s = sin(self.hAngle);
    self.c = cos(self.hAngle);
    self.icon:SetTexCoord(0.5-self.s, 0.5+self.c,
                          0.5+self.c, 0.5+self.s,
                          0.5-self.c, 0.5-self.s,
                          0.5+self.s, 0.5-self.c);
    self.timer = 0;
  end
end

-- :SetBlendMode("BLEND") -- ADD, ALPHAKEY, BLEND, DISABLE, MOD
-- icon:SetTexCoord("Upper left X", "Upper left Y", "Lower left X", "Lower left Y", "Upper right X", "Upper right Y", "Lower right X", "Lower right Y")
-- Interface\\BUTTONS\\WHITE8X8
-- Interface\\ChatFrame\\ChatFrameBackground

-- local prevDist = sqrt((cX - pX)^2 + (cY - pY)^2)
-- local nextDist = sqrt((nX - cX)^2 + (nY - cY)^2)
-- local hypotenuse = sqrt((nX - pX)^2 + (nY - pY)^2)

-- [elseif]* s == ([pName\.?\.?]*".+") then[^\n]+\s+return (.+) -- How to search across new lines
