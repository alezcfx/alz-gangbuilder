fx_version "adamant"
game "gta5"

author 'BZRR - DEV discord.gg/VJEuqYkSWt'

description 'Gang Builder'

version '1.0.1'

client_scripts {
	"input/client.lua"
}

ui_page "input/ui/ui.html"

files {
	"input/ui/*.css",
	"input/ui/*.js",
	"input/ui/*.html"
}

exports {
	"Show",
	"ShowSync",
	"IsVisible",
	"Hide"
}


shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    "RageUI/RMenu.lua",
    "RageUI/menu/RageUI.lua",
    "RageUI/menu/Menu.lua",
    "RageUI/menu/MenuController.lua",
    "RageUI/components/*.lua",
    "RageUI/menu/elements/*.lua",
    "RageUI/menu/items/*.lua",
    "RageUI/menu/panels/*.lua",
    "RageUI/menu/windows/*.lua",
    "client/gang_menu.lua",
    "client/gang_f7.lua",
    "client/gang_garage.lua",
    "client/gang_storage.lua",
    "client/gang_boss.lua"
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/gang_server.lua',
    'server/gang_f7.lua',
    "server/gang_storage.lua",
    "server/gang_boss.lua"
}
