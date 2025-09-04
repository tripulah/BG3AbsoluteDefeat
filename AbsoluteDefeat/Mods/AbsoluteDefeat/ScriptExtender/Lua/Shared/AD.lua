AD = {}

-- let's try a somewhat functional approach so the mod has less bugs

PartyCombats = {} -- party members (general)
-- ReloadingSave = true

function GetOriginPartyMembers()
    local partyMembers = GetPartyMembers()
    local summons = Utils.ConvertDBTable(Osi.DB_PlayerSummons:Get(nil))
    local onlyOrigins = Utils.GetTableDifference(partyMembers, summons)
    return onlyOrigins
end

function GetPartyMembers()
    local partyMembers = Utils.ConvertDBTable(Osi.DB_PartyMembers:Get(nil))
    return partyMembers
end

function GetPartySize()
    local partyMembers = GetPartyMembers()
    return #partyMembers
end

function GetActivePartyCombats()
    local partyMembers = GetPartyMembers()
    local activeCombats = {}
    for i, member in ipairs(partyMembers) do
        if Osi.CombatGetGuidFor(member) ~= nil then
            table.insert(activeCombats, Osi.CombatGetGuidFor(member))
        end
    end
    return activeCombats
end

function IsCriminalCombat(combatguid)
    Utils.Debug("CHECKING IF CRIMINAL COMBAT" .. combatguid)
    local criminalcombats = Utils.ConvertDBTable(Osi.DB_Crime_CombatID:Get(nil, nil), 2)
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

function IsPartyInCombat()
    local partyMembers = GetPartyMembers()
    for i, member in ipairs(partyMembers) do
        if Osi.CombatGetGuidFor(member) ~= nil then
            return true
        end
    end
    return false
end

function IsTargetAnEnemy(guid)
    local partyMembers = GetPartyMembers()
    for _, partyMemberGuid in ipairs(partyMembers) do
        if Osi.IsEnemy(guid, partyMemberGuid) == 1 then
            --Utils.Debug("IS ENEMY " .. partyMemberGuid .. " " .. guid)
            return true
        end
    end
    return false
end

function IsTargetANeutral(guid)
    local partyMembers = GetPartyMembers()
    for _, partyMemberGuid in ipairs(partyMembers) do
        if Osi.IsNeutral(guid, partyMemberGuid) == 1 then
            --Utils.Debug("IS NEUTRAL " .. partyMemberGuid .. " " .. guid)
            return true
        end
    end
    return false
end

function IsTargetAnAlly(guid)
    local partyMembers = GetPartyMembers()
    for _, partyMemberGuid in ipairs(partyMembers) do
        if Osi.IsAlly(guid, partyMemberGuid) == 1 then
            --Utils.Debug("IS ALLY " .. partyMemberGuid .. " " .. guid)
            return true
        end
    end
    return false
end

function IsPartyMember(guid)
    local partymembers = GetPartyMembers()
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

function GetPreviousPartyCombats()
    local partymembers = GetPartyMembers()
    local combats = {}
    for index, partymember in ipairs(partymembers) do
        local prevcombat = GetPreviousCombatFromEntity(partymember)
        if prevcombat ~= nil then
            table.insert(combats, prevcombat)
        end
    end

    return combats
end 

function GetPreviousCombatFromEntity(guid)
    local lastcombat = Utils.ConvertDBTable(Osi.DB_Was_InCombat:Get(guid, nil), 2)
    Utils.PrintTable(lastcombat)
    if lastcombat then
        return lastcombat[1]
    end
    return nil
end

function GetActiveCombatants(combatGuid)
    local combatants = Utils.ConvertDBTable(Osi.DB_Is_InCombat:Get(nil, combatGuid))
    return combatants
end

function GetCombatants(combatGuid)
    local combatants = Utils.ConvertDBTable(Osi.DB_Is_InCombat:Get(nil, combatGuid))
    if #combatants == 0 then
        combatants = Utils.ConvertDBTable(Osi.DB_Was_InCombat:Get(nil, combatGuid))
    end
    return combatants
end

function GetActiveEnemyCombatants(combatGuid)
    local combatants = GetActiveCombatants(combatGuid)
    local enemies = {}
    for index, combatant in ipairs(combatants) do
        if IsTargetAnEnemy(combatant) then
            table.insert(enemies, combatant)
        end
    end
    return enemies
end

function GetEnemyCombatants(combatGuid)
    local combatants = GetCombatants(combatGuid)
    local enemies = {}
    for index, combatant in ipairs(combatants) do
        if IsTargetAnEnemy(combatant) then
            table.insert(enemies, combatant)
        end
    end
    return enemies
end

function GetActiveOriginCombatants(combatGuid)
    local combatants = GetActiveCombatants(combatGuid)
    local partymembers = GetOriginPartyMembers()
    local combatpartymembers = Utils.GetTableIntersection(combatants, partymembers)
    return combatpartymembers
end

function GetActivePartyCombatants(combatGuid)
    local combatants = GetActiveCombatants(combatGuid)
    local partymembers = GetPartyMembers()
    local combatpartymembers = Utils.GetTableIntersection(combatants, partymembers)
    return combatpartymembers
end

function GetPartyCombatants(combatGuid)
    local combatants = GetCombatants(combatGuid)
    local partymembers = GetPartyMembers()
    local combatpartymembers = Utils.GetTableIntersection(combatants, partymembers)
    return combatpartymembers
end

function GetOriginCombatants(combatGuid)
    local combatants = GetCombatants(combatGuid)
    local partymembers = GetOriginPartyMembers()
    local combatpartymembers = Utils.GetTableIntersection(combatants, partymembers)
    return combatpartymembers
end

function GetPostCombatVictors(combatGuid)
    local combatants = Utils.ConvertDBTable(Osi.DB_Was_InCombat:Get(nil, combatGuid))
    local defeatedcombatants = Utils.ConvertDBTable(Osi.DB_Defeated:Get(nil))
    if combatants ~= nil and defeatedcombatants ~= nil then
        for _,c in ipairs(combatants) do
            if Osi.HasActiveStatus(c, "AD_DEFEATED") == 1 then
                table.insert(defeatedcombatants, c)
            end
        end
    end

    local nondefeatedcombatants = Utils.GetTableDifference(combatants, defeatedcombatants)
    return nondefeatedcombatants
end

function GetPostCombatLiving(combatGuid)
    local combatants = Utils.ConvertDBTable(Osi.DB_Was_InCombat:Get(nil, combatGuid))
    local deadcombatants = Utils.ConvertDBTable(Osi.DB_Dead:Get(nil)) -- TODO: find a way to  db query a subset instead of everything
    local alivecombatants = Utils.GetTableDifference(combatants, deadcombatants)
    return alivecombatants
end

function GetActiveCombatLiving(combatGuid)
    local combatants = Utils.ConvertDBTable(Osi.DB_Is_InCombat:Get(nil, combatGuid))
    local deadcombatants = Utils.ConvertDBTable(Osi.DB_Dead:Get(nil)) -- TODO: find a way to  db query a subset instead of everything
    local alivecombatants = Utils.GetTableDifference(combatants, deadcombatants)
    return alivecombatants
end

-- party that has the AD_DEFEAT status
function GetPartyInADDefeatStatus(combatGuid)
    Utils.Debug("Absolute defeated: before")
    local partyMembers = GetPartyCombatants(combatGuid)
    local defeatedPartyMembers = {}
    for _, partyMember in ipairs(partyMembers) do
        if Osi.HasActiveStatus(partyMember, "AD_DEFEATED") == 1 then
            table.insert(defeatedPartyMembers, partyMember)
        end
    end
    Utils.Debug("Absolute defeated: after")
    Utils.PrintTable(defeatedPartyMembers)
    return defeatedPartyMembers
end

-- party that is in the defeateddb, incl. the dead.
function GetDefeatedParty(combatGuid)
    local partyMembers = GetPartyCombatants(combatGuid)
    --print("Get Defeated Party: ")
    --print("PARTY MEMBERS: ")
    Utils.PrintTable(partyMembers)
    local defeatedEntities = Utils.ConvertDBTable(Osi.DB_Defeated:Get(nil))
    local downedEntities = Utils.ConvertDBTable(Osi.DB_Downed:Get(nil))
    --print("DOWNED THINGS: ")
    --Utils.PrintTable(downedEntities)
    --local defeatedAndDownedEntities = Utils.GetTableUnion(defeatedEntities, downedEntities)

    --print("DB_DEFEATED ENTITIES: ")
    --Utils.PrintTable(defeatedEntities)
    local defeatedPartyMembers = Utils.GetTableIntersection(partyMembers, defeatedEntities)
    Utils.PrintTable(defeatedPartyMembers)
    return defeatedPartyMembers
end

-- party that is in the defeateddb, excluding the dead.
function GetDefeatedAliveParty(combatGuid)
    local defeatedPartyMembers = GetDefeatedParty(combatGuid)
    local dead = Utils.ConvertDBTable(Osi.DB_Dead:Get(nil))
    local defeatedAlivePartyMembers = Utils.GetTableDifference(defeatedPartyMembers, dead)
    return defeatedAlivePartyMembers
end

-- party who has participated in combat is currently defeated (incl. dead)
function IsPartyDefeated(combatGuid)
    local defeatedPartyMembers = GetDefeatedParty(combatGuid)

    local allPartyMembers = GetPartyCombatants(combatGuid)

    local notDefeatedPartyMembers = Utils.GetTableDifference(allPartyMembers, defeatedPartyMembers)
    return #notDefeatedPartyMembers == 0
end

-- party currently fighting is defeated (not incl. fleed + defeated people (OOC))
function IsActivePartyDefeated(combatGuid)
    --Utils.Debug("Let's check if currently active combatants are in a defeated state:")
    local defeatedPartyMembers = GetDefeatedParty(combatGuid)
    -- dont end the fight if summons are included
    local fightingPartyMembers
    if Utils.MCMGet("include_summons") then
        fightingPartyMembers = GetActivePartyCombatants(combatGuid)
    else
        fightingPartyMembers = GetActiveOriginCombatants(combatGuid)
    end
    local undefeatedFightingPartyMembers = Utils.GetTableDifference(fightingPartyMembers, defeatedPartyMembers)

    local defeatedFightingPartyMembers = Utils.GetTableIntersection(fightingPartyMembers, defeatedPartyMembers)
    --Utils.PrintTable(defeatedFightingPartyMembers)
    local thebool = #undefeatedFightingPartyMembers == 0
    --print("IsActivePartyDefeated?: ", thebool)
    return thebool
end

function GetDefeatedActiveParty(combatGuid)
    local defeatedPartyMembers = GetDefeatedParty(combatGuid)
    local fightingPartyMembers = GetActivePartyCombatants(combatGuid)
    local defeatedFightingPartyMembers = Utils.GetTableIntersection(fightingPartyMembers, defeatedPartyMembers)
    return defeatedFightingPartyMembers
end

function GetPartySummonsInCombat(combatGuid)
    local fightingPartyMembers = GetActivePartyCombatants(combatGuid)
    local partySummons = Utils.ConvertDBTable(Osi.DB_PlayerSummons:Get(nil))
    local fightingPartySummons = Utils.GetTableIntersection(fightingPartyMembers, partySummons)
    return fightingPartySummons
end

function InitDefeatOnParty(combatguid)
    if Waypoints[Utils.GetCurrentLevel()] == nil then
        Utils.Debug("LEVEL " .. Utils.GetCurrentLevel() .. " IS NOT SUPPORTED, ABORTING DEFEAT.")
        return
    end
    

    local alivePartyMembers = GetDefeatedActiveParty(combatguid)
    if not Utils.MCMGet("include_summons") then

        Utils.Debug("Killing participating party summons.")
        local partySummons = GetPartySummonsInCombat()
        for _, partySummon in ipairs(partySummons) do
            Osi.Die(partySummon)
        end
    end
    -- for _, defeatedPartyMember in ipairs(defeatedParty) do
    --     if Osi.IsDead(defeatedPartyMember) ~= 1 then
    --         table.insert(alivePartyMembers, defeatedPartyMember)
    --     end
    -- end
    Utils.Debug('APPLYING DEFEAT TO THESE DEFEATED PLAYERS')
    Utils.PrintTable(alivePartyMembers)
    -- take party out of combat
    for _, alivePartyMember in ipairs(alivePartyMembers) do

        Osi.ApplyStatus(alivePartyMember, "AD_DEFEATED", -1)
    end
end

function GetScenarioVictims(combatguid)
    local partyMemberWithADStatus = GetPartyInADDefeatStatus(combatguid)
    return partyMemberWithADStatus
end
function StartDefeatScenario(combatguid)
    local defeatedparty = GetScenarioVictims(combatguid)
    Utils.Debug("LOSERS: ")
    Utils.PrintTable(defeatedparty)
    -- get victors
    local survivors = GetPostCombatLiving(combatguid)
    Utils.Debug("SURVIVORS: ")
    Utils.PrintTable(survivors)
    -- victors are enemies
    local enemies = {}
    local neutrals = {}
    local allies = {}

    for i, survivor in ipairs(survivors) do
        if IsTargetAnEnemy(survivor) then
            table.insert(enemies, survivor)
            Utils.TryAddSpell(survivor, "Target_AD_Restrain")
        end
    end

    for i, survivor in ipairs(survivors) do
        if IsTargetANeutral(survivor) then
            table.insert(neutrals, survivor)
        end
    end

    for i, survivor in ipairs(survivors) do
        if IsTargetAnAlly(survivor) then
            table.insert(allies, survivor)
        end
    end
    
    if #defeatedparty == 0 then
        Utils.Debug("Nobody survived.")
        return
    end

    if #enemies > 0 then
        Utils.Debug("Enemies are the victors.")
        Utils.PrintTable(enemies)
        Utils.PrintTable(defeatedparty)
        local humanoidEnemies = {}
        for i, enemy in ipairs(enemies) do
            if (Osi.IsTagged(enemy, "HUMANOID_7fbed0d4-cabc-4a9d-804e-12ca6088a0a8") == 1
            or Osi.IsTagged(enemy, "FIEND_44be2f5b-f27e-4665-86f1-49c5bfac54ab") == 1) then
                table.insert(humanoidEnemies, enemy)
            else
                Utils.Debug(enemy .. " is not a humanoid. Disallowing")
            end
        end
        StartRansackScript(humanoidEnemies, defeatedparty)
        return
    end

    if #neutrals > 0 then
        Utils.Debug("Neutrals are the victors.")
        Utils.PrintTable(neutrals)
        Utils.PrintTable(defeatedparty)
        for i, victim in ipairs(defeatedparty) do
            Osi.RemoveStatus(victim, "AD_DEFEATED")
            Osi.RemoveStatus(victim, "DOWNED")
            Osi.ApplyStatus(victim, "AD_DEFEATED", 30, 1)
        end
    end
    
    if #allies > 0 then
        Utils.Debug("Allies are the victors.")
        Utils.PrintTable(allies)
        Utils.PrintTable(defeatedparty)
        StartHelpAlliesScript(allies, defeatedparty)
        return
    end
end

-- ransack defeated party logic
function StartRansackScript(enemies, defeatedparty)
    local mainPerp = enemies[math.random(#enemies)]
    local mainVictim = defeatedparty[math.random(#defeatedparty)]
    for i, enemy in ipairs(enemies) do
        if enemy ~= mainPerp then
            Osi.ApplyStatus(enemy, "AD_ACTION_CAPTOR_BYSTANDER", -1, 1, defeatedparty[math.random(#defeatedparty)])
        end
    end

    Osi.ApplyStatus(mainPerp, "AD_ACTION_CAPTOR_TIE", -1, 1, mainVictim)
end

-- nearby allies help party logic
function StartHelpAlliesScript(allies, defeatedparty)
    local mainHelper = allies[math.random(#allies)]
    local mainVictim = defeatedparty[math.random(#defeatedparty)]
    Osi.ApplyStatus(mainHelper, "AD_ACTION_ALLY_ASSIST", 30, 1, mainVictim)
end

function EndAllDefeats()
    local lastcombat = GetPreviousPartyCombats()
end

function CleanUpDefeat(combat)
    Utils.Debug("CLEANING UP DEFEAT SCENARIO FOR COMBAT: " .. combat)
    local enemies = GetEnemyCombatants(combat)
    local partyVictims = GetPartyCombatants(combat)

    for index, enemy in ipairs(enemies) do
        Osi.RemoveStatus(enemy, "AD_ACTION_CAPTOR_BYSTANDER")
    end

    for index, victim in ipairs(partyVictims) do
        Osi.RemoveStatus(victim, "DOWNED")
        Osi.RemoveStatus(victim, "AD_DEFEATED")
        Osi.RemoveStatus(victim, "AD_RESTRAIN")
    end
end

function KickOutVictims(victims)
    for index, victim in ipairs(victims) do
        Utils.Fade(victim, 5.0)
        Osi.PROC_WaypointTeleportTo(victim, Waypoints[Utils.GetCurrentLevel()][1])
    end
end

--[[ Region: API ]]--

--[[ Region: EventHandlers ]]--

function AD.CombatStarted(combat)
    Utils.Debug("COMBAT [" .. combat .. "] Started")
    local party = GetPartyCombatants(combat)
    for _, member in ipairs(party) do
        if Osi.HasActiveStatus(member, "AD_DEFEATED") then
            Osi.RemoveStatus(member, "AD_DEFEATED")
        end
    end
end

function AD.CombatEnded(combat)
    Utils.Debug("COMBAT [" .. combat .. "] Ended")
    -- enemy victors (alive)
    local alive = GetPostCombatLiving(combat)
    Utils.Debug("ALIVE:")
    Utils.PrintTable(alive)
    if IsCriminalCombat(combat) then
        Utils.Debug("CRIMINAL COMBAT ENDED, LET GUARDS TP THEM TO PRISON:")
        --EndDefeatByCombat(combat)
        return
    end
    if #GetPartyInADDefeatStatus(combat) > 0 then
        Utils.Debug("Wait for them to heal then init script")
        Utils.DelayedCall(6000, function ()
            StartDefeatScenario(combat)
        end)
    end
end

function AD.StatusApplied(object, status, causee, storyActionID)
    if status == "DOWNED" or status == "HAG_DOWNED" or status == "SCL_DOWNED" then -- seems to be this runs before it is added to the defeat db...
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
            local combatguid = GetActivePartyCombats()[1]  -- unsummoned creature doesn't seem to include combatguid
            Utils.Debug("ALLY SUMMONED UNSUMMONED: Start defeat check for combat: "..combatguid)
            if IsActivePartyDefeated(combatguid) then -- any party members who are currently in combat are all defeated 
                Utils.Debug("ALLY SUMMONED UNSUMMONED: Defeat check successful, initiating defeat.")
                InitDefeatOnParty(combatguid)
            end
        end
    end
    
    if status == "AD_DEFEATED" then
        Osi.SetHitpoints(object, 1)
        --Osi.DB_Defeated(object)
    end

    if status == "AD_ACTION_CAPTOR_LOOT_ITEM" then
        Utils.Debug("ABSORBING ITEM: " .. object)
        Osi.ToInventory(causee, object, 1, 0, 0)
        return
    end
    
    if status == "AD_VICTIM_LOOT_ITEM" then
        
        local weapon = Osi.GetEquippedWeapon(object)

        if weapon ~= nil and Osi.HasActiveStatus(object, "WEAPON_BOND") == 0
                         and Osi.HasActiveStatus(object, "MAG_INVISIBLE_WEAPON") == 0
                         and Osi.HasActiveStatus(object, "PACT_BLADE") == 0
                         and Osi.HasActiveStatus(object, "FLAME_BLADE") == 0
                         and Osi.HasActiveStatus(object, "SHADOW_BLADE") == 0
                         and Osi.HasActiveStatus(object, "SHILLELAGH") == 0 then
            Utils.Debug("WEAPON GOT: " .. weapon)
            Osi.ApplyStatus(object, "DISARM_STEAL", 0, 100, causee)
            return
        end

        local stealList = Utils.GetEquippedGearSlots(object)
        if #stealList > 0 then
            local stealGear = Utils.UnequipGearSlot(object, stealList[math.random(#stealList)], true)
            if stealGear ~= nil then
                Osi.ApplyStatus(object, "AD_ARMOR_STEAL", 0, 100, causee)
                Osi.ApplyStatus(causee, "AD_ACTION_CAPTOR_LOOT_ITEM", 0, 100, stealGear)
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

    -- janky way of doing the capture state management
    if string.sub(status, 1, 9) == "AD_ACTION" and causee ~= nil then
        Utils.Debug("AD ACTION CHANGED: " .. status)
        if status == "AD_ACTION_CAPTOR_TIE" then
            Osi.ApplyStatus(object, "AD_ACTION_CAPTOR_LOOT", 30, 1, causee)
        end

        if status == "AD_ACTION_CAPTOR_LOOT" then
            Osi.ApplyStatus(object, "AD_ACTION_CAPTOR_KNOCKOUT", 12, 1, causee)
        end
    end
    -- end defeat
    if status == "AD_ACTION_CAPTOR_KNOCKOUT" then
        if Osi.IsInCombat(object) == 0 then
            CleanUpDefeat(GetPreviousCombatFromEntity(object))
            KickOutVictims(GetPartyCombatants(GetPreviousCombatFromEntity(object)))
        else
            CleanUpDefeat(GetPreviousCombatFromEntity(object))
        end
    end

    if string.sub(status, 1, 9) == "AD_VICTIM" and causee ~= nil then
        --Utils.Debug("AD STATE CHANGED: ", status)
    end
end

function AD.LeftCombat(object, combatGuid)
    if combatGuid ~= nil then
        if IsPartyMember(object) then
            Utils.Debug("ALLY COMBATANT LEFT THE COMBAT (DIED/FLED): Start defeat check for combat: " .. combatGuid)
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

-- Commands --

function AD.Surrender()
    local activeCombats = GetActivePartyCombats()
    if #activeCombats > 0 then
        local partyMembers = GetActiveOriginCombatants(activeCombats[1])
        for i, partyMember in ipairs(partyMembers) do
            Osi.SetHitpoints(partyMember, 1)
            Osi.ApplyStatus(partyMember, "DOWNED", -1, 1)
        end
    end
end

function AD.GetLastCombat()
    local lastcombat = GetPreviousCombatFromEntity(Osi.GetHostCharacter())
    Utils.Debug(lastcombat)

    Utils.PrintTable(GetPartyMembers())
end

return AD