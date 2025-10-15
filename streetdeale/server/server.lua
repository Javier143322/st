-- server/server.lua

local ESX = nil

TriggerEvent('esx:getExtendedServer', function(obj) ESX = obj end)

-- Función de Callback: Obtener drogas que tiene el jugador
ESX.RegisterServerCallback('streetdealer:server:getDrogasJugador', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerDrogas = {}

    for drugName, config in pairs(Config.Drogas) do
        local item = xPlayer.getInventoryItem(drugName) -- Función ESX
        if item and item.count > 0 then
            playerDrogas[drugName] = item.count
        end
    end
    cb(playerDrogas)
end)

-- Evento del Servidor: Procesa la venta
RegisterNetEvent('streetdealer:server:procesarVenta', function(drugName, npcId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local drugConfig = Config.Drogas[drugName]
    local amount = 1 -- Vender siempre 1 unidad

    if not drugConfig then return end

    -- 1. Validar que el jugador tiene la droga
    local item = xPlayer.getInventoryItem(drugName)
    if not item or item.count < amount then
        TriggerClientEvent('esx:showNotification', source, 'No tienes ' .. drugConfig.label .. ' suficiente.')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
        return
    end

    -- 2. Determinar el resultado (Riesgo)
    local isCop = (math.random(1, 100) <= Config.Riesgo.ProbabilidadPolis)
    local isScared = (math.random(1, 100) <= Config.Riesgo.ProbabilidadCorrer)

    if isCop then
        -- Caso: NPC es policía encubierto
        TriggerClientEvent('esx:showNotification', source, '¡El comprador era un policía encubierto! ¡CORRE!', 'error')
        -- Enviar alerta policial. (Necesitarás el evento de tu script de policía)
        TriggerEvent('esx_policejob:server:createGangsterAlert', GetEntityCoords(npcId)) -- EJEMPLO de evento policial
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
    elseif isScared then
        -- Caso: NPC se asusta y corre
        TriggerClientEvent('esx:showNotification', source, 'El NPC se asustó y salió corriendo. Venta fallida.', 'warning')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
    else
        -- Caso: Éxito
        local sellPrice = math.random(drugConfig.minPrice, drugConfig.maxPrice)

        -- 3. Eliminar la droga y dar dinero (usamos 'bank' o 'cash', en este caso 'money' es el dinero en mano)
        xPlayer.removeInventoryItem(drugName, amount)
        xPlayer.addMoney(sellPrice)

        -- 3.2. Notificación de éxito
        TriggerClientEvent('esx:showNotification', source, 'Venta exitosa. Ganaste $' .. sellPrice .. '.')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
    end
end)

