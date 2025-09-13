Api = {}

--- @param payload table Payload matching the parameters described above.
function Api.ImportScenarios(payload)
	Utils.Debug("Entering ImportScenario", 2)
	Utils.PrintTable(payload)
	if Ext.Mod.IsModLoaded(payload.ModGuid) then
		if payload.Scenarios then
			Utils.Debug("Importing Scenario")
			for _,scenario in pairs(payload.Scenarios) do
				if scenario.Situational then
					AD.SituationalScenarios[scenario.Id] = scenario
				else
					AD.Scenarios[scenario.Id] = scenario
				end
			end
		end

		if payload.CustomDownedStatusList then
			for downedStatus in pairs(payload.CustomDownedStatusList) do
				DownedStatuses[downedStatus] = true
			end
		end
	end
end

return Api