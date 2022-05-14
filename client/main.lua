if not Config.StandAlone then
    if Config.ExtendedMode then
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    else
        ESX = exports['es_extended']:getSharedObject()
    end

    AddEventHandler('esx:setPlayerData', function(key, val, last)
        if GetInvokingResource() == 'es_extended' then
            ESX.PlayerData[key] = val
            if OnPlayerData ~= nil then OnPlayerData(key, val, last) end
        end
    end)
else
    ESX = nil
end

previewPed = nil
isInterfaceOpening = false
isModelLoaded = false

isPlayerReady = false
--[[    NOTE: (on player initialization)

        The way es_extended spawns player causes the ped to start a little above ground
        and 'fall down'. Since our camera position is based off of ped position, 
        if we open the ui too early during player's first login, the camera will be pointing 'too high'.

        Unfortunately, I did not find a way to detect when that fall is finished, so I decided
        to black out the screen and wait a few seconds (if the special animation is disabled).

        This ensures the player will not see that fall or the model being changed from es_extended default.
]]--
function PreparePlayer()
    if ESX.GetConfig().Multichar then
        isPlayerReady = true
        return
    end

    if Config.EnterCityAnimation then
        if not IsScreenFadedOut() then
            DoScreenFadeOut(0)
        end

        while not isModelLoaded do
            Citizen.Wait(0)
        end

        SwitchOutPlayer(PlayerPedId(), 0, 1)

        while GetPlayerSwitchState() ~= 5 do
            Citizen.Wait(0)
        end

        DoScreenFadeIn(500)
        while not IsScreenFadedIn() do
            Citizen.Wait(0)
        end

        SwitchInPlayer(PlayerPedId())

        while GetPlayerSwitchState() ~= 12 do
            Citizen.Wait(0)
        end
    else
        --TODO: Possibly use a more refined first login detection (event from server) if this does not cut it.
        if not IsScreenFadedOut() then
            DoScreenFadeOut(0)
        end
        Citizen.Wait(7500)
        DoScreenFadeIn(500)
    end

    isPlayerReady = true
end

if not Config.ExtendedMode and not Config.StandAlone then
    AddEventHandler('esx:loadingScreenOff', function()
        PreparePlayer()
    end)
else
    Citizen.CreateThread(function()
        while GetIsLoadingScreenActive() do
            Citizen.Wait(100)
        end
        PreparePlayer()
    end)
end

function IsPlayerFullyLoaded()
    return isPlayerReady
end

local initialized = false

local openTabs = {}
local currentTab = nil

local isVisible = false
local isCancelable = true

local playerLoaded = false
local firstSpawn = true
local identityLoaded = false
local preparingSkin = true
local isPlayerNew = false

local firstCharacter = false
local newCharacter = false

local currentChar = {}
local oldChar = {}
local oldLoadout = {}

local currentIdentity = nil

local isOnDuty = false
function SetOnDutyStatus(value)
    isOnDuty = value
end

function BeginCharacterPreview()
    -- Snapshot all changes data (to be reverted if cancelled)
    for k, v in pairs(currentChar) do
        oldChar[k] = v
    end

    local playerHeading = GetEntityHeading(PlayerPedId())
    previewPed = ClonePed(PlayerPedId(), false, false, true)

    SetEntityInvincible(previewPed, true)
    FreezePedCameraRotation(previewPed, true)
    FreezeEntityPosition(previewPed, true)
    PlayIdleAnimation(previewPed)
end

function EndCharacterPreview(save)
    -- This applies (or ignores) changes to current player ped based on value of 'save'
    if previewPed then
        if save then
            local newModelHash = GetHashKey('mp_m_freemode_01')
            if currentChar.sex == 1 then
                newModelHash = GetHashKey('mp_f_freemode_01')
            end

            -- Replace non-preview player model if gender change was accepted
            if GetEntityModel(PlayerPedId()) ~= newModelHash then
                LoadModel(newModelHash)
            end

            ClonePedToTarget(previewPed, PlayerPedId())
        else
            -- Revert all changes to data variables
            for k, v in pairs(oldChar) do
                currentChar[k] = v
            end
        end

        ClearAllAnimations(previewPed)
        DeleteEntity(previewPed)
        previewPed = nil
    end
end

function setVisible(visible)
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        action = 'setVisible',
        show = visible
    })
    isVisible = visible
    DisplayRadar(not visible)
end

function ResetAllTabs()
    local clothes = nil
    for k, v in pairs(openTabs) do
        if openTabs[k] == 'apparel' then
            clothes = GetClothesData()
        end
    end

    SendNUIMessage({
        action = 'enableTabs',
        tabs = openTabs,
        character = currentChar,
        clothes = clothes,
        identity = currentIdentity
    })
end

function GetLoadout()
    local result = {}

    if not Config.StandAlone then
        result = ESX.GetPlayerData().loadout or {}
    end

    return result
end

-- skinchanger/esx_skin replacements
--[[ 
    Unlike skinchanger, this loads only clothes and does not 
    re-load other parts of your character (that did not change)
--]]
function UpdateClothes(data)
    local playerPed = PlayerPedId()

    currentChar.sex = data.sex or currentChar.sex
    currentChar.tshirt_1 = data.tshirt_1 or currentChar.tshirt_1
    currentChar.tshirt_2 = data.tshirt_2 or currentChar.tshirt_2
    currentChar.torso_1 = data.torso_1 or currentChar.torso_1
    currentChar.torso_2 = data.torso_2 or currentChar.torso_2
    currentChar.decals_1 = data.decals_1 or currentChar.decals_1
    currentChar.decals_2 = data.decals_2 or currentChar.decals_2
    currentChar.arms = data.arms or currentChar.arms
    currentChar.arms_2 = data.arms_2 or currentChar.arms_2
    currentChar.pants_1 = data.pants_1 or currentChar.pants_1
    currentChar.pants_2 = data.pants_2 or currentChar.pants_2
    currentChar.shoes_1 = data.shoes_1 or currentChar.shoes_1
    currentChar.shoes_2 = data.shoes_2 or currentChar.shoes_2
    currentChar.mask_1 = data.mask_1 or currentChar.mask_1
    currentChar.mask_2 = data.mask_2 or currentChar.mask_2
    currentChar.bproof_1 = data.bproof_1 or currentChar.bproof_1
    currentChar.bproof_2 = data.bproof_2 or currentChar.bproof_2
    currentChar.neckarm_1 = data.chain_1 or data.neckarm_1 or currentChar.chain_1
    currentChar.neckarm_2 = data.chain_2 or data.neckarm_2 or currentChar.chain_2
    currentChar.helmet_1 = data.helmet_1 or currentChar.helmet_1
    currentChar.helmet_2 = data.helmet_2 or currentChar.helmet_2
    currentChar.glasses_1 = data.glasses_1 or currentChar.glasses_1
    currentChar.glasses_2 = data.glasses_2 or currentChar.glasses_2
    currentChar.lefthand_1 = data.watches_1 or data.lefthand_1 or currentChar.watches_1 or currentChar.lefthand_1
    currentChar.lefthand_2 = data.watches_2 or data.lefthand_2 or currentChar.watches_2 or currentChar.lefthand_2
    currentChar.righthand_1 = data.bracelets_1 or data.righthand_1 or currentChar.bracelets_1 or currentChar.righthand_1
    currentChar.righthand_2 = data.bracelets_2 or data.righthand_2 or currentChar.bracelets_2 or currentChar.righthand_2
    currentChar.bags_1 = data.bags_1 or currentChar.bags_1
    currentChar.bags_2 = data.bags_2 or currentChar.bags_2
    currentChar.ears_1 = data.ears_1 or currentChar.ears_1
    currentChar.ears_2 = data.ears_2 or currentChar.ears_2

    SetPedComponentVariation(playerPed, 8,  currentChar.tshirt_1,   currentChar.tshirt_2,   2)
    SetPedComponentVariation(playerPed, 11, currentChar.torso_1,    currentChar.torso_2,    2)
    SetPedComponentVariation(playerPed, 10, currentChar.decals_1,   currentChar.decals_2,   2)
    SetPedComponentVariation(playerPed, 3,  currentChar.arms,       currentChar.arms_2,     2)
    SetPedComponentVariation(playerPed, 4,  currentChar.pants_1,    currentChar.pants_2,    2)
    SetPedComponentVariation(playerPed, 6,  currentChar.shoes_1,    currentChar.shoes_2,    2)
    SetPedComponentVariation(playerPed, 1,  currentChar.mask_1,     currentChar.mask_2,     2)
    SetPedComponentVariation(playerPed, 9,  currentChar.bproof_1,   currentChar.bproof_2,   2)
    SetPedComponentVariation(playerPed, 7,  currentChar.neckarm_1,  currentChar.neckarm_2,  2)
    SetPedComponentVariation(playerPed, 5,  currentChar.bags_1,     currentChar.bags_2,     2)

    if currentChar.helmet_1 == -1 then
        ClearPedProp(playerPed, 0)
    else
        SetPedPropIndex(playerPed, 0, currentChar.helmet_1, currentChar.helmet_2, 2)
    end

    if currentChar.glasses_1 == -1 then
        ClearPedProp(playerPed, 1)
    else
        SetPedPropIndex(playerPed, 1, currentChar.glasses_1, currentChar.glasses_2, 2)
    end

    if currentChar.lefthand_1 == -1 then
        ClearPedProp(playerPed, 6)
    else
        SetPedPropIndex(playerPed, 6, currentChar.lefthand_1, currentChar.lefthand_2, 2)
    end

    if currentChar.righthand_1 == -1 then
        ClearPedProp(playerPed,	7)
    else
        SetPedPropIndex(playerPed, 7, currentChar.righthand_1, currentChar.righthand_2, 2)
    end

    if currentChar.ears_1 == -1 then
        ClearPedProp(playerPed, 2)
    else
        SetPedPropIndex(playerPed, 2, currentChar.ears_1, currentChar.ears_2, 2)
    end
end

if ESX.GetConfig().Multichar then
    RegisterNetEvent('esx_multicharacter:SetupUI')
    AddEventHandler('esx_multicharacter:SetupUI', function(data)
        if next(data) == nil or (data.current and data.current.new) then
            firstCharacter = true
        else
            firstCharacter = false
        end
    end)
end

RegisterNetEvent('skinchanger:loadClothes')
AddEventHandler('skinchanger:loadClothes', function(playerSkin, clothesSkin)
    UpdateClothes(clothesSkin, false)
end)

RegisterNetEvent('skinchanger:loadSkin')
AddEventHandler('skinchanger:loadSkin', function(skin, cb)
    local newChar = GetDefaultCharacter(skin['sex'] == 0)

    -- corrections for changed data format and names
    local changed = {}
    changed.chain_1 = 'neckarm_1'
    changed.chain_2 = 'neckarm_2'
    changed.watches_1 = 'lefthand_1'
    changed.watches_2 = 'lefthand_2'
    changed.bracelets_1 = 'righthand_1'
    changed.bracelets_2 = 'righthand_2'

    for k, v in pairs(skin) do
        if k ~= 'face' and k ~= 'skin' then
            if changed[k] == nil then
                newChar[k] = v
            else
                newChar[changed[k]] = v
            end
        end
    end

    oldLoadout = GetLoadout()
    LoadCharacter(newChar, cb)
end)

AddEventHandler('skinchanger:loadDefaultModel', function(loadMale, cb)
    local defaultChar = GetDefaultCharacter(loadMale)
    oldLoadout = GetLoadout()
    LoadCharacter(defaultChar, cb)
end)

AddEventHandler('skinchanger:change', function(key, val)
    --[[
            IMPORTANT: This is provided only for compatibility reasons.
            It's VERY inefficient as it reloads entire character for a single change.

            DON'T USE IT.
    ]]
    
    local changed = {}
    changed.chain_1 = 'neckarm_1'
    changed.chain_2 = 'neckarm_2'
    changed.watches_1 = 'lefthand_1'
    changed.watches_2 = 'lefthand_2'
    changed.bracelets_1 = 'righthand_1'
    changed.bracelets_2 = 'righthand_2'

    if key ~= 'face' and key ~= 'skin' then
        if changed[key] == nil then
            currentChar[key] = val
        else
            currentChar[changed[key]] = val
        end

        -- TODO: (!) Rewrite this to only load changed part.
        oldLoadout = GetLoadout()
        LoadCharacter(currentChar, cb)
    end
end)

AddEventHandler('skinchanger:getSkin', function(cb)
    cb(currentChar)
end)

AddEventHandler('skinchanger:modelLoaded', function()
    if not Config.StandAlone then
        ESX.SetPlayerData('loadout', oldLoadout)
        TriggerEvent('esx:restoreLoadout')
    end
end)

RegisterNetEvent('esx_skin:openSaveableMenu')
AddEventHandler('esx_skin:openSaveableMenu', function(submitCb, cancelCb)
    if ESX.GetConfig().Multichar then
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
            if skin ~= nil then
                oldChar = skin
                LoadCharacter(skin, submitCb)
            end
        end)
    end
end)

AddEventHandler('cui_character:close', function(save)
    if (not save) and (not isCancelable) then
        return
    end

    -- Saving and discarding changes
    if save then
        TriggerServerEvent('cui_character:save', currentChar)
    end

    EndCharacterPreview(save)

    -- Release character models and ui textures
    SetModelAsNoLongerNeeded(GetHashKey('mp_m_freemode_01'))
    SetModelAsNoLongerNeeded(GetHashKey('mp_f_freemode_01'))
    SetStreamedTextureDictAsNoLongerNeeded('mparrow')
    SetStreamedTextureDictAsNoLongerNeeded('mpleaderboard')
    if identityLoaded == true then
        SetStreamedTextureDictAsNoLongerNeeded('pause_menu_pages_char_mom_dad')
        SetStreamedTextureDictAsNoLongerNeeded('char_creator_portraits')
        identityLoaded = false
    end

    Camera.Deactivate()

    isCancelable = true
    setVisible(false)

    for i = 0, #openTabs do
        openTabs[i] = nil
    end
end)

RegisterNetEvent('cui_character:open')
AddEventHandler('cui_character:open', function(tabs, cancelable)
    if isOnDuty then
        AddTextEntry('notifyOnDuty', 'You cannot access this command while ~r~on duty~s~.')
        BeginTextCommandThefeedPost('notifyOnDuty')
        ThefeedNextPostBackgroundColor(140)
        EndTextCommandThefeedPostTicker(false, false)
        isInterfaceOpening = false
        return
    end

    if isInterfaceOpening then
        return
    end

    isInterfaceOpening = true

    if cancelable ~= nil then
        isCancelable = cancelable
    end

    while (not initialized) or (not isModelLoaded) or (not isPlayerReady) do
        Citizen.Wait(100)
    end

    if not Config.StandAlone and not newCharacter then
        oldLoadout = GetLoadout()
    end

    -- Request character models and ui textures
    local maleModelHash = GetHashKey('mp_m_freemode_01')
    local femaleModelHash = GetHashKey('mp_f_freemode_01')
    RequestModel(maleModelHash)
    RequestModel(femaleModelHash)
    RequestStreamedTextureDict('mparrow')
    RequestStreamedTextureDict('mpleaderboard')
    while not HasStreamedTextureDictLoaded('mparrow') or 
          not HasStreamedTextureDictLoaded('mpleaderboard') or 
          not HasModelLoaded(maleModelHash) or
          not HasModelLoaded(femaleModelHash) do
        Wait(100)
    end

    BeginCharacterPreview()

    SendNUIMessage({
        action = 'clearAllTabs'
    })

    local firstTabName = ''
    local clothes = nil
    for i = 0, #openTabs do
        openTabs[i] = nil
    end

    for k, v in pairs(tabs) do
        if k == 1 then
            firstTabName = v
        end

        local tabName = tabs[k]
        table.insert(openTabs, tabName)
        if tabName == 'identity' then
            if not identityLoaded then
                RequestStreamedTextureDict('pause_menu_pages_char_mom_dad')
                RequestStreamedTextureDict('char_creator_portraits')
                while not HasStreamedTextureDictLoaded('pause_menu_pages_char_mom_dad') or not HasStreamedTextureDictLoaded('char_creator_portraits') do
                    Wait(100)
                end
                identityLoaded = true
            end
        elseif tabName == 'apparel' then
            -- load clothes data from natives here
            clothes = GetClothesData()
        end
    end

    SendNUIMessage({
        action = 'enableTabs',
        tabs = tabs,
        character = currentChar,
        clothes = clothes,
        identity = currentIdentity
    })

    SendNUIMessage({
        action = 'activateTab',
        tab = firstTabName
    })

    if newCharacter then
        Camera.Activate(500)
    else
        Camera.Activate()
    end

    SendNUIMessage({
        action = 'refreshViewButtons',
        view = Camera.currentView
    })

    SendNUIMessage({
        action = 'setCancelable',
        value = isCancelable
    })

    setVisible(true)
    isInterfaceOpening = false
end)

AddEventHandler('cui_character:playerPrepared', function(newplayer)
    if newplayer and (not Config.EnableESXIdentityIntegration) then
        TriggerEvent('cui_character:open', { 'identity', 'features', 'style', 'apparel' }, false)
    end
end)

AddEventHandler('cui_character:getCurrentClothes', function(cb)
    local result = {}

    result.sex = currentChar.sex
    result.tshirt_1 = currentChar.tshirt_1
    result.tshirt_2 = currentChar.tshirt_2
    result.torso_1 = currentChar.torso_1
    result.torso_2 = currentChar.torso_2
    result.decals_1 = currentChar.decals_1
    result.decals_2 = currentChar.decals_2
    result.arms = currentChar.arms
    result.arms_2 = currentChar.arms_2
    result.pants_1 = currentChar.pants_1
    result.pants_2 = currentChar.pants_2
    result.shoes_1 = currentChar.shoes_1
    result.shoes_2 = currentChar.shoes_2
    result.mask_1 = currentChar.mask_1
    result.mask_2 = currentChar.mask_2
    result.bproof_1 = currentChar.bproof_1
    result.bproof_2 = currentChar.bproof_2
    result.neckarm_1 = currentChar.chain_1 or currentChar.neckarm_1
    result.neckarm_2 = currentChar.chain_2 or currentChar.neckarm_2
    result.helmet_1 = currentChar.helmet_1
    result.helmet_2 = currentChar.helmet_2
    result.glasses_1 = currentChar.glasses_1
    result.glasses_2 = currentChar.glasses_2
    result.lefthand_1 = currentChar.watches_1 or currentChar.lefthand_1
    result.lefthand_2 = currentChar.watches_2 or currentChar.lefthand_2
    result.righthand_1 = currentChar.bracelets_1 or currentChar.righthand_1
    result.righthand_2 = currentChar.bracelets_2 or currentChar.righthand_2
    result.bags_1 = currentChar.bags_1
    result.bags_2 = currentChar.bags_2
    result.ears_1 = currentChar.ears_1
    result.ears_2 = currentChar.ears_2

    cb(result)
end)

AddEventHandler('cui_character:updateClothes', function(data, save, updateOld, callback)
    UpdateClothes(data, updateOld)
    if save then
        TriggerServerEvent('cui_character:save', currentChar)
    end
    if callback then
        callback()
    end
end)

if not Config.StandAlone then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        ESX.PlayerData = xPlayer
        ESX.PlayerLoaded = true

        if Config.EnterCityAnimation and ESX.GetConfig().Multichar then
            if not IsScreenFadedOut() then
                DoScreenFadeOut(0)
            end
    
            while not isModelLoaded do
                Citizen.Wait(0)
            end
    
            SwitchOutPlayer(PlayerPedId(), 0, 1)
    
            while GetPlayerSwitchState() ~= 5 do
                Citizen.Wait(0)
            end
    
            DoScreenFadeIn(500)
            while not IsScreenFadedIn() do
                Citizen.Wait(0)
            end
    
            SwitchInPlayer(PlayerPedId())
    
            while GetPlayerSwitchState() ~= 12 do
                Citizen.Wait(0)
            end
        end

        playerLoaded = true
    end)

    RegisterNetEvent('esx:onPlayerLogout')
    AddEventHandler('esx:onPlayerLogout', function()
        ESX.PlayerLoaded = false
        ESX.PlayerData = {}
    end)

    AddEventHandler('esx:onPlayerSpawn', function()
        Citizen.CreateThread(function()
            while not playerLoaded do
                Citizen.Wait(100)
            end

            if firstSpawn then
                oldLoadout = GetLoadout()
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                    if skin ~= nil then
                        LoadCharacter(skin)
                    else
                        LoadCharacter(GetDefaultCharacter(true))
                        isPlayerNew = true
                    end
                    preparingSkin = false
                end)

                if Config.EnableESXIdentityIntegration then
                    local preparingIndentity = true
                    ESX.TriggerServerCallback('cui_character:getIdentity', function(identity)
                        if identity ~= nil then
                            LoadIdentity(identity)
                        end
                        preparingIndentity = false
                    end)
                    while preparingIdentity do
                        Citizen.Wait(100)
                    end
                end
            end
        end)
    end)

-- StandAlone Deployment
else
    AddEventHandler('onClientResourceStart', function(resource)
        if resource == GetCurrentResourceName() then
            Citizen.CreateThread(function()
                Citizen.Wait(250)
                TriggerServerEvent('cui_character:requestPlayerData')
            end)
        end
    end)

    RegisterNetEvent('cui_character:recievePlayerData')
    AddEventHandler('cui_character:recievePlayerData', function(playerData)
        isPlayerNew = playerData.newPlayer
        if not isPlayerNew then
            LoadCharacter(playerData.skin)
        else
            LoadCharacter(GetDefaultCharacter(true))
        end
        preparingSkin = false
        playerLoaded = true
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
    end)
end

Citizen.CreateThread(function()
    while preparingSkin do
        Citizen.Wait(100)
    end
    TriggerEvent('cui_character:playerPrepared', isPlayerNew)
    firstSpawn = false

    while not initialized do
        SendNUIMessage({
            action = 'loadInitData',
            hair = GetColorData(GetHairColors(), true),
            lipstick = GetColorData(GetLipstickColors(), false),
            facepaint = GetColorData(GetFacepaintColors(), false),
            blusher = GetColorData(GetBlusherColors(), false),
            naturaleyecolors = Config.UseNaturalEyeColors,

            -- esx identity integration
            esxidentity = Config.EnableESXIdentityIntegration,
            identitylimits = {
                namemax = Config.MaxNameLength,
                heightmin = Config.MinHeight,
                heightmax = Config.MaxHeight,
                yearmin = Config.LowestYear,
                yearmax = Config.HighestYear
            },
        })

        initialized = true
        Citizen.Wait(100)
    end
end)

RegisterNUICallback('setCameraView', function(data, cb)
    Camera.SetView(data['view'])
end)

RegisterNUICallback('updateCameraRotation', function(data, cb)
    Camera.mouseX = tonumber(data['x'])
    Camera.mouseY = tonumber(data['y'])
    Camera.updateRot = true
end)

RegisterNUICallback('updateCameraZoom', function(data, cb)
    Camera.radius = Camera.radius + (tonumber(data['zoom']))
    Camera.updateZoom = true
end)

RegisterNUICallback('playSound', function(data, cb)
    local sound = data['sound']

    if sound == 'tabchange' then
        PlaySoundFrontend(-1, 'Continue_Appears', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', 1)
    elseif sound == 'mouseover' then
        PlaySoundFrontend(-1, 'Faster_Click', 'RESPAWN_ONLINE_SOUNDSET', 1)
    elseif sound == 'panelbuttonclick' then
        PlaySoundFrontend(-1, 'Reset_Prop_Position', 'DLC_Dmod_Prop_Editor_Sounds', 0)
    elseif sound == 'optionchange' then
        PlaySoundFrontend(-1, 'HACKING_MOVE_CURSOR', 0, 1)
    end
end)

RegisterNUICallback('setCurrentTab', function(data, cb)
    currentTab = data['tab']
end)

RegisterNUICallback('close', function(data, cb)
    TriggerEvent('cui_character:close', data['save'])
end)

RegisterNUICallback('updateMakeupType', function(data, cb)
    --[[
            NOTE:   This is a pure control variable that does not call any natives.
                    It only modifies which options are going to be visible in the ui.

                    Since face paint replaces blusher and eye makeup,
                    we need to save in the database which type the player selected:

                    0 - 'None',
                    1 - 'Eye Makeup',
                    2 - 'Face Paint'
    ]]--
    local type = tonumber(data['type'])
    currentChar['makeup_type'] = type

    SendNUIMessage({
        action = 'refreshMakeup',
        character = currentChar
    })
end)

RegisterNUICallback('syncFacepaintOpacity', function(data, cb)
    local prevtype = data['prevtype']
    local currenttype = data['currenttype']
    local prevopacity = prevtype .. '_2'
    local currentopacity = currenttype .. '_2'
    currentChar[currentopacity] = currentChar[prevopacity]
end)

RegisterNUICallback('clearMakeup', function(data, cb)
    if data['clearopacity'] then
        currentChar['makeup_2'] = 100
        if data['clearblusher'] then
            currentChar['blush_2'] = 100
        end
    end

    currentChar['makeup_1'] = 255
    currentChar['makeup_3'] = 255
    currentChar['makeup_4'] = 255

    SetPedHeadOverlay(previewPed, 4, currentChar.makeup_1, currentChar.makeup_2 / 100 + 0.0) -- Eye Makeup
    SetPedHeadOverlayColor(previewPed, 4, 0, currentChar.makeup_3, currentChar.makeup_4)     -- Eye Makeup Color

    if data['clearblusher'] then
        currentChar['blush_1'] = 255
        currentChar['blush_3'] = 0
        SetPedHeadOverlay(previewPed, 5, currentChar.blush_1, currentChar.blush_2 / 100 + 0.0)   -- Blusher
        SetPedHeadOverlayColor(previewPed, 5, 2, currentChar.blush_3, 255)                       -- Blusher Color
    end
end)

RegisterNUICallback('updateGender', function(data, cb)
    currentChar.sex = tonumber(data['value'])
    local modelHash = nil
    local isMale = true
    if currentChar.sex == 0 then
        modelHash = GetHashKey('mp_m_freemode_01')
    elseif currentChar.sex == 1 then
        isMale = false
        modelHash = GetHashKey('mp_f_freemode_01')
    else
        return
    end

    -- NOTE: There seems to be no native for model change that preserves existing coords
    local previewCoords = GetEntityCoords(previewPed)
    DeleteEntity(previewPed)
    previewPed = CreatePed(4, modelHash, 397.92, -1004.4, -99.0, false, true)
    local defaultChar = GetDefaultCharacter(isMale)
    ApplySkinToPed(previewPed, defaultChar)
    for k, v in pairs(defaultChar) do
        currentChar[k] = v
    end

    ResetAllTabs()

    local playerCoords = GetEntityCoords(PlayerPedId())
    for height = playerCoords.z, 1000 do
        SetPedCoordsKeepVehicle(previewPed, previewCoords.x, previewCoords.y, height + 0.0)
        local foundGround, zPos = GetGroundZFor_3dCoord(previewCoords.x, previewCoords.y, height + 0.0)
        if foundGround then
            SetPedCoordsKeepVehicle(previewPed, previewCoords.x, previewCoords.y, zPos)
            break
        end
    end

    PlayIdleAnimation(previewPed)
end)

RegisterNUICallback('updateHeadBlend', function(data, cb)
    local key = data['key']
    local value = tonumber(data['value'])
    currentChar[key] = value

    local weightFace = currentChar.face_md_weight / 100 + 0.0
    local weightSkin = currentChar.skin_md_weight / 100 + 0.0

    SetPedHeadBlendData(previewPed, currentChar.mom, currentChar.dad, 0, currentChar.mom, currentChar.dad, 0, weightFace, weightSkin, 0.0, false)
end)

RegisterNUICallback('updateFaceFeature', function(data, cb)
    local key = data['key']
    local value = tonumber(data['value'])
    local index = tonumber(data['index'])
    currentChar[key] = value

    SetPedFaceFeature(previewPed, index, (currentChar[key] / 100) + 0.0)
end)

RegisterNUICallback('updateEyeColor', function(data, cb)
    local value = tonumber(data['value'])
    currentChar['eye_color'] = value

    SetPedEyeColor(previewPed, currentChar.eye_color)
end)

RegisterNUICallback('updateHairColor', function(data, cb)
    local key = data['key']
    local value = tonumber(data['value'])
    local highlight = data['highlight']
    currentChar[key] = value

    if highlight then
        SetPedHairColor(previewPed, currentChar['hair_color_1'], currentChar[key])
    else
        SetPedHairColor(previewPed, currentChar[key], currentChar['hair_color_2'])
    end
end)

RegisterNUICallback('updateHeadOverlay', function(data, cb)
    local key = data['key']
    local keyPaired = data['keyPaired']
    local value = tonumber(data['value'])
    local index = tonumber(data['index'])
    local isOpacity = (data['isOpacity'])
    currentChar[key] = value

    if isOpacity then
        SetPedHeadOverlay(previewPed, index, currentChar[keyPaired], currentChar[key] / 100 + 0.0)
    else
        SetPedHeadOverlay(previewPed, index, currentChar[key], currentChar[keyPaired] / 100 + 0.0)
    end
end)

RegisterNUICallback('updateHeadOverlayExtra', function(data, cb)
    local key = data['key']
    local keyPaired = data['keyPaired']
    local value = tonumber(data['value'])
    local index = tonumber(data['index'])
    local keyExtra = data['keyExtra']
    local valueExtra = tonumber(data['valueExtra'])
    local indexExtra = tonumber(data['indexExtra'])
    local isOpacity = (data['isOpacity'])

    currentChar[key] = value

    if isOpacity then
        currentChar[keyExtra] = value
        SetPedHeadOverlay(previewPed, index, currentChar[keyPaired], currentChar[key] / 100 + 0.0)
        SetPedHeadOverlay(previewPed, indexExtra, valueExtra, currentChar[key] / 100 + 0.0)
    else
        currentChar[keyExtra] = valueExtra
        SetPedHeadOverlay(previewPed, index, currentChar[key], currentChar[keyPaired] / 100 + 0.0)
        SetPedHeadOverlay(previewPed, indexExtra, currentChar[keyExtra], currentChar[keyPaired] / 100 + 0.0)
    end
end)

RegisterNUICallback('updateOverlayColor', function(data, cb)
    local key = data['key']
    local value = tonumber(data['value'])
    local index = tonumber(data['index'])
    local colortype = tonumber(data['colortype'])
    currentChar[key] = value

    SetPedHeadOverlayColor(previewPed, index, colortype, currentChar[key])
end)

RegisterNUICallback('updateComponent', function(data, cb)
    local drawableKey = data['drawable']
    local drawableValue = tonumber(data['dvalue'])
    local textureKey = data['texture']
    local textureValue = tonumber(data['tvalue'])
    local index = tonumber(data['index'])
    currentChar[drawableKey] = drawableValue
    currentChar[textureKey] = textureValue

    SetPedComponentVariation(previewPed, index, currentChar[drawableKey], currentChar[textureKey], 2)
end)

RegisterNUICallback('updateApparelComponent', function(data, cb)
    local drawableKey = data['drwkey']
    local textureKey = data['texkey']
    local component = tonumber(data['cmpid'])
    currentChar[drawableKey] = tonumber(data['drwval'])
    currentChar[textureKey] = tonumber(data['texval'])

    SetPedComponentVariation(previewPed, component, currentChar[drawableKey], currentChar[textureKey], 2)

    -- Some clothes have 'forced components' that change torso and other parts.
    -- adapted from: https://gist.github.com/root-cause/3b80234367b0c856d60bf5cb4b826f86
    local hash = GetHashNameForComponent(previewPed, component, currentChar[drawableKey], currentChar[textureKey])
    --print('main component hash ' .. hash)
    local fcDrawable, fcTexture, fcType = -1, -1, -1
    local fcCount = GetShopPedApparelForcedComponentCount(hash) - 1
    --print('found ' .. fcCount + 1 .. ' forced components')
    for fcId = 0, fcCount do
        local fcNameHash, fcEnumVal, f5, f7, f8 = -1, -1, -1, -1, -1
        fcNameHash, fcEnumVal, fcType = GetForcedComponent(hash, fcId)
        --print('forced component [' .. fcId .. ']: nameHash: ' .. fcNameHash .. ', enumVal: ' .. fcEnumVal .. ', type: ' .. fcType--[[.. ', field5: ' .. f5 .. ', field7: ' .. f7 .. ', field8: ' .. f8 --]])

        -- only set torsos, using other types here seems to glitch out
        if fcType == 3 then
            if (fcNameHash == 0) or (fcNameHash == GetHashKey('0')) then
                fcDrawable = fcEnumVal
                fcTexture = 0
            else
                fcType, fcDrawable, fcTexture = GetComponentDataFromHash(fcNameHash)
            end

            -- Apply component to ped, save it in current character data
            if IsPedComponentVariationValid(previewPed, fcType, fcDrawable, fcTexture) then
                currentChar['arms'] = fcDrawable
                currentChar['arms_2'] = fcTexture
                SetPedComponentVariation(previewPed, fcType, fcDrawable, fcTexture, 2)
            end
        end
    end

    -- Forced components do not pick proper torso for 'None' variant, need manual correction
    if GetEntityModel(previewPed) == GetHashKey('mp_f_freemode_01') then
        if (GetPedDrawableVariation(previewPed, 11) == 15) and (GetPedTextureVariation(previewPed, 11) == 16) then
            currentChar['arms'] = 15
            currentChar['arms_2'] = 0
            SetPedComponentVariation(previewPed, 3, 15, 0, 2);
        end
    elseif GetEntityModel(previewPed) == GetHashKey('mp_m_freemode_01') then
        if (GetPedDrawableVariation(previewPed, 11) == 15) and (GetPedTextureVariation(previewPed, 11) == 0) then
            currentChar['arms'] = 15
            currentChar['arms_2'] = 0
            SetPedComponentVariation(previewPed, 3, 15, 0, 2);
        end
    end
end)

RegisterNUICallback('updateApparelProp', function(data, cb)
    local drawableKey = data['drwkey']
    local textureKey = data['texkey']
    local prop = tonumber(data['propid'])
    currentChar[drawableKey] = tonumber(data['drwval'])
    currentChar[textureKey] = tonumber(data['texval'])

    if currentChar[drawableKey] == -1 then
        ClearPedProp(previewPed, prop)
    else
        SetPedPropIndex(previewPed, prop, currentChar[drawableKey], currentChar[textureKey], false)
    end
end)

function GetHairColors()
    local result = {}
    local i = 0

    if Config.UseNaturalHairColors then
        for i = 0, 18 do
            table.insert(result, i)
        end
        table.insert(result, 24)
        table.insert(result, 26)
        table.insert(result, 27)
        table.insert(result, 28)
        for i = 55, 60 do
            table.insert(result, i)
        end
    else
        for i = 0, 60 do
            table.insert(result, i)
        end
    end

    return result
end

function GetLipstickColors()
    local result = {}
    local i = 0

    for i = 0, 31 do
        table.insert(result, i)
    end
    table.insert(result, 48)
    table.insert(result, 49)
    table.insert(result, 55)
    table.insert(result, 56)
    table.insert(result, 62)
    table.insert(result, 63)

    return result
end

function GetFacepaintColors()
    local result = {}
    local i = 0

    for i = 0, 63 do
        table.insert(result, i)
    end

    return result
end

function GetBlusherColors()
    local result = {}
    local i = 0

    for i = 0, 22 do
        table.insert(result, i)
    end
    table.insert(result, 25)
    table.insert(result, 26)
    table.insert(result, 51)
    table.insert(result, 60)

    return result
end

function RGBToHexCode(r, g, b)
    local result = string.format('#%x', ((r << 16) | (g << 8) | b))
    return result
end

function GetColorData(indexes, isHair)
    local result = {}
    local GetRgbColor = nil

    if isHair then
        GetRgbColor = function(index)
            return GetPedHairRgbColor(index)
        end
    else
        GetRgbColor = function(index)
            return GetPedMakeupRgbColor(index)
        end
    end

    for i, index in ipairs(indexes) do
        local r, g, b = GetRgbColor(index)
        local hex = RGBToHexCode(r, g, b)
        table.insert(result, { index = index, hex = hex })
    end

    return result
end

function GetComponentDataFromHash(hash)
    local blob = string.rep('\0\0\0\0\0\0\0\0', 9 + 16)
    if not Citizen.InvokeNative(0x74C0E2A57EC66760, hash, blob) then
        return nil
    end

    -- adapted from: https://gist.github.com/root-cause/3b80234367b0c856d60bf5cb4b826f86
    local lockHash = string.unpack('<i4', blob, 1)
    local hash = string.unpack('<i4', blob, 9)
    local locate = string.unpack('<i4', blob, 17)
    local drawable = string.unpack('<i4', blob, 25)
    local texture = string.unpack('<i4', blob, 33)
    local field5 = string.unpack('<i4', blob, 41)
    local component = string.unpack('<i4', blob, 49)
    local field7 = string.unpack('<i4', blob, 57)
    local field8 = string.unpack('<i4', blob, 65)
    local gxt = string.unpack('c64', blob, 73)

    return component, drawable, texture, gxt, field5, field7, field8
end

function GetPropDataFromHash(hash)
    local blob = string.rep('\0\0\0\0\0\0\0\0', 9 + 16)
    if not Citizen.InvokeNative(0x5D5CAFF661DDF6FC, hash, blob) then
        return nil
    end

    -- adapted from: https://gist.github.com/root-cause/3b80234367b0c856d60bf5cb4b826f86
    local lockHash = string.unpack('<i4', blob, 1)
    local hash = string.unpack('<i4', blob, 9)
    local locate = string.unpack('<i4', blob, 17)
    local drawable = string.unpack('<i4', blob, 25)
    local texture = string.unpack('<i4', blob, 33)
    local field5 = string.unpack('<i4', blob, 41)
    local prop = string.unpack('<i4', blob, 49)
    local field7 = string.unpack('<i4', blob, 57)
    local field8 = string.unpack('<i4', blob, 65)
    local gxt = string.unpack('c64', blob, 73)

    return prop, drawable, texture, gxt, field5, field7, field8
end

function GetComponentsData(id)
    local result = {}

    local componentBlacklist = nil

    if blacklist ~= nil then
        if GetEntityModel(previewPed) == GetHashKey('mp_m_freemode_01') then
            componentBlacklist = blacklist.components.male
        elseif GetEntityModel(previewPed) == GetHashKey('mp_f_freemode_01') then
            componentBlacklist = blacklist.components.female
        end
    end

    local drawableCount = GetNumberOfPedDrawableVariations(previewPed, id) - 1

    for drawable = 0, drawableCount do
        local textureCount = GetNumberOfPedTextureVariations(previewPed, id, drawable) - 1

        for texture = 0, textureCount do
            local hash = GetHashNameForComponent(previewPed, id, drawable, texture)

            if hash ~= 0 then
                local component, drawable, texture, gxt = GetComponentDataFromHash(hash)
                -- only named components
                if gxt ~= '' then
                    label = GetLabelText(gxt)
                    if label ~= 'NULL' then
                        local blacklisted = false

                        if componentBlacklist ~= nil then
                            if componentBlacklist[component] ~= nil then
                                if componentBlacklist[component][drawable] ~= nil then
                                    if componentBlacklist[component][drawable][texture] ~= nil then
                                        blacklisted = true
                                    end
                                end
                            end
                        end
    
                        if not blacklisted then
                            table.insert(result, {
                                name = label,
                                component = component,
                                drawable = drawable,
                                texture = texture
                            })
                        end
                    end
                end
            end
        end
    end

    return result
end

function GetPropsData(id)
    local result = {}

    local propBlacklist = nil

    if blacklist ~= nil then
        if GetEntityModel(previewPed) == GetHashKey('mp_m_freemode_01') then
            propBlacklist = blacklist.props.male
        elseif GetEntityModel(previewPed) == GetHashKey('mp_f_freemode_01') then
            propBlacklist = blacklist.props.female
        end
    end

    local drawableCount = GetNumberOfPedPropDrawableVariations(previewPed, id) - 1

    for drawable = 0, drawableCount do
        local textureCount = GetNumberOfPedPropTextureVariations(previewPed, id, drawable) - 1

        for texture = 0, textureCount do
            local hash = GetHashNameForProp(previewPed, id, drawable, texture)

            if hash ~= 0 then
                local prop, drawable, texture, gxt = GetPropDataFromHash(hash)

                -- only named props
                if gxt ~= '' then
                    label = GetLabelText(gxt)
                    if label ~= 'NULL' then
                        local blacklisted = false

                        if propBlacklist ~= nil then
                            if propBlacklist[prop] ~= nil then
                                if propBlacklist[prop][drawable] ~= nil then
                                    if propBlacklist[prop][drawable][texture] ~= nil then
                                        blacklisted = true
                                    end
                                end
                            end
                        end

                        if not blacklisted then
                            table.insert(result, {
                                name = label,
                                prop = prop,
                                drawable = drawable,
                                texture = texture
                            })
                        end
                    end
                end
            end
        end
    end

    return result
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function GetComponentsDataWorkaround(id, cb)
    local result = {}

    local componentBlacklist = nil

    local isMale = GetEntityModel(previewPed) == GetHashKey('mp_m_freemode_01')

    if blacklist ~= nil then
        if GetEntityModel(previewPed) == GetHashKey('mp_m_freemode_01') then
            componentBlacklist = blacklist.components.male
        elseif GetEntityModel(previewPed) == GetHashKey('mp_f_freemode_01') then
            componentBlacklist = blacklist.components.female
        end
    end

    local allClothes

    if Config.UseLocalClothingJSON then
        local jsonFile = Config.DefaultClothingLocalPath
        if isMale then
            jsonFile = jsonFile..Config.DefaultClothing.components.male[id]
        else
            jsonFile = jsonFile..Config.DefaultClothing.components.female[id]
        end

        local loadFile= LoadResourceFile(GetCurrentResourceName(), jsonFile)

        allClothes = json.decode(loadFile)
    else
        ESX.TriggerServerCallback('cui_character_workaround:getClothingComponent', function(callback)
            allClothes = json.decode(callback)
        end, id, isMale)
    end

    while not allClothes do
        Wait(10)
    end

    local drawableCount = tablelength(allClothes) - 1
    for drawable = 0, drawableCount do
        local textureCount = tablelength(allClothes[tostring(drawable)]) - 1

        for texture = 0, textureCount do
            -- only named components
            if allClothes[tostring(drawable)][tostring(texture)].Localized ~= 'NULL' then
                local blacklisted = false

                if componentBlacklist ~= nil then
                    if componentBlacklist[id] ~= nil then
                        if componentBlacklist[id][drawable] ~= nil then
                            if componentBlacklist[id][drawable][texture] ~= nil then
                                blacklisted = true
                            end
                        end
                    end
                end

                if not blacklisted then
                    table.insert(result, {
                        name = allClothes[tostring(drawable)][tostring(texture)].Localized,
                        component = id,
                        drawable = drawable,
                        texture = texture
                    })
                end
            end
        end
    end

    if cb then
        cb(result)
    else
        return result
    end
end

function GetPropsDataWorkaround(id, cb)
    local result = {}

    local propBlacklist = nil

    local isMale = GetEntityModel(previewPed) == GetHashKey('mp_m_freemode_01')

    if blacklist ~= nil then
        if GetEntityModel(previewPed) == GetHashKey('mp_m_freemode_01') then
            propBlacklist = blacklist.props.male
        elseif GetEntityModel(previewPed) == GetHashKey('mp_f_freemode_01') then
            propBlacklist = blacklist.props.female
        end
    end

    local allProps

    if Config.UseLocalClothingJSON then
        local jsonFile = Config.DefaultClothingLocalPath
        if isMale then
            jsonFile = jsonFile..Config.DefaultClothing.props.male[id]
        else
            jsonFile = jsonFile..Config.DefaultClothing.props.female[id]
        end

        local loadFile= LoadResourceFile(GetCurrentResourceName(), jsonFile)
        allProps = json.decode(loadFile)
    else
        ESX.TriggerServerCallback('cui_character_workaround:getClothingProp', function(callback)
            allProps = json.decode(callback)
        end, id, isMale)
    end

    while not allProps do
        Wait(10)
    end

    local drawableCount = tablelength(allProps) - 1

    for drawable = 0, drawableCount do
        local textureCount = tablelength(allProps[tostring(drawable)]) - 1

        for texture = 0, textureCount do
            -- only named props
            if allProps[tostring(drawable)][tostring(texture)].Localized ~= 'NULL' then
                local blacklisted = false

                if propBlacklist ~= nil then
                    if propBlacklist[id] ~= nil then
                        if propBlacklist[id][drawable] ~= nil then
                            if propBlacklist[id][drawable][texture] ~= nil then
                                blacklisted = true
                            end
                        end
                    end
                end

                if not blacklisted then
                    table.insert(result, {
                        name = allProps[tostring(drawable)][tostring(texture)].Localized,
                        prop = id,
                        drawable = drawable,
                        texture = texture
                    })
                end
            end
        end
    end

    if cb then
        cb(result)
    else
        return result
    end
end

function GetClothesData()
    local result = {
        topsover = {},
        topsunder = {},
        pants = {},
        shoes = {},
        bags = {},
        masks = {},
        neckarms = {},
        hats = {},
        ears = {},
        glasses = {},
		arms = {},
        lefthands = {},
        righthands = {},
    }

    result.topsover = GetComponentsData(11)
    result.topsunder = GetComponentsData(8)
    result.pants = GetComponentsData(4)
    result.shoes = GetComponentsData(6)
    -- result.bags = GetComponentsData(5)   -- there seems to be no named components in this category
    result.masks = GetComponentsData(1)
    result.neckarms = GetComponentsData(7)  -- chains/ties/suspenders/bangles
    result.arms = GetComponentsData(3)
    result.hats = GetPropsData(0)
    result.ears = GetPropsData(2)
    result.glasses = GetPropsData(1)
    result.lefthands = GetPropsData(6)
    result.righthands = GetPropsData(7)
    --[[
            unused components:   
            face (0), torso/arms (3), parachute/bag (5), bulletproof vest (9), badges (10)

            unused props:
            mouth (3), left hand (4), righ thand (5), left wrist (6), right wrist (7), hip (8), 
            left foot(9), right foot (10)
    ]]

    -- Workaround:

    local isLoading = 0
    if #result.topsover <= 0 then
        isLoading = isLoading + 1
        GetComponentsDataWorkaround(11, function(data)
            result.topsover = data
            isLoading = isLoading - 1
        end)
    end
    if #result.topsunder <= 0 then
        isLoading = isLoading + 1
        GetComponentsDataWorkaround(8, function(data)
            result.topsunder = data
            isLoading = isLoading - 1
        end)
    end
    if #result.pants <= 0 then
        isLoading = isLoading + 1
        GetComponentsDataWorkaround(4, function(data)
            result.pants = data
            isLoading = isLoading - 1
        end)
    end
    if #result.shoes <= 0 then
        isLoading = isLoading + 1
        GetComponentsDataWorkaround(6, function(data)
            result.shoes = data
            isLoading = isLoading - 1
        end)
    end
    if #result.masks <= 0 then
        isLoading = isLoading + 1
        GetComponentsDataWorkaround(1, function(data)
            result.masks = data
            isLoading = isLoading - 1
        end)
    end
    if #result.neckarms <= 0 then
        isLoading = isLoading + 1
        GetComponentsDataWorkaround(7, function(data)
            result.neckarms = data
            isLoading = isLoading - 1
        end)
    end
    if #result.arms <= 0 then
        isLoading = isLoading + 1
        GetComponentsDataWorkaround(3, function(data)
            result.arms = data
            isLoading = isLoading - 1
        end)
    end

    if #result.hats <= 0 then
        isLoading = isLoading + 1
        GetPropsDataWorkaround(0, function(data)
            result.hats = data
            isLoading = isLoading - 1
        end)
    end
    if #result.ears <= 0 then
        isLoading = isLoading + 1
        GetPropsDataWorkaround(2, function(data)
            result.ears = data
            isLoading = isLoading - 1
        end)
    end
    if #result.glasses <= 0 then
        isLoading = isLoading + 1
        GetPropsDataWorkaround(1, function(data)
            result.glasses = data
            isLoading = isLoading - 1
        end)
    end
    if #result.lefthands <= 0 then
        isLoading = isLoading + 1
        GetPropsDataWorkaround(6, function(data)
            result.lefthands = data
            isLoading = isLoading - 1
        end)
    end
    if #result.righthands <= 0 then
        isLoading = isLoading + 1
        GetPropsDataWorkaround(7, function(data)
            result.righthands = data
            isLoading = isLoading - 1
        end)
    end

    while isLoading > 0 do
        Wait(10)
    end

    return result
end

function GetDefaultCharacter(isMale)
    local result = {
        sex = 1,
        mom = 21,
        dad = 0,
        face_md_weight = 50,
        skin_md_weight = 50,
        nose_1 = 0,
        nose_2 = 0,
        nose_3 = 0,
        nose_4 = 0,
        nose_5 = 0,
        nose_6 = 0,
        cheeks_1 = 0,
        cheeks_2 = 0,
        cheeks_3 = 0,
        lip_thickness = 0,
        jaw_1 = 0,
        jaw_2 = 0,
        chin_1 = 0,
        chin_2 = 0,
        chin_3 = 0,
        chin_4 = 0,
        neck_thickness = 0,
        hair_1 = 0,
        hair_2 = 0,
        hair_color_1 = 0,
        hair_color_2 = 0,
        tshirt_1 = 0,
        tshirt_2 = 0,
        torso_1 = 0,
        torso_2 = 0,
        decals_1 = 0,
        decals_2 = 0,
        arms = 15,
        arms_2 = 0,
        pants_1 = 0,
        pants_2 = 0,
        shoes_1 = 0,
        shoes_2 = 0,
        mask_1 = 0,
        mask_2 = 0,
        bproof_1 = 0,
        bproof_2 = 0,
        neckarm_1 = 0,
        neckarm_2 = 0,
        helmet_1 = -1,
        helmet_2 = 0,
        glasses_1 = -1,
        glasses_2 = 0,
        lefthand_1 = -1,
        lefthand_2 = 0,
        righthand_1 = -1,
        righthand_2 = 0,
        bags_1 = 0,
        bags_2 = 0,
        eye_color = 0,
        eye_squint = 0,
        eyebrows_2 = 100,
        eyebrows_1 = 0,
        eyebrows_3 = 0,
        eyebrows_4 = 0,
        eyebrows_5 = 0,
        eyebrows_6 = 0,
        makeup_type = 0,
        makeup_1 = 255,
        makeup_2 = 100,
        makeup_3 = 255,
        makeup_4 = 255,
        lipstick_1 = 255,
        lipstick_2 = 100,
        lipstick_3 = 0,
        lipstick_4 = 0,
        ears_1 = -1,
        ears_2 = 0,
        chest_1 = 255,
        chest_2 = 100,
        chest_3 = 0,
        chest_4 = 0,
        bodyb_1 = 255,
        bodyb_2 = 100,
        bodyb_3 = 255,
        bodyb_4 = 100,
        age_1 = 255,
        age_2 = 100,
        blemishes_1 = 255,
        blemishes_2 = 100,
        blush_1 = 255,
        blush_2 = 100,
        blush_3 = 0,
        complexion_1 = 255,
        complexion_2 = 100,
        sun_1 = 255,
        sun_2 = 100,
        moles_1 = 255,
        moles_2 = 100,
        beard_1 = 255,
        beard_2 = 100,
        beard_3 = 0,
        beard_4 = 0
    }

    if isMale then
        result['sex'] = 0
        result['torso_1'] = 15
        result['tshirt_1'] = 15
        result['pants_1'] = 61
        result['shoes_1'] = 34
    else
        result['torso_1'] = 18
        result['tshirt_1'] = 2
        result['pants_1'] = 19
        result['shoes_1'] = 35
    end

    return result
end

function LoadModel(hash)
    isModelLoaded = false
    local playerPed = PlayerPedId()
    SetEntityInvincible(playerPed, true)

    if IsModelInCdimage(hash) and IsModelValid(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Citizen.Wait(0)
        end
        SetPlayerModel(PlayerId(), hash)
        FreezePedCameraRotation(playerPed, true)
    end
    SetEntityInvincible(playerPed, false)

    isModelLoaded = true
    if not Config.StandAlone then
        TriggerEvent('skinchanger:modelLoaded')
    end
end

function PlayIdleAnimation(ped)
    local animDict = nil

    if GetEntityModel(ped) == GetHashKey('mp_m_freemode_01') then
        animDict = 'anim@heists@heist_corona@team_idles@male_c'
    elseif GetEntityModel(ped) == GetHashKey('mp_f_freemode_01') then
        animDict = 'anim@heists@heist_corona@team_idles@female_a'
    else
        return
    end

    while not HasAnimDictLoaded(animDict) do
        RequestAnimDict(animDict)
        Wait(100)
    end

    ClearPedTasksImmediately(ped)
    TaskPlayAnim(ped, animDict, 'idle', 1.0, 1.0, -1, 1, 1, 0, 0, 0)
end

function ClearAllAnimations(ped)
    ClearPedTasksImmediately(ped)

    if HasAnimDictLoaded('anim@heists@heist_corona@team_idles@female_a') then
        RemoveAnimDict('anim@heists@heist_corona@team_idles@female_a')
    end

    if HasAnimDictLoaded('anim@heists@heist_corona@team_idles@male_c') then
        RemoveAnimDict('anim@heists@heist_corona@team_idles@male_c')
    end
end

-- Loading character data
function ApplySkinToPed(ped, skin)
    -- Face Blend
    local weightFace = skin.face_md_weight / 100 + 0.0
    local weightSkin = skin.skin_md_weight / 100 + 0.0
    SetPedHeadBlendData(ped, skin.mom, skin.dad, 0, skin.mom, skin.dad, 0, weightFace, weightSkin, 0.0, false)

    -- Facial Features
    SetPedFaceFeature(ped, 0,  (skin.nose_1 / 100)         + 0.0)  -- Nose Width
    SetPedFaceFeature(ped, 1,  (skin.nose_2 / 100)         + 0.0)  -- Nose Peak Height
    SetPedFaceFeature(ped, 2,  (skin.nose_3 / 100)         + 0.0)  -- Nose Peak Length
    SetPedFaceFeature(ped, 3,  (skin.nose_4 / 100)         + 0.0)  -- Nose Bone Height
    SetPedFaceFeature(ped, 4,  (skin.nose_5 / 100)         + 0.0)  -- Nose Peak Lowering
    SetPedFaceFeature(ped, 5,  (skin.nose_6 / 100)         + 0.0)  -- Nose Bone Twist
    SetPedFaceFeature(ped, 6,  (skin.eyebrows_5 / 100)     + 0.0)  -- Eyebrow height
    SetPedFaceFeature(ped, 7,  (skin.eyebrows_6 / 100)     + 0.0)  -- Eyebrow depth
    SetPedFaceFeature(ped, 8,  (skin.cheeks_1 / 100)       + 0.0)  -- Cheekbones Height
    SetPedFaceFeature(ped, 9,  (skin.cheeks_2 / 100)       + 0.0)  -- Cheekbones Width
    SetPedFaceFeature(ped, 10, (skin.cheeks_3 / 100)       + 0.0)  -- Cheeks Width
    SetPedFaceFeature(ped, 11, (skin.eye_squint / 100)     + 0.0)  -- Eyes squint
    SetPedFaceFeature(ped, 12, (skin.lip_thickness / 100)  + 0.0)  -- Lip Fullness
    SetPedFaceFeature(ped, 13, (skin.jaw_1 / 100)          + 0.0)  -- Jaw Bone Width
    SetPedFaceFeature(ped, 14, (skin.jaw_2 / 100)          + 0.0)  -- Jaw Bone Length
    SetPedFaceFeature(ped, 15, (skin.chin_1 / 100)         + 0.0)  -- Chin Height
    SetPedFaceFeature(ped, 16, (skin.chin_2 / 100)         + 0.0)  -- Chin Length
    SetPedFaceFeature(ped, 17, (skin.chin_3 / 100)         + 0.0)  -- Chin Width
    SetPedFaceFeature(ped, 18, (skin.chin_4 / 100)         + 0.0)  -- Chin Hole Size
    SetPedFaceFeature(ped, 19, (skin.neck_thickness / 100) + 0.0)  -- Neck Thickness

    -- Appearance
    SetPedComponentVariation(ped, 2, skin.hair_1, skin.hair_2, 2)                  -- Hair Style
    SetPedHairColor(ped, skin.hair_color_1, skin.hair_color_2)                     -- Hair Color
    SetPedHeadOverlay(ped, 2, skin.eyebrows_1, skin.eyebrows_2 / 100 + 0.0)        -- Eyebrow Style + Opacity
    SetPedHeadOverlayColor(ped, 2, 1, skin.eyebrows_3, skin.eyebrows_4)            -- Eyebrow Color
    SetPedHeadOverlay(ped, 1, skin.beard_1, skin.beard_2 / 100 + 0.0)              -- Beard Style + Opacity
    SetPedHeadOverlayColor(ped, 1, 1, skin.beard_3, skin.beard_4)                  -- Beard Color

    SetPedHeadOverlay(ped, 0, skin.blemishes_1, skin.blemishes_2 / 100 + 0.0)      -- Skin blemishes + Opacity
    SetPedHeadOverlay(ped, 12, skin.bodyb_3, skin.bodyb_4 / 100 + 0.0)             -- Skin blemishes body effect + Opacity

    SetPedHeadOverlay(ped, 11, skin.bodyb_1, skin.bodyb_2 / 100 + 0.0)             -- Body Blemishes + Opacity

    SetPedHeadOverlay(ped, 3, skin.age_1, skin.age_2 / 100 + 0.0)                  -- Age + opacity
    SetPedHeadOverlay(ped, 6, skin.complexion_1, skin.complexion_2 / 100 + 0.0)    -- Complexion + Opacity
    SetPedHeadOverlay(ped, 9, skin.moles_1, skin.moles_2 / 100 + 0.0)              -- Moles/Freckles + Opacity
    SetPedHeadOverlay(ped, 7, skin.sun_1, skin.sun_2 / 100 + 0.0)                  -- Sun Damage + Opacity
    SetPedEyeColor(ped, skin.eye_color)                                            -- Eyes Color
    SetPedHeadOverlay(ped, 4, skin.makeup_1, skin.makeup_2 / 100 + 0.0)            -- Makeup + Opacity
    SetPedHeadOverlayColor(ped, 4, 0, skin.makeup_3, skin.makeup_4)                -- Makeup Color
    SetPedHeadOverlay(ped, 5, skin.blush_1, skin.blush_2 / 100 + 0.0)              -- Blush + Opacity
    SetPedHeadOverlayColor(ped, 5, 2,	skin.blush_3)                                -- Blush Color
    SetPedHeadOverlay(ped, 8, skin.lipstick_1, skin.lipstick_2 / 100 + 0.0)        -- Lipstick + Opacity
    SetPedHeadOverlayColor(ped, 8, 2, skin.lipstick_3, skin.lipstick_4)            -- Lipstick Color
    SetPedHeadOverlay(ped, 10, skin.chest_1, skin.chest_2 / 100 + 0.0)             -- Chest Hair + Opacity
    SetPedHeadOverlayColor(ped, 10, 1, skin.chest_3, skin.chest_4)                 -- Chest Hair Color

    -- Clothing and Accessories
    SetPedComponentVariation(ped, 8,  skin.tshirt_1, skin.tshirt_2, 2)        -- Undershirts
    SetPedComponentVariation(ped, 11, skin.torso_1,  skin.torso_2,  2)        -- Jackets
    SetPedComponentVariation(ped, 3,  skin.arms,     skin.arms_2,   2)        -- Torsos
    SetPedComponentVariation(ped, 10, skin.decals_1, skin.decals_2, 2)        -- Decals
    SetPedComponentVariation(ped, 4,  skin.pants_1,  skin.pants_2,  2)        -- Legs
    SetPedComponentVariation(ped, 6,  skin.shoes_1,  skin.shoes_2,  2)        -- Shoes
    SetPedComponentVariation(ped, 1,  skin.mask_1,   skin.mask_2,   2)        -- Masks
    SetPedComponentVariation(ped, 9,  skin.bproof_1, skin.bproof_2, 2)        -- Vests
    SetPedComponentVariation(ped, 7,  skin.neckarm_1,  skin.neckarm_2,  2)    -- Necklaces/Chains/Ties/Suspenders
    SetPedComponentVariation(ped, 5,  skin.bags_1,   skin.bags_2,   2)        -- Bags

    if skin.helmet_1 == -1 then
        ClearPedProp(ped, 0)
    else
        SetPedPropIndex(ped, 0, skin.helmet_1, skin.helmet_2, 2)          -- Hats
    end

    if skin.glasses_1 == -1 then
        ClearPedProp(ped, 1)
    else
        SetPedPropIndex(ped, 1, skin.glasses_1, skin.glasses_2, 2)        -- Glasses
    end

    if skin.lefthand_1 == -1 then
        ClearPedProp(ped, 6)
    else
        SetPedPropIndex(ped, 6, skin.lefthand_1, skin.lefthand_2, 2)      -- Left Hand Accessory
    end

    if skin.righthand_1 == -1 then
        ClearPedProp(ped,	7)
    else
        SetPedPropIndex(ped, 7, skin.righthand_1, skin.righthand_2, 2)    -- Right Hand Accessory
    end

    if skin.ears_1 == -1 then
        ClearPedProp(ped, 2)
    else
        SetPedPropIndex (ped, 2, skin.ears_1, skin.ears_2, 2)             -- Ear Accessory
    end
end

function LoadCharacter(data, callback)
    for k, v in pairs(data) do
        currentChar[k] = v
    end

    local modelHash = nil
    if data.sex == 0 then
        modelHash = GetHashKey('mp_m_freemode_01')
    else
        modelHash = GetHashKey('mp_f_freemode_01')
    end

    LoadModel(modelHash)

    local playerPed = PlayerPedId()
    ApplySkinToPed(playerPed, data)

    if callback ~= nil then
        callback()
    end
end

-- Map Locations
local closestCoords = nil
local closestType = ''
local distToClosest = 1000.0
local inMarkerRange = false

function DisplayTooltip(suffix)
    SetTextComponentFormat('STRING')
    AddTextComponentString('Press ~INPUT_PICKUP~ to ' .. suffix)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function UpdateClosestLocation(locations, type)
    local pedPosition = GetEntityCoords(PlayerPedId())
    for i = 1, #locations do
        local loc = locations[i]
        local distance = GetDistanceBetweenCoords(pedPosition.x, pedPosition.y, pedPosition.z, loc[1], loc[2], loc[3], false)
        if (distToClosest == nil or closestCoords == nil) or (distance < distToClosest) or (closestCoords == loc) then
            distToClosest = distance
            closestType = type
            closestCoords = vector3(loc[1], loc[2], loc[3])
        end

        if (distToClosest < 20.0) and (distToClosest > 1.0) then
            inMarkerRange = true
        else
            inMarkerRange = false
        end
    end
end

Citizen.CreateThread(function()
    while true do
        if Config.EnableClothingShops then
            UpdateClosestLocation(Config.ClothingShops, 'clothing')
        end

        if Config.EnableBarberShops then
            UpdateClosestLocation(Config.BarberShops, 'barber')
        end

        if Config.EnablePlasticSurgeryUnits then
            UpdateClosestLocation(Config.PlasticSurgeryUnits, 'surgery')
        end

        if Config.EnableNewIdentityProviders then
            UpdateClosestLocation(Config.NewIdentityProviders, 'identity')
        end
        Citizen.Wait(500)
    end
end)

Citizen.CreateThread(function()
    while true do
        --  TODO: make nearby players invisible while using these,
        --  use https://runtime.fivem.net/doc/natives/?_0xE135A9FF3F5D05D8
        --  TODO: possibly charge money for use

        if inMarkerRange then
            DrawMarker(
                20,
                closestCoords.x, closestCoords.y, closestCoords.z + 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.0, 1.0, 1.0,
                45, 110, 185, 128,
                true,   -- move up and down
                false,
                2,
                true,  -- rotate
                nil,
                nil,
                false
            )
        end

        if distToClosest < 1.0 and (not isVisible) then
            if isOnDuty then
                SetTextComponentFormat('STRING')
                AddTextComponentString('You cannot access this while ~r~on duty~s~.')
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            else
                if closestType == 'clothing' then
                    DisplayTooltip('use clothing store.')
                    if IsControlJustPressed(1, 38) then
                        TriggerEvent('cui_character:open', { 'apparel' })
                    end
                elseif closestType == 'barber' then
                    DisplayTooltip('use barber shop.')
                    if IsControlJustPressed(1, 38) then
                        TriggerEvent('cui_character:open', { 'style' })
                    end
                elseif closestType == 'surgery' then
                    DisplayTooltip('use platic surgery unit.')
                    if IsControlJustPressed(1, 38) then
                        TriggerEvent('cui_character:open', { 'features' })
                    end
                elseif closestType == 'identity' then
                    DisplayTooltip('change your identity.')
                    if IsControlJustPressed(1, 38) then
                        TriggerEvent('cui_character:open', { 'identity' })
                    end
                end
            end
        end
        Citizen.Wait(0)
    end
end)

-- Map Blips
if Config.EnableClothingShops then
    Citizen.CreateThread(function()
        for k, v in ipairs(Config.ClothingShops) do
            local blip = AddBlipForCoord(v)
            SetBlipSprite(blip, 73)
            SetBlipColour(blip, 84)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString('Clothing Store')
            EndTextCommandSetBlipName(blip)
        end
    end)
end

if Config.EnableBarberShops then
    Citizen.CreateThread(function()
        for k, v in ipairs(Config.BarberShops) do
            local blip = AddBlipForCoord(v)
            SetBlipSprite(blip, 71)
            SetBlipColour(blip, 84)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString('Barber Shop')
            EndTextCommandSetBlipName(blip)
        end
    end)
end

if Config.EnablePlasticSurgeryUnits then
    Citizen.CreateThread(function()
        for k, v in ipairs(Config.PlasticSurgeryUnits) do
            local blip = AddBlipForCoord(v)
            SetBlipSprite(blip, 102)
            SetBlipColour(blip, 84)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString('Platic Surgery Unit')
            EndTextCommandSetBlipName(blip)
        end
    end)
end

if Config.EnableNewIdentityProviders then
    Citizen.CreateThread(function()
        for k, v in ipairs(Config.NewIdentityProviders) do
            local blip = AddBlipForCoord(v)
            SetBlipSprite(blip, 498)
            SetBlipColour(blip, 84)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString('Municipal Building')
            EndTextCommandSetBlipName(blip)
        end
    end)
end

-- ESX Identity Integration
if Config.EnableESXIdentityIntegration then
    local isDead = false

    function LoadIdentity(data)
        currentIdentity = {
            firstName = nil,
            lastName = nil,
            dateOfBirth = nil,
            sex = 'm',
            height = 67
        }
        for k, v in pairs(data) do
            currentIdentity[k] = v
        end
    end

    AddEventHandler('esx:onPlayerDeath', function(data)
        isDead = true
    end)

    AddEventHandler('esx:onPlayerSpawn', function(spawn)
        isDead = false
    end)

    AddEventHandler('esx_skin:resetFirstSpawn', function()
        firstSpawn = true
    end)

    RegisterNetEvent('esx_identity:showRegisterIdentity')
    AddEventHandler('esx_identity:showRegisterIdentity', function()
        TriggerEvent('esx_skin:resetFirstSpawn')
        if ESX.GetConfig().Multichar then
            newCharacter = true

            oldChar = GetDefaultCharacter(true)
            LoadCharacter(oldChar, function()
                local playerPed = PlayerPedId()
                SetPedAoBlobRendering(playerPed, true)
                SetEntityAlpha(playerPed, 0)
            end)
            currentIdentity = {
                firstName = nil,
                lastName = nil,
                dateOfBirth = nil,
                sex = 'm',
                height = 67
            }

            preparingSkin = false
        end
        if not isDead then
            TriggerEvent('cui_character:open', { 'identity', 'features', 'style', 'apparel' }, false)
        end
    end)

    AddEventHandler('cui_character:setCurrentIdentity', function(data)
        currentIdentity = data
    end)

    RegisterNUICallback('identityregister', function(data, cb)
        ESX.TriggerServerCallback('esx_identity:registerIdentity', function(callback)
            if callback then
                -- ESX.ShowNotification(_U('thank_you_for_registering')) TODO: Notification (or sound effect)
                TriggerEvent('cui_character:setCurrentIdentity', data)
                TriggerEvent('cui_character:close', true)
                if not ESX.GetConfig().Multichar then 
                    TriggerEvent('esx_skin:playerRegistered')
                else
                    firstCharacter = false
                    newCharacter = false
                end
            else
                -- ESX.ShowNotification(_U('registration_error')) TODO: Notification (or sound effect)
            end
        end, data)
    end)
    RegisterNUICallback('identityupdate', function(data, cb)
        ESX.TriggerServerCallback('cui_character:updateIdentity', function(callback)
            if callback then
                TriggerEvent('cui_character:setCurrentIdentity', data)
                TriggerEvent('cui_character:close', true)
                if not ESX.GetConfig().Multichar then 
                    TriggerEvent('esx_skin:playerRegistered')
                end
            else
                --TODO: Notification (or sound effect)
            end
        end, data)
    end)
end
