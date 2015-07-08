if not CombatTracker then return end

--------------------------------------------------------------------------------
-- Locals, Frames, and Tables
--------------------------------------------------------------------------------
local CT = CombatTracker
CT.data = {}
local data = CT.data
local round = CT.round

function CT.updatePowerTypes()
  for i = 0, #CT.powerTypes do
    if UnitPowerMax("player", i) > 0 then
      data.power[i] = {}
      local power = data.power[i]
      power.spells = {}
      power.spellCosts = {}
      power.name = CT.powerTypesFormatted[i]
      power.oldPower = UnitPower("player", i)
      power.currentPower = UnitPower("player", i)
      power.maxPower = UnitPowerMax("player", i)
      power.total = power.total or 0
      power.effective = power.effective or 0
      power.wasted = power.wasted or 0
      power.skip = true

      tinsert(data.power, i)
    end
  end
end

do -- Setting basic data table
  data.GUID = UnitGUID("player")
  data.name = GetUnitName("player", false)

  data.brokenBy = {}

  data.spellsOnCD = {}
  data.spells = {}
  data.spells.types = {}

  data.auras = {}
  data.auras.defensives = {}
  data.auras.offensives = {}
  data.auras.active = {}

  data.activity = {}
  data.activity.timeCasting = data.activity.timeCasting or 0
  data.activity.tempCast = data.activity.tempCast or 0
  data.activity.total = data.activity.total or 0

  data.stats = {}
  data.targets = {}
  data.misc = {}

  data.power = {}

  data.health = {}
  data.health.maxHealth = UnitHealthMax("player")
  
  data.throttle = 0.0085
end

function CT.resetData()
  CT:Print("Resetting Data.")

  CT.TimeSinceLogIn = GetTime()

  do -- Reset Power Data
    for k,v in pairs(data.power) do
      if type(v) == "table" then
        v.wasted = 0
        v.change = 0
        v.totalCost = 0
        v.total = 0
        v.totalCastCost = 0
        v.effective = 0
        v.averageCost = 0
        v.amount = 0
        v.numSpells = 0

        for k,v in pairs(v.spells) do -- spellCosts
          if type(v) == "table" then
            v.total = 0
            v.wasted = 0
            v.effective = 0
          end
        end

        for k,v in pairs(v.spellCosts) do
          if type(v) == "table" then
            v.total = 0
            v.casts = 0
            v.average = 0
          end
        end
      end
    end
  end

  do -- Reset Activity Data
    data.activity.total = 0
    data.activity.instantCasts = 0
    data.activity.tempCast = 0
    data.activity.totalGCD = 0
    data.activity.hardCasts = 0
    data.activity.timeCasting = 0
  end

  do -- Reset Spells
    for k,v in pairs(data.spells) do
      if type(v) == "table" then
        if v.casts then v.casts = 0 end
        if v.totalCD then v.totalCD = 0 end
        if v.CD then v.CD = 0 end
        if v.delay then v.delay = 0 end
        if v.totalGCD then v.totalGCD = 0 end
        if v.charges then v.charges = false end
        if v.onCD then
          v.onCD = false
          v.remaining = 0
          v.ticker:Cancel()
        end
      end
    end
  end
  
  do -- Reset graph
    for spellID, self in pairs(CT.registerGraphs) do
      if self.graphData then
        if self.addingUptimeLine then
          -- self:uptimeGraphUpdate(spell, data.spells[spellID])
          self.addingUptimeLine = false
        end
        
        wipe(self.graphData)
        
        if self.graph and type(self.graph) == "table" then
          self.graph.XMax = 10
          
          if self.expanded then
            self.graph:RefreshGraph()
          end
        end
      end
    end
  end
end

local function runCooldown(spell, spellID)
  local baseCD = (GetSpellBaseCooldown(spellID) or 0) * 0.001

  -- The baseCD == 1 check is because of eternal flame, which gives a 1 second base CD but has no real CD
  -- This may be a problem, be aware of it for other hardcasts faking having CDs
  -- I don't want any hardcasts without real CDs making it in here, may cause issues
  if baseCD == 0 or baseCD == 1 then return end
  local cooldown, charges, chargeMax, chargeStart, chargeDuration, start, duration, endCD

  -- What is this?
  if spell.finishedTime then
    spell.delay = (spell.delay or 0) + (GetTime() - spell.finishedTime)
  end

  if not spell.charges then
    spell.onCD = true
    spell.graphLineStart = true

    start = GetTime()
    duration = 1

    endCD = start + duration

    C_Timer.After(0.1, function()
      charges, chargeMax, chargeStart, chargeDuration = GetSpellCharges(spellID)
      start, duration = GetSpellCooldown(spellID)

      if charges and chargeMax > charges then
        duration = chargeDuration
        start = chargeStart
      end

      if charges and charges < chargeMax and not spell.queued then
        spell.charges = true
      end

      endCD = start + duration
    end)

    spell.ticker = C_Timer.NewTicker(0.001, function(ticker)
      spell.remaining = endCD - GetTime()
      spell.CD = duration - spell.remaining

      if spell.remaining <= data.throttle then -- CD should be done, calculate the true CD and stop the ticker
        if baseCD == duration then
          cooldown = baseCD
        elseif baseCD > duration then
          local hasteCD = baseCD / (1 + (GetHaste() / 100)) -- TODO: Also calculate hasted GCD and compare
          local hasteRounded = round(hasteCD, 3)

          if hasteRounded == duration then
            cooldown = hasteCD
          else
            cooldown = duration
          end
        end
        
        do -- Adjusts the throttle, making it more or less likely to delay a tick
          data.timeOffset = (data.timeOffset or 0) + spell.remaining
          
          if data.timeOffset > 0 then
            data.throttle = data.throttle - (data.timeOffset / 100)
          elseif data.timeOffset < 0 then
            data.throttle = data.throttle - (data.timeOffset / 100)
          end
        end

        spell.totalCD = (spell.totalCD or 0) + cooldown

        ticker:Cancel()
        spell.onCD = false
        spell.CD = 0
        spell.finishedTime = GetTime()
        spell.charges = false

        if spell.graphUpdate and spell.graphUpdate.addingUptimeLine then
          spell.graphCooldownEnd = true
          spell.graphUpdate:uptimeGraphUpdate(spell)
          spell.graphUpdate.addingUptimeLine = false
        end

        if spell.queued then
          spell.queued = false
          runCooldown(spell, spellID)
        end
      end
    end)
  else
    spell.queued = true
    spell.charges = false
  end
end
--------------------------------------------------------------------------------
-- Tooltip Scraping
--------------------------------------------------------------------------------
local parser, LT1, LT2, LT3, RT1, RT2, RT3 = CT:getParser()

local function getSpellCost(spellID)
  if not spellID then return end

  parser:SetSpellByID(spellID)
  local costText = LT2:GetText()
  local cost, powerType, powerIndex

  for i = 1, #data.power do
    local index = data.power[i]
    local power = data.power[index].name

    if costText:match(power) then
      cost = costText:gsub("%D+", "") + 0 -- Just making it a number, I assume this is faster than tonumber()
      powerType = power
      powerIndex = index
      break
    end
  end

  return cost, powerType, powerIndex
end

local defensiveKeyWords = {
  ["All damage taken reduced by"] = "All",
  ["Damage taken reduced by"] = "All",
  ["Reduces all damage taken by"] = "All",
  ["Magic damage taken reduced by"] = "Magic",
  ["Magical damage taken reduced by"] = "Magic",
  ["Spell damage taken reduced by"] = "Magic",
  ["Damage dealt to the Monk reduced by"] = "All",
  ["Incoming damage reduced by"] = "All",
  ["Bonus Armor increased by"] = "Bonus Armor",
  ["Immune to all attacks and damage"] = "Immune",
  ["Immune to all attacks and spells"] = "Immune",
}

local function getDefensiveBuff(aura)
  if not aura then return end

  parser:SetUnitBuff("player", aura)
  local auraDescription = LT2:GetText()

  for k,v in pairs(defensiveKeyWords) do
    if v == "Immune" then
      local immunity = auraDescription:match(k)
      if immunity then
        return v
      end
    else
      local percent = auraDescription:match(k .. " (%d+)%%")

      if percent then
        return v, percent
      end
    end
  end
end

data.stats.updated = GetTime()
local function updateStats()
  local stats = data.stats

  if stats.updated and (GetTime() - stats.updated) >= 0.1 then
    -- CT:Print("UPDATING STATS")
    stats.attackSpeed = UnitAttackSpeed("player")
    stats.attackPower = UnitAttackPower("player")
    stats.primaryStat = UnitStat("player", 1) -- I'll need to setup the index
    stats.crit = GetCritChance()
    stats.haste = GetHaste()
    stats.masteryEffect = GetMasteryEffect()
    stats.multistrike = GetMultistrike()
    stats.multistrikeEffect = GetMultistrikeEffect() -- 30%, so will have some uses probably
    stats.parry = GetParryChance()
    stats.powerRegen = GetPowerRegen() -- same as mana regen
    stats.speed = GetSpeed()
    -- stats.versatilityBonus = GetVersatilityBonus("player")

    -- HEALER STATS
    stats.manaRegen = GetManaRegen() -- per second value
    stats.manaFromSpirit = GetUnitManaRegenRateFromSpirit("player") -- Looks okay? Don't know

    -- TANK STATS
    -- stats.armorEffectiveness = GetArmorEffectiveness()
    stats.defense = UnitDefense("player") -- Just returns 1?
    stats.armor = UnitArmor("player") -- flat number
    stats.leech = GetLifesteal()
    stats.dodge = GetDodgeChance()
    stats.block = GetBlockChance()
    stats.shieldBlock = GetShieldBlock() -- % of reduction, might be useful for warrior or something
    stats.avoidance = GetAvoidance() -- unknown, don't have any

    stats.updated = GetTime()

    local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor("player")
    -- for k,v in pairs(stats) do
    --   print(k,v)
    -- end
  end
end

local prevTarget
local function miscUpdates(event, ...)
  if event == "PLAYER_TARGET_CHANGED" then
    local unitName = GetUnitName("target", false)
    if unitName then
      unit = CT.addUnit(unitName)
    end

    if unitName and prevTarget and unitName ~= prevTarget then
      unit.targetGained = GetTime()
      local prevUnit = CT.addUnit(prevTarget)
      prevUnit.targetTime = (prevUnit.targetTime or 0) + (GetTime() - prevUnit.targetGained)
    elseif unitName then
      unit.targetGained = GetTime()
    else
      unit.targetTime = (unit.targetTime or 0) + (GetTime() - unit.targetGained)
    end
  end
end
--------------------------------------------------------------------------------
-- Spell Casts
--------------------------------------------------------------------------------
local function castSent(unit, spellName, rank, target, lineID)
  if unit ~= "player" then return end

  data.queued = true

  local _, _, _, _, _, _, spellID = GetSpellInfo(spellName) -- Get spellID
  if not spellID then print("Failed to find spell ID for " .. spellName .. ".") return end
  
  if spell then error("SPELL IS GLOBAL") end
  
  local spell = data.spells[spellID]
  if not spell then
    data.spells[spellID] = {}
    spell = data.spells[spellID]
    spell.name = spellName
    if CT.registerGraphs[spellID] then
      spell.graphUpdate = CT.registerGraphs[spellID]
    end
    
    data.spells.needsUpdate = true
  end

  spell.timeSent = GetTime()
end

local function castStart(time, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, school)
  if sourceGUID ~= data.GUID then return end

  local spell = data.spells[spellID]
  if not spell then
    data.spells[spellID] = {}
    spell = data.spells[spellID]
    spell.name = spellName
    if CT.registerGraphs[spellID] then
      spell.graphUpdate = CT.registerGraphs[spellID]
    end
    
    data.spells.needsUpdate = true
  end

  data.casting = true
  data.queued = false

  local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spellID)
  local _, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("player")
  local _, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("player")

  -- NOTE: I don't know if spell.castTime or spell.endTime is more accurate
  -- Currently I am using spell.castTime
  spell.name = name
  spell.castStart = GetTime()
  spell.baseCastTime = round(castTime * (1 + (GetHaste() / 100)) / 1000, 1)
  spell.castTime = spell.baseCastTime / (1 + (GetHaste() / 100))
  spell.endTime = (endTime / 1000) - GetTime()

  data.ID = spellID -- Most recently cast spell
  data.name = name

  spell.remaining = 0
  local endCast = spell.castStart + spell.castTime
  spell.ticker = C_Timer.NewTicker(0.001, function(ticker)
    local remaining = endCast - GetTime()
    local cast = spell.castTime - remaining
    data.activity.timeCasting = (data.activity.timeCasting or 0) + (cast - spell.remaining)
    data.activity.total = (data.activity.total or 0) + (cast - spell.remaining)
    spell.remaining = cast

    if remaining <= 0 then
      ticker:Cancel()
      spell.ticker = nil
      data.activity.timeCasting = (data.activity.timeCasting or 0) - spell.remaining + spell.castTime
      data.activity.total = (data.activity.total or 0) - spell.remaining + spell.castTime
      spell.remaining = 0
    end
  end)
end

local function castStop(unitID, spellName, rank, lineID, spellID)
  if unitID ~= "player" then return end

  local spell = data.spells[spellID]
  if not spell then
    data.spells[spellID] = {}
    spell = data.spells[spellID]
    spell.name = spellName
    if CT.registerGraphs[spellID] then
      spell.graphUpdate = CT.registerGraphs[spellID]
    end
    
    data.spells.needsUpdate = true
  end

  -- Check if the hard cast failed
  -- If it did, then update counters and total casting times
  if data.casting then
    spell.failedCasts = (spell.failedCasts or 0) + 1
    data.activity.failedCasts = (data.activity.failedCasts or 0) + 1

    spell.castDuration = GetTime() - spell.castStart
    data.activity.timeCasting = (data.activity.timeCasting or 0) + spell.castDuration
    data.activity.wastedTimeCasting = (data.activity.wastedTimeCasting or 0) + spell.castDuration
    data.casting = false

    if data.moving then
      data.brokenBy.moving = (data.brokenBy.moving or 0) + 1
    end
  end

  if spell.ticker then
    spell.ticker:Cancel()
    data.activity.timeCasting = (data.activity.timeCasting or 0) - spell.remaining + spell.castTime
    data.activity.total = (data.activity.total or 0) - spell.remaining + spell.castTime
    spell.ticker = nil
    spell.remaining = 0
  end
end

local function castSucceeded(unitID, spellName, rank, lineID, spellID)
  if unitID ~= "player" then return end

  local spell = data.spells[spellID]
  if not spell then
    data.spells[spellID] = {}
    spell = data.spells[spellID]
    spell.name = spellName
    if CT.registerGraphs[spellID] then
      spell.graphUpdate = CT.registerGraphs[spellID]
    end
    
    data.spells.needsUpdate = true
  end

  -- Check if the cast spell causes any others to reset their CDs
  if CT.resetCasts[spellID] then
    for i = 1, #CT.resetCasts[spellID] do
      local ID = CT.resetCasts[spellID][i]
      if not data.spells[ID] then data.spells[ID] = {} end
      data.spells[ID].reset = true
    end
  end

  if data.casting then -- It was a hard cast that finished
    if spell.ticker then
      spell.ticker:Cancel()
      spell.graphCD = spell.CD
      data.activity.timeCasting = (data.activity.timeCasting or 0) - spell.remaining + spell.castTime
      data.activity.total = (data.activity.total or 0) - spell.remaining + spell.castTime
      spell.ticker = nil
      spell.remaining = 0
    end

    spell.casts = (spell.casts or 0) + 1
    data.activity.hardCasts = (data.activity.hardCasts or 0) + 1

    data.activity.timeCasting = (data.activity.timeCasting or 0) + spell.castTime
    data.casting = false
  else -- Not data.casting, so it should be instant
    local startGCD, GCD = GetSpellCooldown(61304) -- TODO: Calculate true GCD? Varies based on spell, might be tough
    local timeChange = 0
    local endGCD = startGCD + GCD

    C_Timer.NewTicker(0.001, function(ticker)
      local remaining = endGCD - GetTime()
      local duration = GCD - remaining
      data.activity.total = (data.activity.total or 0) + (duration - timeChange)
      timeChange = duration

      if remaining <= 0 then
        ticker:Cancel()
        data.activity.total = (data.activity.total or 0) - duration + GCD
        timeChange = 0
      end
    end)

    spell.casts = (spell.casts or 0) + 1
    spell.totalGCD = (spell.totalGCD or 0) + GCD

    data.activity.instantCasts = (data.activity.instantCasts or 0) + 1
    data.activity.totalGCD = (data.activity.totalGCD or 0) + GCD
    data.GCD = GCD

    data.queued = false
    
    if spell.graphUpdate then
      spell.graphCooldownStart = true
      spell.graphUpdate:uptimeGraphUpdate(spell, startGCD)
      spell.graphUpdate.addingUptimeLine = true
    end
  end

  runCooldown(spell, spellID) -- Begins the spell's cooldown tracker

  do -- Scrapes the spell's resource data
    local cost, powerType, powerIndex = getSpellCost(spellID)

    if cost then
      local power = data.power[powerIndex]

      if not power.spellCosts[spellID] then
        power.spellCosts[spellID] = {}
        power.addCostLine = true
        power.numSpellsCost = (power.numSpellsCost or 1) + 1
        CT.forceUpdate = true
      end

      if powerIndex ~= 0 then
        cost = abs(power.change)
      end
      
      power.totalCost = (power.totalCost or 0) + cost
      power.totalCastsCost = (power.totalCastsCost or 0) + 1
      power.averageCost = power.totalCost / power.totalCastsCost
      power.lastCast = spellName
      power.lastCost = cost
      
      local spell = power.spellCosts[spellID]
      spell.total = (spell.total or 0) + cost
      spell.casts = (spell.casts or 0) + 1
      spell.average = spell.total / spell.casts
      spell.name = spellName
      spell.cost = cost
    end
  end
end

local function castInterrupt(time, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, school, extraID, extraName, extraSchool)
  if sourceGUID ~= data.GUID then return end
  
  local spell = data.spells[spellID]
  if not spell then
    data.spells[spellID] = {}
    spell = data.spells[spellID]
    spell.name = spellName
    if CT.registerGraphs[spellID] then
      spell.graphUpdate = CT.registerGraphs[spellID]
    end
    
    data.spells.needsUpdate = true
  end

  -- print(event)
end

CT:addEvent("UNIT_SPELLCAST_SENT", castSent)
CT:addEvent("SPELL_CAST_START", castStart)
CT:addEvent("UNIT_SPELLCAST_STOP", castStop)
CT:addEvent("UNIT_SPELLCAST_SUCCEEDED", castSucceeded)
CT:addEvent("SPELL_INTERRUPT", castInterrupt)
--------------------------------------------------------------------------------
-- Auras
--------------------------------------------------------------------------------
local function auraApplied(time, _, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, school, auraType, amount)
  if destGUID ~= data.GUID then return end
  
  local aura = data.auras[spellID]
  if not aura then
    data.auras[spellID] = {}
    aura = data.auras[spellID]
    aura.source = {}
    aura.destination = {}
    aura.name = spellName
    aura.type = auraType
    aura.school = school
    
    if CT.spells.defensives[spellID] then
      aura.defensive = {}
      local type, percent = getDefensiveBuff(spellName)
      aura.defensive.type = type
      aura.defensive.percent = percent
    elseif CT.spells.offensives[spellID] then
      aura.offensive = {}
    end
  end
  
  aura.totalCount = (aura.totalCount or 0) + 1
  aura.appliedCount = (aura.appliedCount or 0) + 1
  aura.source[aura.totalCount] = sourceGUID
  aura.destination[aura.totalCount] = destGUID
  aura.totalAmount = (aura.totalAmount or 0) + ((amount or 0) - (aura.currentAmount or 0))
  aura.currentAmount = amount
  aura.currentStacks = 1
  
  if CT.spells.defensives[spellID] then
    aura.defensive[aura.totalCount] = {}
    aura.defensive[aura.totalCount].start = GetTime()
    aura.defensive[aura.totalCount].percent = (aura.defensive.percent or 0)
  elseif CT.spells.offensives[spellID] then
    aura.offensive[aura.totalCount] = {}
    aura.offensive[aura.totalCount].start = GetTime()
  end
end

local function auraAppliedDose(time, _, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, school, auraType, amount)
  if destGUID ~= data.GUID then return end
  
  local aura = data.auras[spellID]
  if not aura then
    data.auras[spellID] = {}
    aura = data.auras[spellID]
    aura.source = {}
    aura.destination = {}
    aura.name = spellName
    aura.type = auraType
    aura.school = school
    
    if CT.spells.defensives[spellID] then
      aura.defensive = {}
      local type, percent = getDefensiveBuff(spellName)
      aura.defensive.type = type
      aura.defensive.percent = percent
    elseif CT.spells.offensives[spellID] then
      aura.offensive = {}
    end
  end
  
  aura.totalCount = (aura.totalCount or 0) + 1
  aura.appliedDoseCount = (aura.appliedDoseCount or 0) + 1
  aura.source[aura.totalCount] = sourceGUID
  aura.destination[aura.totalCount] = destGUID
  aura.currentStacks = amount
end

local function auraRefresh(time, _, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, school, auraType, amount)
  if destGUID ~= data.GUID then return end
  
  local aura = data.auras[spellID]
  if not aura then
    data.auras[spellID] = {}
    aura = data.auras[spellID]
    aura.source = {}
    aura.destination = {}
    aura.name = spellName
    aura.type = auraType
    aura.school = school
    
    if CT.spells.defensives[spellID] then
      aura.defensive = {}
      local type, percent = getDefensiveBuff(spellName)
      aura.defensive.type = type
      aura.defensive.percent = percent
    elseif CT.spells.offensives[spellID] then
      aura.offensive = {}
    end
  end
  
  aura.totalCount = (aura.totalCount or 0) + 1
  aura.refreshedCount = (aura.refreshedCount or 0) + 1
  aura.source[aura.totalCount] = sourceGUID
  aura.destination[aura.totalCount] = destGUID
  aura.totalAmount = (aura.totalAmount or 0) + ((amount or 0) - (aura.currentAmount or 0))
  aura.currentAmount = amount
  aura.currentStacks = 1
  
  if CT.spells.defensives[spellID] then
    aura.defensive[aura.totalCount] = {}
    aura.defensive[aura.totalCount].start = GetTime()
    aura.defensive[aura.totalCount].percent = (aura.defensive.percent or 0)
    if aura.defensive[aura.totalCount - 1] then aura.defensive[aura.totalCount - 1].stop = GetTime() end
  elseif CT.spells.offensives[spellID] then
    aura.offensive[aura.totalCount] = {}
    aura.offensive[aura.totalCount].start = GetTime()
    if aura.offensive[aura.totalCount - 1] then aura.offensive[aura.totalCount - 1].stop = GetTime() end
  end
end

local function auraRemoved(time, _, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, school, auraType, amount)
  if destGUID ~= data.GUID then return end
  
  local aura = data.auras[spellID]
  if not aura then
    data.auras[spellID] = {}
    aura = data.auras[spellID]
    aura.source = {}
    aura.destination = {}
    aura.name = spellName
    aura.type = auraType
    aura.school = school
    
    if CT.spells.defensives[spellID] then
      aura.defensive = {}
      local type, percent = getDefensiveBuff(spellName)
      aura.defensive.type = type
      aura.defensive.percent = percent
    elseif CT.spells.offensives[spellID] then
      aura.offensive = {}
    end
  end
  
  aura.removedCount = (aura.removedCount or 0) + 1
  aura.removedAmount = (aura.removedAmount or 0) + (amount or 0)
  aura.currentAmount = 0
  aura.currentStacks = 0
  
  if CT.spells.defensives[spellID] then
    aura.defensive[aura.totalCount].stop = GetTime()
  elseif CT.spells.offensives[spellID] then
    aura.offensive[aura.totalCount].stop = GetTime()
  end
end

local function auraRemovedDose(time, _, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, school, auraType, amount)
  if not data.auras[spellID] then data.auras[spellID] = {} end
  local spell = data.auras[spellID]

  aura.currentStacks = amount

  print("Removed Dose")
end

CT:addEvent("SPELL_AURA_APPLIED", auraApplied)
CT:addEvent("SPELL_AURA_APPLIED_DOSE", auraAppliedDose)
CT:addEvent("SPELL_AURA_REFRESH", auraRefresh)
CT:addEvent("SPELL_AURA_REMOVED", auraRemoved)
CT:addEvent("SPELL_AURA_REMOVED_DOSE", auraRemovedDose)
--------------------------------------------------------------------------------
-- Unit Power, Unit Health, and Resources
--------------------------------------------------------------------------------
local function energize(time, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, school, amount, powerType)
  if sourceGUID ~= data.GUID then return end

  local spellID = data.ID or spellID
  local power = data.power[powerType]

  -- If it was a hard cast, spellName will be wrong. If it was instant, ID will be wrong. This check corrects it
  if data.casting then
    spellName = GetSpellInfo(spellID)
  else
    _, _, _, _, _, _, spellID = GetSpellInfo(spellName)
  end

  if not power.spells[spellID] then
    power.spells[spellID] = {} -- NOTE: Can be nil, right after login
    power.spells[spellID].name = spellName
    power.addLine = true
    CT.forceUpdate = true
    power.numSpells = (power.numSpells or 1) + 1
  end

  local spell = power.spells[spellID]

  if (power.currentPower + amount) > power.maxPower then
    power.wasted = (power.wasted or 0) + ((power.currentPower + amount) - power.maxPower)
    spell.wasted = (spell.wasted or 0) + ((power.currentPower + amount) - power.maxPower)
  end

  power.amount = amount

  power.total = (power.total or 0) + amount
  power.effective = power.total - (power.wasted or 0)

  spell.total = (spell.total or 0) + amount
  spell.effective = spell.total - (spell.wasted or 0)
end

local function unitPowerFrequent(unit, powerType)
  if unit ~= "player" then return end

  local powerTypeIndex = CT.powerTypes["SPELL_POWER_" .. powerType]
  local power = data.power[powerTypeIndex]

  power.accuratePower = UnitPower(unit, powerTypeIndex)
  power.change = power.accuratePower - power.oldPower

  -- Blocks it from updating currentPower before Energize has fired, except mana
  if powerTypeIndex ~= 0 then
    if power.skip then
      power.skip = false
      return
    end

    power.skip = true
  end

  power.currentPower = power.accuratePower

  if powerTypeIndex ~= 0 then
    -- CT:Print("Unit Power Update", power.change)
  end

  power.oldPower = power.currentPower
end

local function unitHealthFrequent(unit)
  if unit ~= "player" then return end

  local health = data.health

  health.currentHealth = UnitHealth(unit)
end

local function unitMaxPower(unit, powerType)
  if unit ~= "player" then return end

  local powerTypeIndex = CT.powerTypes["SPELL_POWER_" .. powerType]
  local power = data.power[powerTypeIndex]

  power.maxPower = UnitPowerMax(unit, powerTypeIndex)
end

local function unitMaxHealth(unit)
  if unit ~= "player" then return end

  local health = data.health

  health.maxHealth = UnitHealthMax(unit)
end

CT:addEvent("SPELL_ENERGIZE", energize)
CT:addEvent("UNIT_POWER_FREQUENT", unitPowerFrequent)
CT:addEvent("UNIT_HEALTH_FREQUENT", unitHealthFrequent)
CT:addEvent("UNIT_MAXPOWER", unitMaxPower)
CT:addEvent("UNIT_MAXHEALTH", unitMaxHealth)
--------------------------------------------------------------------------------
-- Player Movement
--------------------------------------------------------------------------------
local function startedMoving()
  data.moving = true
  data.moveStart = GetTime()
end

local function stoppedMoving()
  data.moving = false
  data.movement = (data.movement or 0) + (GetTime() - data.moveStart)
end

CT:addEvent("PLAYER_STARTED_MOVING", startedMoving)
CT:addEvent("PLAYER_STOPPED_MOVING", stoppedMoving)
--------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------


-- CT:addEvent("COMBAT_RATING_UPDATE", updateStats, {src_is_interesting = true, dst_is_not_interesting = true})

-- CT:addEvent("PLAYER_TARGET_CHANGED", miscUpdates, {src_is_interesting = true, dst_is_not_interesting = true})

-- CT:addEvent("UNIT_SPELLCAST_FAILED", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})
-- CT:addEvent("UNIT_SPELLCAST_INTERRUPTED", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})
-- CT:addEvent("UNIT_SPELLCAST_SUCCEEDED", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})
-- CT:addEvent("UNIT_SPELLCAST_DELAYED", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})
-- CT:addEvent("UNIT_SPELLCAST_FAILED_QUIET", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})

-- function ItemCache:CacheItems(force)
-- 	if not force and not doUpdateCache then
-- 		return
-- 	end
--
-- 	wipe(CurrentItems)
--
-- 	-- Cache items in bags.
-- 	for container = 0, NUM_BAG_SLOTS do
-- 		for slot = 1, GetContainerNumSlots(container) do
-- 			local id = GetContainerItemID(container, slot)
-- 			if id then
-- 				local name = GetItemInfo(id)
-- 				name = name and strlower(name)
--
-- 				CurrentItems[id] = name
-- 				cacheItem(id, name)
-- 			end
-- 		end
-- 	end
--
-- 	-- Cache equipped items
-- 	for slot = 1, 19 do
-- 		local id = GetInventoryItemID("player", slot)
-- 		if id then
-- 			local name = GetItemInfo(id)
-- 			name = name and strlower(name)
--
-- 			CurrentItems[id] = name
-- 			cacheItem(id, name)
-- 		end
-- 	end
--
-- 	for id, name in pairs(CurrentItems) do
-- 		CurrentItems[name] = id
-- 	end
--
-- 	doUpdateCache = nil
-- end
