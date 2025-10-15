-- server/server.lua (CÓDIGO COMPLETO FINAL)

local ESX = nil

TriggerEvent('esx:getExtendedServer', function(obj) ESX = obj end)

-- [GLOBALES DEL SERVIDOR]
local PlayerReputation = {} -- Reputación del jugador (se recomienda un sistema de DB para persistencia)
local LocalHeatTracker = {} -- { {coords = vector3, timestamp = os.time()}, ... }


-- [[ GESTIÓN DE LA REPUTACIÓN ]]

-- Eventos de conexión/desconexión para inicializar la reputación
AddEventHandler('esx:playerLoaded', function(source)
    PlayerReputation[source] = 0 -- Se puede cargar desde una DB aquí si es necesario
end)

AddEventHandler('playerDropped', function(source)
    PlayerReputation[source] = nil
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


-- [[ GESTIÓN DEL HEAT LOCAL ]]

-- Función Auxiliar: Calcula el riesgo de "Heat" en un área
local function CalculateAreaHeat(coords)
    local activeSales = 0
    local currentTime = os.time()

    for i = #LocalHeatTracker, 1, -1 do
        local sale = LocalHeatTracker[i]
        
        -- Verificar si la venta sigue siendo "caliente"
        if currentTime - sale.timestamp < Config.Heat.HeatDurationSeconds then
            -- Verificar si la venta está dentro del radio de influencia
            local distance = #(coords - sale.coords)
            if distance <= Config.Heat.HeatRadius then
                activeSales = activeSales + 1
            end
        else
            -- Si la venta es muy vieja, se elimina inmediatamente del tracker
            table.remove(LocalHeatTracker, i)
        end
    end

    -- Calcular el incremento de riesgo
    if activeSales >= Config.Heat.SalesToTriggerHeat then
        -- El riesgo aumenta linealmente por cada venta extra
        local extraSales = activeSales - Config.Heat.SalesToTriggerHeat
        local maxIncrease = Config.Heat.MaxHeatRiskIncrease
        local increasePerSale = maxIncrease / 10 -- Asume que 10 ventas es el máximo "calor"

        local finalIncrease = extraSales * increasePerSale
        if finalIncrease > maxIncrease then
            finalIncrease = maxIncrease
        end

        return finalIncrease, activeSales -- Devuelve el porcentaje de riesgo y el número de ventas cercanas
    end

    return 0, 0
end

-- Thread para limpiar periódicamente el LocalHeatTracker (aunque se limpia parcialmente en CalculateAreaHeat)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(120000) -- Espera 2 minutos
        
        local currentTime = os.time()
        for i = #LocalHeatTracker, 1, -1 do
            if currentTime - LocalHeatTracker[i].timestamp >= Config.Heat.HeatDurationSeconds then
                table.remove(LocalHeatTracker, i)
            end
        end
    end
end)


-- [[ LÓGICA PRINCIPAL DEL SERVIDOR ]]

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

    -- Obtener la posición del NPC (simula la posición de la venta)
    local npcCoords = GetEntityCoords(npcId) 

    -- 2. CALCULAR RIESGO: Reputación + Heat Local
    
    -- a) Cálculo de la Reputación (Reduce Riesgo)
    local playerRep = GetPlayerReputation(source)
    local reduction = (playerRep / Config.Reputacion.PuntosParaMaximaReduccion) * Config.Reputacion.MaxReduccionPorc
    if reduction > Config.Reputacion.MaxReduccionPorc then
        reduction = Config.Reputacion.MaxReduccionPorc
    end
    
    -- b) Cálculo del Heat Local (Añade Riesgo)
    local heatIncrease, activeSales = CalculateAreaHeat(npcCoords)
    
    -- c) Cálculo final de Probabilidad de Policía
    local finalPoliceChance = Config.Riesgo.ProbabilidadPolisBase - reduction + heatIncrease
    finalPoliceChance = math.max(1, finalPoliceChance) -- Mínimo 1%
    
    -- d) Cálculo final de Probabilidad de Huida (Solo Reputación, el Heat solo afecta a la policía)
    local probCorrerAjustada = math.max(3, Config.Riesgo.ProbabilidadCorrerBase - reduction * 2) -- Mínimo 3%
    
    -- Determinar el resultado
    local isCop = (math.random(1, 100) <= finalPoliceChance)
    local isScared = (math.random(1, 100) <= probCorrerAjustada)

    -- 3. CÁLCULO DE PRECIO POR ZONA
    local zoneConfig = Config.ZonasDeVenta[zoneName] or Config.ZonasDeVenta['DEFAULT']
    local priceMultiplier = zoneConfig.multiplier
    
    local basePrice = math.random(drugConfig.minPrice, drugConfig.maxPrice)
    local finalPrice = math.floor(basePrice * priceMultiplier) 

    -- 4. Ejecutar el resultado
    if isCop then
        TriggerClientEvent('esx:showNotification', source, '¡El comprador era un policía encubierto! ¡CORRE! (Riesgo: ' .. math.floor(finalPoliceChance) .. '%)', 'error')
        TriggerEvent('esx_policejob:server:createGangsterAlert', npcCoords)
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
    elseif isScared then
        TriggerClientEvent('esx:showNotification', source, 'El NPC se asustó y salió corriendo. Venta fallida. (Riesgo: ' .. math.floor(probCorrerAjustada) .. '%)', 'warning')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
    else
        -- Éxito
        local sellPrice = finalPrice 

        xPlayer.removeInventoryItem(drugName, amount)
        xPlayer.addMoney(sellPrice)
        
        -- Añadir Reputación
        AddReputation(source, Config.Reputacion.PuntosPorVentaExitosa)
        
        -- Añadir la venta al Heat Tracker
        table.insert(LocalHeatTracker, { coords = npcCoords, timestamp = os.time() })
        
        local heatMsg = ""
        if activeSales > 0 then
            heatMsg = " (Área Caliente: " .. activeSales .. " ventas cercanas)"
        end

        -- Notificación de éxito
        TriggerClientEvent('esx:showNotification', source, 'Venta exitosa en ' .. zoneConfig.label .. '. Ganaste $' .. sellPrice .. '.' .. heatMsg)
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId)
    end
end)
