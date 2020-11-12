ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('cui_character:save')
AddEventHandler('cui_character:save', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.execute('UPDATE users SET skin = @data WHERE identifier = @identifier', {
        ['@data'] = json.encode(data),
        ['@identifier'] = xPlayer.identifier
    })
end)

ESX.RegisterServerCallback('cui_character:getPlayerSkin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.fetchAll('SELECT skin FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(users)
        local user = users[1]
        local skin = nil

        if user.skin ~= nil then
            skin = json.decode(user.skin)
        end

        cb(skin, jobSkin)
    end)
end)

ESX.RegisterCommand('character', 'admin', function(xPlayer, args, showError)
	xPlayer.triggerEvent('cui_character:open', { 'identity', 'features', 'style', 'apparel' })
    end, true, {help = 'Open full character editor.', validate = true, arguments = {}
})

ESX.RegisterCommand('identity', 'admin', function(xPlayer, args, showError)
	xPlayer.triggerEvent('cui_character:open', { 'identity' })
    end, true, {help = 'Open character identity editor.', validate = true, arguments = {}
})

ESX.RegisterCommand('features', 'admin', function(xPlayer, args, showError)
	xPlayer.triggerEvent('cui_character:open', { 'features' })
    end, true, {help = 'Open character physical features editor.', validate = true, arguments = {}
})

ESX.RegisterCommand('style', 'admin', function(xPlayer, args, showError)
	xPlayer.triggerEvent('cui_character:open', { 'style' })
    end, true, {help = 'Open character style editor.', validate = true, arguments = {}
})

ESX.RegisterCommand('apparel', 'admin', function(xPlayer, args, showError)
	xPlayer.triggerEvent('cui_character:open', { 'apparel' })
    end, true, {help = 'Open character apparel editor.', validate = true, arguments = {}
})