local obj = require 'client.object'

local lib = lib
local menus = {}

function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function toggleDebugObjectIds()
    if not showObjectIds then
        showObjectIds = true
        Citizen.CreateThread(function()
            while showObjectIds do
                local playerCoords = GetEntityCoords(PlayerPedId())
                for _, object in pairs(ClientObjects) do
                    local objCoords = object.coords
                    local distance = #(playerCoords - objCoords)
                    if distance < 10.0 and showObjectIds then
                        DrawText3Ds(objCoords.x, objCoords.y, objCoords.z + 1.0, tostring(object.id))
                        SetEntityDrawOutline(object.handle, true)
                        SetEntityDrawOutlineColor(0, 0, 255, 255)
                    else
                        SetEntityDrawOutline(object.handle, false)
                    end
                end
                Citizen.Wait(0)
            end
        end)
    else
        showObjectIds = false
    end
end



local function newObject(sceneId)
    local input = lib.inputDialog('Criador de Objetos', {
        {
            type = 'input',
            label = 'Nome do Objeto',
            required = true,
        },
    })
    local object = nil
    if input then
        object = tostring(input[1])
    else
        lib.notify({title = 'Cancelado', type = 'error', description = 'Você deixou em branco. Ação cancelada.', duration = 10000})
        lib.showContext('scene_object_menu')
        return
    end


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

local function cloneObject(object, sceneId)
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

    if not input then return lib.showContext('object_menu_scenes') end

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

function menus.homeMenu()
    menus.viewAllScenes()
end

function menus.viewAllScenes()
    local allScenes = lib.callback.await('objects:getAllScenes', 100)
    local options = {}

    options[#options+1] = {
        title = 'Criar um novo projeto',
        description = 'Crie um novo projeto com vários objetos',
        icon = 'plus',
        onSelect = function()
            createNewScene()
        end,
    }

    if not showObjectIds then
        options[#options+1] = {
            title = 'Ativar Debug',
            description = 'Veja os IDs de todos objetos',
            icon = 'toggle-off',
            iconColor = 'red',
            onSelect = function()
                toggleDebugObjectIds()
                menus.viewAllScenes()
            end,
        }
    else
        options[#options+1] = {
            title = 'Desativar Debug',
            description = 'Desativar ver os IDs de todos objetos',
            icon = 'toggle-on',
            iconColor = 'green',
            onSelect = function()
                toggleDebugObjectIds()
                menus.viewAllScenes()
            end,
        }
    end

    if #allScenes == 0 then
        lib.notify({
            title = 'Spawner de Objetos',
            description = 'Nenhum projeto criado',
            type = 'error'
        })
        return
    end

    options[#options+1] = {
        title = 'Total de projetos: '..#allScenes,
        icon = 'fa-solid fa-boxes-stacked'
    }

    options[#options+1] = {
        disabled = true,
        progress = 100,
    }

    for i = 1, #allScenes do
        local scene = allScenes[i]
        local count = scene.count
        local name = scene.name
        local id = scene.id

        options[#options+1] = {
            title = name,
            description = ('Ver projeto: %s (%s Objetos)'):format(name, count),
            icon = 'fa-solid fa-floppy-disk',
            onSelect = function()
                menus.viewObjectsInScene(id, name)
            end,
        }
    end

    lib.registerContext({
        id = 'object_menu_scenes',
        title = 'Projetos',
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
        title = ('['..object.id..'] %s'):format(object.model),
        menu = 'scene_object_menu',
        onBack = function()
            if DoesEntityExist(object.handle) then
                SetEntityDrawOutline(object.handle, false)
            end
        end,
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
                title = 'Duplicar',
                icon = 'copy',
                disabled = not DoesEntityExist(object.handle),
                onSelect = function()
                    SetEntityDrawOutline(object.handle, false)
                    cloneObject(object.model, object.sceneid)
                end,
            },
            {
                title = 'Excluir',
                icon = 'trash',
                disabled = not DoesEntityExist(object.handle),
                onSelect = function()
                    SetEntityDrawOutline(object.handle, false)
                    obj.removeObject(insertId)
                    while ClientObjects[insertId]~= nil do
                        Wait(0)
                    end
                    menus.viewObjectsInScene(object.sceneid, "Último objeto excluído ID: "..insertId)
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
                    lib.showContext('object_confirm_edit')
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

    local trash_desc = nil

    options[#options+1] = {
        title = 'Adicionar objeto',
        description = 'Crie um novo objeto',
        icon = 'plus',
        iconAnimate = 'fade',
        onSelect = function()
            newObject(sceneId)
        end,
    }

    options[#options+1] = { 
        title = 'Renomear',
        icon = 'fa-solid fa-pen-to-square',
        disabled = disable,
        description = "Altere o nome do projeto.",
        onSelect = function()
            local input = lib.inputDialog("Renomear", {
                {type = 'input', label = "Nome do projeto", placeholder = sceneName, required = true, icon = "fa-solid fa-font"},
            })
            if input then
                obj.updateSceneName(sceneId, input[1])
                lib.notify({title = 'Sucesso', type = 'success', description = 'Projeto '..input[1]..' renomeado com sucesso.', duration = 10000})
            else
                lib.notify({title = 'Cancelado', type = 'error', description = 'Você deixou em branco. Ação cancelada.', duration = 10000})
                lib.showContext('scene_object_menu')
            end
        end,
    }

    local disable = false
    if #sceneObjects > 0 then
        disable = true
        trash_desc = "Exclua todos os objetos primeiro."
    else
        trash_desc = "Excluir o projeto para sempre."
    end
    options[#options+1] = {
        title = 'Excluir projeto',
        icon = 'trash',
        iconColor = 'red',
        disabled = disable,
        description = trash_desc,
        onSelect = function()
            obj.removeScene(sceneId)
        end,
    }

    options[#options+1] = {
        progress = 100,
    }

    options[#options+1] = {
        title = 'Total de objetos: '..#sceneObjects,
        icon = 'box'
    }

    for i = 1, #sceneObjects do
        local object = sceneObjects[i]
        local model = object.model
        local fmtCoords = ('coords: %.3f, %.3f, %.3f'):format(object.coords.x, object.coords.y, object.coords.z)
        options[#options+1] = {
            title = '**['..object.id..']** '..model,
            description = fmtCoords,
            icon = 'fa-solid fa-caret-right',
            image = 'https://mri-qbox-brasil.github.io/gta-assets/assets/'..model..'.jpg',
            metadata = {
                label = model,
            },
            onSelect = function()
                menus.editConfirmMenu(object.id)
            end,
        }
    end

    lib.registerContext({
        id = 'scene_object_menu',
        title = sceneName,
        menu = 'object_menu_scenes',
        options = options,
    })

    lib.showContext('scene_object_menu')
end

return menus