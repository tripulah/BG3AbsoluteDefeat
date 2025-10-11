DefaultScenario = {}

function DefaultScenario.DefeatScenarioStarted(e)
    Utils.Warn("Default Scenario was selected, attempting to teleport defeated players away.")
    local victims = e.victims
    -- if can flee do it, otherwise kill all victims (gameover)
    local endGameflag = true
    for _,v in pairs(victims) do
        if (Osi.DB_InDangerZone:Get(v,nil)[1] == nil) then
            Osi.QRY_CombatFlee_TryFleeToCamp(v)
            endGameflag = false
            Osi.ApplyStatus(v, "AD_DEFEATED_TEMP", 30, 1)
        end
    end

    if endGameflag then
        if not Osi.QRY_GameOver_AliveCharactersLeft() then
            Utils.Warn("Couldn't safely teleport defeated characters in a Default Defeat Scenario and all Players are defeated. Doing a gameover.")
            Osi.MusicPlayGeneral("Music_Game_Over");
            Osi.ShowGameOverMenu();
        end
    else
        AD.CleanUpDefeat(e.combatGuid)
    end
end

function DefaultScenario.DefeatScenarioForciblyEnded(e)
    AD.CleanUpDefeat(e.combatGuid)
end

return DefaultScenario