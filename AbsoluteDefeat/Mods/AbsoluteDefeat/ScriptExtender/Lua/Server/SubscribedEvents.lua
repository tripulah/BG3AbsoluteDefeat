SubscribedEvents = {}

function SubscribedEvents.SubscribeToEvents()
    local function conditionalWrapper(handler)
        return function(...)
            handler(...)
        end
    end

    Ext.Osiris.RegisterListener("CombatStarted", 1, "after", conditionalWrapper(AD.CombatStarted))
    Ext.Osiris.RegisterListener("CombatEnded", 1, "after", conditionalWrapper(AD.CombatEnded))
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", conditionalWrapper(AD.StatusApplied))
    Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", conditionalWrapper(AD.StatusRemoved))
    Ext.Osiris.RegisterListener("LeftCombat", 2, "after", conditionalWrapper(AD.LeftCombat))
    Ext.Osiris.RegisterListener("FleeFromCombat", 2, "after", conditionalWrapper(AD.FleeFromCombat))
    Ext.Osiris.RegisterListener("DeathSaveStable", 1, "after", conditionalWrapper(AD.Stabilized))
    Ext.Osiris.RegisterListener("Died", 1, "after", conditionalWrapper(AD.Died))

    Ext.RegisterConsoleCommand("surrender", conditionalWrapper(AD.CmdSurrender))
    Ext.RegisterConsoleCommand("lastcombat", conditionalWrapper(AD.CmdGetLastCombat))
    Ext.RegisterConsoleCommand("undefeat", conditionalWrapper(AD.CmdUndefeat))
    Ext.RegisterConsoleCommand("force", conditionalWrapper(AD.CmdForceScenario))

    Ext.RegisterNetListener("AbsoluteDefeat_Update_Slider", function(channel, payload)
        Utils.Debug("Updating slider from client request: ", 2)
        local data = Ext.Json.Parse(payload)
        local uuid = data.ModUUID

        local mod = Ext.Mod.GetMod(uuid)
        if not Ext.Mod.IsModLoaded(uuid) then
            Utils.Error("Failed to update slider value, Mod was not loaded. [" .. data.ModUUID .. "]")
            Ext.Net.BroadcastMessage("AbsoluteDefeat_Update_Slider_Failed",
                Ext.Json.Stringify({ modUUID = data.ModUUID, error = "Mod is not loaded" }))
            return
        end

        local scenario = AD.Scenarios[data.Id]
        if scenario ~= nil then
            scenario.Weight = data.Weight
            UpdateConfigWeight(scenario.ModUUID, scenario.Id, scenario.Weight)
        else
            Utils.Error("Could not find Scenario: " .. data.Id)
        end
    end)

    Ext.ModEvents.BG3MCM["MCM_Mod_Tab_Activated"]:Subscribe(function(eventData)
        if eventData.modUUID == '755a8a72-407f-4f0d-9a33-274ac0f0b53d' then
            Utils.Debug("[SERVER] Tab activated", 2)
            LoadConfigFiles()
        end
    end)
end

return SubscribedEvents