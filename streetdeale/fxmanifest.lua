-- fxmanifest.lua

fx_version 'cerulean'
games { 'gta5' }

-- DEPENDENCIA CLAVE: ESX
dependencies {
    'es_extended'
    -- Puedes añadir aquí la dependencia del menú o target que uses (esx_menu_default, qtarget, etc.)
}

shared_scripts {
    '@es_extended/locale.lua', -- Usar locale de ESX
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

