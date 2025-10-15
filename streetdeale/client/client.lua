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

-- [Mantenemos la función IsValidDealerTarget del plan anterior]
local function IsValidDealerTarget(ped)
    -- Lógica para filtrar NPCs (no jugadores, no en vehículos, no policías/EMS, etc.)
    if IsPedAPlayer(ped) or IsPedInAnyVehicle(ped, false) then
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

                    -- 1. Mostrar texto de interacción (Ejemplo genérico de ayuda)
                    ESX.ShowHelpNotification("Pulsa ~INPUT_CONTEXT~ para ofrecer droga al peatón.", 1) -- INPUT_CONTEXT es la tecla E

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

-- Evento para iniciar la venta
RegisterNetEvent('streetdealer:client:iniciarVenta', function(npc)
    if not isNearNPC or npc ~= currentNPC then return end

    -- 1. Detener al NPC y animaciones
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
            -- Usamos el menú nativo de ESX (o puedes usar esx_menu_dialog/esx_menu_default)
            ESX.UI.Menu.Open(
                'default', GetCurrentResourceName(), 'street_dealer_menu',
                {
                    title    = 'Venta de Drogas',
                    align    = 'right',
                    elements = elements,
                },
                function(data, menu)
                    -- Cuando el jugador selecciona una droga
                    local drugName = data.current.value
                    -- Cierre el menú
                    menu.close()
                    -- Reproducir animación de trato
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
            TriggerEvent('streetdealer:client:resetNPC', currentNPC)
        end
    end)
end)

-- Funciones de animación y reseteo (Implementaremos esto en el siguiente paso)
RegisterNetEvent('streetdealer:client:playDealAnim', function()
    -- Lógica de animación aquí
end)

RegisterNetEvent('streetdealer:client:resetNPC', function(npc)
    -- Lógica para liberar al NPC
    if DoesEntityExist(npc) then
        SetPedKeepTask(npc, false)
        TaskWanderInArea(npc, GetEntityCoords(npc), 10.0, 10.0, 10.0, 1.0, 1.0)
    end
end)

