local obj = require 'client.object'

local lib = lib
local menus = {}

local function newObject(sceneId)
    local input = lib.inputDialog('Criador de Objetos', {
        {
            type = 'input',
            label = 'Nome do Objeto',
            required = true,
        },
    })

    local object = tostring(input[1])

    if not IsModelInCdimage(joaat(object)) then
        lib.notify({
            title = 'Spawner de Objetos',
            description = ("O objeto \"%s\" não existe no GTA V, você já instalou esse mod?"):format(object),
            type = 'error'
        })
        return
    end

    obj.previewObject(object, sceneId)
end

local function createNewScene()
    local input = lib.inputDialog('Novo Projeto', {
        {
            type = 'input',
            label = 'Nome do Projeto',
            icon = 'pencil',
            required = true,
        },
    })

    if not input then return lib.showContext('object_menu_main') end

    local name = tostring(input[1])

    local newScene = lib.callback.await('objects:newScene', 100, name)

    if newScene then
        lib.notify({
            title = 'Spawner de Objetos',
            description = ('Objeto %s criado'):format(name),
            type = 'success'
        })
    end
end

lib.registerContext({
    id = 'object_menu_main',
    title = 'Criador de Objetos',
    options = {
        {
            title = 'Projetos',
            description = 'Ver todos os projetos criados',
            icon = 'camera',
            onSelect = function()
                menus.viewAllScenes()
            end,
        },
        {
            title = 'Criar um novo projeto',
            description = 'Crie um novo projeto com vários objetos',
            icon = 'plus',
            onSelect = function()
                createNewScene()
            end,
        },
    },
})

function menus.homeMenu()
    lib.showContext('object_menu_main')
end

function menus.viewAllScenes()
    local allScenes = lib.callback.await('objects:getAllScenes', 100)

    if #allScenes == 0 then
        lib.notify({
            title = 'Spawner de Objetos',
            description = 'Nenhum projeto criado',
            type = 'error'
        })
        return
    end

    local options = {}

    for i = 1, #allScenes do
        local scene = allScenes[i]
        local count = scene.count
        local name = scene.name
        local id = scene.id

        options[#options+1] = {
            title = name,
            description = ('Ver projeto: %s (%s Objetos)'):format(name, count),
            icon = 'camera',
            onSelect = function()
                menus.viewObjectsInScene(id, name)
            end,
        }
    end

    lib.registerContext({
        id = 'object_menu_scenes',
        title = 'Projetos',
        menu = 'object_menu_main',
        options = options,
    })

    lib.showContext('object_menu_scenes')
end

function menus.editConfirmMenu(insertId)
    local objects = ClientObjects
    local object = objects[insertId]
    if DoesEntityExist(object.handle) then
        SetEntityDrawOutline(object.handle, true)
        SetEntityDrawOutlineColor(255, 0, 0, 255)
    end
    lib.registerContext({
        id = 'object_confirm_edit',
        title = ('Editar: %s'):format(object.model),
        onExit = function()
            if DoesEntityExist(object.handle) then
                SetEntityDrawOutline(object.handle, false)
            end
        end,
        options = {
            {
                title = 'Editar',
                icon = 'check',
                disabled = not DoesEntityExist(object.handle),
                onSelect = function()
                    SetEntityDrawOutline(object.handle, false)
                    obj.editPlaced(insertId)
                end,
            },
            {
                title = 'Excluir',
                icon = 'trash',
                disabled = not DoesEntityExist(object.handle),
                onSelect = function()
                    SetEntityDrawOutline(object.handle, false)
                    obj.removeObject(insertId)
                end,
            },
            {
                title = 'Teleportar',
                icon = 'arrows-to-circle',
                onSelect = function()
                    if DoesEntityExist(object.handle) then
                        SetEntityDrawOutline(object.handle, false)
                    end
                    SetEntityCoords(cache.ped, object.coords.x, object.coords.y, object.coords.z)
                end,
            }
        },
    })

    lib.showContext('object_confirm_edit')
end

local function getAllObjectsByScene(sceneId)
    local sceneObjects = {}
    for k, v in pairs(ClientObjects) do
        if v.sceneid == sceneId then
            sceneObjects[#sceneObjects+1] = v
        end
    end
    return sceneObjects
end

function menus.viewObjectsInScene(sceneId, sceneName)
    local sceneObjects = getAllObjectsByScene(sceneId)

    local options = {}

    options[#options+1] = {
        title = 'Adicionar novo objeto',
        description = 'adiciona um novo objeto ao projeto',
        icon = 'plus',
        onSelect = function()
            newObject(sceneId)
        end,
    }


    for i = 1, #sceneObjects do
        local object = sceneObjects[i]
        local model = object.model
        local fmtCoords = ('coords: %.3f, %.3f, %.3f'):format(object.coords.x, object.coords.y, object.coords.z)
        options[#options+1] = {
            title = model,
            description = fmtCoords,
            icon = 'object-ungroup',
            onSelect = function()
                menus.editConfirmMenu(object.id)
            end,
        }
    end

    lib.registerContext({
        id = 'scene_object_menu',
        title = ('Scene: %s'):format(sceneName),
        menu = 'object_menu_scenes',
        options = options,
    })

    lib.showContext('scene_object_menu')
end

return menus