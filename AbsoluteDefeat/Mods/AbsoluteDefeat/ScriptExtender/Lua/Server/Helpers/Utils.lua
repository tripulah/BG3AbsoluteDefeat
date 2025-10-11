Utils = { }

function Utils.Contains(list, element)
    for _, value in ipairs(list) do
        if value == element then
            return true
        end
    end
    return false
end

function Utils.MCMGet(settingID)
    return Mods.BG3MCM.MCMAPI:GetSettingValue(settingID, ModuleUUID)
end

function Utils.Debug(text, debugLevel)
    if debugLevel == nil then
        debugLevel = 1
    end
    if Utils.MCMGet("debug_level") >= debugLevel then
        _P("AbsoluteDefeat: " .. text)
    end
end

function Utils.Error(text)
    Ext.Utils.PrintError("AbsoluteDefeat: [ERROR] " .. text)
end

function Utils.Warn(text)
    Ext.Utils.PrintWarning("AbsoluteDefeat: [WARN] " .. text)
end

function Utils.NilOrEmpty(thing)
    if thing == "" or thing == nil then
        return true
    end
    return false
end

function Utils.PercentToReal(pct)
    -- Ensure the input is within the valid range of 0 to 100
    if pct < 0 then
        return 0
    end
    
    if pct > 100 then
        return 100
    end
    -- Convert the integer to a real number between 0 and 1
    return pct / 100
end

---Delay a function call by the given time
---@param ms integer
---@param func function
function Utils.DelayedCall(ms, func)
    local Time = 0
    local handler
    handler = Ext.Events.Tick:Subscribe(function(e)
        Time = Time + e.Time.DeltaTime * 1000 -- Convert seconds to milliseconds

        if (Time >= ms) then
            func()
            Ext.Events.Tick:Unsubscribe(handler)
        end
    end)
end

function Utils.GetTags(object)
    local tags = {
        Tags = {},
        OsirisTags = {},
        TemplateTags = {},
    }
    local esvObject = Ext.Entity.Get(object)
    if object ~= nil then
        for _, tag in pairs(esvObject.Tag.Tags) do
            local tagData = Ext.StaticData.Get(tag, "Tag")
            if tagData ~= nil then
                tags.Tags[tagData.Name] = tag
            end
        end

        for _, tag in pairs(esvObject.ServerOsirisTag.Tags) do
            local tagData = Ext.StaticData.Get(tag, "Tag")
            if tagData ~= nil then
                tags.OsirisTags[tagData.Name] = tag
            end
        end

        for _, tag in pairs(esvObject.ServerTemplateTag.Tags) do
            local tagData = Ext.StaticData.Get(tag, "Tag")
            if tagData ~= nil then
                tags.TemplateTags[tagData.Name] = tag
            end
        end
    end

    return tags
end

function Utils.PrintTable(tbl, indent)
    if Utils.MCMGet("debug_level") == 0 then
        return
    end
    if not indent then indent = 0 end

    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "

        if type(v) == "table" then
            print(formatting)
            Utils.PrintTable(v, indent+1)
        else
            print(formatting .. tostring(v))
        end
    end
end

function Utils.ConvertDBTable(dbtable, index)
    if not index then index = 1 end
    if dbtable == nil then
        return {}
    end

    local result = {}
    for i, entry in ipairs(dbtable) do
        result[i] = entry[index]
    end

    return result
end

-- subtract t2 from t1 
function Utils.GetTableDifference(t1, t2)
    local lookup = {}
    for _, v in ipairs(t2) do
        lookup[v] = true
    end

    local result = {}
    for _, v in ipairs(t1) do
        if not lookup[v] then
            table.insert(result, v)
        end
    end

    return result
end

function Utils.GetTableIntersection(t1, t2)
    local lookup = {}
    for _, v in ipairs(t1) do
        lookup[v] = true
    end

    local result = {}
    for _, v in ipairs(t2) do
        if lookup[v] then
            table.insert(result, v)
        end
    end

    return result
end

function Utils.GetTableUnion(t1, t2)
    local result = {}
    local seen = {}

    -- Add all from t1
    for _, v in ipairs(t1) do
        if not seen[v] then
            table.insert(result, v)
            seen[v] = true
        end
    end

    -- Add all from t2
    for _, v in ipairs(t2) do
        if not seen[v] then
            table.insert(result, v)
            seen[v] = true
        end
    end

    return result
end

function Utils.Unique(t)
    local seen = {}
    local result = {}

    for _, value in ipairs(t) do
        if not seen[value] then
            seen[value] = true
            table.insert(result, value)
        end
    end

    return result
end

-- Add spell if actor doesn't have it yet
function Utils.TryAddSpell(actor, spellName)
    if  Osi.HasSpell(actor, spellName) == 0 then
        Utils.Debug("Added [" .. spellName .. "] to " .. actor)
        Osi.AddSpell(actor, spellName)
    end
end

function Utils.TryRemoveSpell(actor, spellName)
    if  Osi.HasSpell(actor, spellName) ~= 0 then
        Utils.Debug("Removed [" .. spellName .. "] to " .. actor)
        Osi.RemoveSpell(actor, spellName)
    end
end

function Utils.IsPlayable(uuid)
    return Osi.IsTagged(uuid, "PLAYABLE_25bf5042-5bf6-4360-8df8-ab107ccb0d37") == 1
end

function Utils.GetCurrentLevel()
    return Osi.DB_CurrentLevel:Get(nil)[1][1]
end

function Utils.GetFullGuid(uuid)
    local entity = Ext.Entity.Get(uuid)
    if entity ~= nil then
        local prefix = entity.ServerCharacter.OriginalTemplate.Name
        local full = string.format("%s_%s", prefix, uuid)
        return full
    end
    return nil
end

---@param uuid string
---@return boolean
function Utils.IsFactionOverriden(uuid)
    return Osi.HasActiveStatusWithGroup(uuid, 'SG_Possessed') == 1 or Osi.HasActiveStatusWithGroup(uuid, 'SG_Dominated') == 1 or Osi.HasActiveStatusWithGroup(uuid, 'SG_Mad') == 1
end

return Utils