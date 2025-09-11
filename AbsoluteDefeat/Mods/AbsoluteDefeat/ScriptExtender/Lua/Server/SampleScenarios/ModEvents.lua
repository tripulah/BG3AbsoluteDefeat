local handlers = {
    ["TieAndRansack_5d50854a-3d0a-42b2-926b-f9359416977c"] = TieAndRansack,
    ["Spare_5d50854a-3d0a-42b2-926b-f9359416977c"] = Spare
}

Ext.ModEvents.AbsoluteDefeat.DefeatScenarioStarted:Subscribe(function (e)
    Utils.Debug("[AbsoluteDefeat][Events] DefeatScenarioStarted received with PayLoad: ")
    Utils.PrintTable(e)
    --TieAndRansack.DefeatScenarioStarted(e)
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