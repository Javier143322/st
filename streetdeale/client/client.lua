-- client/client.lua (CÓDIGO COMPLETO FINAL - Detección, Menú, Animación y Huida/Ataque)

local ESX = nil
local isNearNPC = false
local currentNPC = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getExtendedClient', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

-- Función auxiliar para cargar diccionarios de animación
local function LoadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end

-- Función para comprobar si un ped es un NPC válido
local function IsValidDealerTarget(ped)
    if IsPedAPlayer(ped) or IsPedInAnyVehicle(ped, false) or IsPedDeadOrDying(ped, true) then
        return false
    end
    -- Lógica adicional de filtrado aquí...
    return true
end

-- Bucle principal para la detección y el marker (Tecla E)
Citizen.CreateThread(function()
    while true do
        local sleepTime = 500
        local playerPed = GetPlayerPed(-1)
        local playerCoords = GetEntityCoords(playerPed)

        isNearNPC = false

        for _, ped in ipairs(GetGamePool('CPed')) do
            if ped ~= playerPed and IsValidDealerTarget(ped) then
                local pedCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - pedCoords)

                if distance < Config.Riesgo.rangoDeteccion then
                    sleepTime = 5
                    isNearNPC = true
                    currentNPC = ped

                    ESX.ShowHelpNotification("Pulsa ~INPUT_CONTEXT~ para ofrecer droga al peatón.", 1)

                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('streetdealer:client:iniciarVenta', currentNPC)
                    end
                    break
                end
            end
        end

        Citizen.Wait(sleepTime)
    end
end)

-- Evento para iniciar la venta (activado por la tecla E)
RegisterNetEvent('streetdealer:client:iniciarVenta', function(npc)
    if not isNearNPC or npc ~= currentNPC then return end

    SetPlayerControl(PlayerId(), false, false)

    -- 1. Detener al NPC
    TaskGuardCurrentPosition(currentNPC, GetEntityCoords(currentNPC), 5.0, 10.0, 10000)
    SetPedKeepTask(currentNPC, true)

    -- 2. Llamada al servidor para obtener las drogas (CALLBACK)
    ESX.TriggerServerCallback('streetdealer:server:getDrogasJugador', function(drogas)
        local elements = {}

        for drugName, count in pairs(drogas) do
            local drugConfig = Config.Drogas[drugName]
            if drugConfig then
                local playerCoords = GetEntityCoords(GetPlayerPed(-1))
                local zoneName = GetLabelText(GetNameOfZone(playerCoords.x, playerCoords.y, playerCoords.z))
                local zoneConfig = Config.ZonasDeVenta[zoneName] or Config.ZonasDeVenta['DEFAULT']
                local multiplier = zoneConfig.multiplier

                local estimatedMin = math.floor(drugConfig.minPrice * multiplier)
                local estimatedMax = math.floor(drugConfig.maxPrice * multiplier)

                table.insert(elements, {
                    label = drugConfig.label .. ' (' .. count .. ' uds.)',
                    value = drugName,
                    price = 'Est: ' .. estimatedMin .. ' - ' .. estimatedMax .. '$'
                })
            end
        end

        -- 3. Mostrar el menú de venta
        if #elements > 0 then
            local playerCoords = GetEntityCoords(GetPlayerPed(-1))
            local zoneName = GetLabelText(GetNameOfZone(playerCoords.x, playerCoords.y, playerCoords.z))

            ESX.UI.Menu.Open(
                'default', GetCurrentResourceName(), 'street_dealer_menu',
                {
                    title    = 'Venta de Drogas',
                    align    = 'right',
                    elements = elements,
                },
                function(data, menu)
                    local drugName = data.current.value
                    menu.close()

                    TriggerEvent('streetdealer:client:playDealAnim')

                    -- ENVIAR EL NOMBRE DE LA ZONA AL SERVIDOR
                    TriggerServerEvent('streetdealer:server:procesarVenta', drugName, currentNPC, zoneName)

                end,
                function(data, menu)
                    menu.close()
                    -- Si cierra el menú sin hacer trato, el NPC simplemente sigue caminando (estado 0)
                    TriggerEvent('streetdealer:client:resetNPC', currentNPC, 0) 
                end
            )
        else
            ESX.ShowNotification("No tienes drogas para vender.")
            TriggerEvent('streetdealer:client:resetNPC', currentNPC, 0)
        end
    end)
end)

-- Función: Animación del Trato
RegisterNetEvent('streetdealer:client:playDealAnim', function()
    local playerPed = GetPlayerPed(-1)
    local animDict = 'mp_common'
    local animName = 'givetake_a' 
    
    if currentNPC and DoesEntityExist(currentNPC) then
        
        LoadAnimDict(animDict)

        -- Dar la espalda al NPC para la animación de 'pase rápido'
        TaskTurnPedToFaceEntity(playerPed, currentNPC, 500)
        Citizen.Wait(500)
        
        TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, Config.Riesgo.TiempoAnimacion, 0, 0, false, false, false)
        TaskPlayAnim(currentNPC, animDict, animName, 8.0, 8.0, Config.Riesgo.TiempoAnimacion, 0, 0, false, false, false)

        Citizen.Wait(Config.Riesgo.TiempoAnimacion)
        
        StopAnimTask(playerPed, animDict, animName, -4.0)
        StopAnimTask(currentNPC, animDict, animName, -4.0)
    end
end)

-- Función: Reseteo del NPC con Lógica de Huida/Ataque
-- AHORA RECIBE UN ESTADO: 0 (Normal/Éxito/Cierre), 1 (Asustado/Huye), 2 (Policía/Ataca)
RegisterNetEvent('streetdealer:client:resetNPC', function(npc, state)
    SetPlayerControl(PlayerId(), true, false)

    if DoesEntityExist(npc) then
        ClearPedTasks(npc)
        SetPedKeepTask(npc, false)

        if state == 1 then
            -- NPC Asustado: Huye del jugador
            TaskSmartFleeCoord(npc, GetEntityCoords(GetPlayerPed(-1)), 100.0, -1, false, false)
            
        elseif state == 2 then
            -- NPC Policía: Ataca/Persigue al jugador
            TaskCombatPed(npc, GetPlayerPed(-1), 0, 16)
            
        else 
            -- Venta Exitosa o Cierre de Menú: Vuelve a vagabundear
            TaskWanderInArea(npc, GetEntityCoords(npc), 10.0, 10.0, 10.0, 1.0, 1.0)
        end

        currentNPC = nil 
    end
end)
