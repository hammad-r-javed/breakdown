#!/bin/bash

PROJ_DIR=$(pwd)
SERVER_FOLDER_NAME="server"
CLIENT_FOLDER_NAME="client"

function print_logline {
    echo "[$(date +\"%d-%m-%y\")][$(date +\"%T\")] [full-proj-build] $1"
}

print_logline "Starting full project build process"

function build_client {
    print_logline "Executing client build process"

    cd $CLIENT_FOLDER_NAME
    ./build.sh
    cd ../

    print_logline "Client build process completed"
} 


function build_server {
    print_logline "Executing server build process"

    cd $SERVER_FOLDER_NAME
    ./build.sh
    cd ../

    print_logline "Server build process completed"
}

build_client && build_server

print_logline "Full project build process completed"
