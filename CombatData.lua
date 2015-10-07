if not CombatTracker then return end

--------------------------------------------------------------------------------
-- Locals, Frames, and Tables
--------------------------------------------------------------------------------
local CT = CombatTracker
-- CT.data = {}
local combatevents = CT.combatevents
local round = CT.round
local delayGCD = 0.10
local debug = CT.debug
--------------------------------------------------------------------------------
-- Changing Data
--------------------------------------------------------------------------------
local data

function CT.updateLocalData(set)
  data = set
end
--------------------------------------------------------------------------------
-- Basic Data Tables
--------------------------------------------------------------------------------
function CT.setBasicData()
  data = CT.current

  data.name = GetUnitName("player", false)

  data.pet = {}
  -- data.petGUID = UnitGUID("pet")
  data.petName = GetUnitName("pet", false)
  data.petDamage = {}

  data.brokenBy = {}

  data.spells = {}
  -- data.spellsOnCD = {}
  -- data.spells.types = {}

  data.auras = {}
  -- data.auras.defensives = {}
  -- data.auras.offensives = {}

  data.activity = {}
  data.activity.timeCasting = data.activity.timeCasting or 0
  data.activity.tempCast = data.activity.tempCast or 0
  data.activity.total = data.activity.total or 0

  data.stats = {}
  -- data.stats.updated = GetTime()

  data.target = {}
  data.target.targets = {}
  data.target.prevTarget = "None"

  data.focus = {}
  data.focus.focused = {}
  data.focus.prevFocus = "None"

  data.units = {}

  -- data.misc = {}

  data.power = {}

  data.stance = {}

  data.health = {}
  -- data.health.maxHealth = UnitHealthMax("player")

  data.healing = {}
  data.healingTaken = {}

  data.damage = {}
  data.damageTaken = {}

  CT.settings.spellCooldownThrottle = 0.0085

  data.bossID = {}

  -- CT.sets.current = data -- The current set

  do -- Line graphs
    data.graphs = {}
    data.graphs.updateDelay = 0.2
    data.graphs.lastUpdate = 0
    data.graphs.splitAmount = 500
  end

  do -- Uptime graphs
    data.uptimeGraphs = {}
    data.uptimeGraphs.cooldowns = {}
    data.uptimeGraphs.buffs = {}
    data.uptimeGraphs.debuffs = {}
    data.uptimeGraphs.misc = {}
    data.uptimeGraphs.categories = {
      data.uptimeGraphs.cooldowns,
      data.uptimeGraphs.buffs,
      data.uptimeGraphs.debuffs,
      data.uptimeGraphs.misc,
    }
  end
end
--------------------------------------------------------------------------------
-- Running the Cooldown
--------------------------------------------------------------------------------
local function finishCooldown(spell)
  if not spell.ticker then return end

  local spellID = spell.ID
  local baseCD = spell.baseCD
  local duration = spell.duration

  if not spell.ID then
    debug("No spell.ID!", spell.name)
  end

  if not spell then
    debug("Also no spell table at all!")
  end

  local cooldown

  if baseCD == duration then
    cooldown = baseCD
  elseif baseCD > duration then
    local hasteCD = baseCD / (1 + (GetHaste() / 100))
    local hasteRounded = round(hasteCD, 3)

    if hasteRounded == duration then
      cooldown = hasteCD
    else
      cooldown = duration
    end
  end

  if spell.reset then
    spell.reset = false
  else -- Adjusts the throttle, making it more or less likely to delay a tick
    data.timeOffset = (data.timeOffset or 0) + spell.remaining

    if data.timeOffset > 0 then
      CT.settings.spellCooldownThrottle = CT.settings.spellCooldownThrottle - (data.timeOffset / 100)
    elseif data.timeOffset < 0 then
      CT.settings.spellCooldownThrottle = CT.settings.spellCooldownThrottle - (data.timeOffset / 100)
    end
  end

  spell.totalCD = (spell.totalCD or 0) + (cooldown or 0)

  spell.ticker:Cancel()
  spell.ticker = false
  spell.onCD = false
  spell.CD = 0
  spell.start = 0
  spell.duration = 0
  spell.finishedTime = GetTime()
  spell.charges = false

  do -- Start the hidden line
    local setGraph = data.uptimeGraphs.cooldowns[spellID]

    if setGraph then
      local dstGUID = data.playerGUID
      local dstName = data.playerName

      local data = setGraph[dstGUID].data
      data[#data + 1] = spell.finishedTime - CT.combatStart

      setGraph:refresh()
      debug("Starting graph line")
    end
  end
end

local function runCooldown(spell, spellID, spellName)
  spell.baseCD = (GetSpellBaseCooldown(spellID) or 0) * 0.001

  -- The baseCD == 1 check is because of eternal flame, which gives a 1 second base CD but has no real CD
  -- This may be a problem, be aware of it for other hardcasts faking having CDs
  -- I don't want any hardcasts without real CDs making it in here, may cause issues
  if spell.baseCD == 0 or spell.baseCD == 1 then
    -- debug("Breaking CD early", spellName, baseCD)
    return
  end

  local cooldown, charges, chargeMax, chargeStart, chargeDuration, start, duration, endCD

  if not spell.charges then
    spell.onCD = true

    spell.start, spell.duration = GetSpellCooldown(spellID)

    if spell.start == 0 then
      spell.start = data.timeSent or GetTime() -- start was nil when using weapon enhancement thing
      spell.duration = spell.baseCD
    end

    spell.endCD = spell.start + spell.duration

    if spell.finishedTime then
      spell.delay = (spell.delay or 0) + (spell.start - spell.finishedTime)

      if (spell.start - spell.finishedTime) > (spell.longestDelay or 0) then
        spell.longestDelay = (spell.start - spell.finishedTime)
      end
    end

    do -- Handles creating and refreshing of uptime graph
      local setGraph = data.uptimeGraphs.cooldowns[spellID]

      if not setGraph then
        setGraph = data.addCooldown(spellID, spellName, CT.colors.yellow)
      end

      if setGraph then -- Don't merge above, always needs to be checked
        local dstGUID = data.playerGUID
        local dstName = data.playerName

        if not setGraph[dstGUID] then
          setGraph.addNewLine(dstGUID, dstName)
        end

        local data = setGraph[dstGUID].data
        data[#data + 1] = spell.start - CT.combatStart

        setGraph:refresh()
      end
    end

    C_Timer.After(0.1, function() -- Get the real CD
      charges, chargeMax, chargeStart, chargeDuration = GetSpellCharges(spellID)
      spell.start, spell.duration = GetSpellCooldown(spellID)

      if charges and chargeMax > charges then
        spell.duration = chargeDuration
        spell.start = chargeStart
      end

      if charges and charges < chargeMax and not spell.queued then
        spell.charges = true
      end

      spell.endCD = spell.start + spell.duration
    end)

    if not spell.cooldownHandler then debug("No cooldown handler for", spellName .. ".") end
    spell.ticker = C_Timer.NewTicker(0.001, spell.cooldownHandler)
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
    local index = data.power[i].index
    local powerName = data.power[i].name

    if costText:match(powerName) then
      cost = costText:gsub("%D+", "") + 0 -- Just making it a number, I assume this is faster than tonumber()
      powerType = powerName
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

function CT.getDefensiveBuff(aura)
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

local function updateStats()
  local stats = data.stats

  if stats.updated and (GetTime() - stats.updated) >= 0.1 then
    -- debug("UPDATING STATS")
    stats.attackSpeed = UnitAttackSpeed("player")
    stats.attackPower = UnitAttackPower("player")
    stats.primaryStat = UnitStat("player", 1) -- I'll need to setup the index
    stats.crit = GetCritChance()
    stats.haste = GetHaste()
    stats.masteryEffect = GetMasteryEffect()
    stats.MS = GetMultistrike()
    stats.MSEffect = GetMultistrikeEffect() -- 30%, so will have some uses probably
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
    --   debug(k,v)
    -- end
  end
end
--------------------------------------------------------------------------------
-- General Data Functions
--------------------------------------------------------------------------------
local function addSpell(spellID, spellName, school)
  if not CT.player.loggedIn then debug("Blocking", spellName, "from creating spell table.") return end
  local uptimeGraphs = CT.current.uptimeGraphs

  local spell = data.spells[spellID]

  if not spell then
    data.spells[spellID] = {}
    data.spells[spellName] = data.spells[spellID]
    spell = data.spells[spellID]
    spell.name = spellName
    spell.ID = spellID
    spell.powerGain = {}
    spell.powerCost = {}
    spell.icon = GetSpellTexture(spell.name)
    data.spells[#data.spells + 1] = spell

    spell.cooldownHandler = function(ticker)
      local cTime = GetTime()

      if not spell.endCD then
        spell.start, spell.duration = GetSpellCooldown(spellID)
        spell.endCD = spell.start + spell.duration
      end

      spell.remaining = spell.endCD - cTime
      spell.CD = spell.duration - spell.remaining

      -- local oneTick = currentTime - CT.currentTime -- TODO: Add this into the system for breaking early/delaying

      if spell.reset or (spell.remaining <= CT.settings.spellCooldownThrottle) then -- CD should be done, calculate the true CD and stop the ticker
        -- finishCooldown(spell)
        spell.stopCooldown()

        if spell.queued then
          spell.queued = false
          runCooldown(spell, spellID, spellName)
        end
      end
    end

    spell.stopCooldown = function() -- Finish the cooldown
      -- if not spell.ticker then return end

      -- if spell.ticker then spell.ticker:Cancel() end

      local baseCD = spell.baseCD
      local duration = spell.duration

      local cooldown

      if baseCD == duration then
        cooldown = baseCD
      elseif baseCD > duration then
        local hasteCD = baseCD / (1 + (GetHaste() / 100))
        local hasteRounded = round(hasteCD, 3)

        if hasteRounded == duration then
          cooldown = hasteCD
        else
          cooldown = duration
        end
      end

      if spell.reset then
        spell.reset = false
      else -- Adjusts the throttle, making it more or less likely to delay a tick
        data.timeOffset = (data.timeOffset or 0) + spell.remaining

        if data.timeOffset > 0 then
          CT.settings.spellCooldownThrottle = CT.settings.spellCooldownThrottle - (data.timeOffset / 100)
        elseif data.timeOffset < 0 then
          CT.settings.spellCooldownThrottle = CT.settings.spellCooldownThrottle - (data.timeOffset / 100)
        end
      end

      spell.totalCD = (spell.totalCD or 0) + (cooldown or 0)

      -- spell.ticker:Cancel()
      if spell.ticker then spell.ticker:Cancel() end
      spell.ticker = false
      spell.onCD = false
      spell.CD = 0
      spell.start = 0
      spell.duration = 0
      spell.finishedTime = GetTime()
      spell.charges = false

      do -- Start the hidden gaph line
        local setGraph = data.uptimeGraphs.cooldowns[spellID]

        if setGraph then
          local dstGUID = data.playerGUID
          local dstName = data.playerName

          local data = setGraph[dstGUID].data
          local num = #data
          data[num + 1] = spell.finishedTime - CT.combatStart

          setGraph:refresh()
        end
      end
    end
  end

  if school and not spell.schoolColor then
    spell.school = school
    spell.schoolColor = CT.spells.schoolColors[school]

    -- for i = 1, #uptimeGraphs.categories do
    --   local category = uptimeGraphs.categories[i]
    --   if category[spellID] then
    --     category[spellID].color = spell.schoolColor.decimals
    --     category[spellID].convertedColor = "|c" .. spell.schoolColor.hex
    --     local lineTable = CT.uptimeGraphLines[category[spellID].category][category[spellID].name]
    --
    --     for i = 1, #lineTable do
    --       lineTable[i]:SetVertexColor(category[spellID].color[1], category[spellID].color[2], category[spellID].color[3])
    --     end
    --   end
    -- end
  end

  return spell
end

local function addAura(spellID, spellName, auraType, consolidated, count)
  local uptimeGraphs = CT.current.uptimeGraphs
  local lineTable = CT.uptimeGraphLines[spellName]
  local aura = data.auras[spellID]

  if aura then
    return aura
  else
    data.auras[spellID] = {}
    aura = data.auras[spellID]
    aura.source = {}
    aura.destination = {}
    aura.name = spellName
    aura.type = auraType

    if CT.spells.defensives[spellID] then
      aura.defensive = {}
      local type, percent = CT.getDefensiveBuff(spellName)
      aura.defensive.type = type or "Unknown"
      aura.defensive.percent = percent or "Unknown"
    elseif CT.spells.offensives[spellID] then
      aura.offensive = {}
      -- local type, percent = CT.getOffensiveBuff(spellName)
      aura.offensive.type = type or "Unknown"
      aura.offensive.percent = percent or "Unknown"
    end

    return aura
  end
end

local function findUnitID(GUID, name)
  if not GUID then return end

  -- For anyone looking through my code, I know this may look quite inefficient,
  -- but I did a bunch of tests of looping it, and it really isn't terribly slow
  -- The vast majority of the time it should stop very quickly with the first 9 checks
  -- and running those takes basically nothing, but even the UnitGUID is a fairly
  -- light and quick function
  -- It's only really wasteful if it keeps going to the "boss" part, but that's only
  -- when the player is using macros that specifically cast at boss 1 - 5

  if data.playerGUID == GUID then
    return "player"
  elseif data.units.target == GUID then
    return "target"
  elseif data.group and data.group[GUID] then -- Party or raid
    return data.group[GUID]
  elseif data.units.focus == GUID then
    return "focus"
  elseif data.petGUID and data.petGUID == GUID then
    return "pet"
  elseif data.units.mouseover == GUID then
    return "mouseover"
  elseif data.groupPets and data.groupPets[GUID] then -- Party or raid pet
    return data.groupPets[GUID]
  elseif data.arena and data.arena[GUID] == GUID then -- Arena 1 - 5
    return data.arena[GUID]
  elseif data.arenaPets and data.arenaPets[GUID] == GUID then -- Arena Pets 1 - 5
    return data.arenaPets[GUID]
  elseif UnitGUID("target") == GUID then
    return "target"
  elseif UnitGUID("focus") == GUID then
    return "focus"
  elseif UnitGUID("mouseover") == GUID then
    return "mouseover"
  elseif UnitGUID("vehicle") == GUID then
    return "vehicle"
  else
    for i = 1, 5 do
      if not data.bossID[i] then data.bossID[i] = "boss" .. i end -- Store them in a table just so I don't have to concat it every time

      if UnitGUID(data.bossID[i]) == GUID then
        return data.bossID[i]
      end
    end
  end

  return name -- Failed to find anything, just send name, cause sometimes it's a valid ID
end
--------------------------------------------------------------------------------
-- Healing and Damage
--------------------------------------------------------------------------------
local function spellHeal(time, event, _, srcGUID, srcName, srcFlags, _, dstGUID, dstName, dstFlags, _, spellID, spellName, school, amount, overheal, absorb, crit, MS)
  -- If it isn't done by me or my pet or done to me or my pet, then return
  if (srcName ~= data.petName) and (srcName ~= data.name) and (dstName ~= data.petName) and (dstName ~= data.name) then return end

  if not CT.tracking then
    CT.startTracking("Beginning tracking from HEAL. Source: " .. srcName .. " Spell: " .. spellName .. ".")
  end

  if srcName == data.name then -- From player

    if data.casting then -- Some spellIDs are specific to healing, not the cast, this should transform them into the cast ID
      spellName = GetSpellInfo(spellID)
    else
      local _, _, _, _, _, _, ID = GetSpellInfo(spellName)
      if ID then spellID = ID end -- Sometimes this can return nil
    end

    local heal = data.healing
    local spell = data.spells[spellID]
    if not spell or not spell.schoolColor then
      spell = addSpell(spellID, spellName, school)
    end

    spell.totalHealing = (spell.totalHealing or 0) + amount
    spell.overhealing = (spell.overhealing or 0) + overheal
    spell.effectiveHealing = (spell.effectiveHealing or 0) + (amount - overheal)

    heal.total = (heal.total or 0) + amount
    heal.overhealing = (heal.overhealing or 0) + overheal
    heal.effective = (heal.effective or 0) + (amount - overheal)

    if not MS then -- Figures out how many targets were hit
      if (spell.targetCountTime or time) == time then
        spell.tempCount = (spell.tempCount or 0) + 1

        if not spell.timer then
          spell.timer = true
          C_Timer.After(0.01, function()
            spell.timer = false
            if spell.tempCount > 1 then
              spell.targetCountTotal = (spell.targetCountTotal or 0) + spell.tempCount
            end
          end)
        end
      else
        spell.tempCount = 1
      end

      spell.targetCountTime = time
    end

    if absorb then
      spell.absorbHeal = (spell.absorbHeal or 0) + 1
      heal.absorb = (heal.absorb or 0) + 1
    end
    if crit then
      spell.critHeal = (spell.critHeal or 0) + 1
      heal.crit = (heal.crit or 0) + 1
    end
    if MS then
      spell.MSHeal = (spell.MSHeal or 0) + 1
      heal.MS = (heal.MS or 0) + 1
    end
  end

  if dstName == data.name then -- To player
    local healTaken = data.healingTaken

    healTaken.total = (healTaken.total or 0) + amount
    healTaken.overhealing = (healTaken.overhealing or 0) + overheal
    healTaken.effective = (healTaken.effective or 0) + (amount - overheal)

    if crit then healTaken.crit = (healTaken.crit or 0) + 1 end
    if MS then healTaken.MS = (healTaken.MS or 0) + 1 end
  end
end

local function spellDamage(time, event, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school, amount, overkill, school2, resist, block, absorb, crit, glance, crush, offHand, MS)
  -- If it isn't done by me or my pet or done to me or my pet, then return
  if (srcName ~= data.petName) and (srcName ~= data.name) and (dstName ~= data.petName) and (dstName ~= data.name) then return end

  if not CT.tracking then
    CT.startTracking("Beginning tracking from DAMAGE. Source: " .. srcName .. " Spell: " .. spellName .. ".")
  end

  if (srcName == data.petName) or (srcName == data.name) then -- From player or player's pet

    if data.casting then -- Some spellIDs are specific to damage, not the cast, this should transform them into the cast ID
      spellName = GetSpellInfo(spellID)
    else
      local _, _, _, _, _, _, ID = GetSpellInfo(spellName)
      if ID then spellID = ID end -- Sometimes this can return nil
    end

    local spell = data.spells[spellID]
    if not spell or not spell.schoolColor then
      spell = addSpell(spellID, spellName, school)
    end

    if not multi then -- Figures out how many targets were hit
      if (spell.targetCountTime or time) == time then
        spell.tempCount = (spell.tempCount or 0) + 1

        if not spell.timer then
          spell.timer = true
          C_Timer.After(0.01, function()
            spell.timer = false
            if spell.tempCount > 1 then
              spell.targetCountTotal = (spell.targetCountTotal or 0) + spell.tempCount
            end
          end)
        end
      else
        spell.tempCount = 1
      end

      spell.targetCountTime = time
    end

    spell.totalDamage = (spell.totalDamage or 0) + amount
    spell.overkill = (spell.overkill or 0) + overkill
    spell.effectiveDamage = (spell.effectiveDamage or 0) + (amount - overkill)

    if resist then spell.resist = (spell.resist or 0) + 1 end
    if block then spell.block = (spell.block or 0) + 1 end
    if absorb then spell.absorbDamage = (spell.absorbDamage or 0) + 1 end
    if crit then spell.critDamage = (spell.critDamage or 0) + 1 end
    if glance then spell.glance = (spell.glance or 0) + 1 end
    if crush then spell.crush = (spell.crush or 0) + 1 end
    if offHand then spell.offHand = (spell.offHand or 0) + 1 end
    if MS then spell.MSDamage = (spell.MSDamage or 0) + 1 end

    if (srcName == data.name) then -- From player
      local damage = data.damage

      damage.total = (damage.total or 0) + amount
      damage.overkill = (damage.overkill or 0) + overkill
      damage.effective = (damage.effective or 0) + (amount - overkill)

      if resist then damage.resist = (damage.resist or 0) + 1 end
      if block then damage.block = (damage.block or 0) + 1 end
      if absorb then damage.absorb = (damage.absorb or 0) + 1 end
      if crit then damage.crit = (damage.crit or 0) + 1 end
      if glance then damage.glance = (damage.glance or 0) + 1 end
      if crush then damage.crush = (damage.crush or 0) + 1 end
      if offHand then damage.offHand = (damage.offHand or 0) + 1 end
      if MS then damage.MS = (damage.MS or 0) + 1 end
    end

    if (srcName == data.petName) then -- From player's pet
      local petDamage = data.petDamage

      petDamage.total = (petDamage.total or 0) + amount
      petDamage.overkill = (petDamage.overkill or 0) + overkill
      petDamage.effective = (petDamage.effective or 0) + (amount - overkill)

      if resist then petDamage.resist = (petDamage.resist or 0) + 1 end
      if block then petDamage.block = (petDamage.block or 0) + 1 end
      if absorb then petDamage.absorb = (petDamage.absorb or 0) + 1 end
      if crit then petDamage.crit = (petDamage.crit or 0) + 1 end
      if glance then petDamage.glance = (petDamage.glance or 0) + 1 end
      if crush then petDamage.crush = (petDamage.crush or 0) + 1 end
      if offHand then petDamage.offHand = (petDamage.offHand or 0) + 1 end
      if MS then petDamage.MS = (petDamage.MS or 0) + 1 end
    end
  elseif (dstName == data.name) then -- To player
    local damageTaken = data.damageTaken

    damageTaken.total = (damageTaken.total or 0) + amount
    damageTaken.overkill = (damageTaken.overkill or 0) + overkill
    damageTaken.effective = (damageTaken.effective or 0) + (amount - overkill)

    if resist then damageTaken.resist = (damageTaken.resist or 0) + 1 end
    if block then damageTaken.block = (damageTaken.block or 0) + 1 end
    if absorb then damageTaken.absorb = (damageTaken.absorb or 0) + 1 end
    if crit then damageTaken.crit = (damageTaken.crit or 0) + 1 end
    if glance then damageTaken.glance = (damageTaken.glance or 0) + 1 end
    if crush then damageTaken.crush = (damageTaken.crush or 0) + 1 end
    if offHand then damageTaken.offHand = (damageTaken.offHand or 0) + 1 end
    if MS then damageTaken.MS = (damageTaken.MS or 0) + 1 end
  end
end

local function spellMissed(time, event, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school, missType, offHand, MS, amount)
  -- If it isn't done by me or my pet or done to me or my pet, then return
  if (srcName ~= data.petName) and (srcName ~= data.name) and (dstName ~= data.petName) and (dstName ~= data.name) then return end

  if not CT.tracking then
    CT.startTracking("Beginning tracking from MISSED. Source: " .. srcName .. " Spell: " .. spellName .. ".")
  end

  if (srcName == data.petName) or (srcName == data.name) then -- From player or player's pet

    if data.casting then -- Some spellIDs are specific to damage, not the cast, this should transform them into the cast ID
      spellName = GetSpellInfo(spellID)
    else
      local _, _, _, _, _, _, ID = GetSpellInfo(spellName)
      if ID then spellID = ID end -- Sometimes this can return nil
    end

    local spell = data.spells[spellID]
    if not spell or not spell.schoolColor then
      spell = addSpell(spellID, spellName, school)
    end

    if not MS then -- Figures out how many targets were hit
      if (spell.targetCountTime or time) == time then
        spell.tempCount = (spell.tempCount or 0) + 1

        if not spell.timer then
          spell.timer = true
          C_Timer.After(0.01, function()
            spell.timer = false
            spell.targetCountTotal = (spell.targetCountTotal or 0) + spell.tempCount
          end)
        end
      else
        spell.tempCount = 1
      end

      spell.targetCountTime = time
    end

    spell[missType] = (spell[missType] or 0) + 1

    spell.totalMissed = (spell.totalMissed or 0) + (amount or 0)

    if offHand then spell.offHand = (spell.offHand or 0) + 1 end
    if MS then spell.MSMissed = (spell.MSMissed or 0) + 1 end

    if (srcName == data.name) then -- From player
      local damage = data.damage

      damage[missType] = (damage[missType] or 0) + 1

      damage.missedTotal = (damage.missedTotal or 0) + (amount or 0)

      if offHand then damage.offHand = (damage.offHand or 0) + 1 end
      if MS then damage.MS = (damage.MS or 0) + 1 end
    end

    if (srcName == data.petName) then -- From player's pet
      local petDamage = data.petDamage

      petDamage[missType] = (petDamage[missType] or 0) + 1

      petDamage.missedTotal = (petDamage.missedTotal or 0) + (amount or 0)

      if offHand then petDamage.offHand = (petDamage.offHand or 0) + 1 end
      if MS then petDamage.MS = (petDamage.MS or 0) + 1 end
    end
  elseif (dstName == data.name) then -- To player
    local damageTaken = data.damageTaken

    damageTaken[missType] = (damageTaken[missType] or 0) + 1

    damageTaken.missedTotal = (damageTaken.missedTotal or 0) + (amount or 0)

    if offHand then damageTaken.offHand = (damageTaken.offHand or 0) + 1 end
    if MS then damageTaken.MS = (damageTaken.MS or 0) + 1 end
  end
end

local function swingDamage(time, event, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, amount, overkill, school2, resist, block, absorb, crit, glance, crush, offHand, MS)
  -- If it isn't done by me or my pet or done to me or my pet, then return
  if (srcName ~= data.petName) and (srcName ~= data.name) and (dstName ~= data.petName) and (dstName ~= data.name) then return end

  if not CT.tracking then
    CT.startTracking("Beginning tracking from swing damage. Source:", srcName .. ".")
  end

  if (srcName == data.petName) or (srcName == data.name) then
    if (srcName == data.name) then
      local damage = data.damage

      damage.total = (damage.total or 0) + amount
      damage.overkill = (damage.overkill or 0) + overkill
      damage.effective = (damage.effective or 0) + (amount - overkill)

      if resist then damage.resist = (damage.resist or 0) + 1 end
      if block then damage.block = (damage.block or 0) + 1 end
      if absorb then damage.absorb = (damage.absorb or 0) + 1 end
      if crit then damage.crit = (damage.crit or 0) + 1 end
      if glance then damage.glance = (damage.glance or 0) + 1 end
      if crush then damage.crush = (damage.crush or 0) + 1 end
      if offHand then damage.offHand = (damage.offHand or 0) + 1 end
      if MS then damage.MS = (damage.MS or 0) + 1 end
    end

    if (srcName == data.petName) then
      local petDamage = data.petDamage

      petDamage.total = (petDamage.total or 0) + amount
      petDamage.overkill = (petDamage.overkill or 0) + overkill
      petDamage.effective = (petDamage.effective or 0) + (amount - overkill)

      if resist then petDamage.resist = (petDamage.resist or 0) + 1 end
      if block then petDamage.block = (petDamage.block or 0) + 1 end
      if absorb then petDamage.absorb = (petDamage.absorb or 0) + 1 end
      if crit then petDamage.crit = (petDamage.crit or 0) + 1 end
      if glance then petDamage.glance = (petDamage.glance or 0) + 1 end
      if crush then petDamage.crush = (petDamage.crush or 0) + 1 end
      if offHand then petDamage.offHand = (petDamage.offHand or 0) + 1 end
      if MS then petDamage.MS = (petDamage.MS or 0) + 1 end
    end
  elseif (dstName == data.name) then
    local damageTaken = data.damageTaken

    damageTaken.total = (damageTaken.total or 0) + amount
    damageTaken.overkill = (damageTaken.overkill or 0) + overkill
    damageTaken.effective = (damageTaken.effective or 0) + (amount - overkill)

    if resist then damageTaken.resist = (damageTaken.resist or 0) + 1 end
    if block then damageTaken.block = (damageTaken.block or 0) + 1 end
    if absorb then damageTaken.absorb = (damageTaken.absorb or 0) + 1 end
    if crit then damageTaken.crit = (damageTaken.crit or 0) + 1 end
    if glance then damageTaken.glance = (damageTaken.glance or 0) + 1 end
    if crush then damageTaken.crush = (damageTaken.crush or 0) + 1 end
    if offHand then damageTaken.offHand = (damageTaken.offHand or 0) + 1 end
    if MS then damageTaken.MS = (damageTaken.MS or 0) + 1 end
  end
end

combatevents["SPELL_HEAL"] = spellHeal
combatevents["SPELL_PERIODIC_HEAL"] = spellHeal
combatevents["SPELL_DAMAGE"] = spellDamage
combatevents["SPELL_PERIODIC_DAMAGE"] = spellDamage
combatevents["RANGE_DAMAGE"] = spellDamage
combatevents["SPELL_MISSED"] = spellMissed
combatevents["SPELL_PERIODIC_MISSED"] = spellMissed
combatevents["RANGE_MISSED"] = spellMissed
combatevents["SWING_DAMAGE"] = swingDamage
--------------------------------------------------------------------------------
-- Spell Casts
--------------------------------------------------------------------------------
local function castSent(unit, spellName, rank, dstName, lineID)
  if unit ~= "player" then return end

  -- local _, _, _, _, _, _, spellID = GetSpellInfo(spellName) -- Get spellID
  -- if not spellID then debug("Failed to find spell ID for " .. spellName .. ".") return end

  -- spell.timeSent = GetTime()

  if not CT.tracking then
    if IsHarmfulSpell(spellName) then
      CT.startTracking("Starting tracking from harmful spell cast.")
    elseif data and data.name ~= dstName then -- Make sure I didn't cast it on myself
      local dstUnitID

      -- Find unitID by name
      if dstName == UnitName("target") then
        dstUnitID = "target"
      elseif dstName == UnitName("focus") then
        dstUnitID = "focus"
      elseif dstName == UnitName("mouseover") then
        dstUnitID = "mouseover"
      else
        for i = 1, 5 do
          local unitID = "boss" .. i

          if dstName == UnitName(unitID) then
            dstUnitID = unitID
          end
        end
      end

      if dstUnitID then -- Found unitID, check reaction
        local reaction = UnitReaction("player", dstUnitID)

        if (reaction == 2 or reaction == 4) then -- Hostile or neutral, start tracking
          CT.startTracking("Starting tracking from cast with neutral or hostile NPC.")
        end
      end
    end
  end

  if CT.current then
    data.queued = true
    data.lastCast = spellName
    data.timeSent = GetTime()
    data.lastCastTime = GetTime()
  end
end

local function castStart(time, event, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school)
  if srcGUID ~= data.playerGUID then return end

  local spell = data.spells[spellID]
  if not spell then
    spell = addSpell(spellID, spellName, school)
  end

  data.casting = true
  data.queued = false

  local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spellID)

  spell.castStart = GetTime()
  spell.baseCastLength = round(castTime * (1 + (GetHaste() / 100)) / 1000, 1)
  spell.castLength = spell.baseCastLength / (1 + (GetHaste() / 100))

  spell.stopTime = spell.castStart + spell.castLength

  data.currentCastLength = spell.castLength
  data.currentCastStopTime = spell.stopTime
  data.currentCastDuration = 0
  data.currentCastSpellID = spellID -- Most recently cast spell
  data.currentCastName = name
  spell.remaining = 0

  do -- Handles creating and refreshing of uptime graph
    local setGraph = data.uptimeGraphs.misc["Activity"]

    if not setGraph then
      local flags = {
        ["spellName"] = false,
        ["color"] = false,
      }
      setGraph = data.addMisc("Activity", CT.colors.orange, flags)
      flags = nil
    end

    if setGraph then -- Don't merge with above, always needs to be checked
      local GUID = data.playerGUID

      if not setGraph[GUID] then
        setGraph.addNewLine(GUID, data.playerName)
      end

      local data = setGraph[GUID].data
      local num = #data + 1
      data[num] = spell.castStart - CT.combatStart

      local flags = setGraph.flags
      flags.spellName[num] = spellName
      flags.color[num] = CT.colors.blue

      setGraph:refresh()
    end
  end
end

local function castStop(unitID, spellName, rank, lineID, spellID)
  if unitID ~= "player" then return end
  if not data.casting then return end -- Sometimes castStart doesn't get called, and I don't want castStop running if it didn't

  local spell = data.spells[spellID]
  local finalCastDuration

  if ((data.currentCastDuration or 0) + 0.1) > (spell.castLength or 0) then
    finalCastDuration = (spell.castLength or 0)
  else
    C_Timer.After(0.1, function()
      if spell.castSuccess then
        error("Set " .. spellName .. " as failed, but it didn't.")
      end
    end)

    finalCastDuration = data.currentCastDuration

    spell.failedCasts = (spell.failedCasts or 0) + 1
    data.activity.failedCasts = (data.activity.failedCasts or 0) + 1
    data.activity.wastedTimeCasting = (data.activity.wastedTimeCasting or 0) + finalCastDuration
  end

  -- data.activity.hardCasts = (data.activity.hardCasts or 0) + 1

  data.activity.timeCasting = (data.activity.timeCasting or 0) + finalCastDuration
  data.activity.total = (data.activity.total or 0) + finalCastDuration

  if data.moving then -- TODO: Fix
    -- data.brokenBy.moving = (data.brokenBy.moving or 0) + 1
    -- spell.brokenByMoving = (spell.brokenByMoving or 0) + 1
  end

  do -- Handles creating and refreshing of uptime graph
    local setGraph = data.uptimeGraphs.misc["Activity"]

    if setGraph then
      local GUID = data.playerGUID

      if not setGraph[GUID] then
        setGraph.addNewLine(GUID, data.playerName)
      end

      local data = setGraph[GUID].data
      local num = #data + 1
      data[num] = GetTime() - CT.combatStart

      local flags = setGraph.flags

      if not spell.castSuccess then
        flags.color[num - 1] = CT.colors.red -- Cast failed, so make it red
        if setGraph[GUID].lines[num - 1] then
          setGraph[GUID].lines[num - 1]:SetVertexColor(1.00, 0.00, 0.00, 1.0)
        end
      end

      setGraph:refresh()
    end
  end

  spell.castSuccess = false
  data.casting = false
  data.currentCastDuration = 0
  spell.castStop = true
end

local function castSucceeded(unitID, spellName, rank, lineID, spellID)
  if unitID ~= "player" then return end
  local uptimeGraphs = CT.current.uptimeGraphs

  local spell = data.spells[spellID]
  if not spell then
    spell = addSpell(spellID, spellName)
  end

  if spell.ticker then
    debug(spellName, "still has a ticker!")
  end

  if CT.resetCasts[spellID] then -- Check if the cast spell causes any others to reset their CDs
    for i = 1, #CT.resetCasts[spellID] do
      local ID = CT.resetCasts[spellID][i]
      if not data.spells[ID] then data.spells[ID] = {} end
      data.spells[ID].reset = true
    end

    spell.resetCount = (spell.resetCount or 0) + 1
  end

  if IsSpellOverlayed(spellID) then
    spell.procCount = (spell.procCount or 0) + 1
  end

  spell.casts = (spell.casts or 0) + 1
  data.activity.totalCasts = (data.activity.totalCasts or 0) + 1

  if data.casting then -- It was a hard cast that finished
    spell.castStop = false
    spell.castSuccess = true
  else -- Not spell.castStop, so it should be instant
    local startGCD, GCD = GetSpellCooldown(61304)
    local start, duration = GetSpellCooldown(spellID)

    do -- Calculate the true GCD for accuracy
      local haste = GetHaste()
      local baseGCD = ceil((GCD * (1 + (haste / 100))) * 1000) / 1000
      local hasteGCD = baseGCD / (1 + (haste / 100))

      if hasteGCD + 0.05 > GCD and hasteGCD - 0.05 < GCD then -- Hopefully this will filter out any random GCDs that aren't effected by haste
        GCD = hasteGCD
      end
    end

    if (startGCD > 0) and (start > 0) then -- Make sure it's on the GCD
      data.GCD = GCD
      data.GCDStopTime = startGCD + GCD

      do -- Handles creating and refreshing of uptime graph
        local setGraph = data.uptimeGraphs.misc["Activity"]

        if not setGraph then
          local flags = {
            ["spellName"] = false,
            ["color"] = false,
          }
          setGraph = data.addMisc("Activity", CT.colors.orange, flags)
          flags = nil
        end

        if setGraph then -- Don't merge with above, always needs to be checked
          local GUID = data.playerGUID

          if not setGraph[GUID] then
            setGraph.addNewLine(GUID, data.playerName)
          end

          local data = setGraph[GUID].data
          local num = #data + 1
          data[num] = startGCD - CT.combatStart

          local flags = setGraph.flags
          flags.spellName[num] = spellName

          setGraph:refresh()
        end
      end

      if data.timerGCD then
        local percent = delayGCD * 100
        debug("GCD timer didn't finish! \nDelay was:", percent .. "%", "\nSpell Was:", spellName, "\nIncreasing delay to:", (percent + 2) .. "%")
        delayGCD = delayGCD + 0.02
      end

      local delay = GCD - (GCD * delayGCD) -- Reducing timer by 5%, may need to be more

      data.timerGCD = true
      C_Timer.After(delay, function()
        data.timerGCD = false
        data.activity.total = (data.activity.total or 0) + GCD

        do -- Handles creating and refreshing of uptime graph
          local setGraph = data.uptimeGraphs.misc["Activity"]

          if setGraph then
            local GUID = data.playerGUID

            if not setGraph[GUID] then
              setGraph.addNewLine(GUID, data.playerName)
            end

            local data = setGraph[GUID].data
            data[#data + 1] = (startGCD + GCD) - CT.combatStart

            setGraph:refresh()
          end
        end

        data.GCD = false
        data.currentGCDDuration = 0
        data.activity.totalGCD = (data.activity.totalGCD or 0) + GCD
        spell.totalGCD = (spell.totalGCD or 0) + GCD
      end)

      data.activity.totalGCDCasts = (data.activity.totalGCDCasts or 0) + 1
    else
      data.activity.totalNonGCDCasts = (data.activity.totalNonGCDCasts or 0) + 1
    end

    data.activity.instantCasts = (data.activity.instantCasts or 0) + 1
    data.queued = false
  end

  runCooldown(spell, spellID, spellName) -- Begins the spell's cooldown tracker

  do -- Scrapes the spell's resource data
    local cost, powerType, powerIndex = getSpellCost(spellID)

    if cost then
      local power = data.power[powerIndex]

      if powerIndex ~= 0 then
        cost = power.spent
        if cost < 0 then cost = -cost end
      end

      if not power.spellList[spell] then
        power.spellList[spell] = {}
        power.spellList[#power.spellList + 1] = spell
        spell.cost = cost
        spell.powerTable = power
      end

      spell.totalCost = (spell.totalCost or 0) + cost
      spell.averageCost = spell.totalCost / spell.casts

      power.totalCost = (power.totalCost or 0) + cost
      power.totalCastsCost = (power.totalCastsCost or 0) + 1
      power.averageCost = power.totalCost / power.totalCastsCost
      -- power.lastCast = spellName
      -- power.lastCost = cost

      -- local spellCost = power.spellCosts[spellID]
      -- spellCost.total = (spellCost.total or 0) + cost
      -- spellCost.casts = (spellCost.casts or 0) + 1
      -- spellCost.average = spellCost.total / spellCost.casts
      -- spellCost.name = spellName
      -- spellCost.cost = cost
      --
      -- spell.powerSpent.total = spellCost.total
      -- spell.powerSpent.average = spellCost.average
      -- spell.powerSpent.casts = spellCost.casts
      -- spell.powerSpent.cost = cost
      -- spell.powerSpent.powerName = powerType
    end
  end

  do -- Resources when cast
    local p = data.power
    local power = p["Energy"] or p["Focus"] or p["Mana"] or p["Demonic Fury"] or p["Runic Power"] or p["Rage"]
    if power and power.currentPower then
      spell.resourceTotal = (spell.resourceTotal or 0) + power.currentPower
      spell.resourceAverage = spell.resourceTotal / spell.casts
      -- debug(power.name, "when cast:", spellName, spell.resourceTotal, spell.resourceAverage)
    end

    local power = p["Combo Points"] or p["Chi"] or p["Runes"] or p["Soul Shards"] or p["Burning Embers"] or p["Holy Power"] or p["Shadow Orbs"]
    if power and power.currentPower then
      spell.secondaryResourceTotal = (spell.secondaryResourceTotal or 0) + power.currentPower
      spell.secondaryResourceAverage = spell.secondaryResourceTotal / spell.casts
      -- debug(power.name, "when cast:", spellName, spell.secondaryResourceTotal, spell.secondaryResourceAverage)
    end
  end

  data.lastCastTime = GetTime()
end

local function castInterrupt(time, event, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school, extraID, extraName, school2)
  if srcGUID ~= data.playerGUID then return end

  -- debug("INTERRUPTED")
  --
  -- local spell = data.spells[spellID]
  -- if not spell then
  --   spell = addSpell(spellID, spellName, school)
  -- end
end

local function castSuccess(time, event, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school)
  if srcGUID ~= data.playerGUID then return end
end

combatevents["UNIT_SPELLCAST_SENT"] = castSent
combatevents["SPELL_CAST_START"] = castStart
combatevents["UNIT_SPELLCAST_STOP"] = castStop
combatevents["UNIT_SPELLCAST_SUCCEEDED"] = castSucceeded
combatevents["SPELL_INTERRUPT"] = castInterrupt
combatevents["SPELL_CAST_SUCCESS"] = castSuccess
--------------------------------------------------------------------------------
-- Auras
--------------------------------------------------------------------------------
local function unitAura(unitID)
  local filter
  local index = 0

  if unitID ~= "player" then -- If it isn't player, specifically check for auras I applied
    if UnitCanAttack("player", unitID) then
      filter = "PLAYER|HARMFUL"
    else
      filter = "PLAYER|HELPFUL"
    end
  end

  while true do
    index = index + 1
    local spellName, rank, icon, count, dispelType, duration, expires, caster, stealable, consolidated, spellID, canApply, bossDebuff, v1, v2, v3 = UnitAura(unitID, index, filter)

    local aura = data.auras[spellID]

    if aura then
      if aura.refreshed then

        if aura.duration and duration >= aura.duration then
          aura.wastedRefresh = (aura.wastedRefresh or 0) + (aura.refreshed - (duration - aura.duration))
          aura.wastedRefreshAverage = aura.wastedRefresh / aura.refreshedCount
        end

        aura.refreshed = nil
      end

      aura.duration = (duration or 0)
      aura.stop = (expires or 0)
    end

    if not spellName then
      break
    end
  end
end

local function auraApplied(time, _, _, srcGUID, srcName, srcFlags, _, dstGUID, dstName, dstFlags, _, spellID, spellName, school, auraType, amount)
  if (srcName ~= data.playerName) and (dstName ~= data.playerName) then return end -- If it doesn't effect player then it shouldn't matter
  -- Actually, it will matter for dispellable debuffs

  local uptimeGraphs = CT.current.uptimeGraphs

  local aura = data.auras[spellID]
  if not aura then
    aura = addAura(spellID, spellName, auraType, nil, count)
  end

  local timer = (CT.combatStop or GetTime()) - CT.combatStart

  do -- Store basic aura data
    aura.school = school
    aura.totalCount = (aura.totalCount or 0) + 1
    aura.appliedCount = (aura.appliedCount or 0) + 1
    aura.source[aura.totalCount] = srcGUID
    aura.destination[aura.totalCount] = dstGUID
    aura.totalAmount = (aura.totalAmount or 0) + ((amount or 0) - (aura.currentAmount or 0))
    aura.currentAmount = (amount or 0)
    aura.currentStacks = 1
    aura.start = timer
    aura.applied = timer

    if amount and amount > (aura.maxAmount or 0) then
      aura.maxAmount = amount
    end

    local gap = (timer - (aura.removedTime or 0))
    aura.totalGap = (aura.totalGap or 0) + gap

    if gap > (aura.longestGap or 0) then
      aura.longestGap = gap
    end
  end

  do -- Cooldowns
    if CT.spells.defensives[spellID] then
      aura.defensive[aura.totalCount] = {}
      aura.defensive[aura.totalCount].start = GetTime()
      aura.defensive[aura.totalCount].percent = (aura.defensive.percent or 0)
    elseif CT.spells.offensives[spellID] then
      aura.offensive[aura.totalCount] = {}
      aura.offensive[aura.totalCount].start = GetTime()
      aura.offensive[aura.totalCount].percent = (aura.offensive.percent or 0)
    end
  end

  tinsert(CT.activeAuras, aura)

  do -- Handles creating and refreshing of uptime graph
    local type
    if auraType == "BUFF" then
      type = "buffs"
    elseif auraType == "DEBUFF" then
      type = "debuffs"
    end

    local setGraph = data.uptimeGraphs[type][spellID]

    if not setGraph then
      setGraph = data.addAura(spellID, spellName, type, count, color)
    end

    if setGraph then -- Don't merge with above, always needs to be checked
      if not setGraph[dstGUID] then
        setGraph.addNewLine(dstGUID, dstName)
      end

      local data = setGraph[dstGUID].data
      data[#data + 1] = timer

      setGraph:refresh()
    end
  end

  -- if BreakingThisOnPurpose and uptimeGraphs.buffs[spellID] or uptimeGraphs.debuffs[spellID] then -- Uptime graph
  --   local self = uptimeGraphs.buffs[spellID] or uptimeGraphs.debuffs[spellID]
  --   local num = #self.data + 1
  --   self.data[num] = timer
  --   self.unitName[num] = dstName
  --
  --   local targetData = self.targetData[dstGUID]
  --   if not targetData then
  --     self.targetData[dstGUID] = {}
  --     self.targetData[#self.targetData + 1] = self.targetData[dstGUID]
  --     targetData = self.targetData[dstGUID]
  --     targetData.data = {}
  --     targetData.lines = {}
  --     targetData.data[1] = 0
  --     targetData.name = dstName
  --     targetData.spellName = spellName
  --     targetData.spellID = spellID
  --     targetData.endNum = 1
  --     targetData.group = self.group
  --     targetData.checkButton = self.checkButton
  --     targetData.shown = self.shown
  --
  --     if self.shown then
  --       CT.toggleUptimeGraph(self, true)
  --     end
  --   end
  --
  --   targetData.data[#targetData.data + 1] = timer
  --
  --   if (amount or 0) > 1 then
  --     if self.stacks then
  --       self.stacks[num] = count
  --     end
  --   end
  --
  --   self:refresh(nil, nil, true)
  -- end

  if CT.resetAuras[spellID] then -- Check for reset CDs
    for i = 1, #CT.resetAuras[spellID] do
      local ID = CT.resetAuras[spellID][i]
      if not data.spells[ID] then data.spells[ID] = {} end
      data.spells[ID].reset = true

      data.spells[ID].resetCount = (data.spells[ID].resetCount or 0) + 1
    end
  end

  data.lastAuraTime = GetTime()
end

local function auraAppliedDose(time, _, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school, auraType, amount)
  if dstGUID ~= data.playerGUID then return end
  local uptimeGraphs = CT.current.uptimeGraphs

  local aura = data.auras[spellID]
  if not aura then
    aura = addAura(spellID, spellName, auraType, consolidated, count)
  end

  aura.totalCount = (aura.totalCount or 0) + 1
  aura.appliedDoseCount = (aura.appliedDoseCount or 0) + 1
  aura.source[aura.totalCount] = srcGUID
  aura.destination[aura.totalCount] = dstGUID
  aura.currentStacks = amount

  local timer = GetTime() - CT.combatStart
  if uptimeGraphs.buffs[spellID] or uptimeGraphs.debuffs[spellID] then -- Uptime graph
    local self = uptimeGraphs.buffs[spellID] or uptimeGraphs.debuffs[spellID]
    local num = #self.data + 2
    self.data[num - 1] = timer
    self.data[num] = timer
    self.unitName[num] = dstName

    if self.stacks and amount and amount > 1 then
      self.stacks[num] = amount
    end

    self:refresh(nil, nil, true)
  end
end

local function auraRefresh(time, _, _, srcGUID, srcName, srcFlags, _, dstGUID, dstName, dstFlags, _, spellID, spellName, school, auraType, amount)
  if (srcName ~= data.playerName) and (dstName ~= data.playerName) then return end

  local aura = data.auras[spellID]
  if not aura then
    aura = addAura(spellID, spellName, auraType, consolidated, count)
  end

  -- if not aura.duration then
  --   debug("No aura duration for refresh", spellName, GetTime())
  --   if aura.applied then
  --     debug("Aura was applied though", aura.applied)
  --   end
  -- end

  local timer = (CT.combatStop or GetTime()) - CT.combatStart

  local start = (aura.start or 0)
  local duration = timer - start
  local remaining = (aura.duration or 0) - (timer - start)

  aura.refreshed = remaining
  aura.totalUptime = (aura.totalUptime or 0) + duration

  do -- Basic aura data
    aura.school = school
    aura.totalCount = (aura.totalCount or 0) + 1
    aura.refreshedCount = (aura.refreshedCount or 0) + 1
    aura.source[aura.totalCount] = srcGUID
    aura.destination[aura.totalCount] = dstGUID
    aura.totalAmount = (aura.totalAmount or 0) + ((amount or 0) - (aura.currentAmount or 0))
    aura.currentAmount = (amount or 0)
    aura.currentStacks = 1
    aura.start = timer
    aura.timer = 0

    if amount and amount > (aura.maxAmount or 0) then
      aura.maxAmount = amount
    end
  end

  do -- Handles creating and refreshing of uptime graph
    local type
    if auraType == "BUFF" then
      type = "buffs"
    elseif auraType == "DEBUFF" then
      type = "debuffs"
    end

    local setGraph = data.uptimeGraphs[type][spellID]

    if not setGraph then
      setGraph = data.addAura(spellID, spellName, type, count, color)
    end

    if setGraph then -- Don't merge with above, always needs to be checked
      if not setGraph[dstGUID] then
        setGraph.addNewLine(dstGUID, dstName)
      end

      local data = setGraph[dstGUID].data
      data[#data + 1] = timer
      data[#data + 1] = timer + 0.00000001

      setGraph:refresh()
    end
  end

  -- if (count or 0) > 1 then -- TODO: This passed with hunter's TotH, when it refreshed at 3 stacks I think
  --   debug("WRONG! Refresh can have stacks", spellName, count)
  -- end

  if CT.spells.defensives[spellID] then
    aura.defensive[aura.totalCount] = {}
    aura.defensive[aura.totalCount].start = GetTime()
    aura.defensive[aura.totalCount].percent = (aura.defensive.percent or 0)
    if aura.defensive[aura.totalCount - 1] then aura.defensive[aura.totalCount - 1].stop = GetTime() end
  elseif CT.spells.offensives[spellID] then
    aura.offensive[aura.totalCount] = {}
    aura.offensive[aura.totalCount].start = GetTime()
    aura.offensive[aura.totalCount].percent = (aura.offensive.percent or 0)
    if aura.offensive[aura.totalCount - 1] then aura.offensive[aura.totalCount - 1].stop = GetTime() end
  end
end

local function auraRemoved(time, _, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school, auraType, amount)
  if (srcName ~= data.playerName) and (dstName ~= data.playerName) then return end
  -- if not ((dstGUID == data.playerGUID) or (srcGUID == data.playerGUID)) then return end
  local uptimeGraphs = CT.current.uptimeGraphs

  local timer = GetTime() - CT.combatStart

  local aura = data.auras[spellID]
  if not aura then -- NOTE: Allowing uptime graph to be created with removed may cause issues.
    aura = addAura(spellID, spellName, auraType, consolidated, count)
  end

  -- if not aura.duration then debug("No duration for removing", spellName, "on", dstName .. ".") return end

  local start = (aura.start or 0)
  local duration = timer - start
  local remaining = (aura.duration or 0) - (timer - start)

  if aura.start then
    aura.totalUptime = (aura.totalUptime or 0) + duration
  end

  aura.school = school
  aura.removedCount = (aura.removedCount or 0) + 1
  aura.removedAmount = (aura.removedAmount or 0) + (amount or 0)
  aura.currentAmount = 0
  aura.currentStacks = 0
  aura.expiredEarly = (aura.expiredEarly or 0) + remaining
  aura.removedTime = timer
  aura.start = false
  aura.timer = 0

  if CT.spells.defensives[spellID] and aura.defensive[aura.totalCount - 1] then
    aura.defensive[aura.totalCount - 1].stop = GetTime()
  elseif CT.spells.offensives[spellID] and aura.offensive[aura.totalCount - 1] then
    aura.offensive[aura.totalCount - 1].stop = GetTime()
  end

  do -- Uptime graph
    local type
    if auraType == "BUFF" then
      type = "buffs"
    elseif auraType == "DEBUFF" then
      type = "debuffs"
    end

    local setGraph = data.uptimeGraphs[type][spellID]

    if setGraph and setGraph[dstGUID] then
      local data = setGraph[dstGUID].data
      data[#data + 1] = timer

      setGraph:refresh()
    end
  end

  -- if uptimeGraphs.buffs[spellID] or uptimeGraphs.debuffs[spellID] then
  --   local self = uptimeGraphs.buffs[spellID] or uptimeGraphs.debuffs[spellID]
  --   self.data[#self.data + 1] = timer
  --
  --   if dstGUID and self.targetData[dstGUID] then
  --     self.targetData[dstGUID].data[#self.targetData[dstGUID].data + 1] = timer
  --   end
  --
  --   self:refresh()
  -- end
end

local function auraRemovedDose(time, _, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school, auraType, amount)
  if dstGUID ~= data.playerGUID then return end
  local uptimeGraphs = CT.current.uptimeGraphs

  -- local aura = data.auras[spellID]
  -- if not aura then
  --   aura = addAura(spellID, spellName, auraType, consolidated, count)
  -- end

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
      local type, percent = CT.getDefensiveBuff(spellName)
      aura.defensive.type = type
      aura.defensive.percent = percent
    elseif CT.spells.offensives[spellID] then
      aura.offensive = {}
    end
  end

  aura.school = school
  aura.currentStacks = amount
end

combatevents["UNIT_AURA"] = unitAura
combatevents["SPELL_AURA_APPLIED"] = auraApplied
combatevents["SPELL_AURA_APPLIED_DOSE"] = auraAppliedDose
combatevents["SPELL_AURA_REFRESH"] = auraRefresh
combatevents["SPELL_AURA_REMOVED"] = auraRemoved
combatevents["SPELL_AURA_REMOVED_DOSE"] = auraRemovedDose
--------------------------------------------------------------------------------
-- Unit Power, Unit Health, and Resources
--------------------------------------------------------------------------------
local function energize(time, event, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school, amount, powerType)
  if srcGUID ~= data.playerGUID then return end

  local spellID = data.currentCastSpellID or spellID
  local power = data.power[powerType]

  -- If it was a hard cast, spellName will be wrong. If it was instant, ID will be wrong. This check corrects it
  if data.casting then
    spellName = GetSpellInfo(spellID)
  else
    local _, _, _, _, _, _, ID = GetSpellInfo(spellName)
    if ID then spellID = ID end -- Sometimes this can return nil
  end

  local spell = data.spells[spellID]
  if not spell then
    spell = addSpell(spellID, spellName, school)
  end

  if (power.currentPower + amount) > power.maxPower then
    power.wasted = (power.wasted or 0) + ((power.currentPower + amount) - power.maxPower)
    spell.wastedPower = (spell.wastedPower or 0) + ((power.currentPower + amount) - power.maxPower)
  end

  power.amount = amount

  power.total = (power.total or 0) + amount
  spell.totalGain = (spell.totalGain or 0) + amount

  power.effective = power.total - (power.wasted or 0)
  spell.effectiveGain = spell.totalGain - (spell.wastedPower or 0)

  -- spellGained.casts = (spellGained.casts or 0) + 1
  -- spellGained.cost = amount
  -- spellGained.powerName = CT.powerTypesFormatted[powerType]
  -- spellGained.average = spellGained.total / spellGained.casts
end

local function unitPowerFrequent(unit, powerType)
  if unit ~= "player" then return end
  if not data then debug("Blocking unit power update.") return end

  local powerTypeIndex = CT.powerTypes["SPELL_POWER_" .. powerType]
  local power = data.power[powerTypeIndex]
  local currentTime = GetTime()
  local currentPower = UnitPower(unit, powerTypeIndex)
  local change = currentPower - power.accuratePower

  power.accuratePower = currentPower
  power.change = change

  do -- Time at power cap
    if not power.capped and power.accuratePower == power.maxPower then
      power.cappedTime = currentTime
      power.capped = true
      power.timesCapped = (power.timesCapped or 0) + 1
    elseif power.capped and power.accuratePower ~= power.maxPower then
      power.cappedTotal = (power.cappedTotal or 0) + (currentTime - (power.cappedTime or currentTime))
      power.cappedTime = currentTime
      power.capped = false
    end
  end

  if change > 0 then
    power.totalRegen = (power.totalRegen or 0) + change
  elseif change < 0 then
    power.spent = change
  end

  -- Blocks it from updating currentPower before Energize has fired, except mana
  if powerTypeIndex ~= 0 then
    if power.skip then
      power.skip = false
      return
    end

    power.skip = true
  end

  -- do -- Update graph
  --   local setGraph = CT.current.graphs[CT.powerTypesFormatted[powerTypeIndex]]
  --
  --   if setGraph then
  --     local timer = ((CT.displayedDB.stop or GetTime()) - CT.displayedDB.start) or 0
  --
  --     setGraph:update(timer)
  --   end
  -- end

  power.currentPower = currentPower
  power.oldPower = power.currentPower
end

local function unitPower(unit, powerType)
  local powerTypeIndex = CT.powerTypes["SPELL_POWER_" .. powerType]
  local power = data.power[powerTypeIndex]

  do -- Update graph
    local setGraph = CT.current.graphs[CT.powerTypesFormatted[powerTypeIndex]]

    if setGraph then
      local timer = ((CT.displayedDB.stop or GetTime()) - CT.displayedDB.start) or 0

      setGraph:update(timer)
    end
  end
end

local function unitPowerFrequentOLD(unit, powerType)
  if unit ~= "player" then return end

  local powerTypeIndex = CT.powerTypes["SPELL_POWER_" .. powerType]
  local power = data.power[powerTypeIndex]
  local currentTime = GetTime()
  local currentPower = UnitPower(unit, powerTypeIndex)
  local change = currentPower - power.accuratePower

  -- if power.oldPowerTime then
  --   local regen = GetPowerRegen()
  --   local timeSinceLastUpdate = currentTime - power.oldPowerTime
  --   local estimate = timeSinceLastUpdate * regen
  --
  --   if (estimate + 1) > change and (estimate - 1) < change then
  --     -- debug(estimate, change)
  --   end
  -- end

  -- C_Timer.After(0.5, function()
  --   if UnitPower(unit, powerTypeIndex) ~= power.accuratePower then
  --     debug("No match!", UnitPower(unit, powerTypeIndex), power.accuratePower)
  --   end
  -- end)

  do
    if 0 > change then
      power.amountDropped = change
      power.spent = change
      debug("Drop:", change, currentPower)
    end
  end

  power.accuratePower = currentPower
  power.change = power.accuratePower - power.oldPower

  do -- Time at power cap
    if not power.capped and power.accuratePower == power.maxPower then
      power.cappedTime = currentTime
      power.capped = true
      power.timesCapped = (power.timesCapped or 0) + 1
    elseif power.capped and power.accuratePower ~= power.maxPower then
      power.cappedTotal = (power.cappedTotal or 0) + (currentTime - (power.cappedTime or currentTime))
      power.cappedTime = currentTime
      power.capped = false
    end
  end

  if change >= 0 then
    power.naturalRegen = (power.naturalRegen or 0) + change
    -- debug(power.naturalRegen, power.spent)
  end

  power.oldPowerTime = currentTime

  -- Blocks it from updating currentPower before Energize has fired, except mana
  if powerTypeIndex ~= 0 then
    if power.skip then
      power.skip = false
      return
    end

    power.skip = true
  end

  power.prevChange = change
  power.currentPower = currentPower
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

combatevents["SPELL_ENERGIZE"] = energize
combatevents["UNIT_POWER_FREQUENT"] = unitPowerFrequent
-- combatevents["UNIT_POWER"] = unitPower
combatevents["UNIT_HEALTH_FREQUENT"] = unitHealthFrequent
combatevents["UNIT_MAXPOWER"] = unitMaxPower
combatevents["UNIT_MAXHEALTH"] = unitMaxHealth
--------------------------------------------------------------------------------
-- Player Movement
--------------------------------------------------------------------------------
local function startedMoving()
  data.moving = true
  data.moveStart = GetTime()
end

local function stoppedMoving()
  data.moving = false
  data.moveStart = data.moveStart or GetTime()
  data.movement = (data.movement or 0) + (GetTime() - data.moveStart) -- TODO: Got an error, data.moveStart was nil
end

combatevents["PLAYER_STARTED_MOVING"] = startedMoving
combatevents["PLAYER_STOPPED_MOVING"] = stoppedMoving
--------------------------------------------------------------------------------
-- Player Target and Focus
--------------------------------------------------------------------------------
local function targetChanged()
  if true then return debug("Blocking targetChanged") end
  if not CT.current then return end
  local uptimeGraphs = CT.current.uptimeGraphs
  local currentTime = GetTime()
  local name = GetUnitName("target", false) or "None"
  local GUID = UnitGUID("target")

  data.units.target = GUID

  data.target.current = name

  local target = data.target.targets[name]
  if not target then
    data.target.targets[name] = {}
    target = data.target.targets[name]
    target.name = name
  end

  local prevTarget = data.target.targets[data.target.prevTarget]
  if not prevTarget then
    data.target.targets[data.target.prevTarget] = {}
    prevTarget = data.target.targets[data.target.prevTarget]
    prevTarget.name = data.target.prevTarget
    prevTarget.timeGained = CT.combatStart
  end

  target.timeGained = currentTime
  prevTarget.timeLost = currentTime

  prevTarget.timeTotal = (prevTarget.timeTotal or 0) + (prevTarget.timeLost - prevTarget.timeGained)

  if CT.tracking and uptimeGraphs.misc["Target"] then
    local self = uptimeGraphs.misc["Target"]
    local num = #self.data + 1
    self.data[num] = currentTime - CT.combatStart
    self.unitName[num] = target.name

    self.data[num + 1] = currentTime - CT.combatStart
    self.unitName[num + 1] = target.name

    if self.colorPrimary and self.color == self.colorPrimary then
      self.color = self.colorSecondary
      self.colorChange[num + 1] = self.colorSecondary
    else
      self.color = self.colorPrimary
      self.colorChange[num + 1] = self.colorPrimary
    end

    self:refresh()
  end

  data.target.prevTarget = name
end

local function focusChanged()
  if not CT.current then return end
  local uptimeGraphs = CT.current.uptimeGraphs
  local currentTime = GetTime()
  local name = GetUnitName("focus", false) or "None"
  local GUID = UnitGUID("focus")

  data.units.focus = GUID

  data.focus.current = name

  local focus = data.focus.focused[name]
  if not focus then
    data.focus.focused[name] = {}
    focus = data.focus.focused[name]
    focus.name = name
  end

  local prevFocus = data.focus.focused[data.focus.prevFocus]
  if not prevFocus then
    data.focus.focused[data.focus.prevFocus] = {}
    prevFocus = data.focus.focused[data.focus.prevFocus]
    prevFocus.name = data.focus.prevFocus
    prevFocus.timeGained = CT.combatStart
  end

  focus.timeGained = currentTime
  prevFocus.timeLost = currentTime

  prevFocus.timeTotal = (prevFocus.timeTotal or 0) + (prevFocus.timeLost - prevFocus.timeGained)

  if CT.tracking and uptimeGraphs.misc["Focus Target"] then
    local self = uptimeGraphs.misc["Focus Target"]
    local num = #self.data + 1
    self.data[num] = currentTime - CT.combatStart
    self.unitName[num] = focus.name

    self.data[num + 1] = currentTime - CT.combatStart
    self.unitName[num + 1] = focus.name

    if self.colorPrimary and self.color == self.colorPrimary then
      self.color = self.colorSecondary
      self.colorChange[num + 1] = self.colorSecondary
    else
      self.color = self.colorPrimary
      self.colorChange[num + 1] = self.colorPrimary
    end

    self:refresh()
  end

  data.focus.prevFocus = name
end

local function mouseOverChanged()
  if not CT.current then return end
  -- local GUID = UnitGUID("mouseover")

  data.units.mouseover = GUID
end

combatevents["PLAYER_TARGET_CHANGED"] = targetChanged
combatevents["PLAYER_FOCUS_CHANGED"] = focusChanged
combatevents["UPDATE_MOUSEOVER_UNIT"] = mouseOverChanged
--------------------------------------------------------------------------------
-- Nameplates
--------------------------------------------------------------------------------
local function plateReaction(red, green, blue)
  if red < .01 then 	-- Friendly
    if blue < .01 and green > .99 then return "FRIENDLY", "NPC"
    elseif blue > .99 and green < .01 then return "FRIENDLY", "PLAYER"
    end
  elseif red > .99 then
    if blue < .01 and green > .99 then return "NEUTRAL", "NPC"
    elseif blue < .01 and green < .01 then return "HOSTILE", "NPC"
    end
  elseif red > .5 and red < .6 then
    if green > .5 and green < .6 and blue > .5 and blue < .6 then return "TAPPED", "NPC" end 	-- .533, .533, .99	-- Tapped Mob
  end
  return "HOSTILE", "PLAYER"
end

CT.plateNames = {}
function CT.plateShow(plate)
  local container = CT.plates[plate.ArtContainer]
  container.name = plate.NameContainer.NameText:GetText()
  container.reaction, container.type = plateReaction(plate.ArtContainer.HealthBar:GetStatusBarColor())
  local r, g, b = plate.NameContainer.NameText:GetTextColor()
  if r > 0.5 and g < 0.5 then container.combat = true end

  CT.plates.numShown = (CT.plates.numShown or 0) + 1
  -- debug(container.name, "is shown.", CT.plates.numShown)
end

function CT.plateHide(plate)
  local container = CT.plates[plate.ArtContainer]

  CT.plates.numShown = (CT.plates.numShown or 1) - 1
  -- debug(container.name, "is hidden.", CT.plates.numShown)
end

function CT.plateHealthUpdate(health, value)
  local container = CT.plates[health]
  local percent = value * 100
  local cTime = GetTime()

  if percent > 0 then
    if percent < 45 then
      if not container.executeStart45 then
        container.executeStart45 = cTime
      else
        container.executeTime45 = cTime - container.executeStart45
      end
    end

    if percent < 35 then
      if not container.executeStart35 then
        container.executeStart35 = cTime
      else
        container.executeTime35 = cTime - container.executeStart35
      end
    end

    if percent < 30 then
      if not container.executeStart30 then
        container.executeStart30 = cTime
      else
        container.executeTime30 = cTime - container.executeStart30
      end
    end

    if percent < 20 then
      if not container.executeStart20 then
        container.executeStart20 = cTime
      else
        container.executeTime20 = cTime - container.executeStart20
      end
    end
  else
    container.executeTime45 = cTime - container.executeStart45
    container.executeTime35 = cTime - container.executeStart35
    container.executeTime30 = cTime - container.executeStart30
    container.executeTime20 = cTime - container.executeStart20

    CT.plates.execute45 = (CT.plates.execute45 or 0) + (container.executeTime45 or 0)
    CT.plates.execute35 = (CT.plates.execute35 or 0) + (container.executeTime35 or 0)
    CT.plates.execute30 = (CT.plates.execute30 or 0) + (container.executeTime30 or 0)
    CT.plates.execute20 = (CT.plates.execute20 or 0) + (container.executeTime20 or 0)

    container.executeStart45 = false
    container.executeStart35 = false
    container.executeStart30 = false
    container.executeStart20 = false
  end

  -- debug(container.name, "can execute:", "\n45%", container.executeTime45, "\n35%", container.executeTime35, "\n30%", container.executeTime30, "\n20%", container.executeTime20)
  -- debug(container.name, "total time:", "\n45%", CT.plates.execute45, "\n35%", CT.plates.execute35, "\n30%", CT.plates.execute30, "\n20%", CT.plates.execute20)
end

function CT.plateCastBar(castBar, value)
  local container = CT.plates[castBar]

  if container.casting then
    local percent = value * 100
    -- debug(container.name, "casting:", percent)

    if percent == 0 then
      debug("Cast went to 0 while .casting was true", castBar:IsShown())
      container.casting = false
    end
  end
end

function CT.plateCastBarStart(castBar)
  local container = CT.plates[castBar]

  container.casting = true
  -- debug(container.name, "starting a cast.")
end

function CT.plateCastBarStop(castBar)
  local container = CT.plates[castBar]

  container.casting = false
  -- debug(container.name, "finished a cast.")
end
--------------------------------------------------------------------------------
-- Keybinds
--------------------------------------------------------------------------------
local activeMods = {}
local function keyDown(self, key) -- Fire whenever a key is pressed
  local k = self.binds[key]

  if not k then
    k = {}
    k.count = 0
    k.name = key
    k.action = GetBindingAction(key)
    k.action2 = GetBindingByKey(key)

    -- debug(key, k.action, k.action2)

    self.binds[key] = k
  end

  k.count = k.count + 1

  if key == "ESCAPE" and CT.shown then
    -- CT.base:Hide()
  end

	-- debug(key)
end

local modifiers = {
  ["LCTRL"] = "CTRL-",
  ["RCTRL"] = "CTRL-",
  ["LSHIFT"] = "SHIFT-",
  ["RSHIFT"] = "SHIFT-",
  ["LALT"] = "ALT-",
  ["RALT"] = "ALT-",
}

local function modKeys(key, num) -- NOTE: If the player alt tabs, alt gets added, but the release won't register, causing duplicates
  if num == 1 then -- Add it to active list
    activeMods[#activeMods + 1] = modifiers[key]
    -- debug("Adding", key)
  else -- Remove it
    for i = 1, #activeMods do
      if activeMods[i] == modifiers[key] then
        -- debug("Found mod to remove", key, i)
        tremove(activeMods, i)
      end
    end
  end

  -- debug("Modifier", key, bool)
end

CT.keys = CreateFrame("Frame")
CT.keys:SetScript("OnKeyDown", keyDown)
CT.keys:SetPropagateKeyboardInput(true)

CT.keys.binds = {}
combatevents["MODIFIER_STATE_CHANGED"] = modKeys
--------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------
local function spellSummon(time, event, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school)
  -- debug("Summoned", spellName)
end

combatevents["SPELL_SUMMON"] = spellSummon

function CT.iterateCooldowns()
  local uptimeGraphs = CT.current.uptimeGraphs
  local graphs = CT.current.graphs

  C_Timer.After(0.1, function()
    data.stance.num = GetShapeshiftForm()

    if data.stance.num > 0 then
      local icon, stanceName, active, castable = GetShapeshiftFormInfo(data.stance.num)
      local stanceName, _, _, _, _, _, stanceID = GetSpellInfo(stanceName)
      data.stance.name = stanceName
      data.stanceID = stanceID
      data.stanceSwitchTime = CT.combatStart

      if uptimeGraphs.misc["Stance"] then
        local self = uptimeGraphs.misc["Stance"]
        local num = #self.data + 1
        self.data[num] = data.stanceSwitchTime - CT.combatStart
        self.spellName[num] = stanceName

        if self.colorPrimary and self.color == self.colorPrimary then
          self.color = self.colorSecondary
          self.colorChange[num] = self.colorSecondary
        else
          self.color = self.colorPrimary
          self.colorChange[num] = self.colorPrimary
        end

        self:refresh()
      end
    end
  end)

  -- TODO: Add a second one of these for pets if player has a pet
  for i = 1, GetNumSpellTabs() do
    local name, _, startNum, numEntries, isGuild, offspecID = GetSpellTabInfo(i)

    if CT.player.specName == name then
      for i = startNum, (startNum + numEntries) do
        local spellName, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(i, "BOOKTYPE_SPELL")

        if spellID then
          local start, duration, enable = GetSpellCooldown(spellID)

          if duration > 0 then
            castSucceeded(nil, nil, nil, data.playerGUID, data.name, _, _, data.playerGUID, data.name, _, _, spellID, spellName, nil)
          end
        end
      end
      break
    end
  end
end

function CT.iterateAuras()
  local uptimeGraphs = CT.current.uptimeGraphs
  local graphs = CT.current.graphs

  for i = 1, 40 do -- Buffs
    local spellName, rank, icon, count, dispelType, duration, expires, caster, stealable, consolidated, spellID, canApply, bossDebuff, v1, v2, v3 = UnitBuff("player", i)

    if not spellName then break end

    local aura = data.auras[spellID]
    if not aura then
      aura = addAura(spellID, spellName, "BUFF", consolidated, count)
    end

    aura.totalCount = (aura.totalCount or 0) + 1
    aura.appliedCount = (aura.appliedCount or 0) + 1
    aura.source[aura.totalCount] = "Unknown"
    aura.destination[aura.totalCount] = data.playerGUID
    aura.totalAmount = (aura.totalAmount or 0) + ((amount or 0) - (aura.currentAmount or 0))
    aura.currentAmount = v1 and v2 and v3 -- Dunno exactly how this works
    aura.currentStacks = 1
    aura.rank = rank
    aura.icon = icon
    aura.count = count
    aura.dispelType = dispelType
    aura.stealable = stealable
    aura.consolidate = consolidated
    aura.canApply = canApply
    aura.bossDebuff = bossDebuff
    aura.duration = duration
    aura.stop = expires
    aura.start = 0

    tinsert(CT.activeAuras, aura)

    if not CT.uptimeBlacklist[spellID] then -- Handles creating and refreshing of uptime graph
      local setGraph = data.uptimeGraphs["buffs"][spellID]

      if not setGraph then
        setGraph = data.addAura(spellID, spellName, "buffs", count, CT.colors.blue)
      end

      if setGraph then -- Don't merge with above, always needs to be checked
        local dstGUID = data.playerGUID
        local dstName = data.playerName

        if not setGraph[dstGUID] then
          setGraph.addNewLine(dstGUID, dstName)
        end

        local data = setGraph[dstGUID].data
        data[#data + 1] = 0.000000001

        setGraph:refresh()
      end
    end
  end

  for i = 1, 40 do -- Debuffs
    local spellName, rank, icon, count, dispelType, duration, expires, caster, stealable, consolidated, spellID, canApply, bossDebuff, v1, v2, v3 = UnitDebuff("player", i)

    if not spellName then break end

    local aura = data.auras[spellID]
    if not aura then
      aura = addAura(spellID, spellName, "DEBUFF", consolidated, count)
    end

    aura.totalCount = (aura.totalCount or 0) + 1
    aura.appliedCount = (aura.appliedCount or 0) + 1
    aura.source[aura.totalCount] = "Unknown"
    aura.destination[aura.totalCount] = data.playerGUID
    aura.totalAmount = (aura.totalAmount or 0) + ((amount or 0) - (aura.currentAmount or 0))
    aura.currentAmount = v1 and v2 and v3 -- Dunno exactly how this works
    aura.currentStacks = 1
    aura.rank = rank
    aura.icon = icon
    aura.count = count
    aura.dispelType = dispelType
    aura.stealable = stealable
    aura.consolidate = consolidated
    aura.canApply = canApply
    aura.bossDebuff = bossDebuff
    aura.duration = duration
    aura.stop = expires
    aura.start = 0

    tinsert(CT.activeAuras, aura)

    if not CT.uptimeBlacklist[spellID] then -- Handles creating and refreshing of uptime graph
      local setGraph = data.uptimeGraphs["debuffs"][spellID]

      if not setGraph then
        setGraph = data.addAura(spellID, spellName, "debuffs", count, CT.colors.blue)
      end

      if setGraph then -- Don't merge with above, always needs to be checked
        local dstGUID = data.playerGUID
        local dstName = data.playerName

        if not setGraph[dstGUID] then
          setGraph.addNewLine(dstGUID, dstName)
        end

        local data = setGraph[dstGUID].data
        data[#data + 1] = 0.000000001

        setGraph:refresh()
      end
    end
  end
end

function CT.getPowerTypes()
  if true then return debug("Blocking old power update.") end
  if not CT.power then CT.power = {} end

  for i = 0, #CT.powerTypes do
    if UnitPowerMax("player", i) > 0 then
      CT.power[CT.powerTypesFormatted[i]] = i
      -- CT.power[#CT.power + 1] = {
      --   [1] = i,
      --   [2] = CT.powerTypesFormatted[i],
      -- }
    end
  end
end

function CT.updatePowerTypes()
  if true then return debug("Blocking old power update.") end
  if not CT.current then CT.getPowerTypes() return end -- No active set, get power types to make buttons instead
  if data.power[1] then wipe(data.power) end

  local count = 0
  for i = 0, #CT.powerTypes do
    if UnitPowerMax("player", i) > 0 then
      count = count + 1
      local powerName = CT.powerTypesFormatted[i]
      data.power[count] = {}
      data.power[powerName] = data.power[count] -- Create a reference like data.power["Mana"]
      local power = data.power[count]
      power.name = powerName
      power.num = i
      power.oldPower = UnitPower("player", i)
      power.currentPower = UnitPower("player", i)
      power.maxPower = UnitPowerMax("player", i)
      -- CT.graphList[#CT.graphList + 1] = powerName

      if CT.tracking then
        if not power.capped and power.currentPower == power.maxPower then
          power.cappedTime = GetTime()
          power.capped = true
        else
          power.cappedTotal = (power.cappedTotal or 0) + (GetTime() - (power.cappedTime or GetTime()))
          power.capped = false
        end
      end

      power.accuratePower = power.currentPower
      power.total = power.total or 0
      power.effective = power.effective or 0
      power.wasted = power.wasted or 0
      power.skip = true
      power.spells = {}
      power.spellCosts = {}
      power.spellList = {}
      power.spellList.numAdded = 0
      power.costFrames = {}

      if powerName == "Mana" then
        power.tColor = "|cFF0000FF"
      elseif powerName == "Rage" then
        power.tColor = "|cFFFF0000"
      elseif powerName == "Focus" then
        power.tColor = "|cFFFF8040"
      elseif powerName == "Energy" then
        power.tColor = "|cFFFFFF00"
      elseif powerName == "Combo Points" then
        power.tColor = "|cFFFFFFFF"
      elseif powerName == "Chi" then
        power.tColor = "|cFFB5FFEB"
      elseif powerName == "Runes" then
        power.tColor = "|cFF808080"
      elseif powerName == "Runic Power" then
        power.tColor = "|cFF00D1FF"
      elseif powerName == "Soul Shards" then
        power.tColor = "|cFF80528C"
      elseif powerName == "Eclipse" then
        power.tColor = "|cFF4D85E6"
      elseif powerName == "Holy Power" then
        power.tColor = "|cFFF2E699"
      elseif powerName == "Demonic Fury" then
        power.tColor = "|cFF80528C"
      elseif powerName == "Burning Embers" then
        power.tColor = "|cFFBF6B02"
      else
        debug("No text color found for " .. powerName .. ".")
      end

      data.power[i] = data.power[count]
    end
  end
end

function CT:wipeSavedVariables()
  for k, v in pairs(CT.setDB) do
    for k, v in pairs(v) do
      debug(k, v)

      if v.sets then
        wipe(v.sets)
      end
    end
  end

  collectgarbage("collect")
end

local wipeSVars = false

function CT.resetData(clicked)
  if clicked then
    debug("Resetting Data.")
  end

  CT.addNewSet()

  -- do -- Reset Activity Data
  --   data.activity.total = 0
  --   data.activity.instantCasts = 0
  --   data.activity.tempCast = 0
  --   data.activity.totalGCD = 0
  --   data.activity.hardCasts = 0
  --   data.activity.timeCasting = 0
  -- end
  --
  -- for i = 1, #data.spells do
  --   local spell = data.spells[i]
  --
  --   local spellID = spell.ID
  --   local spellName = spell.name
  --   local school = spell.school
  --   local schoolColor = spell.schoolColor
  --   local icon = spell.icon
  --
  --   wipe(spell)
  --
  --   spell.ID = spellID
  --   spell.name = spellName
  --   spell.school = school
  --   spell.schoolColor = schoolColor
  --   spell.icon = icon
  -- end
  --
  -- wipe(data.auras)
  -- wipe(data.healing)
  -- wipe(data.damage)

  -- local uptimeGraphs = CT.current.
  -- if uptimeGraphs.shownList then -- Restore all previously shown uptime graphs
  --   for i = 1, #uptimeGraphs.shownList do
  --     CT.toggleUptimeGraph(uptimeGraphs.shownList[i])
  --   end
  --
  --   wipe(uptimeGraphs.shownList)
  -- end

  CT.combatStart = GetTime()

  -- CT.forceUpdate = true
end

function CT.cleanSetsTable()
  -- CT.sets

  -- if not CT.sets.pet.damage[1] then CT.sets.pet = nil end
end

-- local COMBATLOG_FILTER_EVERYTHING -- Any entity
-- local COMBATLOG_FILTER_FRIENDLY_UNITS -- Entity is a friendly unit
-- local COMBATLOG_FILTER_HOSTILE_PLAYERS -- Entity is a hostile player unit
-- local COMBATLOG_FILTER_HOSTILE_UNITS -- Entity is a hostile non-player unit
-- local COMBATLOG_FILTER_ME -- Entity is the player
-- local COMBATLOG_FILTER_MINE -- Entity is a non-unit object belonging to the player; e.g. a totem
-- local COMBATLOG_FILTER_MY_PET -- Entity is the players pet
-- local COMBATLOG_FILTER_NEUTRAL_UNITS -- Entity is a neutral unit
-- local COMBATLOG_FILTER_UNKNOWN_UNITS -- Entity is a unit currently unknown to the WoW client

-- local object = CombatLog_Object_IsA

-- CT:addEvent("COMBAT_RATING_UPDATE", updateStats, {src_is_interesting = true, dst_is_not_interesting = true})

-- CT:addEvent("PLAYER_TARGET_CHANGED", miscUpdates, {src_is_interesting = true, dst_is_not_interesting = true})

-- CT:addEvent("UNIT_SPELLCAST_FAILED", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})
-- CT:addEvent("UNIT_SPELLCAST_INTERRUPTED", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})
-- CT:addEvent("UNIT_SPELLCAST_SUCCEEDED", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})
-- CT:addEvent("UNIT_SPELLCAST_DELAYED", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})
-- CT:addEvent("UNIT_SPELLCAST_FAILED_QUIET", unitSpellCast, {src_is_interesting = true, dst_is_not_interesting = true})

-- local shownLineGraphNames = {}
--
-- for i = 1, #CT.graphs do
--   local g = CT.graphs[i]
--
--   if g.data then
--     if g.shown then
--       shownLineGraphNames[#shownLineGraphNames + 1] = g.name
--       CT.graphs.hideLineGraphs(g)
--     end
--
--     g.XMax = g.startX or 10
--     g.YMax = g.startY or 100
--     g.endNum = 4
--     g.splitCount = 0
--
--     wipe(g.lines)
--     wipe(g.data)
--   end
-- end

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

-- for i = 1, #data.spells do
--   local s = data.spells[i]
--
--   -- Reset basic spell stuff
--   if s.onCD then s.onCD = false end
--   if s.charges then s.charges = false end
--   if s.casts then s.casts = 0 end
--   if s.totalCD then s.totalCD = 0 end
--   if s.CD then s.CD = 0 end
--   if s.delay then s.delay = 0 end
--   if s.totalGCD then s.totalGCD = 0 end
--   if s.remaining then s.remaining = 0 end
--   if s.failedCasts then s.failedCasts = 0 end
--   if s.brokenByMoving then s.brokenByMoving = 0 end
--   if s.resetCount then s.resetCount = 0 end
--   if s.procCount then s.procCount = 0 end
--
--   -- Reset all healing stuff
--   if s.totalHealing then s.totalHealing = 0 end
--   if s.overhealing then s.overhealing = 0 end
--   if s.effectiveHealing then s.effectiveHealing = 0 end
--   if s.absorbHeal then s.absorbHeal = 0 end
--   if s.critHeal then s.critHeal = 0 end
--   if s.MSHeal then s.MSHeal = 0 end
--
--   -- Reset all damage stuff
--   if s.totalDamage then s.totalDamage = 0 end
--   if s.overkill then s.overkill = 0 end
--   if s.effectiveDamage then s.effectiveDamage = 0 end
--   if s.resist then s.resist = 0 end
--   if s.block then s.block = 0 end
--   if s.glance then s.glance = 0 end
--   if s.crush then s.crush = 0 end
--   if s.offHand then s.offHand = 0 end
--   if s.absorbDamage then s.absorbDamage = 0 end
--   if s.critDamage then s.critDamage = 0 end
--   if s.MSDamage then s.MSDamage = 0 end
--
--   if s.ticker then s.ticker:Cancel() s.ticker = nil end
-- end

-- local tooltip = CreateFrame("GameTooltip", "ExampleTooltipScanner", UIParent, "GameTooltipTemplate")
--
-- local tooltipMethods = getmetatable(tooltip).__index
-- tooltip = setmetatable(tooltip, {__index = function(self, id)
--     local method = tooltipMethods[id] -- See if this key is a tooltip method
--     if method then return method end -- If it is, return the method now
--
--     -- Otherwise look up a unit
--     self:SetOwner(UIParent, "ANCHOR_NONE")
--     self:SetHyperlink(("unit:0xF53%05X00000000"):format(id))
--     local name
--     if self:IsShown() then
--       for i = 1, self:NumLines() do
--         local text = _G[self:GetName() .. "TextLeft" .. i]
--         if text and text.GetText then
--           name = text:GetText()
--           break
--         end
--       end
--     end
--     self:Hide()
--     self[id] = name
--     return name
--   end})

-- local filters = {
-- 	[COMBATLOG_FILTER_EVERYTHING] = "Any",
-- 	[COMBATLOG_FILTER_FRIENDLY_UNITS] = "Friendly",
-- 	[COMBATLOG_FILTER_HOSTILE_PLAYERS] = "Hostile player",
-- 	[COMBATLOG_FILTER_HOSTILE_UNITS] = "Hostile",
-- 	[COMBATLOG_FILTER_NEUTRAL_UNITS] = "Neutral",
-- 	[COMBATLOG_FILTER_ME] = "Myself",
-- 	[COMBATLOG_FILTER_MINE] = "Mine",
-- 	[COMBATLOG_FILTER_MY_PET] = "My pet",
--   [COMBATLOG_FILTER_UNKNOWN_UNITS] = "Unknown",
-- }

-- local band = bit.band
-- local PET_FLAGS = bit.bor(COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN)
-- local RAID_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)

-- local src = band(srcFlags, RAID_FLAGS) ~= 0 or (band(srcFlags, PET_FLAGS) ~= 0 and data.groupPets[srcGUID]) or data.group[srcGUID]
-- local dst = band(dstFlags, RAID_FLAGS) ~= 0 or (band(dstFlags, PET_FLAGS) ~= 0 and data.groupPets[dstGUID]) or data.group[dstGUID]
--
-- debug(src, dst)
--
-- for k, v in pairs(filters) do
--   if CombatLog_Object_IsA(dstFlags, k) then
--     debug(k, val, v)
--   end
-- end

-- do -- Reset uptime graphs
--   local shownUptimeGraph
--   for index, v in ipairs(uptimeGraphs.categories) do
--     for i = 1, #v do
--       local g = v[i]
--
--       if g.data then
--         if g.shown then
--           shownUptimeGraph = g
--           CT.toggleUptimeGraph(g)
--         end
--
--         wipe(g.lines)
--         wipe(g.data)
--
--         g.XMax = 10
--         g.YMax = 10
--         g.endNum = 1
--         g.data[1] = 0
--       end
--     end
--   end
--
--   if shownUptimeGraph then
--     CT.toggleUptimeGraph(shownUptimeGraph, refresh)
--   end
-- end

-- spell.ticker = C_Timer.NewTicker(0.001, function(ticker)
--   local currentTime = GetTime()
--   spell.remaining = endCD - currentTime
--   spell.CD = duration - spell.remaining
--
--   -- local oneTick = currentTime - CT.currentTime -- TODO: Add this into the system for breaking early/delaying
--
--   if spell.reset or (spell.remaining <= CT.settings.spellCooldownThrottle) then -- CD should be done, calculate the true CD and stop the ticker
--     if baseCD == duration then
--       cooldown = baseCD
--     elseif baseCD > duration then
--       local hasteCD = baseCD / (1 + (GetHaste() / 100)) -- TODO: Also calculate hasted GCD and compare
--       local hasteRounded = round(hasteCD, 3)
--
--       if hasteRounded == duration then
--         cooldown = hasteCD
--       else
--         cooldown = duration
--       end
--     end
--
--     if spell.reset then
--       debug("Reset", spellName)
--       spell.reset = false
--     else -- Adjusts the throttle, making it more or less likely to delay a tick
--       data.timeOffset = (data.timeOffset or 0) + spell.remaining
--
--       if data.timeOffset > 0 then
--         CT.settings.spellCooldownThrottle = CT.settings.spellCooldownThrottle - (data.timeOffset / 100)
--       elseif data.timeOffset < 0 then
--         CT.settings.spellCooldownThrottle = CT.settings.spellCooldownThrottle - (data.timeOffset / 100)
--       end
--     end
--
--     spell.totalCD = (spell.totalCD or 0) + cooldown
--
--     ticker:Cancel()
--     spell.onCD = false
--     spell.CD = 0
--     spell.finishedTime = GetTime()
--     spell.charges = false
--
--     if uptimeGraphs.cooldowns[spellID] and not uptimeGraphs.cooldowns[spellID].ignore then
--       local self = uptimeGraphs.cooldowns[spellID]
--       self.data[#self.data + 1] = spell.finishedTime - CT.combatStart
--       self:refresh()
--     elseif uptimeGraphs.cooldowns[spellID].ignore then
--       uptimeGraphs.cooldowns[spellID].ignore = false
--     end
--
--     if spell.queued then
--       spell.queued = false
--       runCooldown(spell, spellID)
--     end
--   end
-- end)

-- local tempSpellID
-- local tempSpellTable
-- local returnValue
-- local function spellCD()
--   local _, duration = GetSpellCooldown(tempSpellID)
--   debug("Delayed:", tempSpellTable.name, duration)
--   returnValue = duration
-- end

-- local value = C_Timer.After(0.001, spellCD)
-- tempSpellID = spellID
-- tempSpellTable = spell
--
-- do
--   local _, duration = GetSpellCooldown(spellID)
--   debug("Instant:", spell.name, duration)
-- end

-- local function castSuccess(time, event, _, srcGUID, srcName, _, _, dstGUID, dstName, _, _, spellID, spellName, school)
--   if srcGUID ~= data.playerGUID then return end
--
--   local spell = data.spells[spellID]
--   if not spell or not spell.schoolColor then
--     spell = addSpell(spellID, spellName, school)
--   end
--
--   -- Check if the cast spell causes any others to reset their CDs
--   if CT.resetCasts[spellID] then
--     for i = 1, #CT.resetCasts[spellID] do
--       local ID = CT.resetCasts[spellID][i]
--       if not data.spells[ID] then data.spells[ID] = {} end
--       data.spells[ID].reset = true
--     end
--
--     spell.resetCount = (spell.resetCount or 0) + 1
--   end
--
--   if not CT.tracking and IsHarmfulSpell(spellName) then
--     CT.startTracking()
--   end
--
--   if IsSpellOverlayed(spellID) then
--     spell.procCount = (spell.procCount or 0) + 1
--   end
--
--   data.activity.totalCasts = (data.activity.totalCasts or 0) + 1
--
--   if spell.castStop then -- It was a hard cast that finished
--     spell.castStop = false
--     spell.castSuccess = true
--   else -- Not spell.castStop, so it should be instant
--     local startGCD, GCD = GetSpellCooldown(61304)
--     local start, duration = GetSpellCooldown(spellID)
--
--     do -- Calculate the true GCD for accuracy
--       local haste = GetHaste()
--       local baseGCD = ceil((GCD * (1 + (haste / 100))) * 1000) / 1000
--       local hasteGCD = baseGCD / (1 + (haste / 100))
--
--       if hasteGCD + 0.05 > GCD and hasteGCD - 0.05 < GCD then -- Hopefully this will filter out any random GCDs that aren't effected by haste
--         GCD = hasteGCD
--       end
--     end
--
--     if (startGCD > 0) and (start > 0) then -- Make sure it's on the GCD
--       data.GCD = GCD
--       data.GCDStopTime = startGCD + GCD
--
--       if uptimeGraphs.cooldowns["Activity"] then
--         local self = uptimeGraphs.cooldowns["Activity"]
--         local num = #self.data + 1
--         self.data[num] = startGCD - CT.combatStart
--         self.spellName[num] = spellName
--         self:refresh()
--       end
--
--       if data.timerGCD then
--         debug("GCD timer didn't finish!", spellName)
--       end
--
--       data.timerGCD = true
--       C_Timer.After((GCD - 0.03), function() -- Reducing the GCD, otherwise it's likely that a new one will start before this finishes
--         data.timerGCD = false
--         data.activity.total = (data.activity.total or 0) + GCD
--
--         if uptimeGraphs.cooldowns["Activity"] then
--           local self = uptimeGraphs.cooldowns["Activity"]
--           local num = #self.data + 1
--           self.data[num] = (startGCD + GCD) - CT.combatStart
--           self:refresh()
--         end
--
--         data.GCD = false
--         data.currentGCDDuration = 0
--         data.activity.totalGCD = (data.activity.totalGCD or 0) + GCD
--         spell.totalGCD = (spell.totalGCD or 0) + GCD
--       end)
--
--       spell.casts = (spell.casts or 0) + 1
--       data.activity.totalGCDCasts = (data.activity.totalGCDCasts or 0) + 1
--     else
--       data.activity.totalNonGCDCasts = (data.activity.totalNonGCDCasts or 0) + 1
--     end
--
--     local power = data.power["Energy"] or data.power["Focus"]
--     if power and power.currentPower then
--       spell.resourceAverage = (spell.resourceAverage or 0) + power.currentPower
--       -- debug(power.name, "when cast:", spellName, power.currentPower)
--     end
--
--     data.activity.instantCasts = (data.activity.instantCasts or 0) + 1
--     data.queued = false
--   end
--
--   runCooldown(spell, spellID, spellName) -- Begins the spell's cooldown tracker
--
--   do -- Scrapes the spell's resource data
--     local cost, powerType, powerIndex = getSpellCost(spellID)
--
--     if cost then
--       local power = data.power[powerIndex]
--
--       if not power.spellCosts[spellID] then
--         power.spellCosts[spellID] = {}
--         power.addCostLine = true
--         power.numSpellsCost = (power.numSpellsCost or 1) + 1
--         spell.powerSpent = {}
--
--         CT.forceUpdate = true
--       end
--
--       if powerIndex ~= 0 then
--         if 0 > power.change then -- Make sure power.change is positive
--           cost = -power.change
--         else
--           cost = power.change
--         end
--       end
--
--       power.totalCost = (power.totalCost or 0) + cost
--       power.totalCastsCost = (power.totalCastsCost or 0) + 1
--       power.averageCost = power.totalCost / power.totalCastsCost
--       power.lastCast = spellName
--       power.lastCost = cost
--
--       local spellCost = power.spellCosts[spellID]
--       spellCost.total = (spellCost.total or 0) + cost
--       spellCost.casts = (spellCost.casts or 0) + 1
--       spellCost.average = spellCost.total / spellCost.casts
--       spellCost.name = spellName
--       spellCost.cost = cost
--
--       spell.powerSpent.total = spellCost.total
--       spell.powerSpent.average = spellCost.average
--       spell.powerSpent.casts = spellCost.casts
--       spell.powerSpent.cost = cost
--       spell.powerSpent.powerName = powerType
--     end
--   end
--
--   data.lastCastTime = GetTime()
-- end
