# LostJ3ster's fork of PainedPsyche's cui_character
## Changes
In this fork I changed the way to load clothing data.
By default PainedPsyche loads the data from GTA itself. Due to an updated Native that does not work anymore.
This fork includes a workaround to
 a) load the clothing data from local files (clothingnames/*.json) (default)
 b) load the clothing data from [root-cause's v-clothingnames repository](https://github.com/root-cause/v-clothingnames)

Loading the clothing data from local files will reduce the load time a lot, which was requested by [Ciwiel on the cfx forum](https://forum.cfx.re/t/release-cleanui-cui-character/1914841/899)

To change loading style, change Config.UseLocalClothingJSON to false, which will cause the data to be pulled from github, every time the menu opens. 

# CleanUI (cui) character
An advanced character and clothes editor that aims to be comfortable to use, hide complexity and blend in with original GTA V interface elements.

## Character Customization Features
I tried to cover every feature that GTA Online character creator offers, notably:

* Heritage (parent face and skin color blending) working exactly like the one made by Rockstar
* Property names displayed whenever possible instead of raw numbers

I have made improvements in places where I thought Rockstar's creator didn't do a particularly good job:

* Properties are grouped in a more intuitive way
* "2D grids" have been replaced with sliders
* Percentage values are clearly displayed

## Additional features

* Flexible camera that can be zoomed and rotated with mouse as well as switched between `face`, `body` and `legs` views
* Native, in-game sound effects
* Optional (configurable) map locations where characters can be customzied after creation (barber shops, hospital plastic surgery units, clothes shops)
* Optional esx_identity integration (disabled by default, check instructions in config.lua to enable)
* Optional clothes component/prop blacklisting (uncomment `client/blacklist.lua` in fxmanifest client_scripts, then edit the file)

## Requirements and usage notes
**I intended this to be fully functional resource with minimal configuration. Editing and saving characters to the database *should* work out-of-the-box.**

Thanks to [SaltyGrandpa](https://github.com/SaltyGrandpa) you can now use this resource standalone, without esx framework. To do so, follow his instructions in `shared/config.lua`.

In order to use this resource with esx, you need:
legacy version of [es_extended](https://github.com/esx-framework/es_extended/tree/v1-final) **OR**
[extendedmode](https://github.com/extendedmode/extendedmode)

Usage with `extendedmode` requires additional configuration (explained in shared/config.lua)

In addition, the `skin data column` that esx_skin uses is required (SQL file included).
It will most likely conflict with esx_skin as it labels and uses some data in exact same way.

Optional integration with [esx_identity](https://github.com/esx-framework/esx_identity) is possible.
Optional features can be configured editing `config.lua` file.

Admins can use `/identity`, `/features`, `/style`, `/apparel` commands to open respective tabs or `/character` to open full character customization anywhere.

## Simplest possible installation guide

If you are able to install and configure esx, you should have no problem using this resource, but in case you do, here's a very simple step-by-step guide:

1. Click the `Code` button on the github page and select `Download Zip`.
2. Save the file to your disk, extract it and rename `cui_character-master` folder to `cui_character`.
3. Put that folder in your server's resources.
4. Make sure you have `skin` column in your database's `users` table. If you don't, run the included `esx_skin.sql` file.
5. Open your server.cfg and add `start cui_character` somewhere under `start es_extended`.
6. If you wish to use esx_identity integration, make sure that is installed, configured and started as well and before this resource (it's not in dependencies, so won't be auto-started).

## Known Issues

### Clothes selection
Clothes customization is sort-of experimental. It relies on pulling entire data set from the game using natives and filtering them to only those that Rockstar gave names. This seems to result in a more limited selection as well as a noticable loading time when building the html dynamically.

I would be grateful if someone could point out a way to do it better. Preferably one that does not involve including and parsing custom, several megabytes large data files.

Gloves have been omitted entirely from the clothes selection, they are really messy and I have not found a way to automatically match them with other currently selected components. It would require an arduous, manual approach to get them in now.