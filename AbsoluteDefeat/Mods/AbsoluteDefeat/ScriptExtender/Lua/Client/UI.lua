UI = {}
UI.LoadedScenarios = false
UI.Scenarios = {}

function AddScenarioTab(modScenarios)
    print("[CLIENT] Making Scenario Tab")
    -- collect keys
    local keys = {}
    for k in pairs(modScenarios) do
        table.insert(keys, k)
    end

    -- sort keys alphabetically
    table.sort(keys)

    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Scenarios", function(tabHeader)
        for _, key in ipairs(keys) do
            local scenario = modScenarios[key]
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
    print("[CLIENT] load scenerio event received")
    UI.Scenarios = Ext.Json.Parse(payload)
    table.sort(UI.Scenarios)
    loadScenarios(UI.Scenarios)
end)

local function AD_AttemptSoftlockFix()
    if not Ext or not Ext.Net then
        Ext.Print.Error("Ext, Ext.Net are not available.")
        return
    end

    Ext.Net.PostMessageToServer("AD_AttemptSoftlockFix", "")
end

local function AD_Surrender()
    if not Ext or not Ext.Net then
        Ext.Print.Error("Ext, Ext.Net are not available.")
        return
    end

    Ext.Net.PostMessageToServer("AD_Surrender", "")
end

-- Register event button callbacks
if MCM.EventButton and MCM.EventButton.RegisterCallback then
    MCM.EventButton.RegisterCallback("btn_softlockfix", function()
        AD_AttemptSoftlockFix()
    end)

    MCM.EventButton.RegisterCallback("btn_surrender", function()
        AD_Surrender()
    end)
end



return UI