UI = {}
UI.LoadedScenarios = false
UI.Scenarios = {}

function AddScenarioTab(modScenarios)
    --print("[CLIENT] Making Scenario Tab")
    --_D(modScenarios)

    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Scenarios", function(tabHeader)
        for _, scenario in pairs(modScenarios) do
            -- parent, id, text, tooltip, min, max, step, default, icon
            CreateIntSliderWidget(tabHeader, scenario.Id, scenario.NameHandle, scenario.NameHandle, 0, 100, 1, scenario.Weight, "")
        end
    end)
end

local function loadScenarios(scenarios)
    --print("STATUS: ", UI.LoadedScenarios)
    if not UI.LoadedScenarios then
        AddScenarioTab(scenarios)
        UI.LoadedScenarios = true
    end
end

Ext.RegisterNetListener("AbsoluteDefeat_ScenariosLoaded", function(channel, payload)
    --print("[CLIENT] load scenerio event received")
    UI.Scenarios = Ext.Json.Parse(payload)
    loadScenarios(UI.Scenarios)
end)

return UI