if not CombatTracker then return end
if not CombatTracker.loadSpellData then return end

CT = CombatTracker

local f = CreateFrame("Frame", "CopyText", UIParent)
f:SetPoint("TOP", -400, 0)
f:SetSize(350, 500)
f.texture = f:CreateTexture(nil, "BACKGROUND")
f.texture:SetTexture(0.05, 0.05, 0.05, 1)
f.texture:SetAllPoints()

local e = CreateFrame("EditBox", nil, f)
e:SetAllPoints()
e:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
e:SetTextColor(0.9, 0.9, 0.9, 1)

e:SetMultiLine(true)
e:SetMaxLetters(150000)
-- e:SetHistoryLines(100)
e:SetAutoFocus(false)
e:SetFocus(false)
-- e:SetIndentedWordWrap(true)

e:SetScript("OnEscapePressed", function(self)
  e:ClearFocus()
end)

e:SetScript("OnTextSet", function(self)
  print("Set Text")
end)

e:SetScript("OnEditFocusGained", function(self)
  self:HighlightText()
end)

e:SetScript("OnEditFocusLost", function(self)
  self:HighlightText(1, 1)
end)

-- print(e:GetMaxLetters())
-- print(e:HasFocus())

-- CT.scanningTip = CreateFrame("GameTooltip", "MyScanningTooltip", nil, "GameTooltipTemplate")
-- CT.scanningTip:SetOwner(CT.base, "ANCHOR_TOP")
-- CT.scanningTip:SetSize(200, 200)
-- CT.scanningTip:SetOwner(WorldFrame, "ANCHOR_NONE")
-- CT.scanningTip.text = CT.scanningTip:CreateFontString()
-- CT.scanningTip:AddFontStrings(CT.scanningTip:CreateFontString(), CT.scanningTip:CreateFontString())
-- Allow tooltip SetX() methods to dynamically add new lines based on these
-- CT.scanningTooltip:AddFontStrings(
--   CT.scanningTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
--   CT.scanningTooltip:CreateFontString("$parentTextLeft2", nil, "GameTooltipText")
--   )

-- local Parser, LT1, LT2, LT3, RT1, RT2, RT3 = TMW:GetParser()

-- local function EnumerateTooltipLines_helper(...)
--   for i = 1, select("#", ...) do
--     local region = select(i, ...)
--     if region and region:GetObjectType() == "FontString" then
--       local text = region:GetText() -- string or nil
--       if text and text:match("min c") then
--         local text = text:gsub("%a*%s*", "") * 60
--         -- print(text)
--         return text
--       elseif text and text:match("sec c") then
--         local text = text:gsub("%a*%s*", "") + 0
--         return text
--       end
--     end
--   end
-- end
--
-- local function EnumerateTooltipLines(tooltip, spellID) -- good for script handlers that pass the tooltip as the first argument.
--   if spellID then
--     tooltip:ClearLines()
--     tooltip:SetSpellByID(spellID)
--     return EnumerateTooltipLines_helper(tooltip:GetRegions())
--   end
-- end

local function hasteCD(spellID, unit)
  if not unit then unit = "player" end
  return (GetSpellBaseCooldown(spellID) / 1000) / (1 + (UnitSpellHaste(unit) / 100))
end

local function checkCC(description)
  local time
  local desc = description:lower() -- "([xXyY])([+-]?%d+)"
  local seconds = description:match("(%d+ sec)")
  if seconds then
    time = seconds:match("(%d+)")
  end

  if desc:match("interrupt") and not desc:match("immun") then
    return "interrupt", time
  elseif desc:match("stun") and not desc:match("while stun") then
    return "stun", time
  elseif desc:match("fear") then
    return "fear", time
  elseif desc:match("silence") and not desc:match("immun") then
    return "silence", time
  elseif desc:match("disorient") then
    return "disorient", time
  elseif desc:match("incapacit") then
    return "incapacitate", time
  end
end

local function checkDescription(description)
  local desc = description:lower()

  if desc:match("interrupt") then
    return desc
  elseif desc:match("stun") then
    return desc
  elseif desc:match("fear") then
    return desc
  elseif desc:match("silence") then
    return desc
  elseif desc:match("disorient") then
    return desc
  elseif desc:match("incapacit") then
    return desc
  end
end

function CT:GetParser()
  local parser, LT1, LT2, LT3, RT1, RT2, RT3
  if not parser then
    parser = CreateFrame("GameTooltip") -- added in everything beyond the first
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

local function findword(str, word)
  if not strfind(str, word) then
    return nil
  else
    if strfind(str, "%A" .. word .. "%A") -- in the middle
    or strfind(str, "^" .. word .. "%A") -- at the beginning
    or strfind(str, "%A" .. word .. "$")-- at the end
    then
      return true
    end
  end
end

local function resourceType(costText)
  if costText then
    costText = strlower(costText)
    if strmatch(costText, "range") or
    strmatch(costText, "instant") or
    strmatch(costText, "channeled") or
    strmatch(costText, "melee") then return end

    local energy = strmatch(costText, "(%d+ energy)")
    if energy then
      local resourceName = gsub(energy, "%A", "")
      local resourceNum = gsub(energy, "%D", "")
      return resourceNum, resourceName
    end

    local mana = strmatch(costText, "(%d+,%d+ mana)")
    if mana then
      local resourceName = gsub(mana, "%A", "")
      local resourceNum = gsub(mana, "%D", "")
      return resourceNum, resourceName
    end

    local rage = strmatch(costText, "(%d+ rage)")
    if rage then
      local resourceName = gsub(rage, "%A", "")
      local resourceNum = gsub(rage, "%D", "")
      return resourceNum, resourceName
    end

    local holyPower = strmatch(costText, "(%d+ holy)")
    if holyPower then
      local resourceName = gsub(holyPower, "%A", "")
      local resourceNum = gsub(holyPower, "%D", "")
      return resourceNum, resourceName
    end

    local focus = strmatch(costText, "(%d+ focus)")
    if focus then
      local resourceName = gsub(focus, "%A", "")
      local resourceNum = gsub(focus, "%D", "")
      return resourceNum, resourceName
    end

    local ember = strmatch(costText, "(%d+ burning ember)")
    if ember then
      local resourceName = gsub(ember, "%A", "")
      local resourceNum = gsub(ember, "%D", "")
      return resourceNum, resourceName
    end

    local health = strmatch(costText, "(%d+ health)")
    if health then
      local resourceName = gsub(health, "%A", "")
      local resourceNum = gsub(health, "%D", "")
      return resourceNum, resourceName
    end

    local orbs = strmatch(costText, "(%d+ shadow orbs)")
    if orbs then
      local resourceName = gsub(orbs, "%A", "")
      local resourceNum = gsub(orbs, "%D", "")
      return resourceNum, resourceName
    end

    local fury = strmatch(costText, "(%d+ demonic fury)")
    if fury then
      local resourceName = gsub(fury, "%A", "")
      local resourceNum = gsub(fury, "%D", "")
      return resourceNum, resourceName
    end

    local shard = strmatch(costText, "(%d+ soul shard)")
    if shard then
      local resourceName = gsub(shard, "%A", "")
      local resourceNum = gsub(shard, "%D", "")
      return resourceNum, resourceName
    end

    local runicPower = strmatch(costText, "(%d+ runic)")
    if runicPower then
      local resourceName = gsub(runicPower, "%A", "")
      local resourceNum = gsub(runicPower, "%D", "")
      return resourceNum, resourceName
    end

    local death = strmatch(costText, "(%d+ death)")
    local blood = strmatch(costText, "(%d+ blood)")
    local frost = strmatch(costText, "(%d+ frost)")
    local unholy = strmatch(costText, "(%d+ unholy)")
    local rune = death or blood or frost or unholy
    if rune then
      local resourceName = gsub(rune, "%A", "")
      local resourceNum = gsub(rune, "%D", "")
      return resourceNum, resourceName
    end
  end
end

local function scrapeCooldown(text1, text2)
  if text1 and text1:match("cooldown") then
    local sec = strmatch(text1, "(%d+ sec cooldown)")
    if sec then
      local cooldown = gsub(text1, "%s+%a+", "")
      return tonumber(cooldown)
    end

    local min = strmatch(text1, "(%d+ min cooldown)")
    if min then
      local cooldown = gsub(text1, "%s+%a+", "")
      return tonumber(cooldown) * 60
    end

    local hour = strmatch(text1, "(%d+ hour cooldown)")
    if hour then
      local cooldown = gsub(text1, "%s+%a+", "")
      return tonumber(cooldown) * 3600
    end
  end

  if text2 and text2:match("cooldown") then
    local sec = strmatch(text2, "(%d+ sec cooldown)")
    if sec then
      local cooldown = gsub(text2, "%s+%a+", "")
      return tonumber(cooldown)
    end

    local min = strmatch(text2, "(%d+ min cooldown)")
    if min then
      local cooldown = gsub(text2, "%s+%a+", "")
      return tonumber(cooldown) * 60
    end

    local hour = strmatch(text2, "(%d+ hour cooldown)")
    if hour then
      local cooldown = gsub(text2, "%s+%a+", "")
      return tonumber(cooldown) * 3600
    end
  end
end

-- local parser, LT1, LT2, LT3, RT1, RT2, RT3 = CT:GetParser()
-- local function scrapeCooldown(spellID)
--   parser:SetSpellByID(spellID)
--
--   local text1 = RT2:GetText()
--   if text1 and text1:match("cooldown") then
--     local sec = strmatch(text1, "(%d+ sec cooldown)")
--     if sec then
--       local cooldown = gsub(text1, "%s+%a+", "")
--       return tonumber(cooldown)
--     end
--
--     local min = strmatch(text1, "(%d+ min cooldown)")
--     if min then
--       local cooldown = gsub(text1, "%s+%a+", "")
--       return tonumber(cooldown) * 60
--     end
--
--     local hour = strmatch(text1, "(%d+ hour cooldown)")
--     if hour then
--       local cooldown = gsub(text1, "%s+%a+", "")
--       return tonumber(cooldown) * 3600
--     end
--   end
--
--   local text2 = RT3:GetText()
--   if text2 and text2:match("cooldown") then
--     local sec = strmatch(text2, "(%d+ sec cooldown)")
--     if sec then
--       local cooldown = gsub(text2, "%s+%a+", "")
--       return tonumber(cooldown)
--     end
--
--     local min = strmatch(text2, "(%d+ min cooldown)")
--     if min then
--       local cooldown = gsub(text2, "%s+%a+", "")
--       return tonumber(cooldown) * 60
--     end
--
--     local hour = strmatch(text2, "(%d+ hour cooldown)")
--     if hour then
--       local cooldown = gsub(text2, "%s+%a+", "")
--       return tonumber(cooldown) * 3600
--     end
--   end
-- end

local cacheSpell = {
  71,78,100,355,469,772,871,1160,1464,1680,1715,1719,2457,2565,3127,3411,5246,5308,6343,6544,6552,6572,6673,12292,12294,12323,12328,12712,12950,12975,13046,18499,20243,23588,23881,23920,23922,29144,29725,29838,34428,46915,46917,46924,46953,46968,55694,56636,57755,64382,76838,76856,76857,81099,84608,85288,86101,86110,86535,88163,97462,100130,103826,103827,103828,103840,107570,107574,114028,114029,114030,114192,115767,118000,118038,122509,123829,145585,152276,152277,152278,156287,156321,158298,158836,159362,161608,161798,163201,163558,165365,165383,165393,167105,167188,169679,169680,169683,169685,174736,174926,176289,176318,
  498,633,642,853,879,1022,1038,1044,2812,4987,6940,7328,10326,13819,19740,19750,20066,20154,20164,20165,20217,20271,20473,20925,23214,24275,25780,25956,26023,26573,31801,31821,31842,31850,31868,31884,31935,32223,34767,34769,35395,53376,53385,53503,53551,53563,53576,53592,53595,53600,62124,69820,69826,73629,73630,76669,76671,76672,82242,82326,82327,85043,85222,85256,85499,85673,85804,86102,86103,86172,86539,86659,87172,88821,96231,105361,105424,105593,105622,105805,105809,112859,114039,114154,114157,114158,114163,114165,115675,115750,119072,121783,123830,130552,136494,140333,148039,152261,152262,152263,156910,157007,157047,157048,158298,159374,161608,161800,165375,165380,165381,167187,171648,
  136,781,883,982,1462,1494,1499,1515,1543,2641,2643,3044,3045,3674,5116,5118,5384,6197,6991,8737,13159,13809,13813,19263,19386,19387,19434,19506,19574,19577,19623,19801,19878,19879,19880,19882,19883,19884,19885,20736,34026,34477,34483,34954,35110,51753,53209,53253,53260,53270,53271,53301,53351,56315,56641,63458,76657,76658,76659,77767,77769,82692,83242,83243,83244,83245,87935,93321,93322,109212,109215,109248,109259,109260,109298,109304,109306,115939,117050,118675,120360,120679,121818,130392,131894,138430,147362,152244,152245,155228,157443,162534,163485,164856,165378,165389,165396,172106,177667,
  53,408,703,921,1329,1725,1752,1766,1776,1784,1804,1833,1856,1860,1943,1966,2094,2098,2823,2836,2983,3408,5171,5277,5938,6770,8676,8679,13750,13877,14062,14117,14161,14183,14185,14190,16511,26679,31209,31220,31223,31224,31230,32645,35551,36554,51667,51690,51701,51713,51723,57934,58423,61329,73651,74001,76577,76803,76806,76808,79008,79134,79140,79147,79152,82245,84601,84617,84654,91023,108208,108209,108210,108211,108212,108216,111240,113742,114014,114015,114018,121152,121411,121733,131511,137619,138106,152150,152151,152152,154904,157442,165390,
  17,139,527,528,585,586,589,596,605,1706,2006,2060,2061,2096,2944,6346,8092,8122,9484,10060,14914,15286,15407,15473,15487,19236,20711,21562,32375,32379,32546,33076,33206,34433,34861,34914,45243,47515,47517,47536,47540,47585,47788,48045,52798,62618,63733,64044,64129,64843,73325,73510,77484,77485,77486,78203,81206,81208,81209,81662,81700,81749,81782,87336,88625,88684,95649,95740,95860,95861,108920,108942,108945,109142,109175,109186,109964,110744,112833,120517,120644,121135,121536,122121,123040,126135,127632,129250,132157,139139,152116,152117,152118,155245,155246,155271,155361,162448,162452,165201,165362,165370,165376,
  674,3714,42650,43265,45462,45477,45524,45529,46584,47476,47528,47541,47568,48263,48265,48266,48707,48743,48792,48982,49020,49028,49039,49143,49184,49206,49222,49509,49530,49572,49576,49998,50029,50034,50041,50371,50385,50392,50842,50887,50977,51052,51128,51160,51271,51462,51986,53331,53342,53343,53344,53428,54447,54637,55078,55090,55095,55233,55610,56222,56835,57330,59057,61999,62158,63560,66192,77513,77514,77515,77575,77606,81127,81136,81164,81229,81333,82246,85948,86113,86524,86536,86537,91107,96268,108194,108196,108199,108200,108201,111673,114556,114866,115989,119975,123693,130735,130736,152279,152280,152281,155522,158298,161497,161608,161797,165394,165395,178819,
  324,370,403,421,546,556,974,1064,1535,2008,2062,2484,2645,2825,2894,3599,5394,6196,8004,8042,8050,8056,8143,8177,8190,8737,10400,16166,16188,16196,16213,16282,17364,20608,29000,30814,30823,30884,32182,33757,36936,51485,51490,51505,51514,51522,51530,51533,51564,51886,52127,57994,58875,60103,60188,61295,61882,62099,63374,73680,73899,73920,77130,77223,77226,77472,77756,79206,86099,86100,86108,86529,86629,88766,95862,98008,108269,108270,108271,108273,108280,108281,108282,108283,108284,108285,108287,112858,116956,117012,117013,117014,123099,147074,152255,152256,152257,157153,157154,157444,165339,165341,165344,165368,165391,165399,165462,165477,165479,166221,170374,
  10,66,116,118,120,122,130,133,475,1449,1459,1463,1953,2120,2136,2139,2948,3561,3562,3563,3565,3566,3567,5143,6117,7302,10059,11129,11366,11416,11417,11418,11419,11420,11426,11958,12042,12043,12051,12472,12846,12982,28271,28272,30449,30451,30455,30482,31589,31661,31687,32266,32267,32271,32272,33690,33691,35715,35717,42955,43987,44425,44457,44549,44572,44614,45438,49358,49359,49360,49361,53140,53142,55342,61305,61316,61721,61780,76547,76613,80353,84714,86949,88342,88344,88345,88346,102051,108839,108843,108853,108978,110959,111264,112948,112965,113724,114664,114923,116011,117216,117957,120145,120146,126819,132620,132621,132626,132627,140468,152087,153561,153595,153626,155147,155148,155149,157913,157976,157980,157981,157997,159916,161353,161354,161355,161372,165357,165359,165360,176242,176244,176246,176248,
  126,172,348,686,688,689,691,697,698,710,712,755,980,1098,1122,1454,1949,5484,5697,5740,5782,5784,6201,6353,6789,17877,17962,18540,20707,23161,27243,29722,29858,29893,30108,30146,30283,48018,48020,48181,74434,77215,77219,77220,80240,86121,93375,101976,103103,103958,104315,104773,105174,108359,108370,108371,108415,108416,108482,108499,108501,108503,108505,108508,108558,108647,108683,108869,109151,109773,109784,110913,111397,111400,111546,111771,113858,113860,113861,114592,114635,116858,117198,117896,119898,120451,122351,124913,137587,152107,152108,152109,157695,157696,165363,165367,165392,166928,171975,174848,
  100780,100784,100787,101545,101546,101643,103985,107428,109132,113656,115008,115069,115070,115072,115074,115078,115080,115098,115151,115173,115174,115175,115176,115178,115180,115181,115203,115288,115294,115295,115308,115310,115313,115315,115396,115399,115450,115451,115460,115546,115636,115921,116092,116095,116645,116670,116680,116694,116705,116740,116781,116812,116841,116844,116847,116849,117906,117907,117952,117967,119381,119392,119582,119996,120224,120225,120227,120272,120277,121253,121278,121817,122278,122280,122470,122783,123766,123904,123980,123986,124081,124146,124502,124682,126060,126892,126895,128595,128938,137384,137562,137639,139598,152173,152174,152175,154436,154555,157445,157533,157535,157675,157676,158298,161608,165379,165397,165398,166916,173841,
  99,339,740,768,770,774,783,1079,1126,1822,1850,2782,2908,2912,5176,5185,5211,5215,5217,5221,5225,5487,6795,6807,8921,8936,16864,16870,16931,16961,16974,17007,17073,18562,18960,20484,22568,22570,22812,22842,24858,33605,33745,33763,33786,33831,33873,33891,33917,48438,48484,48500,48505,50769,52610,61336,62606,77492,77493,77495,77758,78674,78675,80313,85101,86093,86096,86097,86104,88423,88747,92364,93399,102280,102342,102351,102359,102401,102543,102558,102560,102693,102703,102706,102793,106707,106785,106830,106832,106839,106898,106952,108238,108291,108292,108293,108294,108299,108373,112071,112857,113043,114107,124974,125972,127663,131768,132158,132469,135288,145108,145205,145518,152220,152221,152222,155577,155578,155580,155672,155675,155783,155834,155835,157447,158298,158476,158477,158478,158497,158501,158504,159232,161608,164812,164815,165372,165374,165386,165387,166142,166163,171746,
}

local petCache = {[2649]=3,[16827]=3,[17253]=3,[24423]=3,[24450]=3,[24604]=3,[24844]=3,[26064]=3,[34889]=3,[35290]=3,[35346]=3,[49966]=3,[50256]=3,[50433]=3,[50518]=3,[50519]=3,[54644]=3,[54680]=3,[57386]=3,[58604]=3,[65220]=3,[88680]=3,[90309]=3,[90328]=3,[90339]=3,[90347]=3,[90355]=3,[90361]=3,[90363]=3,[90364]=3,[92380]=3,[93433]=3,[93435]=3,[94019]=3,[94022]=3,[126259]=3,[126309]=3,[126311]=3,[126364]=3,[126373]=3,[126393]=3,[128432]=3,[128433]=3,[128997]=3,[135678]=3,[137798]=3,[159735]=3,[159736]=3,[159788]=3,[159926]=3,[159931]=3,[159953]=3,[159956]=3,[159988]=3,[160003]=3,[160007]=3,[160011]=3,[160014]=3,[160017]=3,[160018]=3,[160039]=3,[160044]=3,[160045]=3,[160049]=3,[160052]=3,[160057]=3,[160060]=3,[160063]=3,[160065]=3,[160067]=3,[160073]=3,[160074]=3,[160077]=3,[173035]=3,[47468]=6,[47481]=6,[47482]=6,[47484]=6,[62137]=6,[91776]=6,[91778]=6,[91797]=6,[91800]=6,[91802]=6,[91809]=6,[91837]=6,[91838]=6,[36213]=7,[57984]=7,[117588]=7,[118297]=7,[118337]=7,[118345]=7,[118347]=7,[118350]=7,[157331]=7,[157333]=7,[157348]=7,[157375]=7,[157382]=7,[3110]=9,[3716]=9,[6358]=9,[6360]=9,[7814]=9,[7870]=9,[17735]=9,[17767]=9,[19505]=9,[19647]=9,[30151]=9,[30153]=9,[30213]=9,[32233]=9,[54049]=9,[89751]=9,[89766]=9,[89792]=9,[89808]=9,[112042]=9,[114355]=9,[115232]=9,[115236]=9,[115268]=9,[115276]=9,[115284]=9,[115408]=9,[115578]=9,[115625]=9,[115746]=9,[115748]=9,[115770]=9,[115778]=9,[115781]=9,[115831]=9,[117225]=9,[119899]=9,[134477]=9,[170176]=9,}
local raceCache = {[822]=10,[5227]=5,[6562]=11,[7744]=5,[20549]=6,[20550]=6,[20551]=6,[20552]=6,[20555]=8,[20557]=8,[20572]={2,45},[20573]=2,[20577]=5,[20579]=5,[20582]=4,[20583]=4,[20585]=4,[20589]=7,[20591]={7,978},[20592]=7,[20593]=7,[20594]=3,[20596]=3,[20598]=1,[20599]=1,[25046]={10,8},[26297]=8,[28730]={10,400},[28875]=11,[28877]=10,[28880]={11,1},[33697]={2,576},[33702]={2,384},[50613]={10,32},[58943]=8,[58984]=4,[59221]=11,[59224]=3,[59542]={11,2},[59543]={11,4},[59544]={11,16},[59545]={11,32},[59547]={11,64},[59548]={11,128},[59752]=1,[68975]=22,[68976]=22,[68978]=22,[68992]=22,[68996]=22,[69041]=9,[69042]=9,[69044]=9,[69045]=9,[69046]=9,[69070]=9,[69179]={10,1},[80483]={10,4},[87840]=22,[92680]=7,[92682]=3,[94293]=22,[107072]=24,[107073]=24,[107074]=24,[107076]=24,[107079]={24,8},[121093]={11,528},[129597]={10,512},[131701]=24,[143368]=25,[143369]=26,[154742]=10,[154743]=6,[154744]={7,520},[154746]={7,1},[154747]={7,32},[154748]=4,[155145]={10,2},}


local failedID = 0
local ignores = {
  [80451] = true, -- Survey
  [78670] = true, -- Archaelogy
  [131474] = true, -- Fishing
  [2656] = true, -- Smelting
  [818] = true, -- Cooking Fire
  [158765] = true, -- Cooking
  [2018] = true, -- Blacksmithing
  [158741] = true, -- First Aid
  [161691] = true, -- Garrison Ability
  [125439] = true, -- Revive Battle Pets
  [83958] = true, -- Mobile Banking
  [83968] = true, -- Mass Resurrection
  [6603] = true, -- Auto Attack
  }
local textTable = {}
local CCTable = {}
local cache = {}
local talent_name, talent_spellID

local index, spellsFailed = 0, 0

-- local spec, class = IsSpellClassOrSpec(name)
-- local usable, nomana = IsUsableSpell(i)
-- helpful and harmful

local cacheCount, filteredCount, extraCount = 0, 0, 0

-- LT1 is always the name, LT2 is either maxRange or cost or "Instant", LT3 is "Instant", "Channeled" or description
-- RT1 is always nil, RT2 can be CD, but so can RT3
local parser, LT1, LT2, LT3, RT1, RT2, RT3 = CT:GetParser()
local resourceNum, resourceName, cooldownText
function CT.runSpellLibrary(startNum, stopNum)
  for i, spellID in ipairs(cacheSpell) do
    local spellName, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spellID)

    if spellName and not IsPassiveSpell(spellID) then

      local charges, maxCharges, charge_start, charge_duration = GetSpellCharges(spellID)
      local baseCD = GetSpellBaseCooldown(spellID)
      if baseCD then baseCD = baseCD / 1000 end

      if (baseCD or charge_duration) then

        parser:SetSpellByID(spellID)
        local resourceNum, resourceName = resourceType(LT2:GetText())
        local cooldown = scrapeCooldown(RT2:GetText(), RT3:GetText())

        if cooldown then

          local hasteCD = hasteCD(spellID)
          if baseCD == cooldown then
            cache[spellID] = format("[%s] = %s, -- %s\n", spellID, charge_duration or baseCD, spellName)
          elseif (hasteCD - 0.5) < cooldown and (hasteCD + 0.5) > cooldown then
            cache[spellID] = format("[%s] = %s, -- %s\n", spellID, "hasteCD", spellName)
          elseif baseCD ~= cooldown then
            cache[spellID] = format("[%s] = {%s, %s,}, -- %s\n", spellID, charge_duration or baseCD, cooldown, spellName)
          end

          cacheCount = cacheCount + 1
        else
          extraCount = extraCount + 1
          -- print(i, spellName, baseCD)
        end
      end
    else
      filteredCount = filteredCount + 1
    end
  end
end

-- local failedID = 0
-- local ignores = {
--   [80451] = true, -- Survey
--   [78670] = true, -- Archaelogy
--   [131474] = true, -- Fishing
--   [2656] = true, -- Smelting
--   [818] = true, -- Cooking Fire
--   [158765] = true, -- Cooking
--   [2018] = true, -- Blacksmithing
--   [158741] = true, -- First Aid
--   [161691] = true, -- Garrison Ability
--   [125439] = true, -- Revive Battle Pets
--   [83958] = true, -- Mobile Banking
--   [83968] = true, -- Mass Resurrection
--   [6603] = true, -- Auto Attack
--   }
-- local textTable = {}
-- local CCTable = {}
-- local talent_name, talent_spellID
--
-- local index, spellsFailed = 0, 0
-- local cache = {}
--
-- -- local spec, class = IsSpellClassOrSpec(name)
-- -- local usable, nomana = IsUsableSpell(i)
-- -- helpful and harmful
--
-- local cacheCount, filteredCount, extraCount = 0, 0, 0
--
-- -- LT1 is always the name, LT2 is either maxRange or cost or "Instant", LT3 is "Instant", "Channeled" or description
-- -- RT1 is always nil, RT2 can be CD, but so can RT3
-- local parser, LT1, LT2, LT3, RT1, RT2, RT3 = CT:GetParser()
-- local resourceNum, resourceName, cooldownText
-- function CT.runSpellLibrary(startNum, stopNum)
--   for i = startNum, stopNum do -- 200000
--     local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(i)
--
--     if name and icon and castTime == 0 and spellID and not IsPassiveSpell(i) then
--
--       icon = icon:lower()
--       local _, isSpell = strfind(icon, "\\spell_%a")
--       local _, isAbility = strfind(icon, "\\ability_%a")
--
--       if isSpell or isAbility then
--         local spellName = name
--         name = name:lower()
--
--         local fail =
--         findword(name, "dnd") or
--         findword(name, "test") or
--         findword(name, "debug") or
--         findword(name, "bunny") or
--         findword(name, "visual") or
--         findword(name, "trigger") or
--         strfind(name, "[%]%[%%%+%?]") or -- no brackets, plus signs, percent signs, or question marks
--         findword(name, "vehicle") or
--         findword(name, "event") or
--         findword(name, "quest") or
--         strfind(name, ":%s?%d") or -- interferes with colon duration syntax
--         findword(name, "camera") or
--         strfind(name, "-") or
--         findword(name, "dmg")
--
--         if not fail then
--           local charges, maxCharges, charge_start, charge_duration = GetSpellCharges(i)
--           local baseCD = GetSpellBaseCooldown(i)
--           if baseCD then baseCD = baseCD / 1000 end
--
--           if (baseCD or charge_duration) then
--
--             parser:SetSpellByID(i)
--             local resourceNum, resourceName = resourceType(LT2:GetText())
--             local cooldown = scrapeCooldown(RT2:GetText(), RT3:GetText())
--
--             if cooldown then
--
--               local hasteCD = hasteCD(i)
--               if baseCD == cooldown then
--                 cache[i] = format("[%s] = %s, -- %s\n", i, baseCD, spellName)
--               elseif (hasteCD - 0.5) < cooldown and (hasteCD + 0.5) > cooldown then
--                 cache[i] = format("[%s] = %s, -- %s\n", i, "hasteCD", spellName)
--               elseif baseCD ~= cooldown then
--                 cache[i] = format("[%s] = {%s, %s,}, -- %s\n", i, baseCD, cooldown, spellName)
--               end
--
--               -- cache[i] = startName
--
--               cacheCount = cacheCount + 1
--             else
--               extraCount = extraCount + 1
--               -- print(i, spellName, baseCD)
--             end
--           end
--         end
--       end
--     else
--       filteredCount = filteredCount + 1
--     end
--   end
-- end

-- for classID, spellList in ipairs(Cache) do
--   local name, token, classID = GetClassInfoByID(classID)
--
--   local spellDict = {}
--   for k, v in pairs(spellList) do
--     spellDict[v] = true
--   end
--
--   Cache[token] = spellDict
--   Cache[classID] = nil
-- end
--
-- for spellID, classID in pairs(Cache.PET) do
--   Cache.PET[spellID] = select(2, GetClassInfoByID(classID))
-- end
--
-- for spellID, data in pairs(Cache.RACIAL) do
--   if type(data) == "table" then
--     local raceID = data[1]
--     local classReq = data[2]
--     data[1] = RaceMap[raceID]
--   else
--     -- data is a raceID.
--     Cache.RACIAL[spellID] = RaceMap[data]
--   end
-- end

-- Adds a spell's texture to the texture cache by name
-- so that we can get textures by spell name much more frequently,
-- reducing the usage of question mark and pocketwatch icons.
-- local function AddID(id)
--   if id > 0x7FFFFFFF then
--     return
--   end
--   local name, _, tex = GetSpellInfo(id)
--   name = TMW.strlowerCache[name]
--   if name and not TMW.SpellTexturesMetaIndex[name] then
--     TMW.SpellTexturesMetaIndex[name] = tex
--   end
-- end
--
-- -- Spells of the user's class should be prioritized.
-- for id in pairs(Cache[pclass]) do
--   AddID(id)
-- end
--
-- -- Next comes spells of all other classes.
-- for class, tbl in pairs(Cache) do
--   if class ~= pclass and class ~= "PET" then
--     for id in pairs(tbl) do
--       AddID(id)
--     end
--   end
-- end
--
-- -- Pets are last because there are some overlapping names with class spells
-- -- and we don't want to overwrite the textures for class spells with ones for pet spells.
-- for id in pairs(Cache.PET) do
--   AddID(id)
-- end

local classTable = {}
local classTable = FillLocalizedClassList(classTable)
local stopCount = 0
local function getSpecSpells()

  -- for k,v in pairs(classTable) do
  --   print(k,v)
  -- end

  for classID, spellList in pairs(cache) do
    if stopCount >= 3 then break end
    local name, token, classID = GetClassInfoByID(classID)
    -- print(name, token, classID)

    -- local spellDict = {}
    -- for k, v in pairs(spellList) do
    --   spellDict[v] = true
    -- end

    -- cache[token] = spellDict
    -- cache[classID] = nil
    stopCount = stopCount + 1
  end

  -- CT.spec1 = {GetSpecializationSpells(3)}
  -- print(CT.spec1)
end

local function addExportText()
  if cache and e then
    for k,v in pairs(cache) do
      e:Insert(v)
    end
  end
end

local cacheFrame = CreateFrame("Frame")
-- cacheFrame.num = 1
-- local delay = 0.0
-- local timer = 0
-- local spellsPerUpdate = 1000
-- local spellsStopNumber = 200000
-- cacheFrame:SetScript("OnUpdate", function(self, elapsed)
--   timer = timer + elapsed
--
--   if CT.player.loggedIn and timer >= delay then
--     CT.cachingSpells = true
--
--     -- CT.runSpellLibrary(self.num, self.num + spellsPerUpdate)
--
--     self.num = self.num + spellsPerUpdate
--     -- print("Update", self.num)
--     timer = 0
--   end
--
--   if self.num >= spellsStopNumber then
--     self:SetScript("OnUpdate", nil)
--     CT.cachingSpells = false
--
--     -- CT:Print("Done Caching!", "\nCache size: " .. cacheCount, "\nNumber Filtered: " .. filteredCount, "\nExtra Filter: " .. extraCount, "\n")
--     -- addExportText()
--     -- getSpecSpells()
--     -- parser:SetPadding(-50)
--     -- parser:SetSpellByID(20473)
--     -- parser:AddSpellByID(20473)
--     -- local numLines = parser:NumLines()
--     -- print(numLines, info)
--   end
-- end)

cacheFrame:RegisterEvent("PLAYER_LOGIN") -- accurately detects changes to InCombatLockdown
cacheFrame:SetScript("OnEvent", function(self, event)
  CT.runSpellLibrary()
  CT:Print("Done Caching!", "\nCache size: " .. cacheCount, "\nNumber Filtered: " .. filteredCount, "\nExtra Filter: " .. extraCount, "\n")
  addExportText()
end)

function CT.checkSpellLibrary()
  for i = 1, 200 do
    failedID = 0
    local skillType, spellID = GetSpellBookItemInfo(i, "BOOKTYPE_SPELL")
    local spellName, spellSubName = GetSpellBookItemName(i, "BOOKTYPE_SPELL")
    local start, duration = GetSpellLossOfControlCooldown(i, "BOOKTYPE_SPELL")
    local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spellID)
    local description = GetSpellDescription(spellID)

    if spellID then
      if skillType == "SPELL" and not IsPassiveSpell(spellID) then
        if (not ignores[spellID]) and (not textTable[spellID]) then
          local talent = IsTalentSpell(name)
          local CC, CCtime = checkCC(description)

          local scrapedText = EnumerateTooltipLines(CT.scanningTip, spellID)
          local baseCD = GetSpellBaseCooldown(spellID) / 1000

          if CC and not CCTable[spellID] then
            CCTable[spellID] = format("[%s] = %s, -- %s\n", spellID, baseCD, spellName)
            -- print(spellName, CC, CCtime)
          end

          if scrapedText and baseCD and castTime == 0 and not CCTable[spellID] then

            if talent then
              talent_name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(name)
              baseCD = GetSpellBaseCooldown(spellID) / 1000
            end

            local hasteCD = hasteCD(spellID)
            if baseCD == scrapedText then
              textTable[spellID] = format("[%s] = %s, -- %s\n", spellID, baseCD, spellName)
            elseif (hasteCD - 0.5) < scrapedText and (hasteCD + 0.5) > scrapedText then
              textTable[spellID] = format("[%s] = %s, -- %s\n", spellID, "hasteCD", spellName)
            elseif baseCD ~= scrapedText then
              textTable[spellID] = format("[%s] = {%s, %s,}, -- %s\n", spellID, baseCD, scrapedText, spellName)
            end
          end
        end
      end
    else
      CT:Print(i, "Ending Spell Check Loop")
      break
    end
  end

  local text = format("[%q] = {\n", CT.player.CLASS)
  e:Insert(text)
  for k,v in pairs(textTable) do
    e:Insert("  " .. v)
  end
  e:Insert("},\n")

  local text = format("\n[%q] = {\n", "CC")
  e:Insert(text)
  for k,v in pairs(CCTable) do
    e:Insert("  " .. v)
  end
  e:Insert("},\n")
end

-- local numSpecGroups = GetNumSpecGroups()

-- for spec = 1, numSpecGroups do
--   for i = 1, 7 do
--     for v = 1, 3 do
--       local talentID, name, texture, selected, available = GetTalentInfo(i, v, spec)
--       local spell_name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(name)
--       -- print(spec, name, talentID, spellID)
--       if (not ignores[spellID]) and (not textTable[spellID]) then
--         if spellID then
--           local scrapedText = EnumerateTooltipLines(CT.scanningTip, spellID)
--           local baseCD = GetSpellBaseCooldown(spellID)
--           local spell_baseCD = GetSpellBaseCooldown(name)
--
--           if baseCD and baseCD > 0 then
--             baseCD = baseCD / 1000
--           end
--
--           if spell_baseCD and spell_baseCD > 0 then
--             spell_baseCD = spell_baseCD / 1000
--           end
--
--           print(name, spellID, spell_baseCD, scrapedText)
--
--           if scrapedText and spell_baseCD then
--             local hasteCD = hasteCD(spellID)
--             if spell_baseCD == scrapedText then
--               textTable[spellID] = format("[%s] = %s, -- %s\n", spellID, spell_baseCD, name)
--             elseif scrapedText >= hasteCD + 0.5 then
--               textTable[spellID] = format("[%s] = %s, -- %s\n", spellID, spell_baseCD, name)
--             elseif spell_baseCD ~= scrapedText then
--               textTable[spellID] = format("[%s] = %s, -- %s\n", spellID, scrapedText, name)
--             end
--           else
--             -- print(name, scrapedText, baseCD / 1000)
--           end
--         end
--       end
--     end
--   end
-- end

-- for k,v in pairs(CT.spells) do
--   if v[spellID] then
--     failedID = 0
--     break
--   else
--     failedID = spellID
--   end
-- end
-- if failedID > 0 then
--
--   local charges, maxCharges, start_charge, duration_charge = GetSpellCharges(failedID)
--   local criteria = GetCriteriaSpell(failedID)
--   local spell_name = GetSpellInfo(failedID)
--   local baseCD = GetSpellBaseCooldown(failedID)
--   local specs = GetSpecsForSpell(failedID)
--   -- local cooldownText = scrapeSpellCooldown(spellID)
--   -- local scrapedText = EnumerateTooltipLines(CT.scanningTip, failedID)
  -- if baseCD and baseCD > 0 then
  --   baseCD = baseCD / 1000
  -- else
  --   baseCD = nil
  -- end
--
  -- if not ignores[failedID] then
  --   local baseCD = cooldownText or baseCD or "true"
  --   local text = format("[%s] = %s, -- %s (%s) \n", failedID, baseCD, spell_name, CT.player.class)
  --   textTable[failedID] = text
  --   -- print(format("%s: Failed to find: %s (ID: %s) \n Base Cooldown: %s", i, spell_name, failedID, baseCD))
  --   -- e:SetText(text)
  --   -- e:AddHistoryLine(text)
  -- end
--
--   failedID = 0

-- local r, g, b = LT1:GetTextColor()
-- if g > .95 and r > .95 and b > .95 then
