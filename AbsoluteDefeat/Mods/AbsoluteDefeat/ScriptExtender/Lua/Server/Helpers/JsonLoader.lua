local authorConfigFilePathPattern = string.gsub("Mods/%s/ScriptExtender/AbsoluteDefeat.AuthorConfig.json", "'", "\'")
local playerConfigFilePathPattern = string.gsub("Mods/%s/ScriptExtender/AbsoluteDefeat.PlayerConfig.json", "'", "\'")

local function CreateAuthorConfigPayload(data, modGUID)
	Utils.Debug("Entering CreateAuthorConfigPayload", 2)
	local payload = {
		ModGuid = modGUID,
		Scenarios = {}
	}

	for _, scenario in pairs(data.Scenarios) do
		payload.Scenarios[scenario.Id] = {
			Id = scenario.Id,
			ModUUID = modGUID,
			NameHandle = scenario.NameHandle,
			Tag = scenario.Tag,
			Weight = scenario.Weight,
			TimeOut = scenario.TimeOut,
			Situational = scenario.Situational,
		}
	end

	-- override with player specific settings

	local playerConfig = TryLoadPlayerConfigForMod(modGUID)

	if playerConfig ~= nil then
		for id,scenario in pairs(playerConfig.Scenarios) do
			if payload.Scenarios[id] ~= nil then
				payload.Scenarios[id].Weight = scenario.Weight
			end
		end
	end

	return payload
end

local function SubmitData(data, modGUID)
	Utils.Debug("Entering SubmitData", 2)
	Api.ImportScenarios(CreateAuthorConfigPayload(data, modGUID))
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
		local filePath = authorConfigFilePathPattern:format(modData.Info.Directory)
		local config = Ext.IO.LoadFile(filePath, "data")
		if config ~= nil and config ~= "" then
			Utils.Debug("Found config for Mod: " .. Ext.Mod.GetMod(uuid).Info.Name)
				local b, err = xpcall(TryLoadConfig, debug.traceback, config, uuid)
			if not b then
				Utils.Error(err)
			end
		end
	end

	Utils.Debug("Finished loading the scenarios, sending to client.")
	Ext.Net.BroadcastMessage("AbsoluteDefeat_ScenariosLoaded", Ext.Json.Stringify(AD.Scenarios))
end

function TryLoadPlayerConfigForMod(modGuid)
	local modData = Ext.Mod.GetMod(modGuid)
	local filePath = playerConfigFilePathPattern:format(modData.Info.Directory)
	local jsonContent = Ext.IO.LoadFile(filePath)
	local config = Ext.Json.Parse(jsonContent)
	
    if not config or not config.Scenarios then
        Utils.Error("Invalid config structure in " .. filePath)
        return
    end
	return config
end

--- Updates the weight of a scenario in the config JSON.
--- @param ModGUID string The GUID of the mod.
--- @param ScenarioId string The scenario Id to update.
--- @param Weight number The new weight value.
function UpdateConfigWeight(ModGUID, ScenarioId, Weight)
    -- Get mod info (for resolving file path)
    local modData = Ext.Mod.GetMod(ModGUID)
    local filePath = playerConfigFilePathPattern:format(modData.Info.Directory)

    -- Load the JSON file
    local jsonContent = Ext.IO.LoadFile(filePath)
    if jsonContent == nil then
        RestorePlayerConfig()
    end

    local config = Ext.Json.Parse(jsonContent)
    if not config or not config.Scenarios then
        Utils.Error("Invalid config structure in " .. filePath)
        return
    end

    -- Find the scenario and update weight
    local updated = false
    for id, scenario in pairs(config.Scenarios) do
        if id == ScenarioId then
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

function CreatePlayerConfig(playerFilePath, authorFilePath)
	local authorContent = Ext.IO.LoadFile(authorFilePath, "data")
	if authorContent ~= nil then
		local authorConfig = Ext.Json.Parse(authorContent)
		if not authorConfig or not authorConfig.Scenarios then
			Utils.Error("Invalid config structure in " .. authorFilePath)
			return
		end

		local playerConfig = {
			FileVersion = authorConfig.FileVersion,
			ModGuid = ModuleUUID,
			Scenarios = {}
		}

		for _, scenario in pairs(authorConfig.Scenarios) do
			playerConfig.Scenarios[scenario.Id] = { Weight = scenario.Weight }
		end

		-- encode to JSON
		SaveJSONFile(playerFilePath, playerConfig)
	else
		Utils.Error("Could not find config file at: " .. authorFilePath)
	end
end


function TryLoadPlayerConfigForMod(modGuid)
	local modData = Ext.Mod.GetMod(modGuid)
	local filePath = playerConfigFilePathPattern:format(modData.Info.Directory)
	local jsonContent = Ext.IO.LoadFile(filePath)
	local config = Ext.Json.Parse(jsonContent)
	
    if not config or not config.Scenarios then
        Utils.Error("Invalid config structure in " .. filePath)
        return
    end
	return config
end

function RestorePlayerConfig()

	local modData = Ext.Mod.GetMod(ModuleUUID)

	local playerFilePath = playerConfigFilePathPattern:format(modData.Info.Directory)
	local authorFilePath = authorConfigFilePathPattern:format(modData.Info.Directory)
	local config = Ext.IO.LoadFile(playerFilePath)

	if config == nil then
		Utils.Warn("Could not find config file at: " .. playerFilePath .. " creating one.")
		CreatePlayerConfig(playerFilePath, authorFilePath)
		return
	end

	local content = Ext.Json.Parse(config)
	if not content or not content.Scenarios then
		Utils.Warn("Invalid Playerconfig, re-creating it at: " .. playerFilePath)
		CreatePlayerConfig(playerFilePath, authorFilePath)
		return
	end

	local authorContent = Ext.IO.LoadFile(authorFilePath, "data")
	local authorConfig = Ext.Json.Parse(authorContent)
	if authorConfig.FileVersion ~= content.FileVersion then
		Utils.Warn("FileVersion change detected, re-creating player config at: " .. playerFilePath)
		CreatePlayerConfig(playerFilePath, authorFilePath)
	end
end

--- Saves the given content to a JSON file.
--- @param filePath string The file path to save the content to.
--- @param content table The table with content to save to the file.
function SaveJSONFile(filePath, content)
    local fileContent = Ext.Json.Stringify(content, { Beautify = true })
    Ext.IO.SaveFile(filePath, fileContent)
    Utils.Debug("[SaveJSONFile] File saved to " .. filePath)
end

RestorePlayerConfig()