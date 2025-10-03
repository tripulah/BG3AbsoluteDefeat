local handlers = {
    ["Executed"] = ExecutePlayers,
    ["DefaultScenario"] = DefaultScenario
}


Ext.ModEvents.AbsoluteDefeat.DefeatScenarioStarted:Subscribe(function (e)
    Utils.Debug("[AbsoluteDefeat][Events] DefeatScenarioStarted received with PayLoad: ")
    Utils.PrintTable(e)

    if e.timeOut ~= nil then
        Utils.Debug("Expiring defeat in " .. e.timeOut .. " seconds.")
        Osi.ApplyStatus(e.victims[1], "AD_EXPIRE_DEFEAT_TIMER", e.timeOut, 100)
    end

    if handlers[e.scenarioId] ~= nil then
        handlers[e.scenarioId].DefeatScenarioStarted(e)
    end
end)

Ext.ModEvents.AbsoluteDefeat.DefeatScenarioActionStarted:Subscribe(function (e)
    Utils.Debug("[AbsoluteDefeat][Events] Action Status Applied: " .. e.status)
    if handlers[e.scenarioId] ~= nil then
        handlers[e.scenarioId].DefeatScenarioActionStarted(e)
    end
end)

Ext.ModEvents.AbsoluteDefeat.DefeatScenarioActionCompleted:Subscribe(function (e)
    Utils.Debug("[AbsoluteDefeat][Events] Action Status Removed: " .. e.status)
    if handlers[e.scenarioId] ~= nil then
        handlers[e.scenarioId].DefeatScenarioActionCompleted(e)
    end
end)

Ext.ModEvents.AbsoluteDefeat.DefeatScenarioActionCompleted:Subscribe(function (e)
    Utils.Debug("[AbsoluteDefeat][Events] Action Status Removed: " .. e.status)
    if handlers[e.scenarioId] ~= nil then
        handlers[e.scenarioId].DefeatScenarioActionCompleted(e)
    end
end)

Ext.ModEvents.AbsoluteDefeat.DefeatScenarioForciblyEnded:Subscribe(function (e)
    _P("[AbsoluteDefeat][Events] DefeatScenarioForciblyEnded")
    if handlers[e.scenarioId] ~= nil then
        handlers[e.scenarioId].DefeatScenarioForciblyEnded(e)
    end

    if Utils.NilOrEmpty(e.scenarioId) then
        AD.CleanUpDefeat(e.combatGuid)
    end
end)