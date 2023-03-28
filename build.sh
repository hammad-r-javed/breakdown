#!/bin/bash


PROJ_DIR=$(pwd)


show_params()
{
    echo -e "Usage: build [args...]"
    echo -e "  -sls                         Starts local PHP dev server at localhost:4000"
    echo -e "  -start-local-server          Starts local PHP dev server at localhost:4000"
    echo ""
    echo -e "  -sw                          Runs watcher script"
    echo -e "  -start-watcher               Runs watcher script"
    echo ""
    echo -e "  -bc                          Builds client src code"
    echo -e "  -build-client                Builds client src code"
    echo ""
    echo -e "  -cc                          Cleans public/ dir"
    echo -e "  -clean-client                Cleans public/ dir"
    echo ""
    echo -e "  -fmt                         Formats src files"
    echo -e "  -format                      Formats src files"
    echo ""
    echo -e "  -h                           Print build script command line options"
    echo -e "  -help                        Print build script command line options"

}


build_login_page()
{
    cp $PROJ_DIR/src/client/login/login.html $PROJ_DIR/public/index.html # temp name (for local PHP server to work)
    elm make src/client/login/Login.elm --output public/login.js
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
        php -S localhost:4000 -t public # default
    elif [[ $param == "-build-client" ]] || [[ $param == "-bc" ]]; then
        build_login_page
    elif [[ $param == "-clean-client" ]] || [[ $param == "-cc" ]]; then
        rm public/*
        echo "public/ folder cleared!"
    elif [[ $param == "-format" ]] || [[ $param == "-fmt" ]]; then
        elm-format src/client
    elif [[ $param == "-start-watcher" ]] || [[ $param == "-sw" ]]; then
        python3 build_tools/watcher.py
    elif [[ $param == "-help" ]] || [[ $param == "-h" ]]; then
        show_params
    else
        echo -e "'$param' is an invalid param."
        show_params
    fi
done
