Config = {}

-- [[ CONFIGURACIÓN PRINCIPAL ]]
Config.Debug = false
Config.EnableBlips = true
Config.EnableAdvancedFeatures = true

-- [[ ZONAS DE VENTA OPTIMIZADAS ]]
Config.ZonasDeVenta = {
    ['VINEYARD'] = { 
        multiplier = 1.35, 
        label = 'Vinewood Hills', 
        ownerJob = 'none',
        heatMultiplier = 0.8,
        spawnChance = 0.3
    },
    ['ROCKFORD'] = { 
        multiplier = 1.25, 
        label = 'Rockford Hills', 
        ownerJob = 'none',
        heatMultiplier = 0.9,
        spawnChance = 0.4
    },
    ['RANCHO']   = { 
        multiplier = 0.85, 
        label = 'Rancho', 
        ownerJob = 'bloods',
        heatMultiplier = 1.3,
        spawnChance = 0.8
    },
    ['DEFAULT'] = { 
        multiplier = 0.90, 
        label = 'Zona Normal', 
        ownerJob = 'none',
        heatMultiplier = 1.0,
        spawnChance = 0.6
    },
}

-- [[ SISTEMA DE DROGAS MEJORADO ]]
Config.Drogas = {
    ['weed'] = {
        label = '💨 Marihuana',
        minPrice = 10,
        maxPrice = 25,
        addictionLevel = 1,
        policeInterest = 1,
        qualityMultiplier = 1.2
    },
    ['cocaine'] = {
        label = '❄️ Cocaína', 
        minPrice = 150,
        maxPrice = 250,
        addictionLevel = 8,
        policeInterest = 9,
        qualityMultiplier = 1.5
    },
    ['meth'] = {
        label = '💊 Metanfetamina',
        minPrice = 100,
        maxPrice = 180,
        addictionLevel = 7,
        policeInterest = 8,
        qualityMultiplier = 1.4
    }
}

-- [[ SISTEMA DE HABILIDADES DEALER ]]
Config.Habilidades = {
    ['persuasion'] = {
        label = 'Persuasión',
        maxLevel = 10,
        effect = function(level)
            return 1 + (level * 0.05)
        end
    },
    ['stealth'] = {
        label = 'Sigilo', 
        maxLevel = 10,
        effect = function(level)
            return 1 - (level * 0.03)
        end
    },
    ['networking'] = {
        label = 'Contactos',
        maxLevel = 5,
        effect = function(level)
            return level * 2
        end
    }
}

-- [[ CLIENTES ESPECIALES ]]
Config.ClientesEspeciales = {
    ['rico'] = {
        model = 'a_m_m_business_01',
        multiplier = 2.0,
        minReputation = 100,
        chance = 0.1
    },
    ['adicto'] = {
        model = 'a_m_m_tramp_01', 
        multiplier = 0.7,
        minReputation = 50,
        chance = 0.2,
        bulkBuy = true
    }
}

-- [[ RIESGOS Y MECÁNICAS ]]
Config.Riesgo = {
    rangoDeteccion = 3.0,
    ProbabilidadPolisBase = 5,
    ProbabilidadCorrerBase = 15,
    TiempoAnimacion = 3000,
    CooldownEntreVentas = 30000,
    MaxVentasPorMinuto = 3
}

-- [[ SISTEMA DE MERCADO NEGRO ]]
Config.MercadoNegro = {
    enabled = true,
    priceFluctuation = 0.2,
    updateInterval = 300,
    demandEffect = 0.1
}

-- [[ ALERTAS MEJORADAS ]]
Config.AlertaMedicos = {
    MedicJobName = 'ambulance',
    GlobalSaleThreshold = 8,
    AlertColor = 'inform',
    CoolDownTime = 300,
    EnableOverdoseAlerts = true
}

Config.AlertaInvasion = {
    HeatThreshold = 4,
    JobAlertColor = 'error', 
    CoolDownTime = 120,
    EnableRetaliation = true
}

-- [[ OPTIMIZACIÓN DE NPCs ]]
Config.NPCOptimization = {
    MaxActiveNPCs = 15,
    SpawnRadius = 100.0,
    DespawnRadius = 150.0,
    CheckInterval = 2000,
    EnablePooling = true
}

-- [[ MODELOS NPC OPTIMIZADOS ]]
Config.ModelosNPC = {
    Whitelist = true,
    CacheModels = true,
    
    AllowedModels = {
        'a_m_m_hillbilly_01', 'a_f_m_beach_01', 'a_m_m_bevhills_02',
        'g_m_y_famfor_01', 'g_m_y_famdnf_01', 'a_m_m_tramp_01',
        'csb_car3guy1', 'csb_chef', 's_m_m_autoshop_01',
        'a_m_y_skater_01', 'a_f_y_hipster_01', 'a_m_m_tourist_01'
    }
}

print('[STREETDEALER] Configuración mejorada cargada')