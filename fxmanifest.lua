fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'sg-outfitbag'
author 'sgMAGLERA'
description 'Outfit bag system for QBCore servers'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    '@qb-core/client/main.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

escrow_ignore {
    'config.lua',
}