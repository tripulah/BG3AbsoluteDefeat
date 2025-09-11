local configFilePathPattern = string.gsub("Mods/%s/ScriptExtender/AbsoluteDefeatConfig.json", "'", "\'")

local function ConvertToPayload(data, modGUID)
	Utils.Debug("Entering ConvertToPayload", 2)
	local payload = {
		ModGuid = modGUID,
		CustomDownedStatusList = {},
		Scenarios = {}
	}

	for _, customDownedStatus in ipairs(data.CustomDownedStatusList) do
		payload.CustomDownedStatusList[customDownedStatus] = true
	end

	for _, scenario in pairs(data.Scenarios) do
		payload.Scenarios[scenario.Id] = {
			Id = scenario.Id,
			ModUUID = modGUID,
			NameHandle = scenario.NameHandle,
			Tag = scenario.Tag,
			Weight = scenario.Weight,
			Situational = scenario.Situational,
		}
	end

	return payload
end

local function SubmitData(data, modGUID)
	Utils.Debug("Entering SubmitData", 2)
	Api.ImportScenarios(ConvertToPayload(data, modGUID))
end

---@param configStr string
---@param modGUID GUIDSTRING
local function TryLoadConfig(configStr, modGUID)
	Utils.Debug("Entering TryLoadConfig", 2)
	local success, data = pcall(function ()
			return Ext.Json.Parse(configStr)
		end)
	if success then
		if data ~= nil then
			SubmitData(data, modGUID)
		end
	else
		Utils.Error("Couldn't Parse AbsoluteDefeat JSON Configuration File from mod guid: " .. Ext.Mod.GetMod(modGUID).Info.Name)
	end
end

function LoadConfigFiles()
	Utils.Debug("Entering LoadConfigFiles", 2)
	for _, uuid in pairs(Ext.Mod.GetLoadOrder()) do
		local modData = Ext.Mod.GetMod(uuid)
		local filePath = configFilePathPattern:format(modData.Info.Directory)
		local config = Ext.IO.LoadFile(filePath)
		if config ~= nil and config ~= "" then
			Utils.Debug("Found config for Mod: " .. Ext.Mod.GetMod(uuid).Info.Name)
				local b, err = xpcall(TryLoadConfig, debug.traceback, config, uuid)
			if not b then
				Utils.Error(err)
			end
		end
	end

	Utils.Debug("Finished loading the scenarios, sending to client.")
	--Utils.PrintTable(AD.Scenarios)
	Ext.Net.BroadcastMessage("AbsoluteDefeat_ScenariosLoaded", Ext.Json.Stringify(AD.Scenarios))
end

--- Updates the weight of a scenario in the config JSON.
--- @param ModGUID string The GUID of the mod.
--- @param ScenarioId string The scenario Id to update.
--- @param Weight number The new weight value.
function UpdateConfigWeight(ModGUID, ScenarioId, Weight)
    -- Get mod info (for resolving file path)
    local modData = Ext.Mod.GetMod(ModGUID)
    local filePath = configFilePathPattern:format(modData.Info.Directory)

    -- Load the JSON file
    local jsonContent = Ext.IO.LoadFile(filePath)
    if not jsonContent then
        Utils.Error("Could not load config file at " .. filePath)
        return
    end

    local config = Ext.Json.Parse(jsonContent)
    if not config or not config.Scenarios then
        Utils.Error("Invalid config structure in " .. filePath)
        return
    end

    -- Find the scenario and update weight
    local updated = false
    for _, scenario in ipairs(config.Scenarios) do
        if scenario.Id == ScenarioId then
            scenario.Weight = Weight
            updated = true
            break
        end
    end

    if not updated then
        Utils.Error("Scenario " .. ScenarioId .. " not found in config.")
        return
    end

    -- Save back to file
    SaveJSONFile(filePath, config)
    Utils.Debug("Updated Weight for " .. ScenarioId .. " to " .. Weight)
end

--- Saves the given content to a JSON file.
--- @param filePath string The file path to save the content to.
--- @param content table The table with content to save to the file.
function SaveJSONFile(filePath, content)
    local fileContent = Ext.Json.Stringify(content, { Beautify = true })
    Ext.IO.SaveFile(filePath, fileContent)
    Utils.Debug("[SaveJSONFile] File saved to " .. filePath)
end

local function LoadConfig()
    -- hacky way of making the config appear in the AppSettings folder
    local modData = Ext.Mod.GetMod(ModuleUUID)
    local filePath = configFilePathPattern:format(modData.Info.Directory)
    local config = Ext.IO.LoadFile(filePath)
    if config == nil then
		Utils.Warn("Creating the AbsoluteDefeat config file.")
        config = Ext.IO.LoadFile(filePath, "data")
    end
    if config ~= nil then
        Ext.IO.SaveFile(filePath, config)
    end
end

LoadConfig()