SubscribedEvents = {}

RequireFiles("Server/", {
    "Helpers/_Init",
    "AD",
    "Data/_Init",
    "Api/_Init",
    "SubscribedEvents",
    "SampleScenarios/_Init"
})


SubscribedEvents.SubscribeToEvents()