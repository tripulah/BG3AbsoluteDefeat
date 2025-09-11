function IconSize()
	local icon_size = Ext.IMGUI.GetViewportSize()[2] * 0.025 + 0.055
	return {icon_size, icon_size}
end
function Tr(text)
	return Ext.Loca.GetTranslatedString(text)
end

function Tooltip(tooltip, format_string, args)
	if tooltip and tooltip ~= "" then
		return Tr(tooltip)
	end
	if type(args) ~= "table" then
		args = {args}
	end
	args = args or {}
	return string.format(Tr(format_string), table.unpack(args))
end

function CreateIntSlider(parent, id, settings, min, max, step, default, tooltip, event, same_line_start)
	local prev_button = parent:AddImageButton("", "input_slider_arrowL_d", IconSize())
	prev_button.IDContext = ModuleUUID .. id .. "PrevButton"
	prev_button.SameLine = same_line_start == true
	prev_button:Tooltip():AddText(Tooltip("", "DecreaseValueBy", step))
	local slider = parent:AddSliderInt("", default, min, max)
	slider.SameLine = true
	slider.IDContext = ModuleUUID .. id .. "Slider"
	local next_button = parent:AddImageButton("", "input_slider_arrowR_d", IconSize())
	next_button.SameLine = true
	next_button.IDContext = ModuleUUID .. id .. "NextButton"
	next_button:Tooltip():AddText(Tooltip("", "IncreaseValueBy", step))
	local reset_button = parent:AddImageButton("", "ico_reset_d", IconSize())
	reset_button.SameLine = true
	reset_button.IDContext = ModuleUUID .. id .. "ResetButton"
	reset_button:Tooltip():AddText(Tooltip("", "ResetValueToDefault", default))

	prev_button.OnClick = function()
		slider.Value = { slider.Value[1] - 1, slider.Value[2], slider.Value[3], slider.Value[4]}
		UpdateSlider(settings, slider.Value[1])
	end
	slider.OnChange = function(value)
		--Mods.BG3MCM.IMGUIAPI:SetSettingValue(settings, value.Value[1], ModuleUUID)
        UpdateSlider(settings, slider.Value[1])
	end
	next_button.OnClick = function()
		slider.Value = { slider.Value[1] + 1, slider.Value[2], slider.Value[3], slider.Value[4]}
		UpdateSlider(settings, slider.Value[1])
	end
	reset_button.OnClick = function()
		slider.Value = {default, min, max, 0}
		UpdateSlider(settings, default)
	end
end

function CreateText(parent, id, text, tooltip, icon)
	if icon and icon ~= "" then
		local image = parent:AddImage(icon, IconSize())
		image.IDContext = ModuleUUID .. id .. "Image"
	end
	local title = parent:AddText(Tr(text))
	title.IDContext = ModuleUUID .. id .. "Text"
	title.SameLine = icon and icon ~= ""
	if tooltip and tooltip ~= "" then
		title:Tooltip():AddText(Tr(tooltip))
	end
end

function CreateIntSliderWidget(parent, id, text, tooltip, min, max, step, default, icon)
	CreateText(parent, id, text, "", icon)
	CreateIntSlider(parent, id, id, min, max, step, default, Tooltip(tooltip, "SetsValueFor", Tr(text)), id .. "PostMessage", false)
end

function UpdateSlider(id, weight)
    Ext.Net.PostMessageToServer("AbsoluteDefeat_Update_Slider", Ext.Json.Stringify({
        ModUUID = Globals.ModUUID,
        Weight = weight,
        Id = id
    }))
end

function MCMGet(settingID)
    return Mods.BG3MCM.MCMAPI:GetSettingValue(settingID, ModuleUUID)
end