local menus = require 'client.menus'
local obj = require 'client.object'

RegisterNetEvent("objects:client:menu", function()
    if GetInvokingResource() then return end -- only allow this to be called from the server
    menus.homeMenu()
end)

RegisterNetEvent("objects:client:removeObject", function(insertId)
    if GetInvokingResource() then return end -- only allow this to be called from the server
    obj.removeObject(insertId)
end)

RegisterNetEvent("objects:client:editConfirmMenu", function(insertId)
    if GetInvokingResource() then return end -- only allow this to be called from the server
    menus.editConfirmMenu(insertId)
end)
