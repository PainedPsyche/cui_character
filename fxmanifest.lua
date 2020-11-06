fx_version 'cerulean'
games { 'gta5' }

client_scripts {
    '@es_extended/locale.lua',
    'config.lua',
    'locales/en.lua',
    'client/data.lua',
    'client/main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua'
}

ui_page('ui/index.html')

files {
    'ui/index.html',
    'ui/script.js',
    'ui/style.css',
    'ui/assets/fonts/chaletlondon1960.woff2',
    'ui/assets/icons/apparel.svg',
    'ui/assets/icons/features.svg',
    'ui/assets/icons/identity.svg',
    'ui/assets/icons/style.svg'
}

dependencies {
    'es_extended'
}