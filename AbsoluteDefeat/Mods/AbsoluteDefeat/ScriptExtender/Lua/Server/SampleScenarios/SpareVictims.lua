Spare = {}

function Spare.DefeatScenarioStarted(e)
    Spare.StartSpareScript(e.captors, e.victims)
end

function Spare.DefeatScenarioActionStarted(e)
    local status = e.status
    local victim = e.victim
    local captor = e.captor
    local defeatContext = e.defeatContext
end

function Spare.DefeatScenarioActionCompleted(e)
    local status = e.status
    local victim = e.victim
    local captor = e.captor
    local defeatContext = e.defeatContext
    -- end defeat
    if status == "AD_ACTION_CAPTOR_SPARE" then
        if Osi.IsInCombat(captor) == 0 then
            Spare.CleanUpDefeat(defeatContext)
            Spare.KickOutVictims(defeatContext.victims)
        else
            Spare.CleanUpDefeat(defeatContext)
        end
    end
end

-- spare defeated party logic
function Spare.StartSpareScript(captors, victims)
    local mainPerp = captors[math.random(#captors)]
    local mainVictim = victims[math.random(#victims)]
    for i, captor in ipairs(captors) do
        if captor ~= mainPerp then
            Osi.ApplyStatus(captor, "AD_ACTION_CAPTOR_BYSTANDER", -1, 1, victims[math.random(#victims)])
        end
    end

    Osi.ApplyStatus(mainPerp, "AD_ACTION_CAPTOR_SPARE", -1, 1, mainVictim)
end

function Spare.KickOutVictims(victims)
    for index, victim in ipairs(victims) do
        Utils.Fade(victim, 5.0)
        Osi.PROC_WaypointTeleportTo(victim, Waypoints[Utils.GetCurrentLevel()][1])
    end
end

function Spare.CleanUpDefeat(defeatContext)
    Utils.Debug("CLEANING UP DEFEAT SCENARIO [" .. defeatContext.scenarioId .. "] FOR COMBAT: " .. defeatContext.combatGuid)
    local partyVictims = defeatContext.victims
    local captors = defeatContext.captors

    for index, captor in ipairs(captors) do
        Osi.RemoveStatus(captor, "AD_ACTION_CAPTOR_BYSTANDER")
        Osi.RemoveStatus(captor, "AD_ACTION_CAPTOR_SPARE")
        Osi.RemoveStatus(captor, "AD_ACTION_CAPTOR_KNOCKOUT")
    end

    for index, victim in ipairs(partyVictims) do
        Osi.RemoveStatus(victim, "DOWNED")
        Osi.RemoveStatus(victim, "AD_DEFEATED")
    end
    AD.CleanUpDefeat(defeatContext.combatGuid)
end

return Spare