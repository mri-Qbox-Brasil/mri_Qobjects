lib.addCommand('objectspawner', {
    help = 'open the object spawner',
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('objects:client:menu', source)
end)

lib.addCommand('objectdelete', {
    help = 'deleta o objeto',
    restricted = 'group.admin'
}, function (source, args, raw)
    TriggerEvent('objects:server:removeObject', args[1])
end)