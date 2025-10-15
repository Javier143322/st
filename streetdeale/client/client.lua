-- client/client.lua

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
    -- Lógica para filtrar NPCs (no jugadores, no en vehículos, no policías/EMS, etc.)
    if IsPedAPlayer(ped) or IsPedInAnyVehicle(ped, false) then
        return false
    end
    
    -- Filtro adicional para evitar errores comunes
    if IsPedDeadOrDying(ped, true) then
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

        isNearNPC = false -- Resetear en cada ciclo

        -- Buscar todos los peds en el área
        for _, ped in ipairs(GetGamePool('CPed')) do
            if ped ~= playerPed and IsValidDealerTarget(ped) then
                local pedCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - pedCoords)

                if distance < Config.Riesgo.rangoDeteccion then
                    sleepTime = 5
                    isNearNPC = true
                    currentNPC = ped

                    -- 1. Mostrar texto de interacción (Tecla E)
                    ESX.ShowHelpNotification("Pulsa ~INPUT_CONTEXT~ para ofrecer droga al peatón.", 1)

                    -- 2. Detección de la tecla
                    if IsControlJustPressed(0, 38) then -- 38 es la tecla INPUT_CONTEXT (E)
                        TriggerEvent('streetdealer:client:iniciarVenta', currentNPC)
                    end
                    break -- Salir del bucle una vez que encontramos un NPC
                end
            end
        end

        Citizen.Wait(sleepTime)
    end
end)

-- Evento para iniciar la venta (activado por la tecla E)
RegisterNetEvent('streetdealer:client:iniciarVenta', function(npc)
    if not isNearNPC or npc ~= currentNPC then return end

    -- *** NUEVO: DESACTIVAR CONTROLES MIENTRAS EL MENÚ ESTÁ ABIERTO ***
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
                table.insert(elements, {
                    label = drugConfig.label .. ' (' .. count .. ' uds.)',
                    value = drugName,
                    price = drugConfig.minPrice .. ' - ' .. drugConfig.maxPrice
                })
            end
        end

        -- 3. Mostrar el menú de venta
        if #elements > 0 then
            ESX.UI.Menu.Open(
                'default', GetCurrentResourceName(), 'street_dealer_menu',
                {
                    title    = 'Venta de Drogas',
                    align    = 'right',
                    elements = elements,
                },
                function(data, menu)
                    -- El jugador selecciona una droga
                    local drugName = data.current.value
                    menu.close()

                    -- Iniciar el proceso de animación ANTES de hablar con el servidor
                    TriggerEvent('streetdealer:client:playDealAnim')

                    -- Enviar al servidor para procesar
                    TriggerServerEvent('streetdealer:server:procesarVenta', drugName, currentNPC)

                end,
                function(data, menu)
                    -- Cuando el jugador cierra el menú
                    menu.close()
                    TriggerEvent('streetdealer:client:resetNPC', currentNPC)
                end
            )
        else
            ESX.ShowNotification("No tienes drogas para vender.")
            TriggerEvent('streetdealer:client:resetNPC', currentNPC) -- Resetear NPC aunque no haya drogas
        end
    end)
end)

-- *** NUEVA FUNCIÓN: Animación del Trato ***
RegisterNetEvent('streetdealer:client:playDealAnim', function()
    local playerPed = GetPlayerPed(-1)
    local animDict = 'mp_common'
    local animName = 'givetake_a' -- Animación de pase de mano rápido
    
    -- Asegurar que el NPC sigue existiendo
    if currentNPC and DoesEntityExist(currentNPC) then
        
        LoadAnimDict(animDict)

        -- Reproducir animación en el NPC y el Jugador simultáneamente
        TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, Config.Riesgo.TiempoAnimacion, 0, 0, false, false, false)
        TaskPlayAnim(currentNPC, animDict, animName, 8.0, 8.0, Config.Riesgo.TiempoAnimacion, 0, 0, false, false, false)

        -- Esperar la duración de la animación (tiempo configurado en config.lua)
        Citizen.Wait(Config.Riesgo.TiempoAnimacion)
        
        -- Detener animaciones forzosamente (aunque deberían terminar solas)
        StopAnimTask(playerPed, animDict, animName, -4.0)
        StopAnimTask(currentNPC, animDict, animName, -4.0)
    end
end)

-- *** NUEVA FUNCIÓN: Reseteo del NPC (Llamada desde el servidor al finalizar) ***
RegisterNetEvent('streetdealer:client:resetNPC', function(npc)
    -- 1. Devolver el control al jugador (es crucial)
    SetPlayerControl(PlayerId(), true, false)

    if DoesEntityExist(npc) then
        -- 2. Limpiar todas las tareas del NPC
        ClearPedTasks(npc)
        
        -- 3. Permitir que el NPC vuelva a su comportamiento normal (vagabundear)
        SetPedKeepTask(npc, false)
        TaskWanderInArea(npc, GetEntityCoords(npc), 10.0, 10.0, 10.0, 1.0, 1.0)
        
        -- 4. Limpiar la referencia global
        currentNPC = nil 
    end
end)
