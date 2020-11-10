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
	xPlayer.triggerEvent('cui_character:open')
    end, true, {help = 'Open character editor.', validate = true, arguments = {}
})