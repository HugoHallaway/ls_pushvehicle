local AttachEntityToEntity = AttachEntityToEntity
local GetEntityCoords = GetEntityCoords
local GetEntityModel = GetEntityModel
local GetVehicleEngineHealth = GetVehicleEngineHealth
local GetModelDimensions = GetModelDimensions
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local NetworkGetEntityOwner = NetworkGetEntityOwner
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local SetVehicleForwardSpeed = SetVehicleForwardSpeed
local SetVehicleEngineOn = SetVehicleEngineOn
local SetVehicleBrake = SetVehicleBrake
local SetVehicleSteeringAngle = SetVehicleSteeringAngle
local DisableControlAction = DisableControlAction
local IsDisabledControlPressed = IsDisabledControlPressed
local TaskVehicleTempAction = TaskVehicleTempAction
local TaskPlayAnim = TaskPlayAnim
local IsEntityUpsidedown = IsEntityUpsidedown
local IsEntityAttachedToAnyVehicle = IsEntityAttachedToAnyVehicle
local IsEntityInAir = IsEntityInAir
local ped = cache.ped
local playerId = cache.playerId
local seat = cache.seat
local pushing, remotepush = false, false
local vehiclepushing = nil
local turnLeftControl = Config.TurnLeftKey
local turnRightControl = Config.TurnRightKey
local stopPushingControl = Config.PushKey

local function startTurn(netid, direction)
    if direction ~= 'left' and direction ~= 'right' then return end
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    SetVehicleSteeringAngle(vehicle, direction == 'left' and 30.0 or direction == 'right' and -30.0)
end
RegisterNetEvent('ls_pushvehicle:startTurn', startTurn)

local function stopTurn(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    SetVehicleSteeringAngle(vehicle, 0.0)
end
RegisterNetEvent('ls_pushvehicle:stopTurn', stopTurn)

local function startMove(netid, direction, pedid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    local remoteped = NetworkGetEntityFromNetworkId(pedid)
    remotepush = true
    while remotepush do
        Wait(0)
        if IsEntityInAir(vehicle) or IsEntityUpsidedown(vehicle) or not IsEntityAttachedToAnyVehicle(remoteped) then
            remotepush = false
            return TriggerServerEvent('ls_pushvehicle:detach', netid)
        end
        local owner = NetworkGetEntityOwner(vehicle)
        if owner ~= playerId then
            remotepush = false
            return TriggerServerEvent('ls_pushvehicle:updateOwner', netid, direction)
        end
        SetVehicleEngineOn(vehicle, false, true, true)
        SetVehicleBrake(vehicle, false)
        SetVehicleForwardSpeed(vehicle, direction == 'trunk' and 1.1 or -1.1)
        if owner == playerId and seat == -1 then
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            if IsDisabledControlPressed(0, 34) then
                TaskVehicleTempAction(ped, vehicle, 11, 1000)
            elseif IsDisabledControlPressed(0, 35) then
                TaskVehicleTempAction(ped, vehicle, 10, 1000)
            end
        end
    end
end
RegisterNetEvent('ls_pushvehicle:startMove', startMove)

local function stopMove()
    remotepush = false
end
RegisterNetEvent('ls_pushvehicle:stopMove', stopMove)

local function GetNetworkIdFromEntity(vehicle)
    if not DoesEntityExist(vehicle) then
        return nil
    end

    if not NetworkGetEntityIsNetworked(vehicle) then
        return nil
    end

    return NetworkGetNetworkIdFromEntity(vehicle)
end

local function startPushing(vehicle)
    if LocalPlayer.state.intrunk then return end
    local health = GetVehicleEngineHealth(vehicle) <= Config.healthMin and true or false
    if not health then return end
    local flipped = IsEntityUpsidedown(vehicle) and true or false
    if flipped then return end
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local size = max - min
    local coords = GetEntityCoords(ped)
    local closest = #(coords - GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (size.y / 2), 0.0)) < #(coords - GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (-size.y / 2), 0.0)) and 'bonnet' or 'trunk'
    local veh = GetNetworkIdFromEntity(vehicle)
    if veh == nil then return end
    local start = lib.callback.await('ls_pushvehicle:startPushing', 500, veh, closest)
    if start then
        vehiclepushing = vehicle
        pushing = true
        AttachEntityToEntity(ped, vehicle, 0, 0.0, closest == 'trunk' and min.y - 0.6 or -min.y + 0.4, closest == 'trunk' and min.z + 1.1 or max.z / 2, 0.0, 0.0, closest == 'trunk' and 0.0 or 180.0, 0.0, false, false, true, 0, true)
        lib.requestAnimDict('missfinale_c2ig_11')
        TaskPlayAnim(ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 1.5, 1.5, -1, 35, 0, false, false, false)
    end
end

local function stopPushing()
    TriggerServerEvent('ls_pushvehicle:stopPushing', NetworkGetNetworkIdFromEntity(vehiclepushing))
    vehiclepushing = nil
    pushing = false
    DetachEntity(ped, true, false)
    ClearPedTasks(ped)
    lib.hideTextUI()
end
RegisterNetEvent('ls_pushvehicle:detach', stopPushing)

CreateThread(function()
    while true do
        if IsControlPressed(0, turnLeftControl) then
            if pushing and not LocalPlayer.state.intrunk then
                TriggerServerEvent('ls_pushvehicle:startTurn', NetworkGetNetworkIdFromEntity(vehiclepushing), 'left')
            end
        elseif IsControlJustReleased(0, turnLeftControl) then
            if pushing then
                TriggerServerEvent('ls_pushvehicle:stopTurn', NetworkGetNetworkIdFromEntity(vehiclepushing))
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if IsControlPressed(0, turnRightControl) then
            if pushing and not LocalPlayer.state.intrunk then
                TriggerServerEvent('ls_pushvehicle:startTurn', NetworkGetNetworkIdFromEntity(vehiclepushing), 'right')
            end
        elseif IsControlJustReleased(0, turnRightControl) then
            if pushing then
                TriggerServerEvent('ls_pushvehicle:stopTurn', NetworkGetNetworkIdFromEntity(vehiclepushing))
            end
        end
        Wait(0)
    end
end)

if Config.target then
    local options = {
        {
            name = 'startPushing',
            icon = "fa-solid fa-truck-arrow-right",
            label = locale('push_vehicle'),
            onSelect = function(data)
                startPushing(data.entity)
            end,
            action = function(entity)
                startPushing(entity)
            end,
            canInteract = function(entity)
                if LocalPlayer.state.intrunk then return false end
                if pushing then return false end
                local health = GetVehicleEngineHealth(entity) <= Config.healthMin and true or false
                if not health then return false end
                local flipped = IsEntityUpsidedown(entity) and true or false
                if flipped then return false end
                return true
            end
        },
        {
            name = 'stopPushing',
            icon = "fa-solid fa-circle-xmark",
            label = locale('stop_push_vehicle'),
            onSelect = function(data)
                stopPushing()
            end,
            action = function(entity)
                stopPushing()
            end,
            canInteract = function(entity)
                if not pushing then return false end
                return true
            end
        }
    }

    local targetSystem = string.lower(Config.targetSystem)
    if targetSystem == 'qtarget' then
        if Config.Usebones then
            exports[targetSystem]:AddTargetBone({'boot', 'bonnet'}, {
                options = options,
                distance = 3
            })
        else
            exports[targetSystem]:Vehicle({
                options = options,
                distance = 3
            })
        end
    elseif targetSystem == 'ox_target' then
        if Config.Usebones then
            for i = 1, #options do
                options[i].bones = { 'bonnet', 'boot' }
            end
            exports[targetSystem]:addGlobalVehicle(options)
        else
            exports[targetSystem]:addGlobalVehicle(options)
        end
    elseif targetSystem == 'qb-target' then
        if Config.Usebones then
            exports[targetSystem]:AddTargetBone({'boot', 'bonnet'}, {
                options = options,
                distance = 3
            })
        else
            exports[targetSystem]:AddGlobalVehicle({
                options = options,
                distance = 3
            })
        end
    end
end

CreateThread(function()
    while true do
        Wait(100)

        if pushing then
            local keyDisplay = GetControlInstructionalButton(0, stopPushingControl, true)
            keyDisplay = keyDisplay:sub(3)  -- Retirer les caractères "~INPUT_" pour garder la touche

            -- Afficher un texte pour relâcher la touche correspondante
            lib.showTextUI(locale('stop_push_vehicle_ui'):format(keyDisplay), {
                position = 'bottom-center',
                icon = 'circle-xmark',
            })

            -- Si le joueur relâche la touche associée, arrêter de pousser
            if IsControlPressed(0, stopPushingControl) then
                stopPushing()
            end
        end
    end
end)


lib.onCache('ped', function(value)
    ped = value
end)

lib.onCache('seat', function(value)
    seat = value
end)
