#!/bin/bash

PROJ_DIR=$(pwd)
SERVER_FOLDER_NAME="server"
CLIENT_FOLDER_NAME="client"

function print_logline {
    echo "[$(date +\"%d-%m-%y\")][$(date +\"%T\")] [full-proj-build] $1"
}

function init_db {
	sqlite3 db/main.db "CREATE TABLE users (user_id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, password TEXT NOT NULL);"
}

function folders_check {
    if [[ ! -d db ]]; then
        print_logline "'db' dir not found."
        print_logline "creating 'db' dir"
        print_logline "'db' dir successfully created"
		init_db
		print_logline "db created"
	elif ! test -f db/main.db; then
        print_logline "database not found."
		print_logline "creating database"
		init_db
		print_logline "database created"
    fi
}

function build_client {
    print_logline "client build process start"

    cd $CLIENT_FOLDER_NAME
    ./build.sh
    cd ../

    print_logline "client build process end"
} 


function build_server {
    print_logline "server build process start"

    cd $SERVER_FOLDER_NAME
    ./build.sh
    cd ../

    print_logline "server build process end"
}

print_logline "full project build process start"

folders_check

build_client && build_server

print_logline "full project build process end"
