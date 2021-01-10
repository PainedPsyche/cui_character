fx_version 'cerulean'
games { 'gta5' }

client_scripts {
    '@es_extended/locale.lua',
    'shared/config.lua',
    'locales/en.lua',
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
    'ui/assets/icons/*.svg'
    'ui/pages/*.html',
	'ui/pages/optional/*.html',
}

dependencies {
    'es_extended'
}

exports {
    'IsPlayerFullyLoaded'
}

provide {
    'skinchanger',
    'esx_skin'
}
