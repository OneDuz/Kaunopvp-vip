fx_version 'cerulean'
game 'gta5'

lua54 "yes"
author "onecodes"
version "1.3.9"
description 'Advanced VIP system made for kaunopvp.lt'


server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

exports {
    'IsVIP',
    'FunctionName2'
}
shared_script '@es_extended/imports.lua'
shared_script '@ox_lib/init.lua'
