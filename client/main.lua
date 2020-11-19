-- TODO: DELETE THIS ONCE WE ARE DONE
function dump(o)
    if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
    else
    return tostring(o)
    end
end

function dumpToChat(arg)
    local argVals
    if type(arg) == 'table' then
        argVals = {'Me', dump(arg)}
    else
        argVals = {'Me', arg}
    end 
    TriggerEvent('chat:addMessage', {
        color = { 255, 0, 0},
        multiline = true,
        args = argVals
    })
end
--------------------------------------

ESX = nil

local isVisible = false
local playerLoaded = false
local firstSpawn = true
local identityLoaded = false

local camera = nil

local currentChar = {}
local oldChar = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

function setVisible(visible)
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        action = 'setVisible',
        show = visible
    })
    isVisible = visible
end

function SetCamera(view)
    local x, y , z = table.unpack(GetEntityCoords(PlayerPedId()))

    if view == 'body' then
        SetCamCoord(camera, x + 0.3, y + 2.0, z + 0.0)
        SetCamRot(camera, 0.0, 0.0, 170.0)
    elseif view == 'head' then
        SetCamCoord(camera, x + 0.2, y + 0.5, z + 0.7)
        SetCamRot(camera, 0.0, 0.0, 150.0)
    end
end

function CreateCamera()
    if not DoesCamExist(camera) then
        camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end

    SetEntityHeading(PlayerPedId(), 0.0)
    SetCamera('head')

    SetCamActive(camera, true)
    RenderScriptCams(true, true, 500, true, true)
end

function DeleteCamera()
    SetCamActive(camera, false)
    RenderScriptCams(false, true, 500, true, true)
    camera = nil
end

AddEventHandler('cui_character:close', function(save)
    -- Saving and discarding changes
    if save then
        TriggerServerEvent('cui_character:save', currentChar)
    else
        LoadCharacter(oldChar)
    end

    -- Release textures
    SetStreamedTextureDictAsNoLongerNeeded('mparrow')
    SetStreamedTextureDictAsNoLongerNeeded('mpleaderboard')
    if identityLoaded == true then
        SetStreamedTextureDictAsNoLongerNeeded('pause_menu_pages_char_mom_dad')
        SetStreamedTextureDictAsNoLongerNeeded('char_creator_portraits')
        identityLoaded = false
    end

    DeleteCamera()
    setVisible(false)
end)

RegisterNetEvent('cui_character:open')
AddEventHandler('cui_character:open', function(tabs)

    -- Request textures
    RequestStreamedTextureDict('mparrow')
    RequestStreamedTextureDict('mpleaderboard')
    while not HasStreamedTextureDictLoaded('mparrow') or not HasStreamedTextureDictLoaded('mpleaderboard') do
        Wait(100)
    end

    SendNUIMessage({
        action = 'clearAllTabs'
    })

    local firstTabName = ''
    for k, v in pairs(tabs) do
        if k == 1 then
            firstTabName = v
        end

        local tabName = tabs[k]
        if tabName == 'identity' then
            if not identityLoaded then
                RequestStreamedTextureDict('pause_menu_pages_char_mom_dad')
                RequestStreamedTextureDict('char_creator_portraits')
                while not HasStreamedTextureDictLoaded('pause_menu_pages_char_mom_dad') or not HasStreamedTextureDictLoaded('char_creator_portraits') do
                    Wait(100)
                end
                identityLoaded = true
            end
        end
    end

    SendNUIMessage({
        action = 'enableTabs',
        tabs = tabs,
        character = currentChar
    })

    SendNUIMessage({
        action = 'activateTab',
        tab = firstTabName
    })

    CreateCamera()
    setVisible(true)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    playerLoaded = true
end)

AddEventHandler('esx:onPlayerSpawn', function()
    Citizen.CreateThread(function()
        while not playerLoaded do
            Citizen.Wait(100)
        end

        if firstSpawn then
            ESX.TriggerServerCallback('cui_character:getPlayerSkin', function(skin)
                if skin ~= nil then
                    print('character found, loading...')
                    oldChar = skin
                    LoadCharacter(skin)
                else
                    print('character not found, loading default...')
                    oldChar = GetDefaultCharacter(true)
                    LoadCharacter(oldChar)
                end
            end)
            firstSpawn = false
        end
    end)
end)

RegisterNUICallback('playSound', function(data, cb)
    local sound = data['sound']
    if sound == 'tabchange' then
        PlaySoundFrontend(-1, 'Continue_Appears', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', 1)
    elseif sound == 'mouseover' then
        PlaySoundFrontend(-1, 'Faster_Click', 'RESPAWN_ONLINE_SOUNDSET', 1)
    elseif sound == 'buttonclick' then
        PlaySoundFrontend(-1, 'Reset_Prop_Position', 'DLC_Dmod_Prop_Editor_Sounds', 0)
    end
end)

RegisterNUICallback('close', function(data, cb)
    TriggerEvent('cui_character:close', data['save'])
end)

RegisterNUICallback('updateGender', function(data, cb)
    local value = tonumber(data['value'])
    --[[
             TODO: bring this back if we decide on not doing
             a complete customization reset here.

            --currentChar['sex'] = value
    ]]--

    LoadCharacter(GetDefaultCharacter(value == 0))
end)

RegisterNUICallback('updateHeadBlend', function(data, cb)
    local key = data['key']
    local value = tonumber(data['value'])
    currentChar[key] = value

    local weightFace = currentChar.face_md_weight / 100 + 0.0
    local weightSkin = currentChar.skin_md_weight / 100 + 0.0

    local playerPed = PlayerPedId()
    SetPedHeadBlendData(playerPed, currentChar.mom, currentChar.dad, 0, currentChar.mom, currentChar.dad, 0, weightFace, weightSkin, 0.0, false)
end)

RegisterNUICallback('updateHeadOverlay', function(data, cb)
end)

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
        chain_1 = 0,
        chain_2 = 0,
        helmet_1 = -1,
        helmet_2 = 0,
        glasses_1 = -1,
        glasses_2 = 0,
        watches_1 = -1,
        watches_2 = 0,
        bracelets_1 = -1,
        bracelets_2 = 0,
        bags_1 = 0,
        bags_2 = 0,
        eye_color = 0,
        eye_squint = 0,
        eyebrows_2 = 0,
        eyebrows_1 = 0,
        eyebrows_3 = 0,
        eyebrows_4 = 0,
        eyebrows_5 = 0,
        eyebrows_6 = 0,
        makeup_1 = 0,
        makeup_2 = 0,
        makeup_3 = 0,
        makeup_4 = 0,
        lipstick_1 = 0,
        lipstick_2 = 0,
        lipstick_3 = 0,
        lipstick_4 = 0,
        ears_1 = -1,
        ears_2 = 0,
        chest_1 = 0,
        chest_2 = 0,
        chest_3 = 0,
        bodyb_1 = -1,
        bodyb_2 = 0,
        bodyb_3 = -1,
        bodyb_4 = 0,
        age_1 = 0,
        age_2 = 0,
        blemishes_1 = 0,
        blemishes_2 = 0,
        blush_1 = 0,
        blush_2 = 0,
        blush_3 = 0,
        complexion_1 = 0,
        complexion_2 = 0,
        sun_1 = 0,
        sun_2 = 0,
        moles_1 = 0,
        moles_2 = 0,
        beard_1 = 0,
        beard_2 = 0,
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

function LoadModel(isMale)
    local playerPed = PlayerPedId()
    local characterModel = GetHashKey('mp_f_freemode_01')
    if isMale then
        characterModel = GetHashKey('mp_m_freemode_01')
    end

    SetEntityInvincible(playerPed, true)
    if IsModelInCdimage(characterModel) and IsModelValid(characterModel) then
        RequestModel(characterModel)
        while not HasModelLoaded(characterModel) do
            Citizen.Wait(0)
        end
        SetPlayerModel(PlayerId(), characterModel)
        SetModelAsNoLongerNeeded(characterModel)
        FreezePedCameraRotation(playerPed, true)
    end
    SetEntityInvincible(playerPed, false)
end

-- Loading character data
function LoadCharacter(data)
    for k, v in pairs(data) do
        currentChar[k] = v
    end

    local isMale = false
    if data.sex ~= 1 then
        isMale = true
    end
    LoadModel(isMale)

    --TODO: Possibly pull these out to separate functions
    local playerPed = PlayerPedId()

    -- Face Blend
    local weightFace = data.face_md_weight / 100 + 0.0
    local weightSkin = data.skin_md_weight / 100 + 0.0
    SetPedHeadBlendData(playerPed, data.mom, data.dad, 0, data.mom, data.dad, 0, weightFace, weightSkin, 0.0, false)

    -- Facial Features
    SetPedFaceFeature(playerPed, 0,  (data.nose_1 / 10)         + 0.0)  -- Nose Width
    SetPedFaceFeature(playerPed, 1,  (data.nose_2 / 10)         + 0.0)  -- Nose Peak Height
    SetPedFaceFeature(playerPed, 2,  (data.nose_3 / 10)         + 0.0)  -- Nose Peak Length
    SetPedFaceFeature(playerPed, 3,  (data.nose_4 / 10)         + 0.0)  -- Nose Bone Height
    SetPedFaceFeature(playerPed, 4,  (data.nose_5 / 10)         + 0.0)  -- Nose Peak Lowering
    SetPedFaceFeature(playerPed, 5,  (data.nose_6 / 10)         + 0.0)  -- Nose Bone Twist
    SetPedFaceFeature(playerPed, 6,  (data.eyebrows_5 / 10)     + 0.0)  -- Eyebrow height
    SetPedFaceFeature(playerPed, 7,  (data.eyebrows_6 / 10)     + 0.0)  -- Eyebrow depth
    SetPedFaceFeature(playerPed, 8,  (data.cheeks_1 / 10)       + 0.0)  -- Cheekbones Height
    SetPedFaceFeature(playerPed, 9,  (data.cheeks_2 / 10)       + 0.0)  -- Cheekbones Width
    SetPedFaceFeature(playerPed, 10, (data.cheeks_3 / 10)       + 0.0)  -- Cheeks Width
    SetPedFaceFeature(playerPed, 11, (data.eye_squint / 10)     + 0.0)  -- Eyes squint
    SetPedFaceFeature(playerPed, 12, (data.lip_thickness / 10)  + 0.0)  -- Lip Fullness
    SetPedFaceFeature(playerPed, 13, (data.jaw_1 / 10)          + 0.0)  -- Jaw Bone Width
    SetPedFaceFeature(playerPed, 14, (data.jaw_2 / 10)          + 0.0)  -- Jaw Bone Length
    SetPedFaceFeature(playerPed, 15, (data.chin_1 / 10)         + 0.0)  -- Chin Height
    SetPedFaceFeature(playerPed, 16, (data.chin_2 / 10)         + 0.0)  -- Chin Length
    SetPedFaceFeature(playerPed, 17, (data.chin_3 / 10)         + 0.0)  -- Chin Width
    SetPedFaceFeature(playerPed, 18, (data.chin_4 / 10)         + 0.0)  -- Chin Hole Size
    SetPedFaceFeature(playerPed, 19, (data.neck_thickness / 10) + 0.0)  -- Neck Thickness

    -- Appearance
    SetPedComponentVariation(playerPed, 2, data.hair_1, data.hair_2, 2)                 -- Hair Style
    SetPedHairColor(playerPed, data.hair_color_1, data.hair_color_2)                    -- Hair Color
    SetPedHeadOverlay(playerPed, 2, data.eyebrows_1, data.eyebrows_2 / 10 + 0.0)        -- Eyebrow Style + Opacity
    SetPedHeadOverlayColor(playerPed, 2, 1, data.eyebrows_3, data.eyebrows_4)           -- Eyebrow Color
    SetPedHeadOverlay(playerPed, 1, data.beard_1, data.beard_2 / 10 + 0.0)              -- Beard Style + Opacity
    SetPedHeadOverlayColor(playerPed, 1, 1, data.beard_3, data.beard_4)                 -- Beard Color

    SetPedHeadOverlay(playerPed, 0, data.blemishes_1, data.blemishes_2 / 10 + 0.0)      -- Face blemishes + Opacity
    if data.bodyb_1 == -1 then
        SetPedHeadOverlay(playerPed, 11, 255, data.bodyb_2 / 10 + 0.0)                  -- Body Blemishes + Opacity
    else
        SetPedHeadOverlay(playerPed, 11, data.bodyb_1, data.bodyb_2 / 10 + 0.0)
    end

    SetPedHeadOverlay(playerPed, 3, data.age_1, data.age_2 / 10 + 0.0)                  -- Age + opacity
    SetPedHeadOverlay(playerPed, 6, data.complexion_1, data.complexion_2 / 10 + 0.0)    -- Complexion + Opacity
    SetPedHeadOverlay(playerPed, 9, data.moles_1, data.moles_2 / 10 + 0.0)              -- Moles/Freckles + Opacity
    SetPedHeadOverlay(playerPed, 7, data.sun_1, data.sun_2 / 10 + 0.0)                  -- Sun Damage + Opacity
    SetPedEyeColor(playerPed, data.eye_color, 0, 1)                                     -- Eyes Color
    SetPedHeadOverlay(playerPed, 4, data.makeup_1, data.makeup_2 / 10 + 0.0)            -- Makeup + Opacity
    SetPedHeadOverlayColor(playerPed, 4, 2, data.makeup_3, data.makeup_4)               -- Makeup Color
    SetPedHeadOverlay(playerPed, 5, data.blush_1, data.blush_2 / 10 + 0.0)              -- Blush + Opacity
    SetPedHeadOverlayColor(playerPed, 5, 2,	data.blush_3)                               -- Blush Color
    SetPedHeadOverlay(playerPed, 8, data.lipstick_1, data.lipstick_2 / 10 + 0.0)        -- Lipstick + Opacity
    SetPedHeadOverlayColor(playerPed, 8, 1, data.lipstick_3, data.lipstick_4)           -- Lipstick Color

    -- Clothing and Accessories
    SetPedComponentVariation(playerPed, 8,  data.tshirt_1, data.tshirt_2, 2)    -- Undershirts
    SetPedComponentVariation(playerPed, 11, data.torso_1,  data.torso_2,  2)    -- Jackets
    SetPedComponentVariation(playerPed, 3,  data.arms,     data.arms_2,   2)    -- Torsos
    SetPedComponentVariation(playerPed, 10, data.decals_1, data.decals_2, 2)    -- Decals
    SetPedComponentVariation(playerPed, 4,  data.pants_1,  data.pants_2,  2)    -- Legs
    SetPedComponentVariation(playerPed, 6,  data.shoes_1,  data.shoes_2,  2)    -- Shoes
    SetPedComponentVariation(playerPed, 1,  data.mask_1,   data.mask_2,   2)    -- Masks
    SetPedComponentVariation(playerPed, 9,  data.bproof_1, data.bproof_2, 2)    -- Vests
    SetPedComponentVariation(playerPed, 7,  data.chain_1,  data.chain_2,  2)    -- Necklaces/Chains
    SetPedComponentVariation(playerPed, 5,  data.bags_1,   data.bags_2,   2)    -- Bags

    if data.helmet_1 == -1 then
        ClearPedProp(playerPed, 0)
    else
        SetPedPropIndex(playerPed, 0, data.helmet_1, data.helmet_2, 2)          -- Hats
    end

    if data.glasses_1 == -1 then
        ClearPedProp(playerPed, 1)
    else
        SetPedPropIndex(playerPed, 1, data.glasses_1, data.glasses_2, 2)        -- Glasses
    end

    if data.watches_1 == -1 then
        ClearPedProp(playerPed, 6)
    else
        SetPedPropIndex(playerPed, 6, data.watches_1, data.watches_2, 2)        -- Watches
    end

    if data.bracelets_1 == -1 then
        ClearPedProp(playerPed,	7)
    else
        SetPedPropIndex(playerPed, 7, data.bracelets_1, data.bracelets_2, 2)    -- Bracelets
    end

    if data.ears_1 == -1 then
        ClearPedProp(playerPed, 2)
    else
        SetPedPropIndex (playerPed, 2, data.ears_1, data.ears_2, 2)             -- Earrings
    end
end