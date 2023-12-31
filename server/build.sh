#!/bin/bash

function print_logline {
    echo "[$(date +\"%d-%m-%y\")][$(date +\"%T\")] [server-build] $1"
}

function folders_check {
    if [[ ! -d build ]]; then
        print_logline "'build/' dir not found."
        print_logline "Creating 'build/' dir"
        mkdir build
        print_logline "'build/' dir successfully created"
    fi
}

folders_check

print_logline "building server proj"
go build -o build/main cmd/*.go
