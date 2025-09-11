SubscribedEvents = {}

function SubscribedEvents.SubscribeToEvents()
    local function conditionalWrapper(handler)
        return function(...)
            if Utils.MCMGet("mod_enabled") then
                handler(...)
            else
                Utils.Debug("Event handling is disabled.", 2)
            end
        end
    end

    Ext.Osiris.RegisterListener("CombatStarted", 1, "after", conditionalWrapper(AD.CombatStarted))
    Ext.Osiris.RegisterListener("CombatEnded", 1, "after", conditionalWrapper(AD.CombatEnded))
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", conditionalWrapper(AD.StatusApplied))
    Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", conditionalWrapper(AD.StatusRemoved))
    Ext.Osiris.RegisterListener("LeftCombat", 2, "after", conditionalWrapper(AD.LeftCombat))
    Ext.Osiris.RegisterListener("FleeFromCombat", 2, "after", conditionalWrapper(AD.FleeFromCombat))
    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", conditionalWrapper(AD.LevelGameplayStarted))
end

return SubscribedEvents