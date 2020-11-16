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
--------------------------------------

ESX = nil

local isVisible = false
local playerLoaded = false
local firstSpawn = true
local featuresLoaded = false

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

AddEventHandler('cui_character:close', function(save)
    -- TODO: Saving and discarding changes

    -- Release textures
    SetStreamedTextureDictAsNoLongerNeeded('mparrow')
    SetStreamedTextureDictAsNoLongerNeeded('mpleaderboard')
    if featuresLoaded == true then
        SetStreamedTextureDictAsNoLongerNeeded('pause_menu_pages_char_mom_dad')
        SetStreamedTextureDictAsNoLongerNeeded('char_creator_portraits')
        featuresLoaded = false
    end
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
        if tabName == 'features' then
            if not featuresLoaded then
                RequestStreamedTextureDict('pause_menu_pages_char_mom_dad')
                RequestStreamedTextureDict('char_creator_portraits')
                while not HasStreamedTextureDictLoaded('pause_menu_pages_char_mom_dad') or not HasStreamedTextureDictLoaded('char_creator_portraits') do
                    Wait(100)
                end
                featuresLoaded = true
            end
        end
        SendNUIMessage({
            action = 'enableTab',
            tab = tabName
        })
    end

    SendNUIMessage({
        action = 'activateTab',
        tab = firstTabName
    })

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
                    LoadCharacter(skin)
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
    local save = false
    if data['save'] == 'true' then
        save = true
    end
    TriggerEvent('cui_character:close', save)
end)

function LoadSkin(isMale, useDefault)
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
        if useDefault then
            --TODO: Further customize this.
            SetPedHeadBlendData(playerPed, 0, 0, 0, 15, 0, 0, 0, 1.0, 0, false)
            if isMale then
                SetPedComponentVariation(playerPed, 3, 15, 0, 2)
                SetPedComponentVariation(playerPed, 11, 15, 0, 2)
                SetPedComponentVariation(playerPed, 8, 15, 0, 2)
                SetPedComponentVariation(playerPed, 4, 61, 0, 2)
                SetPedComponentVariation(playerPed, 6, 34, 0, 2)
            else
                SetPedComponentVariation(playerPed, 3, 15, 0, 2)
                SetPedComponentVariation(playerPed, 11, 18, 0, 2)
                SetPedComponentVariation(playerPed, 8, 2, 0, 2)
                SetPedComponentVariation(playerPed, 4, 19, 0, 2)
                SetPedComponentVariation(playerPed, 6, 35, 0, 2)
            end
            SetPedHeadOverlayColor(playerPed, 1, 1, 0, 0)
            SetPedHeadOverlayColor(playerPed, 2, 1, 0, 0)
            SetPedHeadOverlayColor(playerPed, 4, 2, 0, 0)
            SetPedHeadOverlayColor(playerPed, 5, 2, 0, 0)
            SetPedHeadOverlayColor(playerPed, 8, 2, 0, 0)
            SetPedHeadOverlayColor(playerPed, 10, 1, 0, 0)
            SetPedHeadOverlay(playerPed, 1, 0, 0.0)
            SetPedHairColor(playerPed, 1, 1)
        end
    end
    SetEntityInvincible(playerPed, false)
end

function LoadCharacter(data)
    isMale = false
    if data.sex ~= 1 then
        isMale = true
    end
    LoadSkin(isMale, true)

    --TODO: Possibly pull these out to separate functions
    local playerPed = PlayerPedId()

    -- Face Blend
    local weightFace = data.face_md_weight / 10 + 0.0
    local weightSkin = data.skin_md_weight / 10 + 0.0
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
    if data.ears_1 == -1 then
        ClearPedProp(playerPed, 2)
    else
        SetPedPropIndex (playerPed, 2, data.ears_1, data.ears_2, 2)             -- Earrings
    end

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
end

