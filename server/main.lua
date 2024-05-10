local db = require 'server.db'
local objects = require 'server.objects'

RegisterNetEvent('objects:server:newObject', function(data)
    objects.spawnNewObject(data)
end)

lib.callback.register('objects:server:newObject', function(source, data)
    local insertId = objects.spawnNewObject(data)
    return insertId
end)

RegisterNetEvent('objects:server:updateObject', function(data)
    objects.updateObject(data)
end)

RegisterNetEvent("objects:server:updateSceneName", function(insertId, newName)
    objects.updateSceneName(insertId, newName)
end)

RegisterNetEvent("objects:server:removeScene", function(insertId)
    objects.deleteScene(insertId)
end)

RegisterNetEvent("objects:server:removeObject", function(insertId)
    objects.removeObject(insertId)
end)

lib.callback.register('objects:getAllObjects', function(source)
    return ServerObjects
end)

lib.callback.register('objects:getAllScenes', function(source)
    local allScenes = db.selectAllScenesWithCountOfSceneObjects()
    return allScenes
end)

lib.callback.register('objects:newScene', function(source, sceneName)
    local newScene = db.insertNewScene(sceneName)

    if newScene ~= 0 then
        return true
    end

    return false
end)