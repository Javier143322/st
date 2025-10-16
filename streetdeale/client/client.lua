-- client/client.lua (VERSIÓN MEJORADA Y OPTIMIZADA)
local ESX = nil
local isNearNPC = false
local currentNPC = nil
local lastSaleTime = 0
local salesThisMinute = 0
local lastMinuteCheck = GetGameTimer()
local activeNPCs = {}
local cachedModels = {}
local currentZone = nil

-- Inicializar ESX
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    InitializeModelCache()
end)

-- [[ SISTEMA DE CACHÉ DE MODELOS PARA MEJOR RENDIMIENTO ]]
function InitializeModelCache()
    for _, modelName in ipairs(Config.ModelosNPC.AllowedModels) do
        local modelHash = GetHashKey(modelName)
        cachedModels[modelHash] = true
    end
    print('[STREETDEALER] Caché de modelos inicializado: ' .. #Config.ModelosNPC.AllowedModels .. ' modelos')
end

-- [[ FUNCIONES AUXILIARES OPTIMIZADAS ]]
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(5)
        end
    end
end

local function IsModelValid(ped)
    local pedModel = GetEntityModel(ped)
    return cachedModels[pedModel] == true
end

local function IsValidDealerTarget(ped)
    if not DoesEntityExist(ped) then return false end
    if IsPedAPlayer(ped) or IsPedInAnyVehicle(ped, false) or IsPedDeadOrDying(ped, true) then
        return false
    end
    return IsModelValid(ped)
end

local function GetCurrentZone()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local zoneName = GetNameOfZone(playerCoords.x, playerCoords.y, playerCoords.z)
    return Config.ZonasDeVenta[zoneName] or Config.ZonasDeVenta['DEFAULT']
end

local function CanSellInZone()
    local currentTime = GetGameTimer()
    
    -- Cooldown entre ventas
    if currentTime - lastSaleTime < Config.Riesgo.CooldownEntreVentas then
        local remaining = (Config.Riesgo.CooldownEntreVentas - (currentTime - lastSaleTime)) / 1000
        ESX.ShowNotification('⏰ Espera ' .. math.ceil(remaining) .. ' segundos antes de vender otra vez')
        return false
    end
    
    -- Límite de ventas por minuto
    if currentTime - lastMinuteCheck > 60000 then
        salesThisMinute = 0
        lastMinuteCheck = currentTime
    end
    
    if salesThisMinute >= Config.Riesgo.MaxVentasPorMinuto then
        ESX.ShowNotification('🚫 Demasiadas ventas rápidas, espera un momento')
        return false
    end
    
    return true
end

-- [[ SISTEMA DE DETECCIÓN OPTIMIZADO POR ZONAS ]]
Citizen.CreateThread(function()
    while true do
        local sleepTime = Config.NPCOptimization.CheckInterval
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Actualizar zona actual
        currentZone = GetCurrentZone()
        
        -- Limpiar NPCs lejanos
        for npc, data in pairs(activeNPCs) do
            if #(playerCoords - GetEntityCoords(npc)) > Config.NPCOptimization.DespawnRadius then
                if DoesEntityExist(npc) then
                    DeleteEntity(npc)
                end
                activeNPCs[npc] = nil
            end
        end
        
        -- Spawn de NPCs si es necesario
        if currentZone.spawnChance > math.random() then
            SpawnDealerNPCs(playerCoords)
        end
        
        -- Detección de NPCs cercanos
        isNearNPC = false
        currentNPC = nil
        
        for npc, data in pairs(activeNPCs) do
            if DoesEntityExist(npc) then
                local distance = #(playerCoords - GetEntityCoords(npc))
                if distance < Config.Riesgo.rangoDeteccion then
                    sleepTime = 5
                    isNearNPC = true
                    currentNPC = npc
                    
                    ESX.ShowHelpNotification("Pulsa ~INPUT_CONTEXT~ para ofrecer droga", 1)
                    
                    if IsControlJustPressed(0, 38) then -- Tecla E
                        if CanSellInZone() then
                            TriggerEvent('streetdealer:client:iniciarVenta', currentNPC)
                        end
                    end
                    break
                end
            end
        end
        
        Citizen.Wait(sleepTime)
    end
end)

-- [[ SISTEMA DE SPAWN DE NPCS OPTIMIZADO ]]
function SpawnDealerNPCs(playerCoords)
    if not Config.NPCOptimization.EnablePooling then return end
    
    local activeCount = 0
    for _ in pairs(activeNPCs) do
        activeCount = activeCount + 1
    end
    
    if activeCount >= Config.NPCOptimization.MaxActiveNPCs then
        return
    end
    
    local spawnCoords = GetSafeSpawnCoords(playerCoords)
    if spawnCoords then
        local modelName = Config.ModelosNPC.AllowedModels[math.random(1, #Config.ModelosNPC.AllowedModels)]
        local modelHash = GetHashKey(modelName)
        
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(10)
        end
        
        local npc = CreatePed(4, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)
        
        -- Configurar NPC
        SetEntityAsMissionEntity(npc, true, true)
        SetPedFleeAttributes(npc, 0, false)
        SetPedCombatAttributes(npc, 46, true)
        SetPedAsEnemy(npc, false)
        TaskWanderStandard(npc, 10.0, 10)
        
        activeNPCs[npc] = {
            coords = spawnCoords,
            spawnTime = GetGameTimer()
        }
        
        SetModelAsNoLongerNeeded(modelHash)
    end
end

function GetSafeSpawnCoords(playerCoords)
    for i = 1, 10 do
        local angle = math.random() * math.pi * 2
        local distance = math.random(20, Config.NPCOptimization.SpawnRadius)
        local x = playerCoords.x + math.cos(angle) * distance
        local y = playerCoords.y + math.sin(angle) * distance
        local z = playerCoords.z + 10.0
        
        local groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        if groundZ then
            local safeCoords = vector3(x, y, groundZ)
            if #(playerCoords - safeCoords) > 15.0 then
                return safeCoords
            end
        end
    end
    return nil
end

-- [[ EVENTO PRINCIPAL DE VENTA ]]
RegisterNetEvent('streetdealer:client:iniciarVenta', function(npc)
    if not isNearNPC or npc ~= currentNPC then return end

    SetPlayerControl(PlayerId(), false, false)

    -- Detener NPC
    TaskStandStill(npc, 10000)
    SetPedKeepTask(npc, true)

    -- Obtener drogas del jugador
    ESX.TriggerServerCallback('streetdealer:server:getDrogasJugador', function(drogas)
        local elements = {}
        local playerCoords = GetEntityCoords(PlayerPedId())
        local zoneName = GetNameOfZone(playerCoords.x, playerCoords.y, playerCoords.z)

        for drugName, count in pairs(drogas) do
            local drugConfig = Config.Drogas[drugName]
            if drugConfig then
                local zoneConfig = Config.ZonasDeVenta[zoneName] or Config.ZonasDeVenta['DEFAULT']
                local estimatedMin = math.floor(drugConfig.minPrice * zoneConfig.multiplier)
                local estimatedMax = math.floor(drugConfig.maxPrice * zoneConfig.multiplier)

                table.insert(elements, {
                    label = drugConfig.label .. ' (' .. count .. ' uds.) - ' .. estimatedMin .. '-' .. estimatedMax .. '$',
                    value = drugName,
                    count = count
                })
            end
        end

        -- Mostrar menú
        if #elements > 0 then
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'street_dealer_menu',
                {
                    title    = '💰 Venta de Drogas - ' .. currentZone.label,
                    align    = 'right',
                    elements = elements,
                },
                function(data, menu)
                    local drugName = data.current.value
                    menu.close()

                    -- Animación de trato
                    TriggerEvent('streetdealer:client:playDealAnim')

                    -- Registrar venta
                    lastSaleTime = GetGameTimer()
                    salesThisMinute = salesThisMinute + 1

                    -- Enviar al servidor
                    TriggerServerEvent('streetdealer:server:procesarVenta', drugName, PedToNet(npc), zoneName)

                end,
                function(data, menu)
                    menu.close()
                    TriggerEvent('streetdealer:client:resetNPC', npc, 0)
                end
            )
        else
            ESX.ShowNotification("❌ No tienes drogas para vender.")
            TriggerEvent('streetdealer:client:resetNPC', npc, 0)
        end
    end)
end)

-- [[ ANIMACIÓN DE TRATO ]]
RegisterNetEvent('streetdealer:client:playDealAnim', function()
    local playerPed = PlayerPedId()
    local animDict = 'mp_common'
    local animName = 'givetake_a'
    
    if currentNPC and DoesEntityExist(currentNPC) then
        LoadAnimDict(animDict)

        TaskTurnPedToFaceEntity(playerPed, currentNPC, 500)
        Citizen.Wait(500)
        
        TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, Config.Riesgo.TiempoAnimacion, 0, 0, false, false, false)
        TaskPlayAnim(currentNPC, animDict, animName, 8.0, 8.0, Config.Riesgo.TiempoAnimacion, 0, 0, false, false, false)

        Citizen.Wait(Config.Riesgo.TiempoAnimacion)
        
        ClearPedTasks(playerPed)
        ClearPedTasks(currentNPC)
    end
end)

-- [[ RESETEO DE NPC MEJORADO ]]
RegisterNetEvent('streetdealer:client:resetNPC', function(npc, state)
    SetPlayerControl(PlayerId(), true, false)

    if DoesEntityExist(npc) then
        ClearPedTasks(npc)
        SetPedKeepTask(npc, false)

        if state == 1 then
            -- NPC asustado - huye
            TaskSmartFleePed(npc, PlayerPedId(), 100.0, -1, false, false)
            ESX.ShowNotification('🏃 El cliente se asustó y huyó')
            
        elseif state == 2 then
            -- NPC policía - ataca
            TaskCombatPed(npc, PlayerPedId(), 0, 16)
            ESX.ShowNotification('👮 ¡Era un policía encubierto!')
            
        else 
            -- Venta exitosa o cierre normal
            TaskWanderStandard(npc, 10.0, 10)
        end

        currentNPC = nil
        isNearNPC = false
    end
end)

-- [[ CLEANUP AL SALIR ]]
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for npc, _ in pairs(activeNPCs) do
            if DoesEntityExist(npc) then
                DeleteEntity(npc)
            end
        end
        activeNPCs = {}
    end
end)

print('[STREETDEALER] Cliente mejorado cargado - Sistema optimizado')