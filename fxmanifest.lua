game 'rdr3'
fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

version '0.3'

description 'All in one player and NPC medic script'

shared_script {
    'config.lua',
    'shared/locale.lua',
    'languages/*.lua'
}

client_scripts {
    'client/client.lua',
    'dataview.lua',
    'client/Weapons.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}
