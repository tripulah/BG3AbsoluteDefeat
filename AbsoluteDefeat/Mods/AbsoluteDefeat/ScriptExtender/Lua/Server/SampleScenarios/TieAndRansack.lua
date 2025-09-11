TieAndRansack = {}

function TieAndRansack.DefeatScenarioStarted(e)
    TieAndRansack.StartRansackScript(e.captors, e.victims)
end

function TieAndRansack.DefeatScenarioActionStarted(e)
    local status = e.status
    local victim = e.victim
    local captor = e.captor
    local defeatContext = e.defeatContext
end

function TieAndRansack.DefeatScenarioActionCompleted(e)
    local status = e.status
    local victim = e.victim
    local captor = e.captor
    local defeatContext = e.defeatContext
    
    -- after tie, do a new action that loots the victim's items
    if status == "AD_ACTION_CAPTOR_TIE" then
        Osi.ApplyStatus(captor, "AD_ACTION_CAPTOR_LOOT", 30, 1, victim)
    end
    -- after looting, do a new action that kicks them to a waypoint, ending the defeat scenario
    if status == "AD_ACTION_CAPTOR_LOOT" then
        Osi.ApplyStatus(captor, "AD_ACTION_CAPTOR_KNOCKOUT", 12, 1, victim)
    end

    -- end defeat
    if status == "AD_ACTION_CAPTOR_KNOCKOUT" then
        if Osi.IsInCombat(captor) == 0 then
            TieAndRansack.CleanUpDefeat(defeatContext)
            TieAndRansack.KickOutVictims(defeatContext.victims)
        else
            TieAndRansack.CleanUpDefeat(defeatContext)
        end
    end
end

-- ransack defeated party logic
function TieAndRansack.StartRansackScript(captors, victims)
    local mainPerp = captors[math.random(#captors)]
    local mainVictim = victims[math.random(#victims)]
    for i, captor in ipairs(captors) do
        if captor ~= mainPerp then
            Osi.ApplyStatus(captor, "AD_ACTION_CAPTOR_BYSTANDER", -1, 1, victims[math.random(#victims)])
        end
    end

    Osi.ApplyStatus(mainPerp, "AD_ACTION_CAPTOR_TIE", -1, 1, mainVictim)
end

function TieAndRansack.KickOutVictims(victims)
    for index, victim in ipairs(victims) do
        Utils.Fade(victim, 5.0)
        Osi.PROC_WaypointTeleportTo(victim, Waypoints[Utils.GetCurrentLevel()][1])
    end
end

function TieAndRansack.CleanUpDefeat(defeatContext)
    Utils.Debug("CLEANING UP DEFEAT SCENARIO [" .. defeatContext.scenarioId .. "] FOR COMBAT: " .. defeatContext.combatGuid)

    local captors = defeatContext.captors
    local partyVictims = defeatContext.victims

    for index, captor in ipairs(captors) do
        Osi.RemoveStatus(captor, "AD_ACTION_CAPTOR_BYSTANDER")
        Osi.RemoveStatus(captor, "AD_ACTION_CAPTOR_LOOT")
        Osi.RemoveStatus(captor, "AD_ACTION_CAPTOR_TIE")
        Osi.RemoveStatus(captor, "AD_ACTION_CAPTOR_KNOCKOUT")
    end

    for index, victim in ipairs(partyVictims) do
        Osi.RemoveStatus(victim, "DOWNED")
        Osi.RemoveStatus(victim, "AD_DEFEATED")
        Osi.RemoveStatus(victim, "AD_RESTRAIN")
    end

    AD.CleanUpDefeat(defeatContext.combatGuid)
end

return TieAndRansack