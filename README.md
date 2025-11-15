# Endless Night

This mod allows you to start an endless run. If it is enabled, you will be transported into the other route (Underworld/Surface) after each successful route clear. Afterwards, all enemies get healthier and biomes get shorter. Also, one more Olympian God can appear. This continues until every Olympian can appear, which marks the beginning of your last route.

This means that there will be 6 routes in total and your endless run will end on the route you did NOT choose when leaving the crossroads. Keep this in mind especially if you did not finish the story yet, as the story will progress only once per endless run in the ending route (Surface if you chose Underworld, Underworld if you chose Surface).

When you start a new run with this mod enabled, you should hear Nyx saying "My will be done".

## Installation

Install this mod using r2modman from Thunderstore. Details can be found [here](https://github.com/ebkr/r2modmanPlus?tab=readme-ov-file#first-time-installing).

## Configuration

**NOTE**: When using Hell2Modding, the configuration file is located in the ReturnOfModding/config folder of your r2modman data folder under the name Siuhnexus-EndlessNight.cfg.

The mod comes with a config.lua file that allows you to change certain settings. The following settings are available:

- `enabled`: Set to `true` to enable the mod, set to `false` to disable the mod. Default: `true`.
- `loglevel`: Prints out all message types up to this value. The different types are `1` (Error), `2` (Warning), `3` (Success), `4` (Info). Default: 2 (prints errors and warnings).

## Known issues

- Sometimes the background music of the wrong biome is playing, or the music stops altogether
- After entering a Chaos door in Ephyra, you can be offered a door to a room otherwise only reachable through the Ephyra hub room (does not cause crashes)

## Roadmap

- Balance certain boons (e. g. Chant offered by Chaos) for endless runs
- Increase amount of hex upgrades to benefit more from Paths of Stars in endless runs
- Put endless runs into the pitch-black stone and add different configurations (only one route, stronger enemy scaling, etc.)

## I found a bug or my game crashed, what do I do?
Please create an issue ([click here](https://github.com/Siuhnexus/EndlessNight/issues/new)) with the following details:
- A detailed and clear description of what you were doing and what exactly happened.
- Any steps to reproduce the bug/crash, if possible.
- (Optional, but very helpful) A video showing the bug, if possible.
- The `LogOutput.log` file located at `C:\Program Files (x86)\Steam\steamapps\common\Hades II\Ship\ReturnOfModding` (I am unsure of the location on other operating systems)