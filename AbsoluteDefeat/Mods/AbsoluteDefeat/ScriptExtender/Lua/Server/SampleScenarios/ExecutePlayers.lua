ExecutePlayers = {}

function ExecutePlayers.DefeatScenarioStarted(e)
    local victims = e.victims
    for _,victim in pairs(victims) do
        Osi.RemoveStatus(victim, "DOWNED")
        Osi.Die(victim)
    end
end

return ExecutePlayers