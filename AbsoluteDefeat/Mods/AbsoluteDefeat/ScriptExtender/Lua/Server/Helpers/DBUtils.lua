DBUtils = {

}

function DBUtils.GetPartyMembers()
    local partyMembers = DBUtils.ConvertDBTable(Osi.DB_PartyMembers:Get(nil))
    local notEnemyPartyMembers = {}
    for _,partyMember in ipairs(partyMembers) do
        if Osi.HasActiveStatusWithGroup(partyMember, "SG_Possessed") ~= 1 then
            table.insert(notEnemyPartyMembers, partyMember)
        end
    end
    return notEnemyPartyMembers
end

function DBUtils.GetOriginPartyMembers()
    local partyMembers = DBUtils.GetPartyMembers()
    local summons = DBUtils.ConvertDBTable(Osi.DB_PlayerSummons:Get(nil))
    local onlyOrigins = Utils.GetTableDifference(partyMembers, summons)
    return onlyOrigins
end

function DBUtils.GetPartySize()
    local partyMembers = DBUtils.GetPartyMembers()
    return #partyMembers
end 

function DBUtils.GetActivePartyCombats()
    local partyMembers = DBUtils.GetPartyMembers()
    local activeCombats = {}
    for i, member in ipairs(partyMembers) do
        if Osi.CombatGetGuidFor(member) ~= nil then
            table.insert(activeCombats, Osi.CombatGetGuidFor(member))
        end
    end
    return activeCombats
end

function DBUtils.GetPreviousPartyCombats()
    local partymembers = DBUtils.GetPartyMembers()
    local combats = {}
    for index, partymember in ipairs(partymembers) do
        local prevcombat = DBUtils.GetPreviousCombatFromEntity(partymember)
        if prevcombat ~= nil and next(combats) == nil then
            table.insert(combats, prevcombat)
        elseif prevcombat ~= nil and prevcombat ~= combats[1] then
            table.insert(combats, prevcombat)
        end
    end

    return combats
end 

function DBUtils.GetPreviousCombatFromEntity(guid)
    local lastcombat = DBUtils.ConvertDBTable(Osi.DB_Was_InCombat:Get(guid, nil), 2)

    if lastcombat then
        return lastcombat[1]
    end
    return nil
end

function DBUtils.GetActiveCombatants(combatGuid)
    local combatants = DBUtils.ConvertDBTable(Osi.DB_Is_InCombat:Get(nil, combatGuid))
    return combatants
end

function DBUtils.GetCombatants(combatGuid)
    local combatants = DBUtils.ConvertDBTable(Osi.DB_Is_InCombat:Get(nil, combatGuid))
    if #combatants == 0 then
        combatants = DBUtils.ConvertDBTable(Osi.DB_Was_InCombat:Get(nil, combatGuid))
    end
    return combatants
end

function DBUtils.GetActiveEnemyCombatants(combatGuid)
    local combatants = DBUtils.GetActiveCombatants(combatGuid)
    local enemies = {}
    for index, combatant in ipairs(combatants) do
        if IsTargetAnEnemy(combatant) then
            table.insert(enemies, combatant)
        end
    end
    return enemies
end

function DBUtils.GetEnemyCombatants(combatGuid)
    local combatants = DBUtils.GetCombatants(combatGuid)
    local enemies = {}
    for index, combatant in ipairs(combatants) do
        if IsTargetAnEnemy(combatant) then
            table.insert(enemies, combatant)
        end
    end
    return enemies
end

function DBUtils.GetActiveOriginCombatants(combatGuid)
    local combatants = DBUtils.GetActiveCombatants(combatGuid)
    local partymembers = DBUtils.GetOriginPartyMembers()
    local combatpartymembers = Utils.GetTableIntersection(combatants, partymembers)
    return combatpartymembers
end

function DBUtils.GetActivePartyCombatants(combatGuid)
    local combatants = DBUtils.GetActiveCombatants(combatGuid)
    local partymembers = DBUtils.GetPartyMembers()
    local combatpartymembers = Utils.GetTableIntersection(combatants, partymembers)
    return combatpartymembers
end

function DBUtils.GetPartyCombatants(combatGuid)
    local combatants = DBUtils.GetCombatants(combatGuid)
    local partymembers = DBUtils.GetPartyMembers()
    local combatpartymembers = Utils.GetTableIntersection(combatants, partymembers)
    return combatpartymembers
end

function DBUtils.GetOriginCombatants(combatGuid)
    local combatants = DBUtils.GetCombatants(combatGuid)
    local partymembers = DBUtils.GetOriginPartyMembers()
    local combatpartymembers = Utils.GetTableIntersection(combatants, partymembers)
    return combatpartymembers
end

function DBUtils.GetPostCombatVictors(combatGuid)
    local combatants = DBUtils.ConvertDBTable(Osi.DB_Was_InCombat:Get(nil, combatGuid))
    local defeatedcombatants = DBUtils.ConvertDBTable(Osi.DB_Defeated:Get(nil))
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

function DBUtils.GetPostCombatLiving(combatGuid)
    local combatants = DBUtils.ConvertDBTable(Osi.DB_Was_InCombat:Get(nil, combatGuid))
    local deadcombatants = DBUtils.ConvertDBTable(Osi.DB_Dead:Get(nil)) -- TODO: find a way to  db query a subset instead of everything
    local alivecombatants = Utils.GetTableDifference(combatants, deadcombatants)
    return alivecombatants
end

function DBUtils.GetActiveCombatLiving(combatGuid)
    local combatants = DBUtils.ConvertDBTable(Osi.DB_Is_InCombat:Get(nil, combatGuid))
    local deadcombatants = DBUtils.ConvertDBTable(Osi.DB_Dead:Get(nil)) -- TODO: find a way to  db query a subset instead of everything
    local alivecombatants = Utils.GetTableDifference(combatants, deadcombatants)
    return alivecombatants
end

-- party that has the AD_DEFEAT status
function DBUtils.GetPartyInADDefeatStatus(combatGuid)
    Utils.Debug("Absolute defeated: before")
    local partyMembers = DBUtils.GetPartyCombatants(combatGuid)
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
function DBUtils.GetDefeatedParty(combatGuid)
    local partyMembers = DBUtils.GetPartyCombatants(combatGuid)
    --print("Get Defeated Party: ")
    --print("PARTY MEMBERS: ")
    Utils.PrintTable(partyMembers)
    local defeatedEntities = DBUtils.ConvertDBTable(Osi.DB_Defeated:Get(nil))
    local downedEntities = DBUtils.ConvertDBTable(Osi.DB_Downed:Get(nil))
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
function DBUtils.GetDefeatedAliveParty(combatGuid)
    local defeatedPartyMembers = DBUtils.GetDefeatedParty(combatGuid)
    local dead = DBUtils.ConvertDBTable(Osi.DB_Dead:Get(nil))
    local defeatedAlivePartyMembers = Utils.GetTableDifference(defeatedPartyMembers, dead)
    return defeatedAlivePartyMembers
end

function DBUtils.GetCurrentLevel()
    return Osi.DB_CurrentLevel:Get(nil)[1][1]
end

function DBUtils.GetDefeatedActiveParty(combatGuid)
    local defeatedPartyMembers = DBUtils.GetDefeatedParty(combatGuid)
    local fightingPartyMembers = DBUtils.GetActivePartyCombatants(combatGuid)
    local defeatedFightingPartyMembers = Utils.GetTableIntersection(fightingPartyMembers, defeatedPartyMembers)
    return defeatedFightingPartyMembers
end

function DBUtils.GetPartySummonsInCombat(combatGuid)
    local fightingPartyMembers = DBUtils.GetActivePartyCombatants(combatGuid)
    local partySummons = DBUtils.ConvertDBTable(Osi.DB_PlayerSummons:Get(nil))
    local fightingPartySummons = Utils.GetTableIntersection(fightingPartyMembers, partySummons)
    return fightingPartySummons
end

function DBUtils.GetCriminalCombats()
    local criminalcombats = DBUtils.ConvertDBTable(Osi.DB_Crime_CombatID:Get(nil, nil), 2)
    return criminalcombats
end

function DBUtils.ConvertDBTable(dbtable, index)
    if not index then index = 1 end
    if dbtable == nil then
        return {}
    end

    local result = {}
    for i, entry in ipairs(dbtable) do
        result[i] = entry[index]
    end

    return result
end

return DBUtils