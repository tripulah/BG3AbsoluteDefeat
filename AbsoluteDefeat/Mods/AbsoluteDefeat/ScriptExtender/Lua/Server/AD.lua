AD = {}

AD.Scenarios = {} -- scenarios in the random selection list
AD.SituationalScenarios = {} -- scenarios that are not included in the random selection
AD.ActiveScenario = "AbsoluteDefeatActiveScenario" -- varfixedstring attached to an object, used for determining next defeat scenario to play.


function GetActiveDefeatScenarioIdFromCombat(combatguid)
    local combatants = DBUtils.GetCombatants(combatguid)
    local scenarioId = GetActiveDefeatScenarioIdFromObject(combatants[1])
    for _, combatant in pairs(combatants) do
        if scenarioId ~= GetActiveDefeatScenarioIdFromObject(combatant) then
            Utils.Warn("Combatants in combat " .. combatguid .. " have a different defeat scenario set up.")
        end
    end
    return scenarioId
end

function GetActiveDefeatScenarioIdFromObject(object)
    local scenarioId = Osi.GetVarFixedString(object, AD.ActiveScenario)

    if not Utils.NilOrEmpty(scenarioId) and (not Utils.NilOrEmpty(AD.Scenarios[scenarioId]) or not Utils.NilOrEmpty(AD.SituationalScenarios[scenarioId])) then
        --Utils.Debug("OBJECT " .. object .. " has an active scenario: " .. scenarioId)
        return scenarioId
    end
end

function SetActiveDefeatScenarioIdByCombat(combatguid, scenarioid)
    local combatants = DBUtils.GetCombatants(combatguid)
    for _, combatant in pairs(combatants) do
        SetActiveDefeatScenarioIdByObject(scenarioid, combatant)
    end
end

function SetActiveDefeatScenarioIdByObject(scenarioid, object)
    if AD.Scenarios[scenarioid] ~= nil then
        if not Utils.NilOrEmpty(Osi.GetVarFixedString(object, AD.ActiveScenario)) then
            Utils.Warn("Overriding existing activedefeat scenario on object: " .. object .. " old: " .. Osi.GetVarFixedString(object, AD.ActiveScenario))
        end
        Utils.Debug("Set AbolsuteDefeatScenario var to: " .. scenarioid .. " on object: " .. object)
        Osi.SetVarFixedString(object, AD.ActiveScenario, scenarioid)
    elseif AD.SituationalScenarios[scenarioid] ~= nil then
        Utils.Debug("Set AbolsuteDefeatScenario var to: " .. scenarioid .. " on object: " .. object)
        Osi.SetVarFixedString(object, AD.ActiveScenario, scenarioid)
    else
        Utils.Warn("ScenarioID of " .. scenarioid .. " was not found in ADScenarios list, but it might have not loaded yet, so set the varfixedstring anyway")
        Osi.SetVarFixedString(object, AD.ActiveScenario, scenarioid)
    end
end

function ChooseRandomScenario()
    local totalWeight = 0
    for _, scenario in pairs(AD.Scenarios) do
        Utils.PrintTable(scenario)
        totalWeight = totalWeight + scenario.Weight
    end

    if totalWeight == 0 then
        Utils.Debug("No available scenarios to select from")
        return
    end

    -- Selecting random defeat scenario (weighted)
    local rand = math.random(totalWeight)
    local chosenScenario = nil
    local sumWeights = 0
    for _,scenario in pairs(AD.Scenarios) do
        sumWeights = sumWeights + scenario.Weight
        if sumWeights >= rand then
            chosenScenario = scenario.Id
            break
        end
    end
    if chosenScenario ~= nil then
        Utils.Debug("SCENARIO CHOSEN: " .. chosenScenario)
    else
        Utils.Error("Could not choose a scenario.")
    end
    return chosenScenario
end

function IsCriminalCombat(combatguid)
    Utils.Debug("CHECKING IF CRIMINAL COMBAT" .. combatguid)
    local criminalcombats = DBUtils.GetCriminalCombats()
    Utils.PrintTable(Osi.DB_Crime_CombatID:Get(nil, nil))
    if criminalcombats then
        for index, combat in ipairs(criminalcombats) do
            if combat == combatguid then
                return true
            end
        end
    end
    Utils.Debug("NOT A CRIMINAL COMBAT.")
    return false
end

function IsInPrison(playerguid)
    if Osi.GetFlag("IsInPrison_c9b75b21-6eba-065e-7680-fc9a0c5838e4", playerguid) == 1 then
        return true
    else
        return false
    end
end

function IsPartyInCombat()
    local partyMembers = DBUtils.GetPartyMembers()
    for i, member in ipairs(partyMembers) do
        if Osi.CombatGetGuidFor(member) ~= nil then
            return true
        end
    end
    return false
end

function IsTargetAnEnemy(guid)
    local partyMembers = DBUtils.GetPartyMembers()
    for _, partyMemberGuid in ipairs(partyMembers) do
        if Osi.IsEnemy(guid, partyMemberGuid) == 1 then
            --Utils.Debug("IS ENEMY " .. partyMemberGuid .. " " .. guid)
            return true
        end
    end
    return false
end

function IsTargetANeutral(guid)
    local partyMembers = DBUtils.GetPartyMembers()
    for _, partyMemberGuid in ipairs(partyMembers) do
        if Osi.IsNeutral(guid, partyMemberGuid) == 1 then
            --Utils.Debug("IS NEUTRAL " .. partyMemberGuid .. " " .. guid)
            return true
        end
    end
    return false
end

function IsTargetAnAlly(guid)
    local partyMembers = DBUtils.GetPartyMembers()
    for _, partyMemberGuid in ipairs(partyMembers) do
        if Osi.IsAlly(guid, partyMemberGuid) == 1 then
            --Utils.Debug("IS ALLY " .. partyMemberGuid .. " " .. guid)
            return true
        end
    end
    return false
end

function IsPartyMember(guid)
    local partymembers = DBUtils.GetPartyMembers()
    if partymembers ~= nil then
        for i, member in ipairs(partymembers) do
            if member == guid then
                return true
            end
        end
    end
    return false
end

function CheckIfExcluded(guid)
    for _, v in ipairs(ExcludedCharacters) do
        if v == guid then
            return 1
        end
    end
    return 0
end

-- party who has participated in combat is currently defeated (incl. dead)
function IsPartyDefeated(combatGuid)
    local defeatedPartyMembers = DBUtils.GetDefeatedParty(combatGuid)

    local allPartyMembers = DBUtils.GetPartyCombatants(combatGuid)

    local notDefeatedPartyMembers = Utils.GetTableDifference(allPartyMembers, defeatedPartyMembers)
    return #notDefeatedPartyMembers == 0
end

-- party currently fighting is defeated (not incl. fleed + defeated people (OOC))
function IsActivePartyDefeated(combatGuid)
    --Utils.Debug("Let's check if currently active combatants are in a defeated state:")
    local defeatedPartyMembers = DBUtils.GetDefeatedParty(combatGuid)
    if #defeatedPartyMembers == 0 then
        return false
    end
    -- dont end the fight if summons are included
    local fightingPartyMembers
    if Utils.MCMGet("include_summons") then
        fightingPartyMembers = DBUtils.GetActivePartyCombatants(combatGuid)
    else
        fightingPartyMembers = DBUtils.GetActiveOriginCombatants(combatGuid)
    end
    local undefeatedFightingPartyMembers = Utils.GetTableDifference(fightingPartyMembers, defeatedPartyMembers)

    local defeatedFightingPartyMembers = Utils.GetTableIntersection(fightingPartyMembers, defeatedPartyMembers)
    --Utils.PrintTable(defeatedFightingPartyMembers)
    local thebool = #undefeatedFightingPartyMembers == 0
    --print("IsActivePartyDefeated?: ", thebool)
    return thebool
end

function InitDefeatOnParty(combatguid)
    if Osi.IsNarrativeCombat(combatguid) == 1 then
        Utils.Debug(combatguid .. " is a NarrativeCombat, aborting defeat scenario.")
        return
    end
    local alivePartyMembers = DBUtils.GetDefeatedActiveParty(combatguid)
    if not Utils.MCMGet("include_summons") then

        Utils.Debug("Killing participating party summons.")
        local partySummons = DBUtils.GetPartySummonsInCombat()
        for _, partySummon in ipairs(partySummons) do
            Osi.Die(partySummon)
        end
    end

    Utils.Debug('APPLYING DEFEAT TO THESE DEFEATED PLAYERS')
    Utils.PrintTable(alivePartyMembers)
    -- take party out of combat
    for _, alivePartyMember in ipairs(alivePartyMembers) do
        Osi.ApplyStatus(alivePartyMember, "AD_DEFEATED", -1)
    end
end

function ClearActiveDefeatScenariosByObject(object)
    local scenarioid = GetActiveDefeatScenarioIdFromObject(object)
    if not Utils.NilOrEmpty(scenarioid) then
        Utils.Debug(object .. " has var ActiveDefeatScenario: [" .. scenarioid .. "]. CLEARING!")
        Osi.SetVarFixedString(object, AD.ActiveScenario, "")
    end
end

function ClearAllActiveDefeatScenariosByCombat(combatguid)
    local participated = DBUtils.GetCombatants(combatguid)
    for _, participant in pairs(participated) do
        ClearActiveDefeatScenariosByObject(participant)
    end
end

function AD.CleanUpDefeat(combatguid)
    local participated = DBUtils.GetCombatants(combatguid)
    for _, participant in pairs(participated) do
        ClearActiveDefeatScenariosByObject(participant)
        Osi.RemoveStatus(participant, "AD_DEFEATED")
        Osi.RemoveStatus(participant, "DOWNED")
    end
end

function AD.OverrideDefeatScenarioForCombat(combatguid, overrideScenarioId)
    SetActiveDefeatScenarioIdByCombat(combatguid, overrideScenarioId)
end

function StartDefeatScenario(combatguid)
    local overrideScenarioId = GetActiveDefeatScenarioIdFromCombat(combatguid)
    if Waypoints[Utils.GetCurrentLevel()] == nil and Utils.NilOrEmpty(overrideScenarioId) then
        Utils.Debug("LEVEL " .. Utils.GetCurrentLevel() .. " IS NOT SUPPORTED, ABORTING DEFEAT.")
        return
    end
    
    local defeatedparty = DBUtils.GetPartyInADDefeatStatus(combatguid)
    Utils.Debug("LOSERS: ")
    Utils.PrintTable(defeatedparty)
    Utils.Debug("Removing imprisoned party from consideration.")
    local imprisoned = {}
    for _,p in pairs(defeatedparty) do
        if IsInPrison(p) then
            table.insert(imprisoned, p)
        end
    end
    -- get defeated partymembers that have not already teleported to prison
    local defeatedNotImprisonedParty = Utils.GetTableDifference(defeatedparty, imprisoned)
    -- get victors
    local survivors = DBUtils.GetPostCombatLiving(combatguid)
    Utils.Debug("SURVIVORS: ")
    Utils.PrintTable(survivors)
    Utils.Debug("PRISONERS: ")
    Utils.PrintTable(imprisoned)
    Utils.Debug("Remain: ")
    Utils.PrintTable(defeatedNotImprisonedParty)
    -- victors are enemies
    local enemies = {}
    local neutrals = {}
    local allies = {}

    for i, survivor in ipairs(survivors) do
        if IsTargetAnEnemy(survivor) and not IsPartyMember(survivor) then
            table.insert(enemies, survivor)
        end
        if not IsPartyMember(survivor) then
            Osi.SetHitpointsPercentage(survivor, 100)
        end
    end

    for i, survivor in ipairs(survivors) do
        if IsTargetANeutral(survivor) then
            table.insert(neutrals, survivor)
        end
    end

    for i, survivor in ipairs(survivors) do
        if IsTargetAnAlly(survivor) and not IsPartyMember(survivor) then
            table.insert(allies, survivor)
        end
    end

    if #defeatedNotImprisonedParty == 0 then
        Utils.Debug("Defeated party has been imprisoned.")
        for i, victim in ipairs(imprisoned) do
            Osi.RemoveStatus(victim, "AD_DEFEATED")
            Osi.RemoveStatus(victim, "DOWNED")
            Osi.ApplyStatus(victim, "AD_DEFEATED", 30, 1)
        end
        return
    end

    if #enemies > 0 then
        Utils.Debug("Enemies are the victors.")
        Utils.PrintTable(enemies)
        Utils.PrintTable(defeatedNotImprisonedParty)
        -- If ActiveScenario already exists in this combat, chose it instead of a random one
        if not Utils.NilOrEmpty(overrideScenarioId) then
            Utils.Debug("Existing Defeat Scenario [ " .. overrideScenarioId .. " ] has been set combat " .. combatguid .. " skipping random select.")
            Ext.ModEvents.AbsoluteDefeat.DefeatScenarioStarted:Throw({combatGuid = combatguid, captors = enemies, victims = defeatedNotImprisonedParty, scenarioId = overrideScenarioId})
            return
        end
        -- Random Scenario Selection
        local humanoidEnemies = {}
        for i, enemy in ipairs(enemies) do
            if (Osi.IsTagged(enemy, "HUMANOID_7fbed0d4-cabc-4a9d-804e-12ca6088a0a8") == 1
            or Osi.IsTagged(enemy, "FIEND_44be2f5b-f27e-4665-86f1-49c5bfac54ab") == 1) then
                table.insert(humanoidEnemies, enemy)
            else
                Utils.Debug(enemy .. " is not a humanoid. Disallowing")
            end
        end

        if #humanoidEnemies > 0 then
            local scenarioid = ChooseRandomScenario()
            -- set defeated scenario tag to participants then start defeat scenario
            if scenarioid ~= nil then
                for _,enemy in pairs(humanoidEnemies) do
                    SetActiveDefeatScenarioIdByObject(scenarioid, enemy)
                end
                
                for _,victim in pairs(defeatedNotImprisonedParty) do
                    SetActiveDefeatScenarioIdByObject(scenarioid, victim)
                end
                Ext.ModEvents.AbsoluteDefeat.DefeatScenarioStarted:Throw({combatGuid = combatguid, captors = humanoidEnemies, victims = defeatedNotImprisonedParty, scenarioId = scenarioid})
            else
                Utils.Warn("No Scenario was selected - defaulting to execution")
                Ext.ModEvents.AbsoluteDefeat.DefeatScenarioStarted:Throw({combatGuid = combatguid, captors = humanoidEnemies, victims = defeatedNotImprisonedParty, scenarioId = "Executed"})
            end

        else
            Utils.Warn("All enemies are non-humanoid - defaulting to execution")
            Ext.ModEvents.AbsoluteDefeat.DefeatScenarioStarted:Throw({combatGuid = combatguid, captors = humanoidEnemies, victims = defeatedNotImprisonedParty, scenarioId = "Executed"})
        end
        return

    elseif #neutrals > 0 then
        Utils.Debug("Neutrals are the victors.")
        Utils.PrintTable(neutrals)
        Utils.PrintTable(defeatedNotImprisonedParty)
        for i, victim in ipairs(defeatedNotImprisonedParty) do
            Osi.RemoveStatus(victim, "AD_DEFEATED")
            Osi.RemoveStatus(victim, "DOWNED")
            Osi.ApplyStatus(victim, "AD_DEFEATED_TEMP", 30, 1)
        end
    end
    
    if #allies > 0 then
        Utils.Debug("Allies are the victors.")
        Utils.PrintTable(allies)
        Utils.PrintTable(defeatedNotImprisonedParty)
        StartHelpAlliesScript(allies, defeatedNotImprisonedParty)
    else
        Utils.Debug("Party somehow got defeated and are the only ones alive.")
        for i, victim in ipairs(defeatedNotImprisonedParty) do
            Osi.RemoveStatus(victim, "AD_DEFEATED")
            Osi.RemoveStatus(victim, "DOWNED")
            Osi.ApplyStatus(victim, "AD_DEFEATED_TEMP", 30, 1)
        end
    end
end

-- nearby allies help party logic
function StartHelpAlliesScript(allies, defeatedparty)
    local mainHelper = allies[math.random(#allies)]
    local mainVictim = defeatedparty[math.random(#defeatedparty)]
    Osi.ApplyStatus(mainHelper, "AD_ACTION_ALLY_ASSIST", 30, 1, mainVictim)
end

--[[ Region: EventHandlers ]]--

function AD.CombatStarted(combat)
    Utils.Debug("COMBAT [" .. combat .. "] Started")
    ClearAllActiveDefeatScenariosByCombat(combat)
    local party = DBUtils.GetPartyCombatants(combat)
    for _, member in ipairs(party) do
        if Osi.HasActiveStatus(member, "AD_DEFEATED") then
            Osi.RemoveStatus(member, "AD_DEFEATED")
        end
    end
end

function AD.CombatEnded(combat)
    Utils.Debug("COMBAT [" .. combat .. "] Ended")
    -- enemy victors (alive)
    local alive = DBUtils.GetPostCombatLiving(combat)
    Utils.Debug("ALIVE:")
    Utils.PrintTable(alive)
    if IsCriminalCombat(combat) then
        Utils.Debug("CRIMINAL COMBAT ENDED, LET GUARDS TP THEM TO PRISON:")
        --EndDefeatByCombat(combat)
        return
    end
    
    if #DBUtils.GetPartyInADDefeatStatus(combat) > 0 then
        --Utils.Debug("Wait for them to heal then init script")
        -- Utils.DelayedCall(6000, function ()
        --     StartDefeatScenario(combat)
        -- end)
        StartDefeatScenario(combat)
    end
end

function AD.StatusApplied(object, status, causee, storyActionID)
    if Osi.HasAppliedStatusOfType(object, "DOWNED") == 1 then -- seems to be this runs before it is added to the defeat db...
        local combatguid = Osi.CombatGetGuidFor(object)
        if combatguid ~= nil then
            Utils.Debug("ALLY COMBATANT DOWNED: Start defeat check for combat: "..combatguid)
            Osi.DB_Downed(object)
            if IsActivePartyDefeated(combatguid) then -- any party members who are currently in combat are all defeated 
                Utils.Debug("ALLY COMBATANT DOWNED: Defeat check successful, initiating defeat.")
                InitDefeatOnParty(combatguid)
            end
        end
    end

    if Utils.MCMGet("include_summons") then
        if status == "UNSUMMON_ACTIVE" then
            local combatguid = DBUtils.GetActivePartyCombats()[1]  -- unsummoned creature doesn't seem to include combatguid
            Utils.Debug("ALLY SUMMONED UNSUMMONED: Start defeat check for combat: "..combatguid)
            if IsActivePartyDefeated(combatguid) then -- any party members who are currently in combat are all defeated 
                Utils.Debug("ALLY SUMMONED UNSUMMONED: Defeat check successful, initiating defeat.")
                InitDefeatOnParty(combatguid)
            end
        end
    end
    
    if status == "AD_DEFEATED" then
        Osi.SetHitpoints(object, 1)
        return
    end

    if string.sub(status, 1, 16) == "AD_ACTION_CAPTOR" and causee ~= nil then
        local scenarioid = GetActiveDefeatScenarioIdFromObject(object)
        if not Utils.NilOrEmpty(scenarioid) then
            Ext.ModEvents.AbsoluteDefeat.DefeatScenarioActionStarted:Throw({scenarioId = scenarioid, victim = causee, captor = object, status = status, defeatContext = AD.GetDefeatContextFromObject(object)})
        end
        return
    end

    if string.sub(status, 1, 16) == "AD_ACTION_VICTIM" then
        local scenarioid = GetActiveDefeatScenarioIdFromObject(object)
        if not Utils.NilOrEmpty(scenarioid) then
            Ext.ModEvents.AbsoluteDefeat.DefeatScenarioActionStarted:Throw({scenarioId = scenarioid, victim = object, captor = causee, status = status, defeatContext = AD.GetDefeatContextFromObject(object)})
        end
        return
    end

    if status == "AD_LOOT_ITEM" then
        Utils.Debug("ABSORBING ITEM: " .. object)
        Osi.ToInventory(causee, object, 1, 0, 0)
        return
    end
    
    if status == "AD_VICTIM_LOOT_ITEM" then
        local weapon = Osi.GetEquippedWeapon(object)

        if weapon ~= nil and Osi.HasActiveStatus(weapon, "WEAPON_BOND") == 0
                         and Osi.HasActiveStatus(weapon, "MAG_INVISIBLE_WEAPON") == 0
                         and Osi.HasActiveStatus(weapon, "PACT_BLADE") == 0
                         and Osi.HasActiveStatus(weapon, "FLAME_BLADE") == 0
                         and Osi.HasActiveStatus(weapon, "SHADOW_BLADE") == 0
                         and Osi.HasActiveStatus(weapon, "SHILLELAGH") == 0 then
            Utils.Debug("WEAPON GOT: " .. weapon)
            Osi.ApplyStatus(object, "DISARM_STEAL", 0, 100, causee)
            return
        end

        local stealList = Utils.GetEquippedGearSlots(object)
        if #stealList > 0 then
            local stealGear = Utils.UnequipGearSlot(object, stealList[math.random(#stealList)], true)
            if stealGear ~= nil then
                Osi.ApplyStatus(object, "AD_ARMOR_STEAL", 0, 100, causee)
                Osi.ApplyStatus(causee, "AD_LOOT_ITEM", 0, 100, stealGear)
            end
            return
        end

        -- no gear or weapons? steal items.
        
        local items = Utils.DeepIterateInventory(object, items)
        if #items == 0 then
            Utils.Debug("Nothing to steal")
            return
        end

        local randitem = items[math.random(#items)]
        local attempts = 0
        while not randitem.IsStoryItem and not randitem.IsContainer and attempts < 5 do
            randitem = items[math.random(#items)]
            attempts = attempts + 1
        end

        if randitem ~= nil then
            local itemName = randitem.Object .. "_" ..randitem.Uuid
            Utils.Debug("RANDOM ITEM CHOSEN: " .. itemName)
            Osi.ApplyStatus(object, "AD_ITEM_STEAL", 0, 100, causee)
            Osi.ToInventory(itemName, causee, randitem.Amount, 0, 0)
        else
            Utils.Debug("Nothing left to steal")
        end
    end

end

function AD.StatusRemoved(object, status, causee, storyActionID)
    if causee ~= nil then
        if Osi.GetTechnicalName(causee) ~= nil then
            causee = Osi.GetTechnicalName(causee) .. "_" .. causee
        end
    end

    if status == "AD_DEFEATED" then
        --Osi.DB_Defeated:Delete(object)
        return
    end

    if string.sub(status, 1, 16) == "AD_ACTION_CAPTOR" then
        local scenarioid = GetActiveDefeatScenarioIdFromObject(object)
        if not Utils.NilOrEmpty(scenarioid) then
            Ext.ModEvents.AbsoluteDefeat.DefeatScenarioActionCompleted:Throw({scenarioId = scenarioid, victim = causee, captor = object, status = status, defeatContext = AD.GetDefeatContextFromObject(object)})
        end
    end

    if string.sub(status, 1, 16) == "AD_ACTION_VICTIM" then
        local scenarioid = GetActiveDefeatScenarioIdFromObject(object)
        if not Utils.NilOrEmpty(scenarioid) then
            Ext.ModEvents.AbsoluteDefeat.DefeatScenarioActionCompleted:Throw({scenarioId = scenarioid, victim = object, captor = causee, status = status, defeatContext = AD.GetDefeatContextFromObject(object)})
        end
    end
end

function AD.EnteredCombat(object, combatGuid)
    --GetActiveDefeatScenarioIdFromObject(object)
end

function AD.GetDefeatContextFromObject(object)
    local cb = DBUtils.GetPreviousCombatFromEntity(object)
    local enemies = DBUtils.GetEnemyCombatants(cb)
    local partyVictims = DBUtils.GetPartyCombatants(cb)
    local scenario = GetActiveDefeatScenarioIdFromObject(object)
    local enemiesf = {}
    local partyVictimsf = {}

    for _,enemy in pairs(enemies) do
        if GetActiveDefeatScenarioIdFromObject(enemy) ~= nil then
            table.insert(enemiesf, enemy)
        end
    end

    for _,partyMember in pairs(partyVictims) do
        if GetActiveDefeatScenarioIdFromObject(partyMember) ~= nil then
            table.insert(partyVictimsf, partyMember)
        end
    end
    local dc = { combatGuid = cb, scenarioId = scenario, captors = enemiesf, victims = partyVictimsf }
    return dc
end

function AD.LeftCombat(object, combatGuid)
    if combatGuid ~= nil then
        if IsPartyMember(object) then
            Utils.Debug("ALLY COMBATANT [" .. object .."] LEFT THE COMBAT (DIED/FLED): Start defeat check for combat: " .. combatGuid)
            if IsActivePartyDefeated(combatGuid) then
                Utils.Debug("ALLY COMBATANT DIED/FLED: Defeat check successful, initiating defeat.")
                InitDefeatOnParty(combatGuid)
            end
        end
    end
end

function AD.FleeFromCombat(participant, combatGuid)
    --
end

function AD.Died(object)
    Osi.PROC_GameOver_CheckGameOver();
end

function AD.Stabilized(object)
    if Osi.IsInCombat(object) == 0 and Osi.HasActiveStatus(object, "AD_DEFEATED") == 0 then
        Utils.Debug(object .. " stabilized out of combat, reviving.")
        Osi.ApplyStatus(object, "AD_OOC_DOWNED", 100, 0)
    end

end


-- Commands --

function AD.CmdSurrender()
    local activeCombats = DBUtils.GetActivePartyCombats()
    if #activeCombats > 0 then
        local partyMembers = DBUtils.GetActiveOriginCombatants(activeCombats[1])
        for i, partyMember in ipairs(partyMembers) do
            Osi.ApplyDamage(partyMember, Osi.GetHitpoints(partyMember), "Radiant", "NULL_00000000-0000-0000-0000-000000000000")
        end
    end
end

function AD.CmdUndefeat()
    local combats = DBUtils.GetPreviousPartyCombats()
    for _,combat in ipairs(combats) do
        AD.CleanUpDefeat(combat)
    end

    local partyMembers = DBUtils.GetOriginPartyMembers()
    for i, partyMember in ipairs(partyMembers) do
        Osi.SetHitpointsPercentage(partyMember, 100)
    end
end

function AD.CmdGetLastCombat()
    local lastcombat = DBUtils.GetPreviousCombatFromEntity(Osi.GetHostCharacter())
    Utils.Debug(lastcombat)
end

function AD.CmdForceScenario()
    local combat = DBUtils.GetActivePartyCombats()[1]
    AD.OverrideDefeatScenarioForCombat(combat, "Spare_5d50854a-3d0a-42b2-926b-f9359416977c")
    local sn = GetActiveDefeatScenarioIdFromCombat(combat)
end
return AD