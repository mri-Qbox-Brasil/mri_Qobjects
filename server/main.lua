local db = require 'server.db'
local objects = require 'server.objects'

RegisterNetEvent('objects:server:newObject', function(data)
    if isPlayerNotAuthorized(source) then return end
    objects.spawnNewObject(data)
end)

lib.callback.register('objects:server:newObject', function(source, data)
    if isPlayerNotAuthorized(source) then return end
    local insertId = objects.spawnNewObject(data)
    return insertId
end)

RegisterNetEvent('objects:server:updateObject', function(data)
    if isPlayerNotAuthorized(source) then return end
    objects.updateObject(data)
end)

RegisterNetEvent("objects:server:updateSceneName", function(insertId, newName)
    if isPlayerNotAuthorized(source) then return end
    objects.updateSceneName(insertId, newName)
end)

RegisterNetEvent("objects:server:removeScene", function(insertId)
    if isPlayerNotAuthorized(source) then return end
    objects.deleteScene(insertId)
end)

RegisterNetEvent("objects:server:removeObject", function(insertId)
    if isPlayerNotAuthorized(source) then return end
    objects.removeObject(insertId)
end)

lib.callback.register('objects:getAllObjects', function(source)
    return ServerObjects
end)

lib.callback.register('objects:getAllScenes', function(source)
    if isPlayerNotAuthorized(source) then return end
    local allScenes = db.selectAllScenesWithCountOfSceneObjects()
    return allScenes
end)

lib.callback.register('objects:newScene', function(source, sceneName)
    if isPlayerNotAuthorized(source) then return end
    
    local newScene = db.insertNewScene(sceneName)

    if newScene ~= 0 then
        return true
    end

    return false
end)


function isPlayerAuthorized(src)
    local isAuthorized = false
    if IsPlayerAceAllowed(src, 'admin' ) then
        isAuthorized = true;
    else
        lib.notify(src, {type = "error", description = "Você não possui permissao para realizar essa ação !" })
    end

    return isAuthorized
end

function isPlayerNotAuthorized(src)
    return not isPlayerAuthorized(src)
end