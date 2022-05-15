--[[
    If you use extendedmode or esx legacy WITHOUT multicharacter enabled,
    make sure you modify spawnmanager in:
    resources/[managers]/spawnmanager/spawnmanager.lua

    Delete this part (around line 309):

        if IsScreenFadedOut() then
            DoScreenFadeIn(500)

            while not IsScreenFadedIn() do
                Citizen.Wait(0)
            end
        end


    If you use esx legacy WITH multicharacter enabled and want to use EnterCityAnimation below,
    make sure you modify esx_multicharacter/client/main.lua

    Delete this part, in  (around line 272):

        DoScreenFadeIn(400)

    If you don't do it, you will experience a screen flicker glitch on character spawn after loading screen.
--]]

Config = {}

--[[ 
    This enables/disables the post-loading animation where camera starts in the clouds, 
    above the city like when switching characters in GTA V Story Mode.
--]]
Config.EnterCityAnimation = true

-- Setting these to false will enable all colors available in the game.
Config.UseNaturalHairColors = true
Config.UseNaturalEyeColors = true

-- Map Locations
Config.EnableClothingShops = true
Config.ClothingShops = {
    vector3(72.3, -1399.1, 28.4),
    vector3(-703.8, -152.3, 36.4),
    vector3(-167.9, -299.0, 38.7),
    vector3(428.7, -800.1, 28.5),
    vector3(-829.4, -1073.7, 10.3),
    vector3(-1447.8, -242.5, 48.8),
    vector3(11.6, 6514.2, 30.9),
    vector3(123.6, -219.4, 53.6),
    vector3(1696.3, 4829.3, 41.1),
    vector3(618.1, 2759.6, 41.1),
    vector3(1190.6, 2713.4, 37.2),
    vector3(-1193.4, -772.3, 16.3),
    vector3(-3172.5, 1048.1, 19.9),
    vector3(-1108.4, 2708.9, 18.1)
}

Config.EnableBarberShops = true
Config.BarberShops = {
    vector3(-814.3, -183.8, 36.6),
    vector3(136.8, -1708.4, 28.3),
    vector3(-1282.6, -1116.8, 6.0),
    vector3(1931.5, 3729.7, 31.8),
    vector3(1212.8, -472.9, 65.2),
    vector3(-32.9, -152.3, 56.1),
    vector3(-278.1, 6228.5, 30.7)
}

--[[ 
    Hospital and City Hall coordinates are all outside, 
    because those buildings don't have interiors by default. 
    They should be replaced with proper interior coordinates.
--]]
Config.EnablePlasticSurgeryUnits = true
Config.PlasticSurgeryUnits = {
    vector3(338.8, -1394.5, 31.5),      -- Central Los Santos Medical Center
    -- vector3(240.2, -1380.0, 33.7),   -- Los Santos General Hospital (Coroner)
    -- vector3(1152.2, -1528.0, 34.8),  -- St Fiacre Hospital for East Los Santos
    vector3(-874.7, -307.5, 38.5),      -- Portola Trinity Medical Center
    vector3(-676.7, 311.5, 82.5),       -- Eclipse Medical Tower
    vector3(-449.8, -341.0, 33.7),      -- Mount Zonah Medical Center
    vector3(298.7, -584.6, 42.2),       -- Pillbox Hill Medical Center
    -- vector3(1839.5, 3672.5, 33.2),   -- Sandy Shores Medical Center
    -- vector3(-246.9, 6330.5, 31.4)    -- The Bay Care Center (Paleto)
}

Config.EnableNewIdentityProviders = true
Config.NewIdentityProviders = {
    -- vector3(233.2, -410.1, 47.3),    -- Los Santos City Hall
    vector3(-544.9, -204.4, 37.5),      -- Rockford Hills City Hall
    -- vector3(328.5, -1581.8, 31.9),   -- Davis City Hall
    -- vector3(-1283.4, -565.1, 31.0)   -- Del Perro City Hall
}

--[[    To setup esx_identity integration, edit esx_identity/client/main.lua:

        Delete or comment out this block of code (around line 38):

            RegisterNetEvent('esx_identity:showRegisterIdentity')
            AddEventHandler('esx_identity:showRegisterIdentity', function()
                TriggerEvent('esx_skin:resetFirstSpawn')
                if not isDead then
                    EnableGui(true)
                end
            end)
]]--
Config.EnableESXIdentityIntegration = true

if Config.EnableESXIdentityIntegration then
    -- To avoid errors, make sure these equal the respective values in your in esx_identity config
    Config.MaxNameLength    = 16
    Config.MinHeight        = 48
    Config.MaxHeight        = 96
    Config.LowestYear       = 1900
    Config.HighestYear      = 2020
end

Config.ExtendedMode = false
Config.UseSteamID = false

--[[
    This is for servers without the ESX framework. 

    If you wish to use this for a standalone server, enable this and MAKE SURE YOU MODIFY fxmanifest.lua:

    Delete this part (around line 5):
    '@es_extended/locale.lua'

    And delete this part (around line 51):

        dependencies {
            'es_extended'
        }

    If you don't do it, you will receive an error when launching your server.
--]]
Config.StandAlone = false
if Config.StandAlone then
    Config.ExtendedMode = false
    Config.EnableESXIdentityIntegration = false
    Config.EnableNewIdentityProviders = false
end

Config.UseLocalClothingJSON = true -- true: Load from local files (faster, maybe out of date) | false: load from github (slower, maybe newer)

Config.DefaultClothingLocalPath = 'clothingnames/' -- Path where the clothing json files are located
Config.DefaultClothingUrlBase = 'https://raw.githubusercontent.com/root-cause/v-clothingnames/master/' -- Base path to root-causes clothing repo. Don't touch this.

Config.DefaultClothing = { -- Default clothings. Don't touch, unless you know what you're doing.
    components = {
        male = {
            [11]    = 'male_tops.json', -- 11
            [8]     = 'male_undershirts.json', -- 8
            [4]     = 'male_legs.json', -- 4
            [6]     = 'male_shoes.json', -- 6
            [1]     = 'masks.json', -- 1
            [7]     = 'male_accessories.json', -- 7
            [3]     = 'male_torsos.json', -- 3
        },
        female = {
            [11]    = 'female_tops.json', -- 11
            [8]     = 'female_undershirts.json', -- 8
            [4]     = 'female_legs.json', -- 4
            [6]     = 'female_shoes.json', -- 6
            [1]     = 'masks.json', -- 1
            [7]     = 'female_accessories.json', -- 7
            [3]     = 'female_torsos.json', -- 3
        }
    },
    props = {
        male = {
            [0]     = 'props_male_hats.json', -- 0
            [2]     = 'props_male_ears.json', -- 2
            [1]     = 'props_male_glasses.json', -- 1
            [6]     = 'props_male_watches.json', -- 6
            [7]     = 'props_male_bracelets.json', -- 7
        },
        female = {
            [0]     = 'props_female_hats.json', -- 0
            [2]     = 'props_female_ears.json', -- 2
            [1]     = 'props_female_glasses.json', -- 1
            [6]     = 'props_female_watches.json', -- 6
            [7]     = 'props_female_bracelets.json', -- 7
        }
    }
}