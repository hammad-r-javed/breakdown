#!/bin/bash

PROJ_DIR=$(pwd)

function print_logline {
    echo "[$(date +\"%d-%m-%y\")][$(date +\"%T\")] [full-proj-build] $1"
}

print_logline "Starting full project build process"

function build_client {
    print_logline "Executing client build process"

    cd client
    ./build.sh
    cd ../

    print_logline "Client build process completed"
}


function build_backend {
    print_logline "Executing backend build process"

    cd backend
    ./build.sh
    cd ../

    print_logline "Backend build process completed"
}

build_client && build_backend

print_logline "Full project build process completed successfully"
