if not CombatTracker then return end
--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------
local CT = CombatTracker
local infinity = math.huge
local colors = CT.colors

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
local lightRed = "|cffff6060"
local lightBlue = "|cff00ccff"
local torquiseBlue = "|cff00C78C"
local springGreen = "|cff00FF7F"
local greenYellow = "|cffADFF2F"
local blue = "|cff0000ff"
local purple = "|cffDA70D6"
local green = "|cff00ff00"
local red = "|cffff0000"
local gold = "|cffffcc00"
local gold2 = "|cffFFC125"
local grey = "|cff888888"
local white = "|cffffffff"
local subwhite = "|cffbbbbbb"
local magenta = "|cffff00ff"
local yellow = "|cffffff00"
local orangey = "|cffFF4500"
local chocolate = "|cffCD661D"
local cyan = "|cff00ffff"
local ivory = "|cff8B8B83"
local lightYellow = "|cffFFFFE0"
local sGreen = "|cff71C671"
local sTeal = "|cff388E8E"
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
local eclipsePosative = "|cFFCCD199" -- Pine Glade
local holyPower = "|cFFF2E699" -- Khaki
local demonicFury = "|cFF80528C" -- Purple
local ammoSlot = "|cFFCC9900"	-- Gold
local fuel = "|cFF008C80"	-- Teal

local burningEmbers = "|cFFBF6B02" -- Orange-ish, TODO: custom, will probably need correcting
local comboPoints = "|cFFFFFFFF" -- White, TODO: custom, will probably need correcting

local staggerLight = "|cFF85FF85" -- Mint Green
local staggerMedium = "|cFFFFFAB8"	-- Pale Yellow
local staggerHeavy = "|cFFFF6B6B" -- Light Red

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
    -- print("Calling ticker", duration)
    callback(count)

    if not (count >= ticks) then
      C_Timer.After(duration, func)
    end
  end

  C_Timer.After(duration, func)
end
