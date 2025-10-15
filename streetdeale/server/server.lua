-- server/server.lua (CÓDIGO COMPLETO FINAL)

local ESX = nil

TriggerEvent('esx:getExtendedServer', function(obj) ESX = obj end)

-- Mapa para almacenar la reputación del jugador (Temporal)
local PlayerReputation = {}

-- Eventos de conexión/desconexión para inicializar la reputación
AddEventHandler('esx:playerLoaded', function(source)
    PlayerReputation[source] = 0 -- Podrías cargar esto desde una base de datos aquí
end)

AddEventHandler('playerDropped', function(source)
    PlayerReputation[source] = nil -- Eliminar reputación al desconectar
end)


-- Función de Callback: Obtener drogas que tiene el jugador
ESX.RegisterServerCallback('streetdealer:server:getDrogasJugador', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerDrogas = {}

    for drugName, config in pairs(Config.Drogas) do
        local item = xPlayer.getInventoryItem(drugName)
        if item and item.count > 0 then
            playerDrogas[drugName] = item.count
        end
    end
    cb(playerDrogas)
end)

-- Función Auxiliar: Obtener la reputación del jugador
local function GetPlayerReputation(source)
    return PlayerReputation[source] or 0
end

-- Función Auxiliar: Añadir reputación al jugador
local function AddReputation(source, amount)
    local currentRep = GetPlayerReputation(source)
    local newRep = currentRep + amount

    if newRep > Config.Reputacion.MaxReputacion then
        newRep = Config.Reputacion.MaxReputacion
    end

    PlayerReputation[source] = newRep
    
    TriggerClientEvent('esx:showNotification', source, 'Has ganado ' .. amount .. ' puntos de Reputación Criminal. Total: ' .. newRep)
end

-- Evento del Servidor: Procesa la venta (Ahora recibe 'zoneName')
RegisterNetEvent('streetdealer:server:procesarVenta', function(drugName, npcId, zoneName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local drugConfig = Config.Drogas[drugName]
    local amount = 1 

    if not drugConfig then return end

    -- 1. Validar que el jugador tiene la droga
    local item = xPlayer.getInventoryItem(drugName)
    if not item or item.count < amount then
        TriggerClientEvent('esx:showNotification', source, 'No tienes ' .. drugConfig.label .. ' suficiente.')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
        return
    end

    -- 2. CALCULAR RIESGO AJUSTADO POR REPUTACIÓN
    local playerRep = GetPlayerReputation(source)
    
    local reduction = (playerRep / Config.Reputacion.PuntosParaMaximaReduccion) * Config.Reputacion.MaxReduccionPorc
    if reduction > Config.Reputacion.MaxReduccionPorc then
        reduction = Config.Reputacion.MaxReduccionPorc
    end
    
    local probPolisAjustada = math.max(1, Config.Riesgo.ProbabilidadPolisBase - reduction) 
    local probCorrerAjustada = math.max(3, Config.Riesgo.ProbabilidadCorrerBase - reduction * 2) 
    
    local isCop = (math.random(1, 100) <= probPolisAjustada)
    local isScared = (math.random(1, 100) <= probCorrerAjustada)

    -- 3. CÁLCULO DE PRECIO POR ZONA
    local zoneConfig = Config.ZonasDeVenta[zoneName] or Config.ZonasDeVenta['DEFAULT']
    local priceMultiplier = zoneConfig.multiplier
    
    local basePrice = math.random(drugConfig.minPrice, drugConfig.maxPrice)
    local finalPrice = math.floor(basePrice * priceMultiplier) 

    -- 4. Ejecutar el resultado
    if isCop then
        TriggerClientEvent('esx:showNotification', source, '¡El comprador era un policía encubierto! ¡CORRE!', 'error')
        TriggerEvent('esx_policejob:server:createGangsterAlert', GetEntityCoords(npcId))
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
    elseif isScared then
        TriggerClientEvent('esx:showNotification', source, 'El NPC se asustó y salió corriendo. Venta fallida.', 'warning')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
    else
        -- Éxito
        local sellPrice = finalPrice 

        xPlayer.removeInventoryItem(drugName, amount)
        xPlayer.addMoney(sellPrice)
        
        AddReputation(source, Config.Reputacion.PuntosPorVentaExitosa)

        TriggerClientEvent('esx:showNotification', source, 'Venta exitosa en ' .. zoneConfig.label .. '. Ganaste $' .. sellPrice .. '.')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
    end
end)
