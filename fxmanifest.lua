fx_version 'cerulean'
games { 'gta5' }

client_scripts {
    '@es_extended/locale.lua',
    'shared/config.lua',
    'locales/en.lua',
    --'client/blacklist.lua',
    'client/camera.lua',
    'client/main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'shared/config.lua',
    --'@esx_identity/server/main.lua',
    'server/main.lua'
}

ui_page('ui/index.html')

files {
    'ui/index.html',
    'ui/script.js',
    'ui/style.css',
    'ui/assets/fonts/chaletlondon1960.woff2',
    'ui/assets/icons/apparel.svg',
    'ui/assets/icons/body.svg',
    'ui/assets/icons/check.svg',
    'ui/assets/icons/features.svg',
    'ui/assets/icons/head.svg',
    'ui/assets/icons/identity.svg',
    'ui/assets/icons/legs.svg',
    'ui/assets/icons/style.svg',
    'ui/assets/icons/symbol-female.svg',
    'ui/assets/icons/symbol-male.svg',
    'ui/pages/apparel.html',
    'ui/pages/features.html',
    'ui/pages/identity.html',
    'ui/pages/style.html',
    'ui/pages/optional/blusher.html',
    'ui/pages/optional/chesthair.html',
    'ui/pages/optional/esxidentity.html',
    'ui/pages/optional/facialhair.html',
    'ui/pages/optional/hair_female.html',
    'ui/pages/optional/hair_male.html',
    'ui/pages/optional/makeup_eye.html',
    'ui/pages/optional/makeup_facepaint.html',
}

dependencies {
    'es_extended'
}

exports {
    'IsPlayerFullyLoaded',
    'SetOnDutyStatus'
}

provide {
    'skinchanger',
    'esx_skin'
}