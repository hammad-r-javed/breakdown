#!/bin/bash

PROJ_DIR=$(pwd)
SERVER_FOLDER_NAME="server"
CLIENT_FOLDER_NAME="client"

function print_logline {
    echo "[$(date +\"%d-%m-%y\")][$(date +\"%T\")] [full-proj-build] $1"
}

function folders_check {
    if [[ ! -d db ]]; then
        print_logline "'db' dir not found."
        print_logline "creating 'db' dir"
        mkdir out
        print_logline "'db' dir successfully created"
        # TODO - init DB here
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
