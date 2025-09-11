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

-- Function to deep iterate through the inventory and store items in a table, with depth limit
function Utils.DeepIterateInventory(container, itemList, depth)
    -- Initialize itemList and depth if they are not provided
    itemList = itemList or {}
    depth = depth or 0

    -- Check if the depth limit is reached
    if depth > 4 then
        return itemList
    end

    local entity = Ext.Entity.Get(container)
    if not entity or not entity.InventoryOwner then
        return itemList
    end

    local primaryInventory = entity.InventoryOwner.PrimaryInventory
    if not primaryInventory or not primaryInventory.InventoryContainer then
        return itemList
    end

    for _, item in pairs(primaryInventory.InventoryContainer.Items) do
        local uuid = item.Item.Uuid.EntityUuid
        local _, totalAmount = Osi.GetStackAmount(uuid)
        local root = string.sub(Osi.GetTemplate(uuid), -36)
        local itemEntity = Ext.Entity.Get(uuid)
        local rarity = itemEntity and itemEntity.Value and itemEntity.Value.Rarity or 0
        local isStoryItem = itemEntity and itemEntity.ServerItem and itemEntity.ServerItem.StoryItem and 1 or 0
        local name = itemEntity and itemEntity.ServerItem and itemEntity.ServerItem.Stats
        local isContainer = Osi.IsContainer(uuid)
        
        -- Create a list of key info pairs for the item
        local itemInfo = {
            Owner = container,
			Object = name,
            Uuid = uuid,
            Amount = totalAmount,
            Root = root,
            Rarity = rarity,
            IsStoryItem = isStoryItem,
            IsContainer = isContainer
        }

        -- Add the item info to the itemList table
        table.insert(itemList, itemInfo)

        -- If the item is a container, call the function recursively with incremented depth
        if isContainer == 1 then
            Utils.DeepIterateInventory(uuid, itemList, depth + 1)
        end
    end

    -- Return the table with all items
    return itemList
end

function Utils.GetEquippedGearSlots(character)
    local slots = {"Helmet", "Gloves", "Boots", "Cloak", "Breast", "Ring", "Amulet", "Ring", "Ring2"}
    local equippedGearSlots = {}
    for i = 1, #slots do
        local gearPiece = Osi.GetEquippedItem(character, slots[i]);
        if gearPiece ~= nil then
            table.insert(equippedGearSlots, slots[i])
        end
    end
    return equippedGearSlots
end

function Utils.UnequipGearSlot(character, slot, forceUnlock)
    local gearPiece = Osi.GetEquippedItem(character, slot);
    if gearPiece ~= nil then
        if forceUnlock then
            Osi.LockUnequip(gearPiece, 0)
        end
        Osi.Unequip(character, gearPiece)
    end

    return gearPiece
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

-- Cancels a screen fadeout
---@param entity    string  - The affected entities UUID
local function clearFade(entity)
    Osi.ClearScreenFade(entity, 0.1, "ScreenFade", 0)
end

function Utils.IsPlayable(uuid)
    return Osi.IsTagged(uuid, "PLAYABLE_25bf5042-5bf6-4360-8df8-ab107ccb0d37") == 1
end

function Utils.GetCurrentLevel()
    return Osi.DB_CurrentLevel:Get(nil)[1][1]
end

-- Fades the screen black (e.g. during Setup of a Scene)
---@param entity    string  - The affected entities UUID
---@param duration  number    - The time the fade is active
function Utils.Fade(entity, duration)
    if not duration then duration = 3.0 end
    if Utils.IsPlayable(entity) then
        Osi.ScreenFadeTo(entity, 0.1, 0.1, "ScreenFade")
        Ext.Timer.WaitFor(duration, function()
            clearFade(entity)
        end)
    end
end

return Utils