
Ext.ModEvents.AbsoluteDefeat.DefeatScenarioStarted:Subscribe(function (e)
    if e.scenarioId == "Executed" then
        Utils.Debug("[AbsoluteDefeat][Events] DefeatScenarioStarted received with PayLoad: ")
        Utils.PrintTable(e)
        
        
        StartExecuteScript(e.victims)
    end
end)

function StartExecuteScript(victims)
    for _,victim in pairs(victims) do
        Osi.Die(victim)
    end
end