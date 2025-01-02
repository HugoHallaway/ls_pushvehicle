local pushing = {}
local beingpushed = {}
local skilltrack = {}

lib.callback.register('ls_pushvehicle:startPushing', function(source, netid, direction)
    if netid == nil or direction == nil then return end
    if pushing[source] then return false end
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if beingpushed[netid] then return false end
    local owner = NetworkGetEntityOwner(vehicle)
    beingpushed[netid] = source
    pushing[source] = owner
    TriggerClientEvent('ls_pushvehicle:startMove', owner, netid, direction, NetworkGetNetworkIdFromEntity(GetPlayerPed(source)))
    return true
end)

RegisterNetEvent('ls_pushvehicle:stopPushing', function(netid)
    local src = source
    if not pushing[src] then return end
    TriggerClientEvent('ls_pushvehicle:stopMove', pushing[src])
    pushing[src] = nil
    beingpushed[netid] = nil
end)

RegisterNetEvent('ls_pushvehicle:startTurn', function(netid, direction)
    local src = source
    if not pushing[src] then return end
    TriggerClientEvent('ls_pushvehicle:startTurn', pushing[src], netid, direction)
end)

RegisterNetEvent('ls_pushvehicle:stopTurn', function(netid)
    local src = source
    if not pushing[src] then return end
    TriggerClientEvent('ls_pushvehicle:stopTurn', pushing[src], netid)
end)

RegisterNetEvent('ls_pushvehicle:updateOwner', function(netid, direction)
    local src = source
    if not beingpushed[netid] then return end
    if not pushing[beingpushed[netid]] then return end
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    local owner = NetworkGetEntityOwner(vehicle)
    pushing[beingpushed[netid]] = owner
    if not pushing[beingpushed[netid]] then return end
    TriggerClientEvent('ls_pushvehicle:startMove', owner, netid, direction)
end)

RegisterNetEvent('ls_pushvehicle:detach', function(netid)
    if not beingpushed[netid] then return end
    if not pushing[beingpushed[netid]] then return end
    TriggerClientEvent('ls_pushvehicle:detach', beingpushed[netid])
end)
