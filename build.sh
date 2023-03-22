#!/bin/bash

PROJ_DIR=$(pwd)

show_params()
{
    echo -e "Usage: build [args...]"
    echo -e "  -sls                         Starts local server at localhost:4000"
    echo -e "  -start-local-server          Starts local server at localhost:4000"
    echo ""
    echo -e "  -c                           Builds client src code"
    echo -e "  -client                      Builds client src code"
    echo ""
    echo -e "  -h                           Print build script command line options"
    echo -e "  -help                        Print build script command line options"

}

folders_check()
{
    if [[ ! -d $PROJ_DIR/public ]]; then
        echo -e " public/ not found.\n Creating public/ dir"
        mkdir public
        echo " public/ dir successfully created\n"
    fi
}

if [[ $# -eq 0 ]]; then
    show_params
fi

folders_check

for param in "$@"
do    
    if [[ $param == "-start-local-server" ]] || [[ $param == "-sls" ]]; then
        php -S localhost:4000 -t public
    elif [[ $param == "-client" ]] || [[ $param == "-c" ]]; then
        cp $PROJ_DIR/src/client/index.html $PROJ_DIR/public/index.html
        elm make src/client/Breakdown.elm --output public/breakdown.js
    elif [[ $param == "-help" ]] || [[ $param == "-h" ]]; then
        show_params
    else
        echo -e "'$param' is an invalid param."
        show_params
    fi
done
