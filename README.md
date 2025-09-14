# Absolute Defeat
Nexus page: https://www.nexusmods.com/baldursgate3/mods/18573
Absolute Defeat provides players with alternative outcomes after being defeated in a combat encounter. Encourages continuous gameplay.

## Features

Absolute Defeat has two main gameplay mechanics, "Defeated State" and "Defeat Scenarios".

#### Defeated State

During combat, when all participating party members are downed, instead of receiving a game over and being asked to reload, your party enters a Defeated State, which functions similarly to the Stabilized Downed Condition. If combat ends while your party is in a Defeated State, a post-combat "Defeat Scenario" is randomly chosen and played. Note that game overs triggered by other means, such as dialog choices, remain unaffected by this mod.

#### Defeat Scenarios

Defeat Scenarios are possible outcomes that occur when a combat encounter has concluded and all participating party members are in a defeated state. Depending on the combat outcome, a different scenario plays out.

Allied Victory
- An ally runs over to help up a defeated party member

Neutral Victory
- The party members' defeated state expires after a few seconds

Enemy Victory
- An enemy defeat scenario is randomly chosen (note: mod authors can override the random selection)


Currently Absolute Defeat natively supports two enemy defeat scenarios.

#### Framework

Absolute Defeat supports an API and Mod Events that allow mod authors to create their own enemy defeat scenarios, which become accessible in the configuration menu.

## Installation

Download the .zip file and install using BG3MM or manually extract to your mods folder.

## Recommended Mod Management Tools
- [Laughing Leader's Mod Manager](https://github.com/LaughingLeader/BG3ModManager)

## Requirements

- [Mod Configuration Menu 1.33+](https://www.nexusmods.com/baldursgate3/mods/9162)
- BG3 Script Extender v24+ (easily installed with BG3MM through its Tools tab)
- AbsoluteDefeat Resources - Used for displaying the overhead dialog options during the sample defeat scenarios. Without it, the npcs would stay silent during the default defeat scenarios.

## Compatability
- Can be installed or uninstalled at any time

## For Modders
See the [WIKI](https://github.com/tripulah/BG3AbsoluteDefeat/wiki)

Absolute Defeat supports an API and Mod Events that allow mod authors to create their own enemy
defeat scenarios, which become accessible in the configuration menu.
A sample mod that creates a custom defeat scenario can be found [here]
