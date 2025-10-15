-- config.lua (CÓDIGO COMPLETO FINAL con ALERTA PARA MÉDICOS)

Config = {}

-- [[ Zonas y Multiplicadores de Precios y Dueños ]]
-- ownerJob: El nombre del job que será alertado de actividad en su zona. 'none' si no tiene dueño.
Config.ZonasDeVenta = {
    -- ZONAS DE ALTO VALOR (Sin dueño por defecto)
    ['VINEYARD'] = { multiplier = 1.35, label = 'Vinewood Hills', ownerJob = 'none' },
    ['ROCKFORD'] = { multiplier = 1.25, label = 'Rockford Hills', ownerJob = 'none' },
    ['DOWNTOWN'] = { multiplier = 1.15, label = 'Downtown Los Santos', ownerJob = 'none' },
    
    -- ZONAS DE BAJO VALOR (Controladas por pandillas)
    ['RANCHO']   = { multiplier = 0.85, label = 'Rancho', ownerJob = 'bloods' }, 
    ['DAVIS']    = { multiplier = 0.80, label = 'Davis', ownerJob = 'gang_a' },    
    ['GROVE']    = { multiplier = 0.70, label = 'Grove Street Area', ownerJob = 'gang_b' },  

    -- ZONAS NEUTRAS O POR DEFECTO
    ['VESPUCCI'] = { multiplier = 1.00, label = 'Vespucci Beach', ownerJob = 'none' },
    ['CHILAD']   = { multiplier = 1.00, label = 'Chiliad Mountain', ownerJob = 'none' },
    ['DELPERRO'] = { multiplier = 1.10, label = 'Del Perro', ownerJob = 'none' },
    ['DEFAULT'] = { multiplier = 0.90, label = 'Zona Desconocida/Normal', ownerJob = 'none' },
}

-- [[ Configuracion de Drogas ]]
Config.Drogas = {
    ['weed'] = {
        label = 'Marihuana',
        minPrice = 10,
        maxPrice = 25,
    },
    ['cocaine'] = {
        label = 'Cocaína',
        minPrice = 150,
        maxPrice = 250,
    },
    ['meth'] = {
        label = 'Metanfetamina',
        minPrice = 100,
        maxPrice = 180,
    }
}

-- [[ Configuracion de Riesgos BASE y Reputación ]]
Config.Riesgo = {
    rangoDeteccion = 3.0,  
    
    ProbabilidadPolisBase = 5,   
    ProbabilidadCorrerBase = 15, 
    
    TiempoAnimacion = 3000,      
}

Config.Reputacion = {
    MaxReputacion = 1000,
    PuntosPorVentaExitosa = 5,
    MaxReduccionPorc = 4,           
    PuntosParaMaximaReduccion = 500
}

-- [[ CONFIGURACIÓN: HEAT LOCAL (Riesgo en el Área) ]]
Config.Heat = {
    HeatRadius = 50.0,             
    SalesToTriggerHeat = 3,        
    MaxHeatRiskIncrease = 10,      
    HeatDurationSeconds = 300,     
}

-- [[ CONFIGURACIÓN: ALERTA DE INVASIÓN (Pandillas) ]]
Config.AlertaInvasion = {
    HeatThreshold = 5,             -- Cuántas ventas recientes (activeSales) se necesitan en la zona.
    JobAlertColor = 'error',       
    CoolDownTime = 120,            
}

-- [[ NUEVA CONFIGURACIÓN: ALERTA DE USO DE DROGAS (Médicos) ]]
Config.AlertaMedicos = {
    MedicJobName = 'ambulance',     -- Nombre del trabajo de paramédico/enfermero (e.g. 'ambulance', 'medic')
    GlobalSaleThreshold = 10,       -- Número TOTAL de ventas en la ciudad para disparar la alerta.
    AlertColor = 'inform',          -- Color de la notificación (e.g. 'success', 'inform', 'warning').
    CoolDownTime = 300,             -- Tiempo de espera (en segundos, 5 minutos) entre alertas.
}

-- [[ CONFIGURACIÓN: FILTRO DE MODELOS DE NPC ]]

Config.ModelosNPC = {
    Whitelist = true, 
    
    AllowedModels = {
        'a_m_m_hillbilly_01', 'a_f_m_beach_01', 'a_m_m_bevhills_02',
        'g_m_y_famfor_01', 'g_m_y_famdnf_01', 'a_m_m_tramp_01',
        'csb_car3guy1', 'csb_chef', 's_m_m_autoshop_01',
    },

    ExcludedModels = {
        's_m_y_cop_01', 's_m_y_hwaycop_01', 's_f_y_hooker_01', 'a_m_m_business_01',
    }
}
