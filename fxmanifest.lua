fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'rsg-banking'
version '1.2.1'

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'locales/en.lua', -- preferred language
    'config.lua',
}

server_scripts {
    'server/server.lua',
}

client_scripts {
    'client/client.lua',
}

ui_page {
    'ui/index.html'
}

files {
    'ui/index.html',
    'ui/script.js',
    'ui/style.css',
    'ui/*',
    'ui/fonts/*',
    'ui/img/*',
}

dependencies { 
    'rsg-core',
    'rsg-target',
    'ox_lib' 
}

lua54 'yes'
